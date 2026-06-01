import 'dart:io' show File;
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

class CertificateService {
  static Future<void> generateAndShare({
    required String studentName,
    required String courseName,
    required String teacherName,
  }) async {
    final pdf = pw.Document();

    // Load Arabic Font (Essential for Sryia environment)
    final arabicFont = await PdfGoogleFonts.almaraiRegular();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(40),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.teal, width: 5),
            ),
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text("شهادة إنجاز", 
                    style: pw.TextStyle(font: arabicFont, fontSize: 40, color: PdfColors.teal),
                    textDirection: pw.TextDirection.rtl),
                pw.SizedBox(height: 20),
                pw.Text("تمنح منصة كورسيريا التعليمية هذه الشهادة لـ", 
                    style: pw.TextStyle(font: arabicFont, fontSize: 18),
                    textDirection: pw.TextDirection.rtl),
                pw.SizedBox(height: 15),
                pw.Text(studentName, 
                    style: pw.TextStyle(font: arabicFont, fontSize: 30, fontWeight: pw.FontWeight.bold),
                    textDirection: pw.TextDirection.rtl),
                pw.SizedBox(height: 15),
                pw.Text("وذلك لاجتيازه بنجاح كامل متطلبات كورس:", 
                    style: pw.TextStyle(font: arabicFont, fontSize: 18),
                    textDirection: pw.TextDirection.rtl),
                pw.SizedBox(height: 10),
                pw.Text(courseName, 
                    style: pw.TextStyle(font: arabicFont, fontSize: 24, color: PdfColors.teal700),
                    textDirection: pw.TextDirection.rtl),
                pw.SizedBox(height: 40),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      children: [
                        pw.Text("توقيع المدرس", style: pw.TextStyle(font: arabicFont, fontSize: 14), textDirection: pw.TextDirection.rtl),
                        pw.SizedBox(height: 5),
                        pw.Text(teacherName, style: pw.TextStyle(font: arabicFont, fontSize: 16, fontWeight: pw.FontWeight.bold), textDirection: pw.TextDirection.rtl),
                      ],
                    ),
                    pw.Column(
                      children: [
                        pw.Text("ختم المنصة", style: pw.TextStyle(font: arabicFont, fontSize: 14), textDirection: pw.TextDirection.rtl),
                        pw.SizedBox(height: 10),
                        pw.Container(width: 60, height: 60, decoration: const pw.BoxDecoration(shape: pw.BoxShape.circle, color: PdfColors.teal100)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    final pdfBytes = await pdf.save();

    if (kIsWeb) {
      await Printing.sharePdf(
        bytes: pdfBytes, 
        filename: "certificate_${courseName.replaceAll(' ', '_')}.pdf"
      );
    } else {
      final output = await getTemporaryDirectory();
      final filePath = "${output.path}/certificate_${courseName.replaceAll(' ', '_')}.pdf";
      final file = File(filePath);
      await file.writeAsBytes(pdfBytes);

      await Share.shareXFiles([XFile(filePath)], text: "حصلت على شهادة من منصة كورسيريا! 🎓");
    }
  }
}
