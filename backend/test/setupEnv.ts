// Runs before the test framework is installed, and before any test file
// (or the modules it imports) reads process.env — keeps tests independent
// of a real .env / real credentials.
process.env.NODE_ENV = 'test';
process.env.DATABASE_URL = 'postgresql://spendsense:spendsense@localhost:5432/spendsense_test?schema=public';
process.env.GEMINI_API_KEY = 'test-gemini-key';
process.env.GEMINI_MODEL = 'gemini-2.0-flash';
process.env.FIREBASE_PROJECT_ID = 'spendsense-test';
process.env.CORS_ORIGIN = '*';
process.env.RATE_LIMIT_AI_PER_MINUTE = '10';
