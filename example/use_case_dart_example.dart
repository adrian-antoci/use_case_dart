import 'package:use_case_dart/use_case.dart';

// A typed failure — extending UseCaseException routes it through UseCaseFailure
// instead of being wrapped as an UnexpectedUseCaseException.
class EmptyEmailException extends UseCaseException {
  const EmptyEmailException() : super('email is empty');
}

class CredentialsException extends UseCaseException {
  const CredentialsException() : super('invalid credentials');
}

// No dedicated use-case class. Service methods return UseCase directly.
class AuthService {
  // Sync: trims/lowercases the email or throws a typed failure.
  UseCase<String> validateEmail(String input) => useCaseSync(() {
        final trimmed = input.trim();
        if (trimmed.isEmpty) throw const EmptyEmailException();
        return trimmed.toLowerCase();
      });

  // Async: any thrown UseCaseException becomes a UseCaseFailure;
  // any other error is funneled into UnexpectedUseCaseException.
  Future<UseCase<String>> login({
    required String email,
    required String password,
  }) =>
      useCase(() async {
        if (password != 'hunter2') throw const CredentialsException();
        return 'token-for-$email';
      });
}

Future<void> main() async {
  final auth = AuthService();

  // Sync call — short-circuit on failure.
  final emailResult = auth.validateEmail('  Ada@Example.com  ');
  if (emailResult.failed) {
    print('invalid email: ${emailResult.exception.message}');
    return;
  }
  print('normalized: ${emailResult.result}');

  // Async call — branch on succeeded / failed.
  final result = await auth.login(email: emailResult.result, password: 'hunter2');
  if (result.succeeded) {
    print('logged in: ${result.result}');
  } else {
    print('login failed: ${result.exception.message}');
  }

  // Or pattern-match exhaustively over the sealed UseCase<T>.
  final bad = await auth.login(email: emailResult.result, password: 'wrong');
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
