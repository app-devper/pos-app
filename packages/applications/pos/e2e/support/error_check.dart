// Which error messages on screen are faults. Pure, so it is unit-tested.

/// The texts of [errors] (red snackbars) that are not the [tolerated] error
/// code. A tolerated code is matched exactly, e.g. `[SY-404-002]`, and lets
/// through only the messages that carry it; every other error is returned.
List<String> unexpectedErrors(Iterable<String> errors, {String? tolerated}) => [
      for (final error in errors)
        if (tolerated == null || !error.contains(tolerated)) error,
    ];
