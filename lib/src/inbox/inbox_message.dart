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

/// Represents a message in the inbox.
class WMTInboxMessage {
  /// Message's identifier.
  String id;

  /// Message's subject.
  String subject;

  /// Message's summary. It typically contains a reduced
  /// information from message's body, with no additional formatting.
  String summary;

  /// Message's body. It may be in HTML or plain text format.
  /// The body is returned only for detailed message view.
  String? body; 

  /// Message body's content type.
  WMTInboxMessageType type;

  /// If `true`, then user already read the message.
  bool read;

  /// Date and time when the message was created.
  DateTime timestampCreated;

  WMTInboxMessage({
    required this.id,
    required this.subject,
    required this.summary,
    this.body,
    required this.type,
    required this.read,
    required this.timestampCreated,
  });

  /// Creates a [WMTInboxMessage] from a JSON map.
  factory WMTInboxMessage.fromJson(Map<String, dynamic> json) {
    return WMTInboxMessage(
      id: json['id'] as String,
      subject: json['subject'] as String,
      summary: json['summary'] as String,
      body: json['body'] as String?,
      type: json['type'] == "html" ? WMTInboxMessageType.html : WMTInboxMessageType.text,
      read: json['read'] as bool,
      timestampCreated: DateTime.parse(json['timestampCreated'] as String),
    );
  }
}

/// Type of the inbox message.
enum WMTInboxMessageType {
  /// Message is in plain text format.
  text("text"),
  /// Message is in HTML format.
  html("html");

  final String value;
  const WMTInboxMessageType(this.value);
}