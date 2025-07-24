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

import '../utils/log_utils.dart';

/// Known PowerAuth server error codes.
enum WMTKnownRestApiError {

  // COMMON ERRORS

  /// When unexpected error happened.
  genericError('ERROR_GENERIC'),

  /// General authentication failure (wrong password, wrong activation state, etc...)
  authenticationFailure('POWERAUTH_AUTH_FAIL'),
  /// Invalid request sent - missing request object in request
  invalidRequest('INVALID_REQUEST'),
  /// Activation is not valid (it is different from configured activation)
  invalidActivation('INVALID_ACTIVATION'),
  /// Invalid application identifier is attempted for operation manipulation
  invalidApplication('INVALID_APPLICATION'),
  /// Invalid operation identifier is attempted for operation manipulation
  invalidOperation('INVALID_OPERATION'),
  /// Error during activation
  activationError('ERR_ACTIVATION'),
  /// Error in case that PowerAuth authentication fails
  authenticationError('ERR_AUTHENTICATION'),
  /// Error during secure vault unlocking
  secureVaultError('ERR_SECURE_VAULT'),
  /// Returned in case encryption or decryption fails
  encryptionError('ERR_ENCRYPTION'),

  // PUSH ERRORS

  /// Failed to register push notifications
  pushRegistrationFailed('PUSH_REGISTRATION_FAILED'),

  // OPERATIONS ERRORS

  /// Operation is already finished
  operationAlreadyFinished('OPERATION_ALREADY_FINISHED'),
  /// Operation is already failed
  operationAlreadyFailed('OPERATION_ALREADY_FAILED'),
  /// Operation is cancelled
  operationAlreadyCancelled('OPERATION_ALREADY_CANCELED'),
  /// Operation is expired
  operationExpired('OPERATION_EXPIRED'),
  /// Operation authorization failed
  operationFailed('OPERATION_FAILED');

  final String code;
  const WMTKnownRestApiError(this.code);
  
  /// Returns the [WMTKnownRestApiError] for the given code, or null if not found.
  static Map<String, WMTKnownRestApiError> _codeMap = {
    for (var value in WMTKnownRestApiError.values) value.code: value,
  };

  static WMTKnownRestApiError fromCode(String code) {
    var error = _codeMap[code];
    if (error == null) {
      Log.error("Unknown error code: ${code}");
    }
    return error ?? WMTKnownRestApiError.genericError; // Fallback to generic error
  }
}