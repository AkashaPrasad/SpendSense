import { Router } from 'express';
import * as controller from '../controllers/insights.controller';
import { requireAuth } from '../middleware/authMiddleware';
import { asyncHandler } from '../utils/asyncHandler';

const router = Router();
router.use(requireAuth);

router.get('/category-summary', asyncHandler(controller.categorySummary));
router.get('/trend', asyncHandler(controller.trend));
router.get('/budget-vs-actual', asyncHandler(controller.budgetVsActual));
router.get('/income-vs-expense', asyncHandler(controller.incomeVsExpense));

export default router;
