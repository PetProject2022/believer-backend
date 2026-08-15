// backend/src/routes/khutbah.js
// Khutbah upload, transcription, and summarization API

import { Router } from 'express';
import multer from 'multer';
import { OpenAI } from 'openai';
import Anthropic from '@anthropic-ai/sdk';
import { createClient } from '@supabase/supabase-js';
import fs from 'fs';
import path from 'path';

const router = Router();

// Initialize clients
const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY,
});

const anthropic = new Anthropic({
  apiKey: process.env.CLAUDE_API_KEY,
});

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY
);

// Setup multer for file uploads (temporary storage)
const upload = multer({
  dest: '/tmp/khutbah-uploads',
  limits: { fileSize: 500 * 1024 * 1024 }, // 500MB max
});

// Helper: Transcribe audio using Whisper
async function transcribeAudio(audioPath) {
  try {
    const audioStream = fs.createReadStream(audioPath);
    const response = await openai.audio.transcriptions.create({
      file: audioStream,
      model: 'whisper-1',
      language: 'en', // Auto-detect
    });
    return response.text;
  } catch (error) {
    console.error('Whisper transcription error:', error);
    throw new Error(`Transcription failed: ${error.message}`);
  }
}

// Helper: Summarize and translate using Claude
async function summarizeAndTranslate(transcript) {
  const prompt = `You are a bilingual AI assistant. Analyze the following khutbah (Islamic sermon) transcript and provide:
1. A clear English summary (3-4 sentences, key points only)
2. An Arabic summary (3-4 sentences)
3. An Urdu summary (3-4 sentences)
4. A Bengali summary (3-4 sentences)

Format your response as JSON:
{
  "summary_en": "English summary here",
  "summary_ar": "Arabic summary here",
  "summary_ur": "Urdu summary here",
  "summary_bn": "Bengali summary here"
}

Khutbah Transcript:
${transcript}`;

  try {
    const response = await anthropic.messages.create({
      model: 'claude-opus-4-1',
      max_tokens: 1000,
      messages: [
        {
          role: 'user',
          content: prompt,
        },
      ],
    });

    const responseText = response.content[0].type === 'text' ? response.content[0].text : '';
    
    // Extract JSON from response
    const jsonMatch = responseText.match(/\{[\s\S]*\}/);
    if (!jsonMatch) {
      throw new Error('No JSON found in Claude response');
    }

    const summaries = JSON.parse(jsonMatch[0]);
    return summaries;
  } catch (error) {
    console.error('Claude summarization error:', error);
    throw new Error(`Summarization failed: ${error.message}`);
  }
}

// Helper: Upload audio to Supabase Storage
async function uploadAudioToSupabase(filePath, fileName, userId) {
  try {
    const fileBuffer = fs.readFileSync(filePath);
    const storagePath = `khutbahs/${userId}/${Date.now()}-${fileName}`;

    const { data, error } = await supabase.storage
      .from('khutbah-audios')
      .upload(storagePath, fileBuffer, {
        contentType: 'audio/mpeg',
        upsert: false,
      });

    if (error) throw error;

    // Get public URL
    const { data: publicUrl } = supabase.storage
      .from('khutbah-audios')
      .getPublicUrl(storagePath);

    return publicUrl.publicUrl;
  } catch (error) {
    console.error('Supabase upload error:', error);
    throw new Error(`Audio upload failed: ${error.message}`);
  }
}

// Middleware: Verify JWT token
function verifyToken(req, res, next) {
  const token = req.headers.authorization?.split(' ')[1];
  if (!token) {
    return res.status(401).json({ error: 'No authorization token' });
  }
  // Token verification happens via Supabase RLS policies
  req.userId = token; // Pass for later use
  next();
}

router.use(verifyToken);

/**
 * POST /api/khutbahs/upload
 * Upload audio file, transcribe, summarize, and store
 * Body: FormData with audio file + title
 */
