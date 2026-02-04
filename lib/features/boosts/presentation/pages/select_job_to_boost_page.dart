import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/resources/app_resources.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../injection/injection_container.dart';
import '../../../dashboard/domain/entities/dashboard_job.dart';
import '../../../dashboard/presentation/bloc/dashboard_cubit.dart';
import '../../../dashboard/presentation/pages/boost_listing_page.dart';
import '../../../home/presentation/bloc/business_owner_home_cubit.dart';
import '../../../home/presentation/bloc/business_owner_home_state.dart';
import '../bloc/boosts_cubit.dart';
import '../bloc/boosts_state.dart';
import '../widgets/job_selection_card.dart';

class SelectJobToBoostPage extends StatefulWidget {
  const SelectJobToBoostPage({super.key});

  @override
  State<SelectJobToBoostPage> createState() => _SelectJobToBoostPageState();
}

class _SelectJobToBoostPageState extends State<SelectJobToBoostPage> {
  @override
  void initState() {
    super.initState();
    final homeState = context.read<BusinessOwnerHomeCubit>().state;
    if (homeState is BusinessOwnerHomeLoaded &&
        homeState.selectedPresence != null &&
        homeState.selectedPresence!.id != 'all') {
      context.read<BoostsCubit>().loadJobs(homeState.selectedPresence!.id);
    }
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
          'Select Job to Boost',
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
          if (state is! BoostJobsLoaded) {
            return const Center(child: CircularProgressIndicator());
          }
          final jobs = state.jobs;
          final selectedId = state.selectedId;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.all(AppResources.spacingM),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Which job do you want to boost?',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: AppResources.spacingM),
                  itemCount: jobs.length,
                  itemBuilder: (context, index) {
                    final job = jobs[index];
                    return JobSelectionCard(
                      job: job,
                      isSelected: selectedId == job.id,
                      onTap: () => context.read<BoostsCubit>().selectJob(job.id),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppResources.spacingM),
                child: AppButton(
                  text: 'Continue',
                  onPressed: selectedId != null
                      ? () => _continueWithJob(context, jobs, selectedId)
                      : null,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _continueWithJob(
    BuildContext context,
    List<DashboardJob> jobs,
    String selectedId,
  ) {
    DashboardJob? selected;
    for (final j in jobs) {
      if (j.id == selectedId) {
        selected = j;
        break;
      }
    }
    if (selected == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) => sl<DashboardCubit>(),
          child: BoostListingPage(
            boostType: 'job',
            selectedId: selected.id,
            selectedTitle: selected.title,
            jobEmployerName: selected.employerName,
          ),
        ),
      ),
    );
  }
}
