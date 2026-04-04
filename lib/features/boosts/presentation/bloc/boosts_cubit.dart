import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/boost_filter.dart';
import '../../domain/repositories/boosts_repository.dart';
import 'boosts_state.dart';

class BoostsCubit extends Cubit<BoostsState> {
  BoostsCubit(this._repository) : super(BoostsInitial());

  final BoostsRepository _repository;

  static const Duration _loadBoostsTimeout = Duration(seconds: 25);

  /// Bumped on each [loadBoosts] so stale async completions do not emit.
  int _boostLoadGeneration = 0;

  /// Last non-empty business id used with [loadBoosts] (for reverting failed auto-renew).
  String? _lastLoadedBusinessId;

  Future<void> loadBoosts(String businessId) async {
    if (businessId.isEmpty || businessId == 'all') {
      _lastLoadedBusinessId = null;
      _boostLoadGeneration++;
      emit(const BoostsLoaded(
        activeBoosts: [],
        pastBoosts: [],
        filter: BoostFilter.all,
      ));
      return;
    }
    _lastLoadedBusinessId = businessId;
    final gen = ++_boostLoadGeneration;
    emit(BoostsLoading());
    try {
      final active = await _repository
          .getActiveBoosts(businessId)
          .timeout(_loadBoostsTimeout);
      if (isClosed || gen != _boostLoadGeneration) return;
      final past = await _repository
          .getPastBoosts(businessId)
          .timeout(_loadBoostsTimeout);
      if (isClosed || gen != _boostLoadGeneration) return;
      emit(BoostsLoaded(
        activeBoosts: active,
        pastBoosts: past,
        filter: BoostFilter.all,
      ));
    } on TimeoutException {
      if (isClosed || gen != _boostLoadGeneration) return;
      emit(const BoostsError(
        'Boost list timed out. Check your connection and try again.',
      ));
    } catch (e) {
      if (isClosed || gen != _boostLoadGeneration) return;
      emit(BoostsError(e.toString()));
    }
  }

  void setFilter(BoostFilter filter) {
    final current = state;
    if (current is BoostsLoaded) {
      emit(current.copyWith(filter: filter));
    }
  }

  Future<void> loadBoostOptions() async {
    try {
      final options = await _repository.getBoostOptions();
      emit(BoostOptionsLoaded(options));
    } catch (e) {
      emit(BoostsError(e.toString()));
    }
  }

  Future<void> loadLocations(String businessId) async {
    try {
      final locations = await _repository.getLocations(businessId);
      emit(BoostLocationsLoaded(locations, null));
    } catch (e) {
      emit(BoostsError(e.toString()));
    }
  }

  void selectLocation(String? id) {
    final current = state;
    if (current is BoostLocationsLoaded) {
      emit(BoostLocationsLoaded(current.locations, id));
    }
  }

  Future<void> loadDeals(String businessId) async {
    try {
      final deals = await _repository.getDealsForBoost(businessId);
      emit(BoostDealsLoaded(deals, null));
    } catch (e) {
      emit(BoostsError(e.toString()));
    }
  }

  void selectDeal(String? id) {
    final current = state;
    if (current is BoostDealsLoaded) {
      emit(BoostDealsLoaded(current.deals, id));
    }
  }

  Future<void> loadJobs(String businessId) async {
    try {
      final jobs = await _repository.getJobsForBoost(businessId);
      emit(BoostJobsLoaded(jobs, null));
    } catch (e) {
      emit(BoostsError(e.toString()));
    }
  }

  void selectJob(String? id) {
    final current = state;
    if (current is BoostJobsLoaded) {
      emit(BoostJobsLoaded(current.jobs, id));
    }
  }

  Future<void> loadActiveBoostDetail(String boostId) async {
    try {
      final boost = await _repository.getActiveBoostDetail(boostId);
      if (boost != null) {
        emit(ActiveBoostDetailLoaded(boost));
      } else {
        emit(const BoostsError('Boost not found'));
      }
    } catch (e) {
      emit(BoostsError(e.toString()));
    }
  }

  Future<void> submitBoostOrder({
    required String businessId,
    required String optionType,
    required String selectedId,
    required String planId,
    required String price,
    required bool autoRenew,
  }) async {
    await _repository.submitBoostOrder(
      businessId: businessId,
      optionType: optionType,
      selectedId: selectedId,
      planId: planId,
      price: price,
      autoRenew: autoRenew,
    );
  }

  Future<void> cancelBoost(String boostId, {String? reason}) async {
    await _repository.cancelBoost(boostId, reason: reason);
  }

  Future<void> setAutoRenew(String boostId, bool autoRenew) async {
    await _repository.setAutoRenew(boostId, autoRenew);
  }

  /// Updates [autoRenew] in [BoostsLoaded] for immediate UI feedback, then persists.
  Future<void> updateActiveBoostAutoRenew(String boostId, bool autoRenew) async {
    final loaded = state;
    if (loaded is BoostsLoaded) {
      final nextActive = loaded.activeBoosts
          .map((b) => b.id == boostId ? b.copyWith(autoRenew: autoRenew) : b)
          .toList();
      emit(loaded.copyWith(activeBoosts: nextActive));
    }
    try {
      await _repository.setAutoRenew(boostId, autoRenew);
    } catch (e) {
      final homeId = _lastLoadedBusinessId;
      if (homeId != null && homeId.isNotEmpty) {
        await loadBoosts(homeId);
      }
      rethrow;
    }
  }
}
