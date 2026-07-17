import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Non-secret runtime config for the Flutter client. There is no API key in
/// here for Gemini or any LLM — the app only ever talks to our own backend,
/// which is the sole holder of that credential.
class Env {
  Env._();

  static Future<void> load() => dotenv.load(fileName: '.env');

  static String get backendBaseUrl =>
      dotenv.maybeGet('BACKEND_BASE_URL') ?? 'http://localhost:4000';
}
