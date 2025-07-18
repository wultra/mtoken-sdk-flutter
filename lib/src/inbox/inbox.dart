import 'package:flutter_powerauth_mobile_sdk_plugin/flutter_powerauth_mobile_sdk_plugin.dart';
import 'package:mtoken_sdk_flutter/src/core/exception.dart';
import 'package:mtoken_sdk_flutter/src/inbox/inbox_message.dart';
import 'package:mtoken_sdk_flutter/src/utils/response_processor.dart';

import 'inbox_count.dart';
import '../networking/networking.dart';

/// Inbox networking layer for Wultra Mobile Token API.
class WMTInbox extends WMTNetworking {

  /// Constructor that initializes the inbox networking layer.
  /// 
  /// Params:
  /// - [powerAuth] is the PowerAuth instance used for signing requests.
  /// - [baseUrl] is the base URL of the Wultra Mobile Token API (usually ending with /enrollment-server).
  WMTInbox(super.powerAuth, super.baseUrl);

  /// Get number of unread messages in the inbox.
  /// 
  /// Params:
  /// - [requestProcessor] You may modify the request headers via this processor.
  /// 
  /// Returns the count of unread messages in the inbox.
  Future<WMTInboxCount> getUnreadCount({ WMTRequestProcessor? requestProcessor }) async {
    final response = await postSignedWithToken(
      {},
      PowerAuthAuthentication.possession(),
      "/api/inbox/count",
      "possession_universal",
      requestProcessor: requestProcessor,
    );

    return WMTInboxCount.fromJson(response as Map<String, dynamic>);
  }

  /// Paged list of messages in the inbox.
  /// 
  /// Params:
  /// - [pageNumber] Page number. First page is `0`, second `1`, etc.
  /// - [pageSize] Size of the page.
  /// - [onlyUnread] Get only unread messages.
  /// - [requestProcessor] You may modify the request headers via this processor.
  ///
  /// Returns a list of messages in the inbox.
  Future<List<WMTInboxMessage>> getMessageList(int pageNumber, int pageSize, bool onlyUnread, { WMTRequestProcessor? requestProcessor }) async {
    final response = await postSignedWithToken(
      { "requestObject": { "page": pageNumber, "size": pageSize, "onlyUnread": onlyUnread } },
      PowerAuthAuthentication.possession(),
      "/api/inbox/message/list",
      "possession_universal",
      requestProcessor: requestProcessor,
    );

    // TODO: use this handling for all deserialization (create helper method?)
    return processResponse("inbox message list", () {
      final list = response as List<dynamic>;
      return list.map((item) => WMTInboxMessage.fromJson(item as Map<String, dynamic>)).toList();
    });
  }

   /// Get message detail in the inbox.
   /// 
   /// Params:
   /// - [messageId] Message identifier.
   /// - [requestProcessor] You may modify the request headers via this processor.
   ///
   /// Returns the message detail
  Future<WMTInboxMessage> getMessageDetail(String messageId, { WMTRequestProcessor? requestProcessor }) async{
    final response = await postSignedWithToken(
      { "requestObject": { "id": messageId } },
      PowerAuthAuthentication.possession(),
      "/api/inbox/message/detail",
      "possession_universal",
      requestProcessor: requestProcessor,
    );

    return processResponse("inbox detail", () {
      return WMTInboxMessage.fromJson(response as Map<String, dynamic>);
    });
  }

  /// Mark the message with the given identifier as read.
  /// 
  /// Params:
  ///  - [messageId] Message identifier.
  /// - [requestProcessor] You may modify the request headers via this processor.
  Future<void> markRead(String messageId, { WMTRequestProcessor? requestProcessor }) async {
    await postSignedWithToken(
      { "requestObject": { "id": messageId } },
      PowerAuthAuthentication.possession(),
      "/api/inbox/message/read",
      "possession_universal",
      requestProcessor: requestProcessor,
    );
  }

  /// Marks all unread messages in the inbox as read.
  /// 
  /// - [requestProcessor] You may modify the request headers via this processor.
  Future<void> markAllRead({ WMTRequestProcessor? requestProcessor }) async {
    await postSignedWithToken(
      {},
      PowerAuthAuthentication.possession(),
      "/api/inbox/message/read-all",
      "possession_universal",
      requestProcessor: requestProcessor,
    );
  }
}