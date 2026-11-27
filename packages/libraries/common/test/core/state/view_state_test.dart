import 'package:common/core/state/view_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('listeners hear a new value while the screen is alive', () {
    final state = ViewState<int>(0);
    final seen = <int>[];
    state.addListener(() => seen.add(state.value));

    state.value = 1;
    state.value = 2;

    expect(seen, [1, 2]);
  });

  test('a value set after dispose is ignored instead of throwing', () {
    final state = ViewState<int>(0);

    state.dispose();

    expect(() => state.value = 5, returnsNormally);
    expect(state.value, 0);
    expect(state.isDisposed, isTrue);
  });

  test('the last value can still be read after dispose', () {
    final state = ViewState<int>(0)..value = 3;

    state.dispose();

    expect(state.value, 3);
  });

  test('dispose can be called twice', () {
    final state = ViewState<int>(0);

    state.dispose();

    expect(state.dispose, returnsNormally);
  });

  test('a listener added after dispose is ignored instead of throwing', () {
    final state = ViewState<int>(0);
    var calls = 0;

    state.dispose();

    expect(() => state.addListener(() => calls++), returnsNormally);
    expect(calls, 0);
  });

  test('notifying after dispose does nothing instead of throwing', () {
    final state = ViewState<int>(0);
    var calls = 0;
    state.addListener(() => calls++);

    state.dispose();

    expect(state.notifyListeners, returnsNormally);
    expect(calls, 0);
  });
}
