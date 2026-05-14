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
  String? _currentScreenId;

  /// Starts recording a visit to the screen identified by [id].
  ///
  /// If another screen visit is currently open, it will be auto-closed
  /// without an action before the new visit begins.
  /// Does nothing if [id] is empty.
  ///
  /// Returns this recorder for chaining.
  WMTPreApprovalScreensRecorder begin(String id) {
    if (id.isEmpty) return this;

    // Auto-close previous open visit if switching screens
    if (_currentScreenId != null && _currentScreenId != id) {
      _closeCurrentVisit(null);
    }

    // Ignore duplicate begin for the same screen
    if (_currentScreenId == id) return this;

    _visits.add(_Visit(
      screen: id,
      timestampOpened: DateTime.now().millisecondsSinceEpoch,
    ));
    _currentScreenId = id;
    return this;
  }

  /// Closes the visit to the screen identified by [id] with the given [action].
  ///
  /// Only closes the visit if [id] matches the currently open screen.
  ///
  /// Returns this recorder for chaining.
  WMTPreApprovalScreensRecorder end(String id, WMTPreApprovalScreenAction action) {
    if (_currentScreenId != id) return this;
    _closeCurrentVisit(action);
    return this;
  }

  /// Builds the visit records as a JSON-serializable list.
  ///
  /// Any currently open visit is auto-closed without an action.
  @override
  dynamic build() {
    // Auto-close any open visit
    if (_currentScreenId != null) {
      _closeCurrentVisit(null);
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
    _currentScreenId = null;
  }

  void _closeCurrentVisit(WMTPreApprovalScreenAction? action) {
    if (_visits.isNotEmpty) {
      final last = _visits.last;
      if (last.timestampClosed == null) {
        last.timestampClosed = DateTime.now().millisecondsSinceEpoch;
        last.action = action?.name;
      }
    }
    _currentScreenId = null;
  }
}

class _Visit {
  final String screen;
  final int timestampOpened;
  int? timestampClosed;
  String? action;

  _Visit({required this.screen, required this.timestampOpened});
}
