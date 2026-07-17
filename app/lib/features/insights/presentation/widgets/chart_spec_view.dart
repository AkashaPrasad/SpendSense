import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/chart_spec.dart';

/// Renders whatever chart shape the /api/query answer comes back with —
/// the NL query bar can return a bar, line, or pie chart depending on the
/// question, so this stays generic rather than one chart per intent.
class ChartSpecView extends StatelessWidget {
  const ChartSpecView({super.key, required this.chart});

  final ChartSpec chart;

  @override
  Widget build(BuildContext context) {
    return switch (chart.type) {
      ChartType.pie => _PieView(chart: chart),
      ChartType.line => _LineView(chart: chart),
      ChartType.bar => _BarView(chart: chart),
    };
  }
}

class _PieView extends StatelessWidget {
  const _PieView({required this.chart});
  final ChartSpec chart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final values = chart.series.first.values;
    return SizedBox(
      height: 200,
      child: Row(
        children: [
          Expanded(
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: [
                  for (var i = 0; i < chart.labels.length; i++)
                    PieChartSectionData(
                      value: values[i],
                      color: AppColors.categoryColor(chart.labels[i]),
                      radius: 32,
                      showTitle: false,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < chart.labels.length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: AppColors.categoryColor(chart.labels[i]),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            chart.labels[i],
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LineView extends StatelessWidget {
  const _LineView({required this.chart});
  final ChartSpec chart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final values = chart.series.first.values;
    final maxY = values.isEmpty ? 10.0 : values.reduce((a, b) => a > b ? a : b);

    return SizedBox(
      height: 180,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: maxY <= 0 ? 10 : maxY * 1.2,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) =>
                FlLine(color: theme.colorScheme.outlineVariant, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (value, meta) {
                  final index = value.round();
                  if (index < 0 || index >= chart.labels.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      chart.labels[index],
                      style: theme.textTheme.labelSmall,
                    ),
                  );
                },
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: [
                for (var i = 0; i < values.length; i++)
                  FlSpot(i.toDouble(), values[i]),
              ],
              isCurved: true,
              color: theme.colorScheme.primary,
              barWidth: 3,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: theme.colorScheme.primary.withValues(alpha: 0.12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BarView extends StatelessWidget {
  const _BarView({required this.chart});
  final ChartSpec chart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final seriesColors = [theme.colorScheme.primary, AppColors.warning];
    final allValues = chart.series.expand((s) => s.values);
    final maxY = allValues.isEmpty
        ? 10.0
        : allValues.reduce((a, b) => a > b ? a : b);

    return SizedBox(
      height: 200,
      child: Column(
        children: [
          if (chart.series.length > 1)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Wrap(
                spacing: 16,
                children: [
                  for (var s = 0; s < chart.series.length; s++)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          color: seriesColors[s % seriesColors.length],
                        ),
                        const SizedBox(width: 6),
                        Text(
                          chart.series[s].label,
                          style: theme.textTheme.labelSmall,
                        ),
                      ],
                    ),
                ],
              ),
            ),
          Expanded(
            child: BarChart(
              BarChartData(
                maxY: maxY <= 0 ? 10 : maxY * 1.2,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: theme.colorScheme.outlineVariant,
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      getTitlesWidget: (value, meta) {
                        final index = value.round();
                        if (index < 0 || index >= chart.labels.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            chart.labels[index],
                            style: theme.textTheme.labelSmall,
                            textAlign: TextAlign.center,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: [
                  for (var i = 0; i < chart.labels.length; i++)
                    BarChartGroupData(
                      x: i,
                      barRods: [
                        for (var s = 0; s < chart.series.length; s++)
                          BarChartRodData(
                            toY: i < chart.series[s].values.length
                                ? chart.series[s].values[i]
                                : 0,
                            color: seriesColors[s % seriesColors.length],
                            width: chart.series.length > 1 ? 10 : 18,
                            borderRadius: BorderRadius.circular(4),
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
