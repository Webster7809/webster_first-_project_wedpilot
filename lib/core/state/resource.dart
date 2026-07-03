/// Shared async status wrapper for owned/mutable resources backed by a
/// StateNotifier (e.g. tasks, budget, a vendor's own profile).
///
/// Read-only parameter-keyed fetches should keep using FutureProvider /
/// FutureProvider.family instead — this type is only for resources a
/// notifier owns and mutates over time.
enum ResourceStatus { initial, loading, ready, error }

class Resource<T> {
  final ResourceStatus status;
  final T? data;
  final String? errorMessage;

  const Resource({
    this.status = ResourceStatus.initial,
    this.data,
    this.errorMessage,
  });

  bool get isLoading =>
      status == ResourceStatus.loading || status == ResourceStatus.initial;
  bool get hasError => status == ResourceStatus.error;
  bool get hasData => data != null && status == ResourceStatus.ready;

  Resource<T> copyWith({
    ResourceStatus? status,
    T? data,
    String? errorMessage,
  }) =>
      Resource<T>(
        status: status ?? this.status,
        data: data ?? this.data,
        errorMessage: errorMessage,
      );

  /// Mirrors AsyncValue.when's call shape so screens use identical code
  /// whether the provider behind them is a FutureProvider or a
  /// Resource-backed notifier.
  R when<R>({
    required R Function(T data) data,
    required R Function() loading,
    required R Function(String message) error,
  }) {
    if (status == ResourceStatus.error) {
      return error(errorMessage ?? 'Something went wrong.');
    }
    if (this.data != null && status == ResourceStatus.ready) {
      return data(this.data as T);
    }
    return loading();
  }
}
