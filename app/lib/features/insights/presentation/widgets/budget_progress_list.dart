import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../domain/entities/budget_vs_actual.dart';

/// Budget vs actual as progress bars — clearer than a grouped bar chart at
/// small sizes, and the over-budget state reads instantly via color + text
/// (not color alone).
class BudgetProgressList extends StatelessWidget {
  const BudgetProgressList({super.key, required this.items});

  final List<BudgetVsActual> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            'No budgets set for this month',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return Column(
      children: items.map((item) {
        final isOver = item.isOverBudget;
        final barColor = isOver
            ? (theme.brightness == Brightness.dark
                  ? AppColors.expenseDark
                  : AppColors.expense)
            : AppColors.categoryColor(item.category.apiValue);

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.category.displayName,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  if (isOver) ...[
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 16,
                      color: barColor,
                    ),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    '${formatMoney(item.actual)} / ${formatMoney(item.budget)}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isOver ? barColor : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: item.percentUsed.clamp(0, 1).toDouble(),
                  minHeight: 8,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  color: barColor,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
