import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../dashboard/presentation/bloc/dashboard_cubit.dart';
import '../../../dashboard/presentation/widgets/business_gallery_photos_dialog.dart';
import '../../domain/entities/business_presence.dart';

/// Full-screen gallery editor for [BusinessPresence.imageUrls] (listing photos).
class ManageBusinessPhotosPage extends StatelessWidget {
  const ManageBusinessPhotosPage({super.key, required this.business});

  final BusinessPresence business;

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: context.read<DashboardCubit>(),
      child: BusinessGalleryPhotosDialog(
        businessId: business.id,
        businessName: business.displayName,
        initialImageUrls: business.imageUrls,
        embeddedAsPage: true,
      ),
    );
  }
}
