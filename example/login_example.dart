import 'package:bloc/bloc.dart';
import 'package:use_case_dart/use_case.dart';

// UI logic lives in the cubit; everything else is delegated to use cases.
class LoginPageCubit extends Cubit<LoginPageState> {
  final ValidateEmailUseCase validateEmailUseCase;
  final LoginUseCase loginUseCase;

  LoginPageCubit(this.validateEmailUseCase, this.loginUseCase) : super(const LoginPageInitial());

  Future<void> onLoginTap({required String email, required String password}) async {
    // Sync validation — short-circuit on failure.
    final emailResult = validateEmailUseCase(email);
    if (emailResult.failed) {
      emit(LoginPageError(emailResult.exception));
      return;
    }

    // Async login using the normalized email.
    emit(const LoginPageLoading());
    final result = await loginUseCase(email: emailResult.result, password: password);

    if (result.succeeded) {
      emit(LoginPageSuccess(result.result));
    } else {
      emit(LoginPageError(result.exception));
    }
  }
}

// Sync use case: trims/lowercases the email or throws a typed failure.
class ValidateEmailUseCase {
  UseCase<String> call(String input) => useCaseSync(() {
    final trimmed = input.trim();
    if (trimmed.isEmpty) throw const EmptyEmailException();
    return trimmed.toLowerCase();
  });
}

// Async use case: any thrown UseCaseException becomes a UseCaseFailure.
class LoginUseCase {
  final AuthenticationService authService;
  const LoginUseCase(this.authService);

  Future<UseCase<LoginResult>> call({required String email, required String password}) =>
      useCase(() => authService.login(email: email, password: password));
}

// Typed failures — extending UseCaseException routes them through UseCaseFailure.
class EmptyEmailException extends UseCaseException {
  const EmptyEmailException() : super('email is empty');
}

class CredentialsException extends UseCaseException {
  const CredentialsException() : super('invalid credentials');
}

class NetworkException extends UseCaseException {
  const NetworkException(this.statusCode) : super('network error');
  final int statusCode;
}
