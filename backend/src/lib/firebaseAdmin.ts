import admin from 'firebase-admin';
import { env } from '../config/env';

/**
 * GOOGLE_APPLICATION_CREDENTIALS (set in .env) points at a service account
 * JSON key, which applicationDefault() picks up automatically.
 */
if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.applicationDefault(),
    projectId: env.FIREBASE_PROJECT_ID,
  });
}

export const firebaseAuth = admin.auth();
