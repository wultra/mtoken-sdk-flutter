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

import 'package:flutter_powerauth_mobile_sdk_plugin/flutter_powerauth_mobile_sdk_plugin.dart';
import 'inbox_message.dart';
import '../utils/response_processor.dart';
import 'inbox_count.dart';
import '../networking/networking.dart';

/// Inbox networking layer for Wultra Mobile Token API.
class WMTInbox extends WMTNetworking {

  /// Constructor that initializes the inbox networking layer.
  /// 
  /// Params:
  /// - [powerAuth] is the PowerAuth instance used for signing requests.
  /// - [baseUrl] is the base URL of the Wultra Mobile Token API (usually ending with /enrollment-server).
  WMTInbox(PowerAuth powerAuth, String baseUrl, {super.configuration})
      : super(powerAuth, baseUrl, "WMTInbox");

  /// Get number of unread messages in the inbox.
  /// 
  /// Params:
  /// 
  /// Returns the count of unread messages in the inbox.
  Future<WMTInboxCount> getUnreadCount() async {
    final response = await postSignedWithToken(
      {},
      PowerAuthAuthentication.possession(),
      "/api/inbox/count",
      "possession_universal",
    );

    return WMTInboxCount.fromJson(response as Map<String, dynamic>);
  }

  /// Paged list of messages in the inbox.
  /// 
  /// Params:
  /// - [pageNumber] Page number. First page is `0`, second `1`, etc.
  /// - [pageSize] Size of the page.
  /// - [onlyUnread] Get only unread messages.
  ///
  /// Returns a list of messages in the inbox.
  Future<List<WMTInboxMessage>> getMessageList(int pageNumber, int pageSize, bool onlyUnread) async {
    final response = await postSignedWithToken(
      { "requestObject": { "page": pageNumber, "size": pageSize, "onlyUnread": onlyUnread } },
      PowerAuthAuthentication.possession(),
      "/api/inbox/message/list",
      "possession_universal",
    );

    return processResponse("inbox message list", () {
      final list = response as List<dynamic>;
      return list.map((item) => WMTInboxMessage.fromJson(item as Map<String, dynamic>)).toList();
    });
  }

   /// Get message detail in the inbox.
   /// 
   /// Params:
   /// - [messageId] Message identifier.
   ///
   /// Returns the message detail
  Future<WMTInboxMessage> getMessageDetail(String messageId) async{
    final response = await postSignedWithToken(
      { "requestObject": { "id": messageId } },
      PowerAuthAuthentication.possession(),
      "/api/inbox/message/detail",
      "possession_universal",
    );

    return processResponse("inbox detail", () {
      return WMTInboxMessage.fromJson(response as Map<String, dynamic>);
    });
  }

  /// Mark the message with the given identifier as read.
  /// 
  /// Params:
  ///  - [messageId] Message identifier.
  Future<void> markRead(String messageId) async {
    await postSignedWithToken(
      { "requestObject": { "id": messageId } },
      PowerAuthAuthentication.possession(),
      "/api/inbox/message/read",
      "possession_universal",
    );
  }

  /// Marks all unread messages in the inbox as read.
  /// 
  Future<void> markAllRead() async {
    await postSignedWithToken(
      {},
      PowerAuthAuthentication.possession(),
      "/api/inbox/message/read-all",
      "possession_universal",
    );
  }
}