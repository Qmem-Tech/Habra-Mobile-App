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

  static SavedItem _jobListingToSavedItem(
    JobListing job, {
    DateTime? bookmarkedAt,
  }) {
    final subtitleParts = <String>[
      job.companyName,
      if (job.location != null && job.location!.trim().isNotEmpty) job.location!,
    ];
    final savedAt = bookmarkedAt ??
        job.postedDate ??
        DateTime.fromMillisecondsSinceEpoch(0);
    return SavedItem(
      id: job.id,
      userId: '',
      itemType: SavedItemType.job,
      referenceId: job.id,
      savedAt: savedAt,
      title: job.title,
      subtitle: subtitleParts.join(' · '),
      imageUrl: job.companyLogoUrl,
    );
  }

  Future<Map<String, DateTime>> _bookmarkSavedAtByJobId() async {
    final r = await jobsRepository.getBookmarkedJobSavedAtByJobId();
    return r.fold((_) => <String, DateTime>{}, (m) => m);
  }

  Future<void> loadSavedItems({SavedItemType? filterType}) async {
    emit(SavedItemsLoading());

    if (filterType == SavedItemType.job) {
      final bookmarks = await _bookmarkSavedAtByJobId();
      final result = await jobsRepository.getBookmarkedJobs();
      result.fold(
        (failure) => emit(SavedItemsError(failure.message)),
        (jobs) {
          final items = jobs
              .map((j) => _jobListingToSavedItem(
                    j,
                    bookmarkedAt: bookmarks[j.id],
                  ))
              .toList()
            ..sort((a, b) => b.savedAt.compareTo(a.savedAt));
          emit(SavedItemsLoaded(items: items, filterType: filterType));
        },
      );
      return;
    }

    if (filterType == null) {
      final savedResult = await getSavedItemsUseCase(filterType: null);
      final jobsResult = await jobsRepository.getBookmarkedJobs();
      final bookmarks = await _bookmarkSavedAtByJobId();

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

      final jobItems = jobs
          .map((j) => _jobListingToSavedItem(
                j,
                bookmarkedAt: bookmarks[j.id],
              ))
          .toList();
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

  /// Returns `null` on success, or an error message to show the user.
  Future<String?> removeItem(SavedItem item) async {
    final current = state;
    if (current is! SavedItemsLoaded) {
      return 'Unable to update the list. Try again.';
    }

    if (item.itemType == SavedItemType.job) {
      final result = await toggleBookmarkUseCase(item.referenceId, false);
      return result.fold(
        (f) => f.message,
        (_) {
          final updated = current.items
              .where((i) => i.referenceId != item.referenceId)
              .toList();
          emit(SavedItemsLoaded(
            items: updated,
            filterType: current.filterType,
          ));
          return null;
        },
      );
    }

    final result = await removeSavedItemUseCase(item.id);
    return result.fold(
      (f) => f.message,
      (_) {
        final updated = current.items.where((i) => i.id != item.id).toList();
        emit(SavedItemsLoaded(
          items: updated,
          filterType: current.filterType,
        ));
        return null;
      },
    );
  }
}
