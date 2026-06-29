/*
 * Copyright 2025 Wultra s.r.o.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'mobile_token_data.dart';

/// Action taken by the user on a pre-approval screen.
class WMTPreApprovalScreenAction {
  final String name;

  const WMTPreApprovalScreenAction._(this.name);

  /// User continued to the next screen.
  static const WMTPreApprovalScreenAction continueAction = WMTPreApprovalScreenAction._('CONTINUE');

  /// User navigated back.
  static const WMTPreApprovalScreenAction back = WMTPreApprovalScreenAction._('BACK');

  /// User closed the screen.
  static const WMTPreApprovalScreenAction close = WMTPreApprovalScreenAction._('CLOSE');

  /// User rejected the operation from the pre-approval screen.
  static const WMTPreApprovalScreenAction reject = WMTPreApprovalScreenAction._('REJECT');

  /// User scanned a QR code.
  static const WMTPreApprovalScreenAction scan = WMTPreApprovalScreenAction._('SCAN');

  /// Custom action with a user-defined name.
  factory WMTPreApprovalScreenAction.custom(String action) {
    return WMTPreApprovalScreenAction._(action);
  }
}

/// Records user navigation through pre-approval screens.
///
/// Each "visit" captures an opening timestamp and, when closed, a closing
/// timestamp and the action that ended the visit.
///
/// This helper implements [WMTMobileTokenDataRecord] and tracks which
/// screens were displayed, when they were opened/closed, and what action
/// the user took. The recorded data is included in the `mobileTokenData`
/// sent with the operation authorization request.
///
/// Example usage:
/// ```dart
/// final recorder = WMTPreApprovalScreensRecorder();
/// recorder.begin('screen1');
/// // ... user interacts ...
/// recorder.end('screen1', WMTPreApprovalScreenAction.continueAction);
/// recorder.begin('screen2');
/// recorder.end('screen2', WMTPreApprovalScreenAction.scan);
///
/// final builder = WMTMobileTokenDataBuilder();
/// builder.putRecord(recorder);
/// operation.mobileTokenData = builder.build();
/// ```
class WMTPreApprovalScreensRecorder implements WMTMobileTokenDataRecord {

  @override
  String get key => 'preApprovalScreens';

  final List<_Visit> _visits = [];
  _Visit? _openVisit;

  final DateTime Function() _now;

  /// Creates a new recorder.
  ///
  /// An optional [timeProvider] can be injected for deterministic testing
  /// or to use PowerAuth time synchronization.
  WMTPreApprovalScreensRecorder({DateTime Function()? timeProvider})
      : _now = timeProvider ?? (() => DateTime.now());

  /// Opens a new visit for [id].
  ///
  /// If a different visit is already open, it is appended as-is
  /// (without `timestampClosed` / `action`). If the same screen is
  /// already open, this call is a no-op.
  /// Does nothing if [id] is empty.
  ///
  /// Returns this recorder for chaining.
  WMTPreApprovalScreensRecorder begin(String id) {
    if (id.isEmpty) return this;

    if (_openVisit != null) {
      if (_openVisit!.screen == id) return this;
      _visits.add(_openVisit!);
    }

    _openVisit = _Visit(
      screen: id,
      timestampOpened: _now().toUtc().toIso8601String(),
    );
    return this;
  }

  /// Closes the current visit (if its id matches) and records [action].
  ///
  /// Falls back to the last recorded visit with the same id that is still
  /// unclosed (no `timestampClosed` and no `action`).
  ///
  /// Returns this recorder for chaining.
  WMTPreApprovalScreensRecorder end(String id, WMTPreApprovalScreenAction action) {
    // Currently open visit matches this id → close & append
    if (_openVisit != null && _openVisit!.screen == id) {
      _openVisit!.timestampClosed = _now().toUtc().toIso8601String();
      _openVisit!.action = action.name;
      _visits.add(_openVisit!);
      _openVisit = null;
      return this;
    }

    // Fallback: last recorded visit with same id still unfinished
    if (_visits.isNotEmpty) {
      final last = _visits.last;
      if (last.screen == id && last.timestampClosed == null && last.action == null) {
        last.timestampClosed = _now().toUtc().toIso8601String();
        last.action = action.name;
      }
    }

    return this;
  }

  /// Builds the visit records as a JSON-serializable list.
  ///
  /// If a visit is still open, it is auto-closed (with `timestampClosed`
  /// but no action) and appended.
  @override
  dynamic build() {
    if (_openVisit != null) {
      _openVisit!.timestampClosed = _now().toUtc().toIso8601String();
      _visits.add(_openVisit!);
      _openVisit = null;
    }

    return _visits.map((v) {
      final map = <String, dynamic>{
        'screen': v.screen,
        'timestampOpened': v.timestampOpened,
      };
      if (v.timestampClosed != null) {
        map['timestampClosed'] = v.timestampClosed;
      }
      if (v.action != null) {
        map['action'] = v.action;
      }
      return map;
    }).toList();
  }

  /// Clears all recorded visits, allowing reuse for a new operation.
  void reset() {
    _visits.clear();
    _openVisit = null;
  }
}

class _Visit {
  final String screen;
  final String timestampOpened;
  String? timestampClosed;
  String? action;

  _Visit({required this.screen, required this.timestampOpened});
}
