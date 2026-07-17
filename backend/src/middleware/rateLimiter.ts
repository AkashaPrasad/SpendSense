import rateLimit from 'express-rate-limit';
import { Request } from 'express';
import { env } from '../config/env';
import { AuthedRequest } from './authMiddleware';

/**
 * Gemini calls cost real money (or eat free-tier quota) per request. This
 * caps AI-backed endpoints (/api/ocr, /api/query) per signed-in user so a
 * runaway client (or bug) can't burn through quota. Applied AFTER requireAuth
 * so req.userId is available as the rate-limit key.
 */
export const aiRateLimiter = rateLimit({
  windowMs: 60_000,
  limit: env.RATE_LIMIT_AI_PER_MINUTE,
  standardHeaders: true,
  legacyHeaders: false,
  keyGenerator: (req: Request) => (req as AuthedRequest).userId ?? req.ip ?? 'anonymous',
  message: { error: 'Too many AI requests — please wait a minute and try again.' },
});
