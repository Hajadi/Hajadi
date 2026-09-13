import 'package:flutter/foundation.dart';

/// Shared loading/error plumbing for every view-model.
///
/// Errors are surfaced as catalog keys, never as provider messages, so the
/// view can render them in the user's language.
abstract class BaseViewModel extends ChangeNotifier {
  bool _busy = false;
  String? _errorKey;
  bool _disposed = false;

  bool get busy => _busy;
  String? get errorKey => _errorKey;
  bool get hasError => _errorKey != null;

  @protected
  void setBusy(bool value) {
    if (_busy == value) {
      return;
    }
    _busy = value;
    safeNotify();
  }

  @protected
  void setError(String? key) {
    _errorKey = key;
    safeNotify();
  }

  void clearError() => setError(null);

  /// Runs [action] with the busy flag set, mapping any throw to [errorKey].
  /// Returns null when the action failed.
  @protected
  Future<T?> guard<T>(
    Future<T> Function() action, {
    String errorKey = 'errorGeneric',
  }) async {
    setBusy(true);
    setError(null);
    try {
      return await action();
    } catch (error, stack) {
      debugPrint('$runtimeType failed: $error\n$stack');
      setError(errorKey);
      return null;
    } finally {
      setBusy(false);
    }
  }

  /// Streams outlive the widgets that started them; this keeps a late event
  /// from notifying a disposed model.
  @protected
  void safeNotify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
