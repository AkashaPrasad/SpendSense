import { Response } from 'express';
import { AuthedRequest } from '../middleware/authMiddleware';
import { HttpError } from '../middleware/errorHandler';
import * as geminiService from '../services/gemini.service';

interface OcrRequest extends AuthedRequest {
  file?: Express.Multer.File;
}

export async function extract(req: OcrRequest, res: Response) {
  if (!req.file) {
    throw new HttpError(400, 'No image uploaded — attach it under the "receipt" field');
  }
  const draft = await geminiService.extractReceiptData(req.file.buffer, req.file.mimetype);
  res.json({ draft });
}
