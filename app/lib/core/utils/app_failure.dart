/// Domain-level failure categories. Data-layer exceptions (Dio, Firebase,
/// Drift) are caught and translated into one of these at the repository
/// boundary, so the domain layer and UI never depend on a specific
/// networking or auth package.
sealed class AppFailure {
  const AppFailure(this.message);

  final String message;
}

class NetworkFailure extends AppFailure {
  const NetworkFailure([
    super.message =
        'No internet connection. Changes will sync when you\'re back online.',
  ]);
}

class ServerFailure extends AppFailure {
  const ServerFailure([
    super.message = 'Something went wrong on our end. Please try again.',
  ]);
}

class UnauthorizedFailure extends AppFailure {
  const UnauthorizedFailure([
    super.message = 'Your session expired. Please sign in again.',
  ]);
}

class ValidationFailure extends AppFailure {
  const ValidationFailure([
    super.message = 'Please check the details you entered.',
  ]);
}

class NotFoundFailure extends AppFailure {
  const NotFoundFailure([super.message = 'That item could not be found.']);
}

class RateLimitedFailure extends AppFailure {
  const RateLimitedFailure([
    super.message = 'Too many requests — please wait a moment and try again.',
  ]);
}

class UnknownFailure extends AppFailure {
  const UnknownFailure([super.message = 'An unexpected error occurred.']);
}
