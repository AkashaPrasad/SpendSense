import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/app_failure.dart';
import 'empty_state.dart';

/// Consistent loading / error / data handling for any AsyncValue, so every
/// screen doesn't hand-roll its own spinner and error card.
class AsyncValueWidget<T> extends StatelessWidget {
  const AsyncValueWidget({
    super.key,
    required this.value,
    required this.data,
    this.onRetry,
  });

  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: data,
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stackTrace) {
        final message = error is AppFailure
            ? error.message
            : 'Something went wrong.';
        return EmptyState(
          icon: Icons.error_outline,
          title: 'Couldn\'t load this',
          message: message,
          actionLabel: onRetry != null ? 'Retry' : null,
          onAction: onRetry,
        );
      },
    );
  }
}
