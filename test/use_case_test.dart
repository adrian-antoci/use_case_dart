import 'package:test/test.dart';
import 'package:use_case_dart/use_case.dart';

class _TestException extends UseCaseException {
  const _TestException(super.message);
}

void main() {
  group('UseCase', () {
    test('UseCaseSuccess exposes result', () {
      const r = UseCaseSuccess<int>(7);
      expect(r.succeeded, isTrue);
      expect(r.failed, isFalse);
      expect(r.result, 7);
      expect(() => r.exception, throwsStateError);
    });

    test('UseCaseFailure exposes exception', () {
      const r = UseCaseFailure<int>(_TestException('boom'));
      expect(r.failed, isTrue);
      expect(r.succeeded, isFalse);
      expect(r.exception, isA<_TestException>());
      expect(() => r.result, throwsStateError);
    });

    test('fold dispatches to the correct branch', () {
      const ok = UseCaseSuccess<int>(1);
      const err = UseCaseFailure<int>(_TestException('x'));
      expect(ok.fold((_) => 'F', (v) => 'S$v'), 'S1');
      expect(err.fold((e) => 'F${e.message}', (_) => 'S'), 'Fx');
    });

    test('value equality', () {
      expect(const UseCaseSuccess<int>(1), const UseCaseSuccess<int>(1));
      expect(const UseCaseSuccess<int>(1) == const UseCaseSuccess<int>(2), isFalse);
    });
  });

  group('useCase', () {
    test('wraps success', () async {
      final r = await useCase(() async => 42);
      expect(r.succeeded, isTrue);
      expect(r.result, 42);
    });

    test('catches UseCaseException', () async {
      final r = await useCase<int>(() async => throw const _TestException('nope'));
      expect(r.failed, isTrue);
      expect(r.exception, isA<_TestException>());
      expect(r.exception.message, 'nope');
    });

    test('wraps unknown errors in UnexpectedUseCaseException', () async {
      final r = await useCase<int>(() async => throw StateError('weird'));
      expect(r.failed, isTrue);
      expect(r.exception, isA<UnexpectedUseCaseException>());
      expect(r.exception.stackTrace, isNotNull);
    });
  });

  group('useCaseSync', () {
    test('wraps success', () {
      final r = useCaseSync(() => 'ok');
      expect(r.succeeded, isTrue);
      expect(r.result, 'ok');
    });

    test('catches UseCaseException', () {
      final r = useCaseSync<int>(() => throw const _TestException('bad'));
      expect(r.failed, isTrue);
      expect(r.exception, isA<_TestException>());
    });

    test('wraps unknown errors in UnexpectedUseCaseException', () {
      final r = useCaseSync<int>(() => throw StateError('weird'));
      expect(r.failed, isTrue);
      expect(r.exception, isA<UnexpectedUseCaseException>());
    });
  });
}
