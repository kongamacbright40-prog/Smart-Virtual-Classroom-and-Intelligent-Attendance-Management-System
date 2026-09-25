/// Shared behaviour for the in-memory test repositories: optional latency.
abstract class MockRepositoryBase {
  MockRepositoryBase({Duration? latency}) : latency = latency ?? Duration.zero;

  final Duration latency;

  Future<T> delay<T>(T Function() compute) async {
    if (latency > Duration.zero) await Future<void>.delayed(latency);
    return compute();
  }
}
