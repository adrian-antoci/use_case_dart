import 'package:use_case_dart/use_case.dart';

// A typed failure — extending UseCaseException routes it through UseCaseFailure
// instead of being wrapped as an UnexpectedUseCaseException.
class EmptyEmailException extends UseCaseException {
  const EmptyEmailException() : super('email is empty');
}

class CredentialsException extends UseCaseException {
  const CredentialsException() : super('invalid credentials');
}

// A sync use case: trims/lowercases the email or throws a typed failure.
class ValidateEmailUseCase {
  UseCase<String> call(String input) => useCaseSync(() {
        final trimmed = input.trim();
        if (trimmed.isEmpty) throw const EmptyEmailException();
        return trimmed.toLowerCase();
      });
}

// An async use case: any thrown UseCaseException becomes a UseCaseFailure;
// any other error is funneled into UnexpectedUseCaseException.
class LoginUseCase {
  Future<UseCase<String>> call({
    required String email,
    required String password,
  }) =>
      useCase(() async {
        if (password != 'hunter2') throw const CredentialsException();
        return 'token-for-$email';
      });
}

Future<void> main() async {
  final validateEmail = ValidateEmailUseCase();
  final login = LoginUseCase();

  // Sync use case — short-circuit on failure.
  final emailResult = validateEmail('  Ada@Example.com  ');
  if (emailResult.failed) {
    print('invalid email: ${emailResult.exception.message}');
    return;
  }
  print('normalized: ${emailResult.result}');

  // Async use case — branch on succeeded / failed.
  final result = await login(email: emailResult.result, password: 'hunter2');
  if (result.succeeded) {
    print('logged in: ${result.result}');
  } else {
    print('login failed: ${result.exception.message}');
  }

  // Or pattern-match exhaustively over the sealed UseCase<T>.
  final bad = await login(email: emailResult.result, password: 'wrong');
  switch (bad) {
    case UseCaseSuccess(:final value):
      print('unexpected success: $value');
    case UseCaseFailure(value: CredentialsException()):
      print('wrong email or password');
    case UseCaseFailure(:final value):
      print('other failure: ${value.message}');
  }

  // fold collapses both branches into one value.
  final message = bad.fold(
    (ex) => 'failed: ${ex.message}',
    (token) => 'ok: $token',
  );
  print(message);
}