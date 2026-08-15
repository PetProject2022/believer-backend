// lib/features/khutbah/screens/khutbah_record_screen.dart
// Flutter UI for recording, uploading, and viewing khutbah with summaries

import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

class KhutbahRecordScreen extends StatefulWidget {
  const KhutbahRecordScreen({Key? key}) : super(key: key);

  @override
  State<KhutbahRecordScreen> createState() => _KhutbahRecordScreenState();
}

class _KhutbahRecordScreenState extends State<KhutbahRecordScreen> {
  late AudioRecorder _audioRecorder;
  bool _isRecording = false;
  String? _recordingPath;
  int _recordingDuration = 0;
  Timer? _durationTimer;
  
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  
  bool _isProcessing = false;
  double _uploadProgress = 0;
  String _processingStatus = '';
  
  Map<String, String>? _summaries;
  String _selectedLanguage = 'en';

  @override
  void initState() {
    super.initState();
    _audioRecorder = AudioRecorder();
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    _durationTimer?.cancel();
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      final hasPermission = await _audioRecorder.hasPermission();
      if (!hasPermission) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission required')),
        );
        return;
      }

      final outputFile = '/tmp/khutbah_${DateTime.now().millisecondsSinceEpoch}.wav';
      await _audioRecorder.start(
        RecordConfig(encoder: AudioEncoder.wav),
        path: outputFile,
      );

      setState(() {
        _isRecording = true;
        _recordingPath = outputFile;
        _recordingDuration = 0;
      });

      // Update duration timer
      _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() => _recordingDuration++);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to start recording: $e')),
      );
    }
  }

  Future<void> _stopRecording() async {
    try {
      _durationTimer?.cancel();
      await _audioRecorder.stop();
      setState(() => _isRecording = false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to stop recording: $e')),
      );
    }
  }

  Future<void> _pickAudioFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );

      if (result != null) {
        setState(() => _recordingPath = result.files.single.path);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick file: $e')),
      );
    }
  }

  Future<void> _uploadKhutbah() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title')),
      );
      return;
    }

    if (_recordingPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please record or select audio')),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final dio = Dio();
      final formData = FormData.fromMap({
        'audio': await MultipartFile.fromFile(_recordingPath!),
        'title': _titleController.text,
        'description': _descriptionController.text,
      });

      setState(() => _processingStatus = 'Uploading audio...');

      final response = await dio.post(
        '/api/khutbahs/upload',
        data: formData,
        onSendProgress: (sent, total) {
          setState(() => _uploadProgress = sent / total);
        },
      );

      if (response.statusCode == 201) {
        setState(() => _processingStatus = 'Processing transcription...');
        
        await Future.delayed(const Duration(seconds: 2));
        
        setState(() => _processingStatus = 'Generating summaries...');
        
        final khutbahData = response.data['khutbah'];
        setState(() {
          _summaries = {
            'en': khutbahData['summary_en'] ?? '',
            'ar': khutbahData['summary_ar'] ?? '',
            'ur': khutbahData['summary_ur'] ?? '',
            'bn': khutbahData['summary_bn'] ?? '',
          };
          _isProcessing = false;
          _processingStatus = 'Complete!';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Khutbah uploaded successfully!')),
        );
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: $e')),
      );
    }
  }

  String _formatDuration(int seconds) {
    final duration = Duration(seconds: seconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final secs = duration.inSeconds % 60;
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'Khutbah Recorder',
          style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Recording Section
            if (_summaries == null) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0x1FFFFFFF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    // Duration Display
                    if (_isRecording)
                      Text(
                        _formatDuration(_recordingDuration),
                        style: const TextStyle(
                          color: Colors.amber,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                        ),
                      )
                    else if (_recordingPath != null)
                      const Text(
                        'Audio Ready',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    else
                      const Text(
                        'Ready to Record',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                    
                    const SizedBox(height: 20),

                    // Record Button
                    GestureDetector(
                      onTap: _isRecording ? _stopRecording : _startRecording,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isRecording ? Colors.red : Colors.amber,
                          boxShadow: [
                            BoxShadow(
                              color: (_isRecording ? Colors.red : Colors.amber)
                                  .withOpacity(0.5),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Icon(
                          _isRecording ? Icons.stop : Icons.mic,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Pick File Button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _pickAudioFile,
                        icon: const Icon(Icons.upload_file),
                        label: const Text('Or Upload File'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white30),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Title Input
              TextField(
                controller: _titleController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Khutbah Title',
                  labelStyle: const TextStyle(color: Colors.white70),
                  hintText: 'e.g., Jumu\'ah Sermon - August 2026',
                  hintStyle: const TextStyle(color: Colors.white30),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.white30),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.amber),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Description Input
              TextField(
                controller: _descriptionController,
                style: const TextStyle(color: Colors.white),
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Description (Optional)',
                  labelStyle: const TextStyle(color: Colors.white70),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.white30),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.amber),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Upload Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _isProcessing ? null : _uploadKhutbah,
                  icon: const Icon(Icons.cloud_upload),
                  label: Text(
                    _isProcessing ? 'Processing...' : 'Upload & Process',
                    style: const TextStyle(fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black,
                    disabledBackgroundColor: Colors.grey,
                  ),
                ),
              ),

              // Progress Indicator
              if (_isProcessing) ...[
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: _uploadProgress > 0 ? _uploadProgress : null,
                  backgroundColor: Colors.white10,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
                ),
                const SizedBox(height: 8),
                Text(
                  _processingStatus,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ] else ...[
              // Summaries Display
              const Text(
                'Summaries',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Language Tabs
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildLanguageTab('English', 'en', 'en'),
                    _buildLanguageTab('العربية', 'ar', 'ar'),
                    _buildLanguageTab('اردو', 'ur', 'ur'),
                    _buildLanguageTab('বাংলা', 'bn', 'bn'),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Summary Content
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0x1FFFFFFF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _summaries![_selectedLanguage] ?? 'No summary available',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    height: 1.6,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Share Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Share feature coming soon')),
                    );
                  },
                  icon: const Icon(Icons.share),
                  label: const Text('Share with Community'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageTab(String label, String code, String langCode) {
    final isSelected = _selectedLanguage == langCode;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() => _selectedLanguage = langCode),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.amber : Colors.white10,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.black : Colors.white,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
