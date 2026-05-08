import 'exceptions.dart';

/// The result of running a use case: either a [UseCaseSuccess] holding [T],
/// or a [UseCaseFailure] holding a [UseCaseException].
sealed class UseCase<T> {
  const UseCase();

  /// True if this is a [UseCaseSuccess].
  bool get succeeded => this is UseCaseSuccess<T>;

  /// True if this is a [UseCaseFailure].
  bool get failed => this is UseCaseFailure<T>;

  /// The success value. Throws [StateError] on a failure.
  T get result => switch (this) {
        UseCaseSuccess(:final value) => value,
        UseCaseFailure() =>
          throw StateError('UseCase.result called on a failure'),
      };

  /// The failure exception. Throws [StateError] on a success.
  UseCaseException get exception => switch (this) {
        UseCaseFailure(:final value) => value,
        UseCaseSuccess() =>
          throw StateError('UseCase.exception called on a success'),
      };

  /// Folds both branches into a single value.
  R fold<R>(
    R Function(UseCaseException exception) onFailure,
    R Function(T value) onSuccess,
  ) =>
      switch (this) {
        UseCaseSuccess(:final value) => onSuccess(value),
        UseCaseFailure(:final value) => onFailure(value),
      };
}

/// A successful use case carrying a [value] of type [T].
final class UseCaseSuccess<T> extends UseCase<T> {
  final T value;
  const UseCaseSuccess(this.value);

  @override
  bool operator ==(Object other) =>
      other is UseCaseSuccess<T> && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'UseCaseSuccess($value)';
}

/// A failed use case carrying a [UseCaseException].
final class UseCaseFailure<T> extends UseCase<T> {
  final UseCaseException value;
  const UseCaseFailure(this.value);

  @override
  bool operator ==(Object other) =>
      other is UseCaseFailure<T> && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'UseCaseFailure($value)';
}

/// Executes the given async [request] and returns a [UseCase] with the result.
Future<UseCase<T>> useCase<T>(Future<T> Function() request) async {
  try {
    return UseCaseSuccess(await request());
  } on UseCaseException catch (ex) {
    return UseCaseFailure(ex);
  } catch (ex, st) {
    return UseCaseFailure(UnexpectedUseCaseException(ex.toString(), st));
  }
}

/// Executes the given sync [request] and returns a [UseCase] with the result.
UseCase<T> useCaseSync<T>(T Function() request) {
  try {
    return UseCaseSuccess(request());
  } on UseCaseException catch (ex) {
    return UseCaseFailure(ex);
  } catch (ex, st) {
    return UseCaseFailure(UnexpectedUseCaseException(ex.toString(), st));
  }
}

/// Casts [x] to [T] if it is of that type, otherwise returns null.
T? cast<T>(dynamic x) => x is T ? x : null;
