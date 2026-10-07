import 'package:flutter/material.dart';

import '../network/api_client.dart';
import '../theme/app_theme.dart';
import 'chefni_ui.dart';

/// Renders a future with consistent loading, error and empty states, and a
/// retry that actually re-runs the request. Screens use this instead of each
/// hand-rolling a spinner.
class AsyncView<T> extends StatefulWidget {
  const AsyncView({
    super.key,
    required this.load,
    required this.builder,
    this.emptyCheck,
    this.emptyBuilder,
    this.loadingBuilder,
  });

  /// Called on first build and on every retry / refresh.
  final Future<T> Function() load;
  final Widget Function(BuildContext context, T data, VoidCallback reload) builder;

  /// Returns true when [T] carries no rows, so the empty state shows instead.
  final bool Function(T data)? emptyCheck;
  final WidgetBuilder? emptyBuilder;
  final WidgetBuilder? loadingBuilder;

  @override
  State<AsyncView<T>> createState() => AsyncViewState<T>();
}

class AsyncViewState<T> extends State<AsyncView<T>> {
  late Future<T> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.load();
  }

  void reload() => setState(() => _future = widget.load());

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return widget.loadingBuilder?.call(context) ?? const _Loading();
        }

        if (snapshot.hasError) {
          return ErrorState(error: snapshot.error!, onRetry: reload);
        }

        final data = snapshot.data as T;
        if (widget.emptyCheck?.call(data) ?? false) {
          return widget.emptyBuilder?.call(context) ?? const _Empty();
        }

        return widget.builder(context, data, reload);
      },
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) => const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 60),
          child: CircularProgressIndicator(
            color: AppTheme.coralPrimary,
            strokeWidth: 2.5,
          ),
        ),
      );
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 30),
          child: Text(
            'Nothing here yet.',
            style: AppTheme.body(size: 14, color: AppTheme.mutedText),
          ),
        ),
      );
}

/// Error panel that distinguishes connectivity problems from server errors,
/// so a stopped API reads differently from a genuine failure.
class ErrorState extends StatelessWidget {
  const ErrorState({super.key, required this.error, this.onRetry});

  final Object error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final api = error is ApiException ? error as ApiException : null;
    final isNetwork = api == null || api.isNetworkError;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isNetwork ? Icons.wifi_off_rounded : Icons.error_outline,
              size: 40,
              color: AppTheme.mutedText,
            ),
            const SizedBox(height: 14),
            Text(
              isNetwork ? "Can't reach Chefni" : 'Something went wrong',
              style: AppTheme.display(size: 16),
            ),
            const SizedBox(height: 8),
            Text(
              api?.message ?? error.toString(),
              textAlign: TextAlign.center,
              style: AppTheme.body(
                size: 13,
                color: AppTheme.mutedText,
                height: 1.5,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              SizedBox(
                width: 160,
                child: ChefniPrimaryButton(
                  label: 'Try again',
                  color: AppTheme.tealPrimary,
                  glow: false,
                  onPressed: onRetry,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Shows an API error as a snackbar — for actions rather than page loads.
void showApiError(BuildContext context, Object error) {
  final message = error is ApiException ? error.message : error.toString();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message, style: AppTheme.body(size: 13.5, color: Colors.white)),
      backgroundColor: AppTheme.alertRed,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}
