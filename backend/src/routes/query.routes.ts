import { Router } from 'express';
import * as controller from '../controllers/query.controller';
import { requireAuth } from '../middleware/authMiddleware';
import { aiRateLimiter } from '../middleware/rateLimiter';
import { asyncHandler } from '../utils/asyncHandler';

const router = Router();
router.post('/', requireAuth, aiRateLimiter, asyncHandler(controller.ask));

export default router;
