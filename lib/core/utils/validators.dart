/// Form validators used across every KSMS form.
class V {
  static String? required(String? v, {String message = 'Required'}) =>
      (v == null || v.trim().isEmpty) ? message : null;

  static String? email(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email is required';
    final re = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return re.hasMatch(v.trim()) ? null : 'Enter a valid email address';
  }

  static String? phone(String? v) {
    if (v == null || v.trim().isEmpty) return 'Phone is required';
    final digits = v.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < 10 || digits.length > 15) return 'Enter a valid phone number';
    return null;
  }

  static String? cnic(String? v) {
    if (v == null || v.trim().isEmpty) return null; // optional field
    final digits = v.replaceAll(RegExp(r'[^0-9]'), '');
    return digits.length == 13 ? null : 'CNIC must contain 13 digits';
  }

  static String? positiveNum(String? v, {String message = 'Enter a positive number'}) {
    if (v == null || v.trim().isEmpty) return message;
    final n = num.tryParse(v.replaceAll(',', ''));
    return (n == null || n <= 0) ? message : null;
  }

  static String? nonNegativeNum(String? v, {String message = 'Enter a valid amount'}) {
    if (v == null || v.trim().isEmpty) return message;
    final n = num.tryParse(v.replaceAll(',', ''));
    return (n == null || n < 0) ? message : null;
  }

  static String? minLength(String? v, int n, {String? message}) {
    if (v == null || v.trim().length < n) return message ?? 'Minimum $n characters';
    return null;
  }

  static String? dateOrder(DateTime? from, DateTime? to, {String message = 'End date must be after start date'}) {
    if (from == null || to == null) return null;
    return to.isAfter(from) || to == from ? null : message;
  }
}
