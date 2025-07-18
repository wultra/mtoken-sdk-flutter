
/// WMTInboxCount represents the count of unread messages in the inbox.
class WMTInboxCount {

  /// Number of unread messages in the inbox.
  final int countUnread;

  WMTInboxCount(this.countUnread);

  /// Creates a [WMTInboxCount] from a JSON map.
  factory WMTInboxCount.fromJson(Map<String, dynamic> json) {
    return WMTInboxCount(
      json['countUnread'] as int,
    );
  }
}