/// Base class for exceptions surfaced through a [UseCase].
class UseCaseException implements Exception {
  final String message;
  final StackTrace? stackTrace;

  const UseCaseException(this.message, [this.stackTrace]);

  @override
  String toString() => 'UseCaseException: $message';
}

/// Exception raised when an unexpected error escapes a [useCase] body.
class UnexpectedUseCaseException extends UseCaseException {
  const UnexpectedUseCaseException(super.message, [super.stackTrace]);

  @override
  String toString() => 'UnexpectedUseCaseException: $message';
}
