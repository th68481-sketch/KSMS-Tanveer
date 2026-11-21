import 'package:flutter/material.dart';

/// KSMS design language: calm Navy & Teal education SaaS palette.
abstract final class KsmsColors {
  static const navy900 = Color(0xFF0B1F33);
  static const navy800 = Color(0xFF10293F);
  static const navy700 = Color(0xFF163A5F);
  static const navy600 = Color(0xFF1B4A7A);
  static const navy500 = Color(0xFF24619B);
  static const navy100 = Color(0xFFDCE7F2);
  static const navy50 = Color(0xFFF2F6FA);

  static const teal600 = Color(0xFF0B7C7C);
  static const teal500 = Color(0xFF0FA3A3);
  static const teal400 = Color(0xFF2FBDBD);
  static const teal100 = Color(0xFFD3F1F1);
  static const teal50 = Color(0xFFEAF9F9);

  static const success = Color(0xFF2E7D32);
  static const warning = Color(0xFFB26A00);
  static const danger = Color(0xFFB3261E);
  static const info = Color(0xFF1B4A7A);
}

abstract final class KsmsSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const card = 12.0;
}

abstract final class KsmsRadii {
  static final sm = BorderRadius.circular(6);
  static final md = BorderRadius.circular(10);
  static final lg = BorderRadius.circular(16);
}

class KsmsTypography {
  static TextTheme get textTheme => const TextTheme(
        displaySmall: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, letterSpacing: -0.5),
        headlineMedium: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, letterSpacing: -0.4),
        headlineSmall: TextStyle(fontSize: 21, fontWeight: FontWeight.w600),
        titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600),
        titleSmall: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(fontSize: 15.5),
        bodyMedium: TextStyle(fontSize: 14),
        bodySmall: TextStyle(fontSize: 12.5),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        labelMedium: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500),
        labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
      );
}

/// Semantic status colors shared by chips across the app.
Color statusColor(String status) {
  switch (status.toUpperCase()) {
    case 'ACTIVE':
    case 'APPROVED':
    case 'APPROVE':
    case 'PRESENT':
    case 'CLEARED':
    case 'PAID':
    case 'PUBLISHED':
    case 'RESOLVED':
    case 'RETURNED':
      return KsmsColors.success;
    case 'PENDING':
    case 'PENDING_REVIEW':
    case 'UNDER_REVIEW':
    case 'SUBMITTED':
    case 'OPEN':
    case 'PARTIALLY_PAID':
    case 'DRAFT':
    case 'REQUESTED':
    case 'INVITED':
      return KsmsColors.warning;
    case 'REJECTED':
    case 'ABSENT':
    case 'SUSPENDED':
    case 'REVERSED':
    case 'VOID':
    case 'OVERDUE':
    case 'NEEDS_INFORMATION':
      return KsmsColors.danger;
    case 'LATE':
    case 'IN_PROGRESS':
    case 'LOCKED':
      return KsmsColors.info;
    default:
      return Colors.blueGrey;
  }
}
