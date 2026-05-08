# use_case_dart

Hello devs!

I built this library to give business logic a consistent shape: small, reusable 'use cases' that drop into any UI.

I mainly pair it with Bloc: UI logic stays in the Bloc, everything else lives in a Use Case.

Wrap any function call in a `UseCase<T>` so callers can branch on success or
failure without try/catch noise, and so unexpected errors are funneled into a
single `UnexpectedUseCaseException`.

## Usage

This is how I typically use the library:

Define a use case as a class. Wrap the work in `useCase(...)` for async work or
`useCaseSync(...)` for synchronous work — any thrown `UseCaseException` becomes a
`UseCaseFailure` and anything else is funneled into `UnexpectedUseCaseException`.

```dart
import 'package:use_case_dart/use_case.dart';

/// Define a use case like this:
class LoginUseCase {
  const LoginUseCase(this.authService);

  /// Declare your dependencies. In this example the service logs the user in.
  final AuthenticationService authService;

  /// Wrap your logic in `useCase` and return it as `UseCase<YourResult>`.
  Future<UseCase<LoginResult>> call({
    required String email,
    required String password,
  }) =>
      useCase(() => authService.login(email: email, password: password));
}


/// Another example — a synchronous use case that does not return a future.
///
/// Here there are no dependencies, just business logic.
class ValidateEmailUseCase {
  UseCase<String> call(String input) => useCaseSync(() {
    final trimmed = input.trim();
    if (trimmed.isEmpty) throw const EmptyEmailException();
    return trimmed.toLowerCase();
  });
}

/// Now let's put the use cases to work.
class LoginPageCubit extends Cubit<LoginPageState> {

  /// Inject them like any other dependency.
  final LoginUseCase loginUseCase;
  final ValidateEmailUseCase validateEmailUseCase;

  LoginPageCubit(this.validateEmailUseCase, this.loginUseCase)
      : super(LoginPageInitial());

  /// Triggered when the user taps the login button.
  Future<void> onLoginTap({
    required String email,
    required String password,
  }) async {
    /// Run the first use case.
    final emailResult = validateEmailUseCase(email);

    /// Check the result and react accordingly.
    if (emailResult.failed) {
      emit(LoginPageError(emailResult.exception));
      return;
    }

    emit(LoginPageLoading());

    /// Run the second use case — note the `await`.
    final result = await loginUseCase(
      email: emailResult.result,
      password: password,
    );

    /// React to the result. No try/catch needed — `.succeeded` and `.failed` cover both paths.
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

## Install

```yaml
dependencies:
  use_case_dart: ^1.0.2
```

## License

See `LICENSE`.
