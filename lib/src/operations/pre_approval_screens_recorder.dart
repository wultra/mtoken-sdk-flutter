/*
 * Copyright 2026 Wultra s.r.o.
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

import 'package:flutter_powerauth_mobile_sdk_plugin/flutter_powerauth_mobile_sdk_plugin.dart';

import '../core/logger.dart';
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
/// timestamp and the action that ended the visit. Timestamps are captured
/// in local device time and synchronized against the server time
/// (via PowerAuth time synchronization) when [build] is called.
///
/// This helper implements [WMTMobileTokenDataRecord] and tracks which
/// screens were displayed, when they were opened/closed, and what action
/// the user took. The recorded data is included in the `mobileTokenData`
/// sent with the operation authorization request.
///
/// Example usage:
/// ```dart
/// final recorder = WMTPreApprovalScreensRecorder(powerAuth: sdk);
/// recorder.begin('screen1');
/// // ... user interacts ...
/// recorder.end('screen1', WMTPreApprovalScreenAction.continueAction);
/// recorder.begin('screen2');
/// recorder.end('screen2', WMTPreApprovalScreenAction.scan);
///
/// final builder = WMTMobileTokenDataBuilder();
/// await builder.putRecord(recorder);
/// operation.mobileTokenData = builder.build();
/// ```
class WMTPreApprovalScreensRecorder implements WMTMobileTokenDataRecord {

  @override
  String get key => 'preApprovalScreens';

  final List<_Visit> _visits = [];
  _Visit? _openVisit;

  final DateTime Function() _now;
  final Future<int> Function() _localTimeAdjustmentMs;

  /// Creates a new recorder.
  ///
  /// Timestamps are captured in local device time. When [build] is called,
  /// the [powerAuth] instance provides the local time adjustment against
  /// the server and all timestamps are shifted by it. If the time is not
  /// synchronized, the adjustment is zero and local time is used as-is.
  ///
  /// An optional [timeProvider] and [timeAdjustmentProvider] can be injected
  /// for deterministic testing, bypassing the device clock and PowerAuth
  /// time synchronization.
  WMTPreApprovalScreensRecorder({
    required PowerAuth powerAuth,
    DateTime Function()? timeProvider,
    Future<int> Function()? timeAdjustmentProvider,
  }) : _now = timeProvider ?? DateTime.now,
       _localTimeAdjustmentMs = timeAdjustmentProvider ??
           (() => powerAuth.timeSynchronizationService.localTimeAdjustment());

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
      timestampOpened: _now(),
    );
    return this;
  }

  /// Closes the current visit (if its id matches) and records [action].
  ///
  /// If no open visit matches, falls back to the last recorded visit if it
  /// has the same [id] and is still unclosed (no `timestampClosed` / `action`).
  ///
  /// Returns this recorder for chaining.
  WMTPreApprovalScreensRecorder end(String id, WMTPreApprovalScreenAction action) {
    // Currently open visit matches this id → close & append
    if (_openVisit != null && _openVisit!.screen == id) {
      _openVisit!.timestampClosed = _now();
      _openVisit!.action = action.name;
      _visits.add(_openVisit!);
      _openVisit = null;
      return this;
    }

    // Fallback: last recorded visit with same id still unfinished
    if (_visits.isNotEmpty) {
      final last = _visits.last;
      if (last.screen == id && last.timestampClosed == null && last.action == null) {
        last.timestampClosed = _now();
        last.action = action.name;
      }
    }

    return this;
  }

  /// Builds the visit records as a JSON-serializable list.
  ///
  /// If a visit is still open, it is auto-closed (with `timestampClosed`
  /// but no action) and appended.
  ///
  /// All timestamps are shifted by the PowerAuth local time adjustment
  /// against the server, so the resulting payload is in synchronized time
  /// even when the visits were recorded before the time was synchronized.
  @override
  Future<dynamic> build() async {
    if (_openVisit != null) {
      Log.warn('PreApprovalScreensRecorder is building unended visit for screen: ${_openVisit!.screen}, ending it automatically with no action.');
      _openVisit!.timestampClosed = _now();
      _visits.add(_openVisit!);
      _openVisit = null;
    }

    final adjustment = await _timeAdjustment();

    return _visits.map((v) {
      final map = <String, dynamic>{
        'screen': v.screen,
        'timestampOpened': _serialize(v.timestampOpened, adjustment),
      };
      final closed = v.timestampClosed;
      if (closed != null) {
        map['timestampClosed'] = _serialize(closed, adjustment);
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

  /// Local time adjustment against the server (fallback: zero).
  Future<Duration> _timeAdjustment() async {
    try {
      final ms = await _localTimeAdjustmentMs();
      Log.debug('PreApprovalScreensRecorder is adjusting timestamps by $ms ms (local time adjustment against the server).');
      return Duration(milliseconds: ms);
    } catch (e) {
      Log.warn('PreApprovalScreensRecorder failed to obtain local time adjustment, timestamps will use unadjusted device time: $e');
      return Duration.zero;
    }
  }

  static String _serialize(DateTime timestamp, Duration adjustment) {
    return timestamp.add(adjustment).toUtc().toIso8601String();
  }
}

class _Visit {
  final String screen;
  final DateTime timestampOpened;
  DateTime? timestampClosed;
  String? action;

  _Visit({required this.screen, required this.timestampOpened});
}
