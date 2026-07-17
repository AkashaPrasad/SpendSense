import { Router } from 'express';
import * as controller from '../controllers/budgets.controller';
import { requireAuth } from '../middleware/authMiddleware';
import { asyncHandler } from '../utils/asyncHandler';

const router = Router();
router.use(requireAuth);

router.get('/', asyncHandler(controller.list));
router.post('/', asyncHandler(controller.upsert));
router.delete('/:id', asyncHandler(controller.remove));

export default router;
