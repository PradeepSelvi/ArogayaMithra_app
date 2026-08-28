import 'package:meta/meta.dart';

import '../errors/failure.dart';

/// Outcome of an operation that is expected to fail in normal use.
///
/// Repositories return `Result` rather than throwing so that callers are forced
/// to handle the failure path. Programming errors still throw.
@immutable
sealed class Result<T> {
  const Result();

  /// True when the operation succeeded.
  bool get isSuccess => this is Success<T>;

  /// The value, or null on failure.
  T? get valueOrNull => switch (this) {
        Success<T>(:final value) => value,
        Err<T>() => null,
      };

  /// The failure, or null on success.
  Failure? get failureOrNull => switch (this) {
        Success<T>() => null,
        Err<T>(:final failure) => failure,
      };

  /// Collapses both branches into a single value.
  R fold<R>({
    required R Function(T value) onSuccess,
    required R Function(Failure failure) onFailure,
  }) =>
      switch (this) {
        Success<T>(:final value) => onSuccess(value),
        Err<T>(:final failure) => onFailure(failure),
      };

  /// Transforms a successful value, leaving a failure untouched.
  Result<R> map<R>(R Function(T value) transform) => switch (this) {
        Success<T>(:final value) => Success<R>(transform(value)),
        Err<T>(:final failure) => Err<R>(failure),
      };
}

@immutable
final class Success<T> extends Result<T> {
  const Success(this.value);

  final T value;

  @override
  bool operator ==(Object other) =>
      other is Success<T> && other.value == value;

  @override
  int get hashCode => Object.hash(Success<T>, value);
}

@immutable
final class Err<T> extends Result<T> {
  const Err(this.failure);

  final Failure failure;

  @override
  bool operator ==(Object other) =>
      other is Err<T> && other.failure == failure;

  @override
  int get hashCode => Object.hash(Err<T>, failure);
}
