import cors from 'cors';
import express from 'express';
import helmet from 'helmet';
import { env } from './config/env';
import { errorHandler, notFoundHandler } from './middleware/errorHandler';
import budgetsRoutes from './routes/budgets.routes';
import expensesRoutes from './routes/expenses.routes';
import insightsRoutes from './routes/insights.routes';
import ocrRoutes from './routes/ocr.routes';
import queryRoutes from './routes/query.routes';

export function createApp() {
  const app = express();

  app.use(helmet());
  app.use(cors({ origin: env.CORS_ORIGIN }));
  app.use(express.json({ limit: '2mb' }));

  app.get('/health', (_req, res) => {
    res.json({ status: 'ok' });
  });

  app.use('/api/expenses', expensesRoutes);
  app.use('/api/budgets', budgetsRoutes);
  app.use('/api/insights', insightsRoutes);
  app.use('/api/ocr', ocrRoutes);
  app.use('/api/query', queryRoutes);

  app.use(notFoundHandler);
  app.use(errorHandler);

  return app;
}
