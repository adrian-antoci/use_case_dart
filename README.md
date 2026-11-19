# use_case_dart

A result wrapper for functionality. A function returns a `UseCase<T>` instead of throwing, so callers branch on success or failure without try/catch. There is no separate use-case class — call the function directly.

It pairs well with Bloc: UI logic stays in the Bloc, and the functionality it calls returns `UseCase`.

Wrap the body in `useCase(...)` or `useCaseSync(...)`. Unexpected errors are funneled into a single `UnexpectedUseCaseException`.

## Usage

Functions that perform the work return `UseCase`. Wrap async work in `useCase(...)` and synchronous work in `useCaseSync(...)`. A thrown `UseCaseException` becomes a `UseCaseFailure`; anything else is funneled into `UnexpectedUseCaseException`.

```dart
import 'package:use_case_dart/use_case.dart';

class EmptyEmailException extends UseCaseException {
  const EmptyEmailException() : super('email is empty');
}

class CredentialsException extends UseCaseException {
  const CredentialsException() : super('invalid credentials');
}

class LoginResult {
  const LoginResult(this.token);
  final String token;
}

/// Call the service. Methods return UseCase — no LoginUseCase class.
class AuthenticationService {
  /// Sync work returns UseCase directly.
  UseCase<String> validateEmail(String input) => useCaseSync(() {
        final trimmed = input.trim();
        if (trimmed.isEmpty) throw const EmptyEmailException();
        return trimmed.toLowerCase();
      });

  /// Async work returns Future<UseCase>.
  Future<UseCase<LoginResult>> login({
    required String email,
    required String password,
  }) =>
      useCase(() async {
        if (password != 'hunter2') throw const CredentialsException();
        return LoginResult('token-for-$email');
      });
}

/// The Cubit depends on the service, not on use-case classes.
class LoginPageCubit extends Cubit<LoginPageState> {
  final AuthenticationService authService;

  LoginPageCubit(this.authService) : super(LoginPageInitial());

  /// Triggered when the user taps the login button.
  Future<void> onLoginTap({
    required String email,
    required String password,
  }) async {
    final emailResult = authService.validateEmail(email);

    if (emailResult.failed) {
      emit(LoginPageError(emailResult.exception));
      return;
    }

    emit(LoginPageLoading());

    final result = await authService.login(
      email: emailResult.result,
      password: password,
    );

    /// No try/catch — `.succeeded` and `.failed` cover both paths.
    if (result.succeeded) {
      emit(LoginPageSuccess(result.result));
    } else {
      emit(LoginPageError(result.exception));
    }
  }
}
```

## Extending `UseCaseException`

Exceptions that should surface as a typed failure extend `UseCaseException`. Anything else thrown inside the wrapped function is treated as a bug and wrapped in `UnexpectedUseCaseException`.

```dart
class CredentialsException extends UseCaseException {
  const CredentialsException() : super('invalid credentials');
}

class NetworkException extends UseCaseException {
  const NetworkException(this.statusCode) : super('network error');
  final int statusCode;
}
```

Extended types let callers pattern-match on the cause without parsing strings:

```dart
final result = await authService.login(email: email, password: password);

if (result.failed) {
  switch (result.exception) {
    case CredentialsException():
      emit(LoginPageError('wrong email or password'));
    case NetworkException(:final statusCode):
      emit(LoginPageError('network failed ($statusCode)'));
    case UnexpectedUseCaseException():
      emit(LoginPageError('something went wrong'));
    default:
      emit(LoginPageError(result.exception.message));
  }
}
```

Tips:

- Make subclasses `const` constructible when possible — throw with `throw const MyException()`.
- Add fields the caller needs in order to react (status codes, ids, retry hints).
- Keep them next to the function that throws them, or group them per feature.

## Behavior

- A thrown `UseCaseException` (or any subclass) is returned as a `UseCaseFailure`.
- Any other thrown object is wrapped in `UnexpectedUseCaseException` with the original stack trace.

`UseCase<T>` is a sealed class, so both outcomes can be matched exhaustively:

```dart
switch (result) {
  case UseCaseSuccess(:final value):
    print('welcome, token=${value.token}');
  case UseCaseFailure(:final value):
    print('failed: $value');
}
```

`fold` collapses both branches into one value:

```dart
final message = result.fold(
  (ex) => 'failed: ${ex.message}',
  (login) => 'ok: ${login.token}',
);
```

## Install

```yaml
dependencies:
  use_case_dart: ^1.0.4
```

## License

See `LICENSE`.
