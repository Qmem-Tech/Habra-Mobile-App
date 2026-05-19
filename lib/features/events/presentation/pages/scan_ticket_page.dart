import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../utils/event_ticket_scan_payload.dart';

/// Result of a single QR scan attempt.
enum _ScanResult { valid, alreadyUsed, wrongEvent, notFound, error }

class _CheckInInfo {
  _CheckInInfo(
    this.result, {
    this.attendeeName,
    this.ticketType,
    this.message,
  });

  final _ScanResult result;
  final String? attendeeName;
  final String? ticketType;
  final String? message;
}

/// Full-screen QR scanner for event organizers to check in attendees.
class ScanTicketPage extends StatefulWidget {
  const ScanTicketPage({
    super.key,
    required this.eventId,
    required this.eventTitle,
  });

  final String eventId;
  final String eventTitle;

  @override
  State<ScanTicketPage> createState() => _ScanTicketPageState();
}

class _ScanTicketPageState extends State<ScanTicketPage> {
  final MobileScannerController _scanner = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  bool _processing = false;
  _CheckInInfo? _lastResult;
  int _checkedInCount = 0;

  @override
  void dispose() {
    _scanner.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_processing) return;
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null || raw.isEmpty) return;

    setState(() {
      _processing = true;
      _lastResult = null;
    });
    await _scanner.stop();

    final info = await _lookupAndCheckIn(raw.trim());

    if (!mounted) return;
    setState(() {
      _processing = false;
      _lastResult = info;
      if (info.result == _ScanResult.valid) _checkedInCount++;
    });
  }

  Future<_CheckInInfo> _lookupAndCheckIn(String raw) async {
    final ticketId = ticketIdFromScanPayload(raw);
    if (ticketId == null) {
      return _CheckInInfo(
        _ScanResult.notFound,
        message: 'Unrecognized QR code. Scan the ticket QR from the Habra app.',
      );
    }

    try {
      final db = Supabase.instance.client;

      // Prefer SECURITY DEFINER RPC (organizer check-in; see allow_organizer_event_ticket_checkin.sql).
      try {
        final res = await db.rpc(
          'check_in_event_ticket',
          params: {
            'p_ticket_id': ticketId,
            'p_event_id': widget.eventId,
          },
        );
        if (res != null) {
          if (res is Map) {
            return _checkInFromRpc(Map<String, dynamic>.from(res));
          }
          if (res is String && res.isNotEmpty) {
            return _CheckInInfo(
              _ScanResult.error,
              message: 'Unexpected check-in response. Please try again.',
            );
          }
        }
      } on PostgrestException catch (e) {
        if (!_isMissingRpc(e)) rethrow;
      }

      return await _lookupAndCheckInDirect(db, ticketId);
    } catch (e) {
      debugPrint('[ScanTicket] error: $e');
      return _CheckInInfo(
        _ScanResult.error,
        message: 'Something went wrong. Please try again.',
      );
    }
  }

  static bool _isMissingRpc(PostgrestException e) {
    final message = e.message.toLowerCase();
    return e.code == 'PGRST202' ||
        e.code == '42883' ||
        message.contains('could not find the function') ||
        message.contains('does not exist');
  }

  _CheckInInfo _checkInFromRpc(Map<String, dynamic> body) {
    final result = body['result'] as String? ?? 'not_found';
    final ticketType = body['ticket_type'] as String?;
    final attendeeName = body['attendee_name'] as String?;

    switch (result) {
      case 'valid':
        return _CheckInInfo(
          _ScanResult.valid,
          attendeeName: attendeeName,
          ticketType: ticketType,
        );
      case 'already_used':
        return _CheckInInfo(
          _ScanResult.alreadyUsed,
          ticketType: ticketType,
          message: 'This ticket has already been scanned.',
        );
      case 'wrong_event':
        return _CheckInInfo(
          _ScanResult.wrongEvent,
          message: 'This ticket is for a different event.',
        );
      case 'unpaid':
        return _CheckInInfo(
          _ScanResult.notFound,
          message: 'Payment for this ticket was not completed.',
        );
      case 'cancelled':
        return _CheckInInfo(
          _ScanResult.notFound,
          message: 'This ticket has been cancelled.',
        );
      default:
        return _CheckInInfo(
          _ScanResult.notFound,
          message: 'Ticket not found. Make sure you are scanning a Habra ticket.',
        );
    }
  }

  Future<_CheckInInfo> _lookupAndCheckInDirect(
    SupabaseClient db,
    String ticketId,
  ) async {
    final row = await db
        .from('tickets')
        .select(
          'id, status, event_ticket_id, '
          'orders!inner(event_id, status, user_id, profiles(full_name)), '
          'event_tickets!inner(name)',
        )
        .eq('id', ticketId)
        .maybeSingle();

    if (row == null) {
      return _CheckInInfo(
        _ScanResult.notFound,
        message:
            'Ticket not found. Run allow_organizer_event_ticket_checkin.sql in Supabase, '
            'or confirm this is a Habra ticket for this event.',
      );
    }

    final orders = row['orders'];
    if (orders is! Map) {
      return _CheckInInfo(_ScanResult.error, message: 'Could not read ticket order.');
    }
    final orderMap = Map<String, dynamic>.from(orders);

    final orderEventId = orderMap['event_id'] as String?;
    if (orderEventId != widget.eventId) {
      return _CheckInInfo(
        _ScanResult.wrongEvent,
        message: 'This ticket is for a different event.',
      );
    }

    final orderStatus = orderMap['status'] as String?;
    if (orderStatus != 'completed') {
      return _CheckInInfo(
        _ScanResult.notFound,
        message: 'Payment for this ticket was not completed.',
      );
    }

    final ticketStatus = row['status'] as String?;
    final eventTickets = row['event_tickets'];
    final ticketTypeName =
        eventTickets is Map ? eventTickets['name'] as String? : null;

    if (ticketStatus == 'used') {
      return _CheckInInfo(
        _ScanResult.alreadyUsed,
        ticketType: ticketTypeName,
        message: 'This ticket has already been scanned.',
      );
    }
    if (ticketStatus == 'cancelled') {
      return _CheckInInfo(
        _ScanResult.notFound,
        message: 'This ticket has been cancelled.',
      );
    }

    await db.from('tickets').update({'status': 'used'}).eq('id', ticketId);

    final profile = orderMap['profiles'];
    final name = profile is Map ? profile['full_name'] as String? : null;

    return _CheckInInfo(
      _ScanResult.valid,
      attendeeName: (name?.trim().isEmpty ?? true) ? null : name,
      ticketType: ticketTypeName,
    );
  }

  void _resumeScanning() {
    setState(() => _lastResult = null);
    _scanner.start();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Scan Tickets',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              widget.eventTitle,
              style: const TextStyle(fontSize: 12, color: Colors.white70),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          if (_checkedInCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.brandPrimary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$_checkedInCount checked in',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: _scanner,
              builder: (_, state, __) => Icon(
                state.torchState == TorchState.on
                    ? Icons.flash_on
                    : Icons.flash_off,
                color: Colors.white,
              ),
            ),
            onPressed: _scanner.toggleTorch,
            tooltip: 'Toggle torch',
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _scanner,
            onDetect: _onDetect,
          ),
          _ScanFrame(),
          if (_processing)
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          if (_lastResult != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _ResultCard(
                info: _lastResult!,
                onContinue: _resumeScanning,
              ),
            ),
        ],
      ),
    );
  }
}

