import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/design_tokens.dart';
import '../../l10n/generated/app_localizations.dart';

/// Unified async rendering: loading / populated / empty / error(+retry).
class AsyncView<T> extends StatelessWidget {
  const AsyncView({
    super.key,
    required this.value,
    required this.builder,
    this.onRetry,
    this.isEmpty,
    this.loadingLabel,
  });

  final AsyncValue<T> value;
  final Widget Function(BuildContext context, T data) builder;
  final VoidCallback? onRetry;
  final bool Function(T data)? isEmpty;
  final String? loadingLabel;

  @override
  Widget build(BuildContext context) {
    return value.when(
      loading: () => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              if (loadingLabel != null) ...[
                const SizedBox(height: KsmsSpacing.md),
                Text(loadingLabel!, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ],
          ),
        ),
      ),
      error: (e, _) => ErrorState(message: e.toString(), onRetry: onRetry),
      data: (data) {
        if (isEmpty != null && isEmpty!(data)) {
          return const EmptyState();
        }
        return builder(context, data);
      },
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, this.title, this.message, this.icon = Icons.inbox_outlined});
  final String? title;
  final String? message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(KsmsSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: KsmsSpacing.md),
            Text(title ?? l.common_noData,
                style: Theme.of(context).textTheme.titleMedium),
            if (message != null) ...[
              const SizedBox(height: KsmsSpacing.xs),
              Text(message!, textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ],
        ),
      ),
    );
  }
}

class ErrorState extends StatelessWidget {
  const ErrorState({super.key, required this.message, this.onRetry});
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(KsmsSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 44, color: KsmsColors.danger),
            const SizedBox(height: KsmsSpacing.md),
            Text(l.common_error, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: KsmsSpacing.xs),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Text(message, textAlign: TextAlign.center,
                  maxLines: 6, overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: KsmsSpacing.md),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(l.common_retry),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
