import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Non-secret runtime config for the Flutter client. There is no API key in
/// here for Gemini or any LLM — the app only ever talks to our own backend,
/// which is the sole holder of that credential.
class Env {
  Env._();

  /// Tolerant of a missing .env (e.g. first run before `cp .env.example
  /// .env`) — falls back to the defaults below rather than crashing.
  static Future<void> load() async {
    try {
      await dotenv.load(fileName: '.env');
    } catch (_) {
      // No file yet — backendBaseUrl below has a hardcoded fallback.
    }
  }

  static String get backendBaseUrl =>
      dotenv.maybeGet('BACKEND_BASE_URL') ?? 'http://localhost:4000';
}