class _ScanFrame extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 260,
        height: 260,
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white30, width: 1),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            ..._corners(),
          ],
        ),
      ),
    );
  }

  static List<Widget> _corners() {
    const size = 24.0;
    const thick = 3.5;
    const color = Colors.white;
    const r = 4.0;

    Widget corner({required Alignment alignment, required BorderRadius border}) =>
        Align(
          alignment: alignment,
          child: SizedBox(
            width: size,
            height: size,
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border(
                  top: alignment.y < 0
                      ? const BorderSide(color: color, width: thick)
                      : BorderSide.none,
                  bottom: alignment.y > 0
                      ? const BorderSide(color: color, width: thick)
                      : BorderSide.none,
                  left: alignment.x < 0
                      ? const BorderSide(color: color, width: thick)
                      : BorderSide.none,
                  right: alignment.x > 0
                      ? const BorderSide(color: color, width: thick)
                      : BorderSide.none,
                ),
                borderRadius: border,
              ),
            ),
          ),
        );

    return [
      corner(
        alignment: Alignment.topLeft,
        border: const BorderRadius.only(topLeft: Radius.circular(r)),
      ),
      corner(
        alignment: Alignment.topRight,
        border: const BorderRadius.only(topRight: Radius.circular(r)),
      ),
      corner(
        alignment: Alignment.bottomLeft,
        border: const BorderRadius.only(bottomLeft: Radius.circular(r)),
      ),
      corner(
        alignment: Alignment.bottomRight,
        border: const BorderRadius.only(bottomRight: Radius.circular(r)),
      ),
    ];
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.info, required this.onContinue});

  final _CheckInInfo info;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final isValid = info.result == _ScanResult.valid;
    final isWarn = info.result == _ScanResult.alreadyUsed;

    final Color bg = isValid
        ? const Color(0xFF1B5E20)
        : isWarn
            ? const Color(0xFF7B4F00)
            : const Color(0xFFB71C1C);
    final IconData icon = isValid
        ? Icons.check_circle_rounded
        : isWarn
            ? Icons.warning_amber_rounded
            : Icons.cancel_rounded;
    final String heading = isValid
        ? 'Check-in successful'
        : isWarn
            ? 'Already checked in'
            : info.result == _ScanResult.wrongEvent
                ? 'Wrong event'
                : info.result == _ScanResult.notFound
                    ? 'Invalid ticket'
                    : 'Error';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        MediaQuery.paddingOf(context).bottom + 24,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 52, color: Colors.white),
          const SizedBox(height: 10),
          Text(
            heading,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          if (info.attendeeName != null) ...[
            const SizedBox(height: 6),
            Text(
              info.attendeeName!,
              style: const TextStyle(fontSize: 16, color: Colors.white),
            ),
          ],
          if (info.ticketType != null) ...[
            const SizedBox(height: 4),
            Text(
              info.ticketType!,
              style: const TextStyle(fontSize: 14, color: Colors.white70),
            ),
          ],
          if (info.message != null) ...[
            const SizedBox(height: 8),
            Text(
              info.message!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Colors.white70),
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: onContinue,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: bg,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Scan next ticket',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
