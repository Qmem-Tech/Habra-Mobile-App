import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/dashboard/domain/repositories/dashboard_repository.dart';
import '../../features/dashboard/presentation/bloc/dashboard_cubit.dart';
import '../../features/dashboard/presentation/widgets/legal_documents_upload_dialog.dart';
import '../../injection/injection_container.dart' as di;

/// Requires approved legal documents before creating events (EIN remains optional).
///
/// Flow:
/// 1. Missing / rejected docs → prompt upload
/// 2. Uploaded but pending review → block with wait-for-approval message
/// 3. Approved → allow event creation
abstract final class BusinessLegalDocsGate {
  static Future<LegalDocumentsStatus> _status(String businessId) {
    return di.sl<DashboardCubit>().getLegalDocumentsStatus(businessId);
  }

  /// Opens the upload dialog. Returns `true` if upload succeeded.
  static Future<bool> openUploadDialog(
    BuildContext context, {
    required String businessId,
    required String businessName,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        DashboardCubit cubit;
        try {
          cubit = context.read<DashboardCubit>();
        } catch (_) {
          cubit = di.sl<DashboardCubit>();
        }
        return BlocProvider.value(
          value: cubit,
          child: LegalDocumentsUploadDialog(
            businessId: businessId,
            businessName: businessName,
          ),
        );
      },
    );
    return result == true;
  }

  static void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 5)),
    );
  }

  /// Blocks event **creation** until legal docs are uploaded **and approved**.
  /// Editing existing events should skip this gate.
  static Future<bool> ensureCanCreateEvents(
    BuildContext context, {
    required String businessId,
    required String businessName,
  }) async {
    var status = await _status(businessId);
    if (status.canCreateEvents) return true;
    if (!context.mounted) return false;

    if (status.needsOwnerAction) {
      final uploaded = await openUploadDialog(
        context,
        businessId: businessId,
        businessName: businessName,
      );
      if (!context.mounted) return false;
      if (!uploaded) {
        _showMessage(
          context,
          status.hasRejected
              ? 'Re-upload your corrected business license before creating events.'
              : 'Upload your business license before creating events. EIN proof is optional.',
        );
        return false;
      }
      status = await _status(businessId);
      if (!context.mounted) return false;
      if (status.canCreateEvents) return true;
    }

    if (status.awaitingLegalDocReview ||
        (status.hasRequiredUploaded && !status.canCreateEvents && !status.hasRejected)) {
      _showMessage(
        context,
        'Your legal documents are under review. You can create events after Habra approves them.',
      );
      return false;
    }

    if (!context.mounted) return false;
    _showMessage(
      context,
      'Upload your business license before creating events. EIN proof is optional.',
    );
    return false;
  }
}
