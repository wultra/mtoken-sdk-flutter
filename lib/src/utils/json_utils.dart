import 'dart:convert';

/// Decodes a Base64 string that may not be padded correctly.
String decodeBase64Safe(String base64Str) {
  // Add padding if necessary
  int padding = base64Str.length % 4;
  if (padding > 0) {
    base64Str += '=' * (4 - padding);
  }

  return utf8.decode(base64.decode(base64Str));
}
