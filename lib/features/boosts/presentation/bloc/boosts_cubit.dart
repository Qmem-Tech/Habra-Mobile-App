import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/boost_filter.dart';
import '../../domain/repositories/boosts_repository.dart';
import 'boosts_state.dart';

class BoostsCubit extends Cubit<BoostsState> {
  BoostsCubit(this._repository) : super(BoostsInitial());

  final BoostsRepository _repository;

  Future<void> loadBoosts(String businessId) async {
    if (businessId.isEmpty || businessId == 'all') {
      emit(const BoostsLoaded(
        activeBoosts: [],
        pastBoosts: [],
        filter: BoostFilter.all,
      ));
      return;
    }
    emit(BoostsLoading());
    try {
      final active = await _repository.getActiveBoosts(businessId);
      final past = await _repository.getPastBoosts(businessId);
      emit(BoostsLoaded(
        activeBoosts: active,
        pastBoosts: past,
        filter: BoostFilter.all,
      ));
    } catch (e) {
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
}
