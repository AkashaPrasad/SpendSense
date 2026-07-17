import { Router } from 'express';
import multer, { FileFilterCallback } from 'multer';
import { Request } from 'express';
import * as controller from '../controllers/ocr.controller';
import { requireAuth } from '../middleware/authMiddleware';
import { aiRateLimiter } from '../middleware/rateLimiter';
import { asyncHandler } from '../utils/asyncHandler';

const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 8 * 1024 * 1024 },
  fileFilter: (_req: Request, file: Express.Multer.File, cb: FileFilterCallback) => {
    if (!file.mimetype.startsWith('image/')) {
      cb(new Error('Only image uploads are allowed'));
      return;
    }
    cb(null, true);
  },
});

const router = Router();
router.post('/', requireAuth, aiRateLimiter, upload.single('receipt'), asyncHandler(controller.extract));

export default router;
