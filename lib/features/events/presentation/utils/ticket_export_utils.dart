import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/entities/ticket.dart';

/// Share QR as PNG, build a simple ticket PDF, open Google Maps for in-person events.
class TicketExportUtils {
  TicketExportUtils._();

  static const String _logoAsset = 'assets/logos/habra_app_logo.png';

  static String _qrPayload(Ticket ticket) {
    return ticket.qrCode?.isNotEmpty == true ? ticket.qrCode! : ticket.ticketId;
  }

  static Future<Uint8List?> _qrPngBytes(String data, {double size = 512}) async {
    final painter = QrPainter(
      data: data,
      version: QrVersions.auto,
      gapless: true,
    );
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    painter.paint(canvas, Size(size, size));
    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }

  /// Share QR image + short caption.
  static Future<void> shareQrImage(Ticket ticket) async {
    final payload = _qrPayload(ticket);
    final bytes = await _qrPngBytes(payload);
    if (bytes == null) return;
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/habra_ticket_${ticket.ticketId}.png');
    await file.writeAsBytes(bytes);
    await Share.shareXFiles(
      [XFile(file.path)],
      text:
          'Ticket for "${ticket.event.title}" • ${ticket.ticketTypeName}\nShow this QR at check-in.',
    );
  }

  /// Generate and share a PDF (users can save via the system sheet).
  static Future<void> saveAndSharePdf(Ticket ticket) async {
    final payload = _qrPayload(ticket);
    final qrBytes = await _qrPngBytes(payload, size: 320);
    final event = ticket.event;
    final pdf = pw.Document();

    Uint8List? logoPdfBytes;
    try {
      final logoData = await rootBundle.load(_logoAsset);
      logoPdfBytes = logoData.buffer.asUint8List();
    } catch (_) {}

    final policies = event.policies ?? const <String>[];
    final policyWidgets = <pw.Widget>[
      pw.Text(
        'Event policy',
        style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
      ),
      pw.SizedBox(height: 6),
    ];
    if (policies.isEmpty) {
      policyWidgets.add(
        pw.Text(
          'No separate policy text was added by the organizer.',
          style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
        ),
      );
    } else {
      for (final line in policies) {
        policyWidgets.add(
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 4),
            child: pw.Text('• $line', style: const pw.TextStyle(fontSize: 11)),
          ),
        );
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (ctx) => [
          if (logoPdfBytes != null)
            pw.Container(
              width: double.infinity,
              color: PdfColor.fromInt(0xFF1F563F),
              padding: const pw.EdgeInsets.fromLTRB(18, 16, 18, 16),
              margin: const pw.EdgeInsets.only(bottom: 18),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Image(
                    pw.MemoryImage(logoPdfBytes),
                    width: 76,
                    height: 38,
                  ),
                  pw.Spacer(),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.white, width: 0.8),
                      borderRadius: pw.BorderRadius.circular(18),
                    ),
                    child: pw.Text(
                      'E-TICKET',
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 9,
                        letterSpacing: 1.4,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          pw.Text(
            event.title,
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            ticket.ticketTypeName,
            style: pw.TextStyle(fontSize: 14, color: PdfColors.blue800),
          ),
          pw.SizedBox(height: 12),
          pw.Text(
            DateFormat('EEEE, MMMM d, yyyy • h:mm a').format(event.startDate),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            event.isOnline
                ? 'Online event'
                : '${event.venue}, ${event.fullAddress}',
          ),
          pw.SizedBox(height: 16),
          if (qrBytes != null)
            pw.Center(
              child: pw.Image(
                pw.MemoryImage(qrBytes),
                width: 200,
                height: 200,
              ),
            ),
          pw.SizedBox(height: 12),
          pw.Text(
            'Present this PDF or QR at entrance.',
            style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 16),
          pw.Divider(),
          pw.SizedBox(height: 8),
          ...policyWidgets,
        ],
      ),
    );

    final bytes = await pdf.save();
    final dir = await getTemporaryDirectory();
    final slug = event.title.replaceAll(RegExp(r'[^\w\-]+'), '_');
    final safeTitle =
        slug.length > 40 ? slug.substring(0, 40) : slug;
    final file = File('${dir.path}/habra_ticket_${safeTitle}_${ticket.ticketId}.pdf');
    await file.writeAsBytes(bytes);
    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'Ticket — ${event.title}',
    );
  }

  /// Opens Google Maps directions/search for physical venues only.
  static Future<bool> openDirections(Ticket ticket) async {
    final event = ticket.event;
    if (event.isOnline) return false;

    final lat = event.latitude;
    final lng = event.longitude;
    Uri uri;
    if (lat != null && lng != null) {
      uri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng',
      );
    } else {
      final query =
          '${event.venue}, ${event.fullAddress}'.trim().replaceAll(RegExp(r'\s+'), ' ');
      uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}',
      );
    }

    if (await canLaunchUrl(uri)) {
      return launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    return false;
  }
}
