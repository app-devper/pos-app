import 'package:flutter/foundation.dart';

/// What a screen renders, held so a late answer cannot reach a screen that is
/// gone.
///
/// A request can outlive its screen: the user opens a list, leaves before it
/// loads, and the answer arrives after `dispose()`. A plain [ValueNotifier]
/// asserts (in debug builds and tests) when it is set then, so every view
/// model would have to check a flag after every `await` — and the one that
/// forgets fails only when somebody navigates away at the wrong moment.
///
/// This holds the check instead. Once disposed, setting [value], adding a
/// listener and notifying do nothing, and the last value stays readable, so a
/// view model's
/// `try / on Exception catch / finally` is safe exactly as written. Paired
/// with `OneShot`, which drops an event emitted after dispose, a view model
/// needs no publication policy of its own.
///
/// ```dart
/// final _state = ViewState<CustomersState>(const CustomersState());
/// ValueListenable<CustomersState> get state => _state;
/// ```
class ViewState<S> extends ValueNotifier<S> {
  ViewState(super.value);

  bool _disposed = false;

  bool get isDisposed => _disposed;

  @override
  set value(S newValue) {
    if (_disposed) return;
    super.value = newValue;
  }

  @override
  void addListener(VoidCallback listener) {
    if (_disposed) return;
    super.addListener(listener);
  }

  @override
  void notifyListeners() {
    if (_disposed) return;
    super.notifyListeners();
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    super.dispose();
  }
}
