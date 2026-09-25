import '../../core/constants/app_constants.dart';

/// Shared behaviour for mock repositories: simulated latency.
abstract class MockRepositoryBase {
  MockRepositoryBase({Duration? latency})
    : latency = latency ?? AppConfig.mockLatency;

  final Duration latency;

  Future<T> delay<T>(T Function() compute) async {
    if (latency > Duration.zero) await Future<void>.delayed(latency);
    return compute();
  }
}
