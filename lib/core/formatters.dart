import 'package:flutter/material.dart';

import 'p3d_models.dart';

String formatMoney(int cents) {
  final value = cents / 100;
  return 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
}

String formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month';
}

Color quoteStatusColor(QuoteStatus status, ColorScheme colors) {
  return switch (status) {
    QuoteStatus.draft => colors.outline,
    QuoteStatus.sent => colors.primary,
    QuoteStatus.approved => Colors.green.shade700,
    QuoteStatus.rejected => colors.error,
  };
}

Color jobStatusColor(JobStatus status, ColorScheme colors) {
  return switch (status) {
    JobStatus.briefing || JobStatus.quoted => colors.outline,
    JobStatus.approved || JobStatus.queue => colors.primary,
    JobStatus.printing => Colors.indigo.shade600,
    JobStatus.finishing => Colors.amber.shade800,
    JobStatus.readyPickup => Colors.green.shade700,
    JobStatus.delivered => Colors.teal.shade700,
    JobStatus.canceled => colors.error,
  };
}
