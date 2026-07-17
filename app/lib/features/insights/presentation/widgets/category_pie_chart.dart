import 'package:decimal/decimal.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../domain/entities/category_summary.dart';

class CategoryPieChart extends StatelessWidget {
  const CategoryPieChart({super.key, required this.items});

  final List<CategorySummary> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            'No spending yet this month',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    final total = items.fold<Decimal>(
      Decimal.zero,
      (sum, item) => sum + item.total,
    );
    final sorted = [...items]..sort((a, b) => b.total.compareTo(a.total));

    return Column(
      children: [
        SizedBox(
          height: 180,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 48,
              sections: sorted.map((item) {
                final color = AppColors.categoryColor(item.category.apiValue);
                final percent = total == Decimal.zero
                    ? 0.0
                    : (item.total.toDouble() / total.toDouble()) * 100;
                return PieChartSectionData(
                  value: item.total.toDouble(),
                  color: color,
                  radius: 34,
                  showTitle: percent >= 8,
                  title: '${percent.round()}%',
                  titleStyle: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _Legend(items: sorted, total: total),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.items, required this.total});

  final List<CategorySummary> items;
  final Decimal total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: items.map((item) {
        final color = AppColors.categoryColor(item.category.apiValue);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.category.displayName,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              Text(
                formatMoney(item.total),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
