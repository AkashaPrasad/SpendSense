import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/transaction_type.dart';

class ExpenseTile extends StatelessWidget {
  const ExpenseTile({super.key, required this.expense, this.onTap});

  final Expense expense;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isIncome = expense.type == TransactionType.income;
    final color = AppColors.categoryColor(expense.category.apiValue);
    final amountColor = isIncome
        ? (theme.brightness == Brightness.dark
              ? AppColors.incomeDark
              : AppColors.income)
        : theme.colorScheme.onSurface;
    final sign = isIncome ? '+' : '-';

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: color.withValues(alpha: 0.15),
                child: Icon(
                  _iconFor(expense.category.apiValue),
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      expense.merchant,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${expense.category.displayName} · ${DateFormat.yMMMd().format(expense.date)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$sign${formatMoney(expense.amount, currency: expense.currency)}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: amountColor,
                    ),
                  ),
                  if (!expense.isSynced) ...[
                    const SizedBox(height: 2),
                    Icon(
                      Icons.cloud_off,
                      size: 14,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconFor(String category) {
    switch (category) {
      case 'FOOD':
        return Icons.restaurant_outlined;
      case 'GROCERIES':
        return Icons.local_grocery_store_outlined;
      case 'TRANSPORT':
        return Icons.directions_car_outlined;
      case 'SHOPPING':
        return Icons.shopping_bag_outlined;
      case 'ENTERTAINMENT':
        return Icons.movie_outlined;
      case 'BILLS_UTILITIES':
        return Icons.receipt_long_outlined;
      case 'HEALTH':
        return Icons.local_hospital_outlined;
      case 'TRAVEL':
        return Icons.flight_takeoff_outlined;
      case 'EDUCATION':
        return Icons.school_outlined;
      case 'RENT_HOUSING':
        return Icons.home_outlined;
      case 'SALARY':
        return Icons.payments_outlined;
      case 'OTHER_INCOME':
        return Icons.trending_up_outlined;
      default:
        return Icons.category_outlined;
    }
  }
}
