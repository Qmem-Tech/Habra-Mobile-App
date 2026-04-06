import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../jobs/domain/entities/job_listing.dart';
import '../../../jobs/domain/repositories/jobs_repository.dart';
import '../../../jobs/domain/usecases/toggle_bookmark_usecase.dart';
import '../../../../injection/injection_container.dart' as di;
import '../../domain/entities/saved_item.dart';
import '../../domain/usecases/get_saved_items_usecase.dart';
import '../../domain/usecases/remove_saved_item_usecase.dart';
import 'saved_items_state.dart';

class SavedItemsCubit extends Cubit<SavedItemsState> {
  SavedItemsCubit({
    required this.getSavedItemsUseCase,
    required this.removeSavedItemUseCase,
    JobsRepository? jobsRepository,
    ToggleBookmarkUseCase? toggleBookmarkUseCase,
  })  : _jobsRepository = jobsRepository,
        _toggleBookmarkUseCase = toggleBookmarkUseCase,
        super(SavedItemsInitial());

  final GetSavedItemsUseCase getSavedItemsUseCase;
  final RemoveSavedItemUseCase removeSavedItemUseCase;
  final JobsRepository? _jobsRepository;
  final ToggleBookmarkUseCase? _toggleBookmarkUseCase;

  JobsRepository get jobsRepository => _jobsRepository ?? di.sl<JobsRepository>();
  ToggleBookmarkUseCase get toggleBookmarkUseCase =>
      _toggleBookmarkUseCase ?? di.sl<ToggleBookmarkUseCase>();

  static SavedItem _jobListingToSavedItem(JobListing job) {
    final subtitleParts = <String>[
      job.companyName,
      if (job.location != null && job.location!.trim().isNotEmpty) job.location!,
    ];
    return SavedItem(
      id: job.id,
      userId: '',
      itemType: SavedItemType.job,
      referenceId: job.id,
      savedAt: job.postedDate ?? DateTime.fromMillisecondsSinceEpoch(0),
      title: job.title,
      subtitle: subtitleParts.join(' · '),
      imageUrl: job.companyLogoUrl,
    );
  }

  Future<void> loadSavedItems({SavedItemType? filterType}) async {
    emit(SavedItemsLoading());

    if (filterType == SavedItemType.job) {
      final result = await jobsRepository.getBookmarkedJobs();
      result.fold(
        (failure) => emit(SavedItemsError(failure.message)),
        (jobs) => emit(
          SavedItemsLoaded(
            items: jobs.map(_jobListingToSavedItem).toList(),
            filterType: filterType,
          ),
        ),
      );
      return;
    }

    if (filterType == null) {
      final savedResult = await getSavedItemsUseCase(filterType: null);
      final jobsResult = await jobsRepository.getBookmarkedJobs();

      String? err;
      List<SavedItem> savedItems = [];
      savedResult.fold((f) => err = f.message, (items) => savedItems = items);
      if (err != null) {
        emit(SavedItemsError(err!));
        return;
      }

      List<JobListing> jobs = [];
      jobsResult.fold((f) => err = f.message, (list) => jobs = list);
      if (err != null) {
        emit(SavedItemsError(err!));
        return;
      }

      final jobItems = jobs.map(_jobListingToSavedItem).toList();
      final merged = [...savedItems, ...jobItems]
        ..sort((a, b) => b.savedAt.compareTo(a.savedAt));
      emit(SavedItemsLoaded(items: merged, filterType: null));
      return;
    }

    final result = await getSavedItemsUseCase(filterType: filterType);
    result.fold(
      (failure) => emit(SavedItemsError(failure.message)),
      (items) => emit(SavedItemsLoaded(items: items, filterType: filterType)),
    );
  }

  Future<void> removeItem(SavedItem item) async {
    final current = state;
    if (current is! SavedItemsLoaded) return;

    if (item.itemType == SavedItemType.job) {
      final result = await toggleBookmarkUseCase(item.referenceId, false);
      result.fold(
        (_) => {},
        (_) {
          final updated =
              current.items.where((i) => i.referenceId != item.referenceId).toList();
          emit(SavedItemsLoaded(
            items: updated,
            filterType: current.filterType,
          ));
        },
      );
      return;
    }

    final result = await removeSavedItemUseCase(item.id);
    result.fold(
      (_) => {},
      (_) {
        final updated = current.items.where((i) => i.id != item.id).toList();
        emit(SavedItemsLoaded(
          items: updated,
          filterType: current.filterType,
        ));
      },
    );
  }
}