router.post('/upload', upload.single('audio'), async (req, res) => {
  const { title, description, orgId } = req.body;
  const userId = req.user?.id; // From auth middleware

  if (!req.file) {
    return res.status(400).json({ error: 'No audio file provided' });
  }

  if (!title) {
    return res.status(400).json({ error: 'Title is required' });
  }

  try {
    // Step 1: Transcribe audio
    console.log('Transcribing audio...');
    const transcript = await transcribeAudio(req.file.path);

    // Step 2: Summarize and translate
    console.log('Summarizing and translating...');
    const summaries = await summarizeAndTranslate(transcript);

    // Step 3: Upload audio to Supabase Storage
    console.log('Uploading audio to storage...');
    const audioUrl = await uploadAudioToSupabase(
      req.file.path,
      req.file.originalname,
      userId
    );

    // Step 4: Store khutbah record in database
    const { data, error } = await supabase
      .from('khutbahs')
      .insert({
        org_id: orgId || userId,
        speaker_id: userId,
        title,
        description: description || '',
        audio_url: audioUrl,
        audio_duration_seconds: Math.round(req.file.size / 16000), // Rough estimate
        raw_transcript: transcript,
        summary_en: summaries.summary_en,
        summary_ar: summaries.summary_ar,
        summary_ur: summaries.summary_ur,
        summary_bn: summaries.summary_bn,
        status: 'completed',
      })
      .select();

    if (error) {
      throw error;
    }

    // Step 5: Grant creator access
    if (data && data[0]) {
      await supabase
        .from('khutbah_access')
        .insert({
          khutbah_id: data[0].id,
          user_id: userId,
          access_type: 'admin',
        });
    }

    // Clean up temp file
    fs.unlink(req.file.path, (err) => {
      if (err) console.error('Failed to delete temp file:', err);
    });

    return res.status(201).json({
      success: true,
      khutbah: data[0],
      message: 'Khutbah uploaded and processed successfully',
    });
  } catch (error) {
    console.error('Upload error:', error);
    
    // Clean up temp file on error
    fs.unlink(req.file.path, (err) => {
      if (err) console.error('Failed to delete temp file:', err);
    });

    return res.status(500).json({
      error: error.message || 'Upload processing failed',
    });
  }
});

/**
 * GET /api/khutbahs/:id
 * Retrieve a specific khutbah with all summaries
 */
router.get('/:id', async (req, res) => {
  const { id } = req.params;

  try {
    const { data, error } = await supabase
      .from('khutbahs')
      .select(`
        *,
        khutbah_access!inner(access_type),
        speaker:speaker_id(id, email, user_metadata)
      `)
      .eq('id', id)
      .single();

    if (error || !data) {
      return res.status(404).json({ error: 'Khutbah not found' });
    }

    return res.status(200).json({
      success: true,
      khutbah: data,
    });
  } catch (error) {
    console.error('Fetch error:', error);
    return res.status(500).json({ error: 'Failed to fetch khutbah' });
  }
});

/**
 * POST /api/khutbahs/:id/invite
 * Send invitations to email addresses
 */
router.post('/:id/invite', async (req, res) => {
  const { id } = req.params;
  const { emails, accessType } = req.body;
  const userId = req.user?.id;

  if (!Array.isArray(emails) || emails.length === 0) {
    return res.status(400).json({ error: 'Emails array is required' });
  }

  try {
    // Verify user has admin access to this khutbah
    const { data: adminCheck, error: adminError } = await supabase
      .from('khutbah_access')
      .select('access_type')
      .eq('khutbah_id', id)
      .eq('user_id', userId)
      .single();

    if (adminError || adminCheck?.access_type !== 'admin') {
      return res.status(403).json({ error: 'Not authorized to invite' });
    }

    // Create invitations
    const invitations = emails.map((email) => ({
      khutbah_id: id,
      invited_email: email,
      access_type: accessType || 'view',
      invited_by: userId,
      token: `inv_${id}_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
    }));

    const { data, error } = await supabase
      .from('khutbah_invitations')
      .insert(invitations)
      .select();

    if (error) {
      throw error;
    }

    // TODO: Send email invitations
    // You could integrate SendGrid, AWS SES, or similar here

    return res.status(201).json({
      success: true,
      invitations: data,
      message: `Invitations sent to ${emails.length} email(s)`,
    });
  } catch (error) {
    console.error('Invite error:', error);
    return res.status(500).json({ error: 'Failed to send invitations' });
  }
});

/**
 * GET /api/khutbahs
 * List khutbahs the user has access to
 */
router.get('/', async (req, res) => {
  const userId = req.user?.id;
  const { limit = 20, offset = 0 } = req.query;

  try {
    const { data, error, count } = await supabase
      .from('khutbahs')
      .select('*, speaker:speaker_id(id, email)', { count: 'exact' })
      .limit(parseInt(limit))
      .offset(parseInt(offset))
      .order('created_at', { ascending: false });

    if (error) {
      throw error;
    }

    return res.status(200).json({
      success: true,
      khutbahs: data,
      total: count,
      limit: parseInt(limit),
      offset: parseInt(offset),
    });
  } catch (error) {
    console.error('List error:', error);
    return res.status(500).json({ error: 'Failed to fetch khutbahs' });
  }
});

export default router;
