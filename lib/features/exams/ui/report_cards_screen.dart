import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ReportCardsScreen extends ConsumerWidget {
  const ReportCardsScreen({super.key});

  Future<void> _printReportCard(BuildContext context) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) => pw.Directionality(
          textDirection: pw.TextDirection.rtl,
          child: pw.Center(child: pw.Text('Report Card')),
        ),
      ),
    );
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Report Cards')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => _printReportCard(context),
          child: const Text('Print Report Card'),
        ),
      ),
    );
  }
}
