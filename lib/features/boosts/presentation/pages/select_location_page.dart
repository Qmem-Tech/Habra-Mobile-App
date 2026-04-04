import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/resources/app_resources.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/habra_circular_loader.dart';
import '../../../../injection/injection_container.dart';
import '../../../dashboard/presentation/bloc/dashboard_cubit.dart';
import '../../../dashboard/presentation/pages/boost_listing_page.dart';
import '../../../home/presentation/bloc/business_owner_home_cubit.dart';
import '../../../home/presentation/bloc/business_owner_home_state.dart';
import '../../domain/entities/boost_location.dart';
import '../bloc/boosts_cubit.dart';
import '../bloc/boosts_state.dart';
import '../utils/boost_flow_business_id.dart';
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
    final homeState = context.read<BusinessOwnerHomeCubit>().state;
    final id = focusBusinessIdForBoostFlows(homeState);
    if (id == null) return;
    context.read<BoostsCubit>().loadLocations(id);
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
      body: BlocListener<BusinessOwnerHomeCubit, BusinessOwnerHomeState>(
        listenWhen: (prev, curr) =>
            focusBusinessIdForBoostFlows(curr) !=
            focusBusinessIdForBoostFlows(prev),
        listener: (context, homeState) => _tryLoadLocations(),
        child: BlocBuilder<BusinessOwnerHomeCubit, BusinessOwnerHomeState>(
          builder: (context, homeState) {
            if (homeState is! BusinessOwnerHomeLoaded) {
              return const HabraCircularLoader(fullScreen: true);
            }
            final businessId = focusBusinessIdForBoostFlows(homeState);
            if (businessId == null) {
              return BoostFlowMissingBusinessBody(
                onBack: () => Navigator.pop(context),
              );
            }
            return BlocBuilder<BoostsCubit, BoostsState>(
              builder: (context, state) {
                if (state is BoostsError) {
                  return BoostFlowErrorBody(
                    message: state.message,
                    onRetry: () =>
                        context.read<BoostsCubit>().loadLocations(businessId),
                    onBack: () => Navigator.pop(context),
                  );
                }
                if (state is! BoostLocationsLoaded) {
                  return const HabraCircularLoader(fullScreen: true);
                }
                final locations = state.locations;
                final selectedId = state.selectedId;
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
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(AppResources.spacingM),
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
                          Text(
                            'Choose specific branches to promote or select all for a bundle discount.',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppResources.spacingM,
                        ),
                        itemCount: locations.length,
                        itemBuilder: (context, index) {
                          final loc = locations[index];
                          return LocationSelectionCard(
                            location: loc,
                            isSelected: selectedId == loc.id,
                            onTap: () =>
                                context.read<BoostsCubit>().selectLocation(loc.id),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(AppResources.spacingM),
                      child: AppButton(
                        text: 'Continue',
                        onPressed: selectedId != null
                            ? () => _continueWithLocation(
                                  context,
                                  locations,
                                  selectedId,
                                )
                            : null,
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _continueWithLocation(
    BuildContext context,
    List<BoostLocation> locations,
    String selectedId,
  ) {
    BoostLocation? selected;
    for (final l in locations) {
      if (l.id == selectedId) {
        selected = l;
        break;
      }
    }
    if (selected == null) return;
    final BoostLocation chosen = selected;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) => sl<DashboardCubit>(),
          child: BoostListingPage(
            boostType: 'business_listing',
            selectedId: chosen.id,
            selectedTitle: chosen.name,
          ),
        ),
      ),
    );
  }
}
