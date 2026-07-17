import { NextFunction, Request, Response } from 'express';
import { firebaseAuth } from '../lib/firebaseAdmin';
import { prisma } from '../lib/prisma';
import { HttpError } from './errorHandler';

export interface AuthedRequest extends Request {
  userId: string;
  userEmail: string;
}

/**
 * Verifies the Firebase ID token on every request and lazily provisions a
 * matching User row so foreign keys always resolve. Firebase is the source
 * of truth for identity; Postgres just mirrors the uid + email.
 */
export async function requireAuth(req: Request, _res: Response, next: NextFunction) {
  try {
    const header = req.headers.authorization;
    if (!header?.startsWith('Bearer ')) {
      throw new HttpError(401, 'Missing bearer token');
    }
    const idToken = header.slice('Bearer '.length);
    const decoded = await firebaseAuth.verifyIdToken(idToken);

    if (!decoded.email) {
      throw new HttpError(401, 'Firebase account has no email on file');
    }

    await prisma.user.upsert({
      where: { id: decoded.uid },
      update: { email: decoded.email, displayName: decoded.name ?? undefined },
      create: { id: decoded.uid, email: decoded.email, displayName: decoded.name ?? undefined },
    });

    (req as AuthedRequest).userId = decoded.uid;
    (req as AuthedRequest).userEmail = decoded.email;
    next();
  } catch (err) {
    if (err instanceof HttpError) return next(err);
    next(new HttpError(401, 'Invalid or expired token'));
  }
}
