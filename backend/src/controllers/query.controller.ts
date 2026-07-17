import { Response } from 'express';
import { z } from 'zod';
import { AuthedRequest } from '../middleware/authMiddleware';
import * as geminiService from '../services/gemini.service';
import * as nlQueryService from '../services/nlQuery.service';

const askSchema = z.object({ question: z.string().min(3).max(500) });

export async function ask(req: AuthedRequest, res: Response) {
  const { question } = askSchema.parse(req.body);
  const intent = await geminiService.extractQueryIntent(question, new Date());
  const result = await nlQueryService.runQuery(req.userId, intent);
  res.json(result);
}
