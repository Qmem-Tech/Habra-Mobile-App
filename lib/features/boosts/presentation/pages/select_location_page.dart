import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/resources/app_resources.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/habra_circular_loader.dart';
import '../../../../injection/injection_container.dart';
import '../../../dashboard/presentation/bloc/dashboard_cubit.dart';
import '../../../dashboard/presentation/pages/boost_listing_page.dart';
import '../../domain/entities/boost_location.dart';
import '../bloc/boosts_cubit.dart';
import '../bloc/boosts_state.dart';
import '../widgets/boost_flow_status_body.dart';
import '../widgets/location_selection_card.dart';

class SelectLocationPage extends StatefulWidget {
  const SelectLocationPage({super.key});

  @override
  State<SelectLocationPage> createState() => _SelectLocationPageState();
}

class _SelectLocationPageState extends State<SelectLocationPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryLoadLocations());
  }

  void _tryLoadLocations() {
    if (!mounted) return;
    context.read<BoostsCubit>().loadLocations();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.backgroundWhite,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Select Location',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: BlocBuilder<BoostsCubit, BoostsState>(
        builder: (context, state) {
          if (state is BoostsError) {
            return BoostFlowErrorBody(
              message: state.message,
              onRetry: () => context.read<BoostsCubit>().loadLocations(),
              onBack: () => Navigator.pop(context),
            );
          }
          if (state is! BoostLocationsLoaded) {
            return const HabraCircularLoader(fullScreen: true);
          }
          final locations = state.locations;
          final selectedIds = state.selectedIds;
          if (locations.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppResources.spacingL),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'No locations found for your account.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Go back'),
                    ),
                  ],
                ),
              ),
            );
          }
          final allSelected = selectedIds.length == locations.length;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppResources.spacingM,
                  AppResources.spacingM,
                  AppResources.spacingM,
                  0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Which locations need a boost?',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            'Choose specific branches to promote or select all for a bundle discount.',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                              height: 1.4,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            final cubit = context.read<BoostsCubit>();
                            if (allSelected) {
                              cubit.clearLocationSelection();
                            } else {
                              cubit.selectAllLocations();
                            }
                          },
                          child: Text(
                            allSelected ? 'Clear all' : 'Select all',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(
                    AppResources.spacingM,
                    8,
                    AppResources.spacingM,
                    AppResources.spacingM,
                  ),
                  itemCount: locations.length,
                  itemBuilder: (context, index) {
                    final loc = locations[index];
                    return LocationSelectionCard(
                      location: loc,
                      isSelected: selectedIds.contains(loc.id),
                      onTap: () => context
                          .read<BoostsCubit>()
                          .toggleLocationSelection(loc.id),
                    );
                  },
                ),
              ),
              SafeArea(
                top: false,
                minimum: const EdgeInsets.fromLTRB(
                  AppResources.spacingM,
                  0,
                  AppResources.spacingM,
                  AppResources.spacingM,
                ),
                child: AppButton(
                  text: 'Continue',
                  onPressed: selectedIds.isNotEmpty
                      ? () => _continueWithLocation(
                            context,
                            locations,
                            selectedIds,
                          )
                      : null,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _continueWithLocation(
    BuildContext context,
    List<BoostLocation> locations,
    Set<String> selectedIds,
  ) {
    if (selectedIds.isEmpty) return;
    BoostLocation? primary;
    for (final l in locations) {
      if (selectedIds.contains(l.id)) {
        primary = l;
        break;
      }
    }
    if (primary == null) return;
    final chosen = primary;
    final count = selectedIds.length;
    final title = count > 1
        ? '${chosen.name} + ${count - 1} more'
        : chosen.name;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) => sl<DashboardCubit>(),
          child: BoostListingPage(
            boostType: 'business_listing',
            selectedId: chosen.id,
            selectedTitle: title,
          ),
        ),
      ),
    );
  }
}
