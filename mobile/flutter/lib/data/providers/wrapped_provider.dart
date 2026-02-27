import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/wrapped_data.dart';
import '../services/wrapped_service.dart';

final wrappedProvider =
    FutureProvider.family<WrappedData, String>((ref, periodKey) async {
  final service = ref.read(wrappedServiceProvider);
  return service.getWrapped(periodKey);
});

final availableWrappedPeriodsProvider =
    FutureProvider<List<String>>((ref) async {
  final service = ref.read(wrappedServiceProvider);
  return service.getAvailablePeriods();
});
