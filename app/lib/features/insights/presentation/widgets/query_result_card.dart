import 'package:flutter/material.dart';
import '../../domain/entities/query_result.dart';
import 'chart_spec_view.dart';

class QueryResultCard extends StatelessWidget {
  const QueryResultCard({super.key, required this.result});

  final QueryResult result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(result.answer, style: theme.textTheme.bodyLarge),
            if (result.chart != null) ...[
              const SizedBox(height: 16),
              ChartSpecView(chart: result.chart!),
            ],
          ],
        ),
      ),
    );
  }
}
