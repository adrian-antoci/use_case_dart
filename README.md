# use_case_dart

Hello devs!

I created this library to standardise the way to split business logic into 'use cases' that can be reused.

The way I use the library is mainly with Bloc, where I keep the UI logic in the Bloc and for anything else I create 'Use Cases'.

Wrap any function call in a `UseCase<T>` so callers can branch on success or
failure without try/catch noise, and so unexpected errors are funneled into a
single `UnexpectedUseCaseException`.

## Install

```yaml
dependencies:
  use_case_dart: ^0.1.0
```

## Usage

This is how I typically use the library:

Define a use case as a class. Wrap the work in `useCase(...)` for async work or
`useCaseSync(...)` for synchronous work — any thrown `UseCaseException` becomes a
`UseCaseFailure` and anything else is funneled into `UnexpectedUseCaseException`.

```dart
import 'package:use_case_dart/use_case.dart';

class EmptyEmailException extends UseCaseException {
  const EmptyEmailException() : super('email is empty');
}

/// An example of a use case I can use in multiple cubits
class ValidateEmailUseCase {
  UseCase<String> call(String input) => useCaseSync(() {
        final trimmed = input.trim();
        if (trimmed.isEmpty) throw const EmptyEmailException();
        return trimmed.toLowerCase();
      });
}

class LoginUseCase {
  final AuthenticationService authService;
  const LoginUseCase(this.authService);

  Future<UseCase<LoginResult>> call({
    required String email,
    required String password,
  }) =>
      useCase(() => authService.login(email: email, password: password));
}

class LoginPageCubit extends Cubit<LoginPageState> {
  final ValidateEmailUseCase validateEmailUseCase;
  final LoginUseCase loginUseCase;

  LoginPageCubit(this.validateEmailUseCase, this.loginUseCase)
      : super(LoginPageInitial());

  Future<void> onLoginTap({
    required String email,
    required String password,
  }) async {
    final emailResult = validateEmailUseCase(email);
    if (emailResult.failed) {
      emit(LoginPageError(emailResult.exception));
      return;
    }

    emit(LoginPageLoading());
    final result = await loginUseCase(
      email: emailResult.result,
      password: password,
    );

    if (result.succeeded) {
      emit(LoginPageSuccess(result.result));
    } else {
      emit(LoginPageError(result.exception));
    }
  }
}
```

## Extending `UseCaseException`

Any exception you want to surface as a typed failure should extend
`UseCaseException`. Anything else thrown inside a use case body is treated as a
bug and wrapped in `UnexpectedUseCaseException`.

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
final result = await loginUseCase(email: email, password: password);

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
- Add fields for whatever the caller needs to react (status codes, ids, retry hints).
- Keep them in the same file as the use case that throws them, or group them per feature.

## Behavior

- A thrown `UseCaseException` (or any subclass) is returned as a `UseCaseFailure`.
- Any other thrown object is wrapped in `UnexpectedUseCaseException` with the
  original stack trace.

`UseCase<T>` is a sealed class — pattern-match exhaustively if you prefer:

```dart
switch (result) {
  UseCaseSuccess(:final value) => print('welcome, token=${value.token}'),
  UseCaseFailure(:final value) => print('failed: $value'),
}
```

## License

See `LICENSE`.
