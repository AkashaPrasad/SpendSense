import { NextFunction, Request, RequestHandler, Response } from 'express';
import { AuthedRequest } from '../middleware/authMiddleware';

/**
 * Express 4 does not forward rejected promises from async handlers to the
 * error middleware on its own — without this, a thrown error in a
 * controller would hang the request instead of returning a JSON error.
 *
 * Returns a plain Express RequestHandler (so it satisfies router.get/post
 * overloads) and casts to AuthedRequest internally — safe because every
 * route using this always runs requireAuth first.
 */
export function asyncHandler(fn: (req: AuthedRequest, res: Response, next: NextFunction) => Promise<void>): RequestHandler {
  return (req: Request, res: Response, next: NextFunction) => {
    fn(req as AuthedRequest, res, next).catch(next);
  };
}
