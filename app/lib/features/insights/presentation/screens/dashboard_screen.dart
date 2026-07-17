import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../../core/widgets/async_value_widget.dart';
import '../providers/insights_providers.dart';
import '../widgets/category_pie_chart.dart';
import '../widgets/nl_query_bar.dart';
import '../widgets/query_result_card.dart';
import '../widgets/trend_line_chart.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  late DateTime _month;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
  }

  void _shiftMonth(int delta) {
    setState(() => _month = DateTime(_month.year, _month.month + delta));
  }

  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(
      dashboardSummaryProvider(month: _month.month, year: _month.year),
    );
    final queryState = ref.watch(nlQueryControllerProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('SpendSense')),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(dashboardSummaryProvider),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
          children: [
            const NlQueryBar(),
            if (queryState.isLoading ||
                queryState.hasValue && queryState.value != null ||
                queryState.hasError) ...[
              const SizedBox(height: 12),
              if (queryState.isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (queryState.hasError)
                Card(
                  color: theme.colorScheme.errorContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      ref
                              .read(nlQueryControllerProvider.notifier)
                              .errorMessage ??
                          'Something went wrong.',
                      style: TextStyle(
                        color: theme.colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                )
              else if (queryState.value != null)
                QueryResultCard(result: queryState.value!),
            ],
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => _shiftMonth(-1),
                ),
                Text(
                  DateFormat.yMMMM().format(_month),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => _shiftMonth(1),
                ),
              ],
            ),
            const SizedBox(height: 8),
            AsyncValueWidget(
              value: summaryAsync,
              onRetry: () => ref.invalidate(dashboardSummaryProvider),
              data: (summary) {
                final net = summary.totalIncome - summary.totalExpense;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Expanded(
                              child: _SummaryStat(
                                label: 'Income',
                                value: formatMoney(summary.totalIncome),
                                color: Colors.green,
                              ),
                            ),
                            Expanded(
                              child: _SummaryStat(
                                label: 'Spent',
                                value: formatMoney(summary.totalExpense),
                                color: theme.colorScheme.error,
                              ),
                            ),
                            Expanded(
                              child: _SummaryStat(
                                label: 'Net',
                                value:
                                    '${net.sign.isNegative ? '-' : ''}${formatMoney(net.abs())}',
                                color: net.sign.isNegative
                                    ? theme.colorScheme.error
                                    : Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Spending by category',
                              style: theme.textTheme.titleMedium,
                            ),
                            const SizedBox(height: 12),
                            CategoryPieChart(items: summary.categorySummary),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '6-month trend',
                              style: theme.textTheme.titleMedium,
                            ),
                            const SizedBox(height: 12),
                            TrendLineChart(points: summary.trend),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => context.go('/budgets'),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Icon(
                                Icons.pie_chart_outline,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  summary.budgetVsActual.isEmpty
                                      ? 'Set a budget to track spending limits'
                                      : '${summary.budgetVsActual.where((b) => b.isOverBudget).length} categor${summary.budgetVsActual.where((b) => b.isOverBudget).length == 1 ? 'y' : 'ies'} over budget',
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ),
                              const Icon(Icons.chevron_right),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  const _SummaryStat({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}
