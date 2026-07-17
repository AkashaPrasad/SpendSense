import 'package:decimal/decimal.dart';
import 'package:intl/intl.dart';

String formatMoney(Decimal amount, {String currency = 'USD'}) {
  final format = NumberFormat.simpleCurrency(name: currency);
  return format.format(amount.toDouble());
}
