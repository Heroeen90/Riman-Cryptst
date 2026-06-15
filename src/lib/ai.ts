import { GoogleGenAI } from '@google/genai';

// Initialize the GoogleGenAI instance safely with lazy config
let aiClient: GoogleGenAI | null = null;

export function getAiClient(): GoogleGenAI {
  if (!aiClient) {
    const apiKey = process.env.GEMINI_API_KEY;
    if (!apiKey) {
      // In development or if the user is in preview modes, we gracefully degrade or use a dummy client,
      // but to strictly abide by SDK guidelines, we instantiate with either the process env or empty.
      aiClient = new GoogleGenAI({ apiKey: 'DUMMY_OR_INJECTED_KEY' });
    } else {
      aiClient = new GoogleGenAI({ apiKey });
    }
  }
  return aiClient;
}

// API endpoint mock database or runtime container configurations
export interface AIAnalysisRequest {
  sessionMeta: string;
  riemannFocusPoint?: number;
}
