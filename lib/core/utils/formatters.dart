import 'package:intl/intl.dart';

class F {
  static final NumberFormat _money = NumberFormat('#,##0.00');
  static final NumberFormat _int = NumberFormat('#,##0');

  static String pkr(num v) => 'PKR ${_money.format(v)}';

  static String intFmt(num v) => _int.format(v);

  static String date(DateTime? d) =>
      d == null ? '—' : DateFormat('dd MMM yyyy').format(d);

  static String dateTime(DateTime? d) =>
      d == null ? '—' : DateFormat('dd MMM yyyy, hh:mm a').format(d);

  static String time(DateTime? d) => d == null ? '—' : DateFormat('hh:mm a').format(d);

  static DateTime? tryParseDate(String? s) {
    if (s == null || s.isEmpty) return null;
    return DateTime.tryParse(s);
  }

  static String monthKey(DateTime d) => DateFormat('yyyy-MM').format(d);

  static String weekdayShort(int isoDay) =>
      const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][isoDay - 1];

  /// Humanizes enum values like PARTIALLY_PAID -> "Partially Paid".
  static String humanize(String value) {
    if (value.isEmpty) return '—';
    final parts = value.toLowerCase().split('_');
    return parts.map((p) => p.isEmpty ? p : '${p[0].toUpperCase()}${p.substring(1)}').join(' ');
  }
}
