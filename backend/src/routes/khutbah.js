// backend/src/routes/khutbah.js
// Khutbah upload, transcription, and summarization API - Fastify version

import { OpenAI } from 'openai';
import Anthropic from '@anthropic-ai/sdk';
import { createClient } from '@supabase/supabase-js';
import fs from 'fs';
import path from 'path';

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

// Helper: Transcribe audio using Whisper
async function transcribeAudio(audioBuffer) {
  try {
    const response = await openai.audio.transcriptions.create({
      file: new File([audioBuffer], 'audio.wav', { type: 'audio/wav' }),
      model: 'whisper-1',
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
async function uploadAudioToSupabase(audioBuffer, fileName, userId) {
  try {
    const storagePath = `khutbahs/${userId}/${Date.now()}-${fileName}`;

    const { data, error } = await supabase.storage
      .from('khutbah-audios')
      .upload(storagePath, audioBuffer, {
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

export async function khutbahRoutes(api) {
  /**
   * POST /api/khutbahs/upload
   * Upload audio file, transcribe, summarize, and store
   */
  api.post('/upload', async (request, reply) => {
    try {
      const data = await request.file();
      
      if (!data) {
        return reply.status(400).send({ error: 'No audio file provided' });
      }

      const { title, description, orgId } = request.body || {};

      if (!title) {
        return reply.status(400).send({ error: 'Title is required' });
      }

      const userId = request.user?.id || request.user?.sub;

      // Read file buffer
      const audioBuffer = await data.toBuffer();
      const fileName = data.filename;

      // Step 1: Transcribe audio
      request.log.info('Transcribing audio...');
      const transcript = await transcribeAudio(audioBuffer);

      // Step 2: Summarize and translate
      request.log.info('Summarizing and translating...');
      const summaries = await summarizeAndTranslate(transcript);

      // Step 3: Upload audio to Supabase Storage
      request.log.info('Uploading audio to storage...');
      const audioUrl = await uploadAudioToSupabase(audioBuffer, fileName, userId);

      // Step 4: Store khutbah record in database
      const { data: khutbahData, error } = await supabase
        .from('khutbahs')
        .insert({
          org_id: orgId || userId,
          speaker_id: userId,
          title,
          description: description || '',
          audio_url: audioUrl,
          audio_duration_seconds: Math.round(audioBuffer.length / 16000),
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
      if (khutbahData && khutbahData[0]) {
        await supabase
          .from('khutbah_access')
          .insert({
            khutbah_id: khutbahData[0].id,
            user_id: userId,
            access_type: 'admin',
          });
      }

      return reply.status(201).send({
        success: true,
        khutbah: khutbahData[0],
        message: 'Khutbah uploaded and processed successfully',
      });
    } catch (error) {
      request.log.error(error);
      return reply.status(500).send({
        error: error.message || 'Upload processing failed',
      });
    }
  });

  /**
   * GET /api/khutbahs/:id
   * Retrieve a specific khutbah with all summaries
   */
  api.get('/:id', async (request, reply) => {
    try {
      const { id } = request.params;

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
        return reply.status(404).send({ error: 'Khutbah not found' });
      }

      return reply.send({
        success: true,
        khutbah: data,
      });
    } catch (error) {
      request.log.error(error);
      return reply.status(500).send({ error: 'Failed to fetch khutbah' });
    }
  });

  /**
   * GET /api/khutbahs
   * List khutbahs
   */
  api.get('/', async (request, reply) => {
    try {
      const { limit = 20, offset = 0 } = request.query;

      const { data, error, count } = await supabase
        .from('khutbahs')
        .select('*, speaker:speaker_id(id, email)', { count: 'exact' })
        .limit(parseInt(limit))
        .offset(parseInt(offset))
        .order('created_at', { ascending: false });

      if (error) {
        throw error;
      }

      return reply.send({
        success: true,
        khutbahs: data,
        total: count,
        limit: parseInt(limit),
        offset: parseInt(offset),
      });
    } catch (error) {
      request.log.error(error);
      return reply.status(500).send({ error: 'Failed to fetch khutbahs' });
    }
  });

  /**
   * POST /api/khutbahs/:id/invite
   * Send invitations to email addresses
   */
  api.post('/:id/invite', async (request, reply) => {
    try {
      const { id } = request.params;
      const { emails, accessType } = request.body;
      const userId = request.user?.id || request.user?.sub;

      if (!Array.isArray(emails) || emails.length === 0) {
        return reply.status(400).send({ error: 'Emails array is required' });
      }

      // Verify user has admin access
      const { data: adminCheck, error: adminError } = await supabase
        .from('khutbah_access')
        .select('access_type')
        .eq('khutbah_id', id)
        .eq('user_id', userId)
        .single();

      if (adminError || adminCheck?.access_type !== 'admin') {
        return reply.status(403).send({ error: 'Not authorized to invite' });
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

      return reply.status(201).send({
        success: true,
        invitations: data,
        message: `Invitations sent to ${emails.length} email(s)`,
      });
    } catch (error) {
      request.log.error(error);
      return reply.status(500).send({ error: 'Failed to send invitations' });
    }
  });
}
