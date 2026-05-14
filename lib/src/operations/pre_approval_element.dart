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

/// Type of a pre-approval element.
enum WMTPreApprovalElementType {
  listItem('LIST_ITEM'),
  alert('ALERT'),
  button('BUTTON'),
  unknown('UNKNOWN');

  final String serialized;
  const WMTPreApprovalElementType(this.serialized);

  static WMTPreApprovalElementType fromSerialized(String value) {
    return WMTPreApprovalElementType.values.firstWhere(
      (e) => e.serialized == value,
      orElse: () => WMTPreApprovalElementType.unknown,
    );
  }
}

/// Visual style for pre-approval elements.
enum WMTPreApprovalElementStyle {
  info('INFO'),
  warning('WARNING'),
  danger('DANGER');

  final String serialized;
  const WMTPreApprovalElementStyle(this.serialized);

  static WMTPreApprovalElementStyle? fromSerialized(String? value) {
    if (value == null) return null;
    return WMTPreApprovalElementStyle.values.cast<WMTPreApprovalElementStyle?>().firstWhere(
      (e) => e!.serialized == value,
      orElse: () => null,
    );
  }
}

/// Action type for button elements.
enum WMTPreApprovalButtonAction {
  link('LINK'),
  mail('MAIL'),
  phone('PHONE');

  final String serialized;
  const WMTPreApprovalButtonAction(this.serialized);

  static WMTPreApprovalButtonAction? fromSerialized(String? value) {
    if (value == null) return null;
    return WMTPreApprovalButtonAction.values.cast<WMTPreApprovalButtonAction?>().firstWhere(
      (e) => e!.serialized == value,
      orElse: () => null,
    );
  }
}

/// Base class for pre-approval screen elements.
///
/// Subclasses provide type-specific properties:
/// - [WMTPreApprovalElementListItem] for list items with optional icon and style
/// - [WMTPreApprovalElementAlert] for alert boxes with style
/// - [WMTPreApprovalElementButton] for action buttons
class WMTPreApprovalElement {
  /// Optional unique identifier of the element.
  final String? id;

  /// Type of the element.
  final WMTPreApprovalElementType type;

  /// Text content of the element.
  final String? text;

  WMTPreApprovalElement({
    this.id,
    required this.type,
    this.text,
  });

  /// Creates a [WMTPreApprovalElement] from a JSON map.
  ///
  /// Dispatches to the appropriate subclass based on the `type` field.
  /// Unknown types are returned as the base [WMTPreApprovalElement].
  factory WMTPreApprovalElement.fromJson(Map<String, dynamic> json) {
    final type = WMTPreApprovalElementType.fromSerialized(json['type'] as String? ?? '');
    switch (type) {
      case WMTPreApprovalElementType.listItem:
        return WMTPreApprovalElementListItem.fromJson(json);
      case WMTPreApprovalElementType.alert:
        return WMTPreApprovalElementAlert.fromJson(json);
      case WMTPreApprovalElementType.button:
        return WMTPreApprovalElementButton.fromJson(json);
      case WMTPreApprovalElementType.unknown:
        return WMTPreApprovalElement(
          id: json['id'] as String?,
          type: type,
          text: json['text'] as String?,
        );
    }
  }
}

/// List item element with optional icon and visual style.
class WMTPreApprovalElementListItem extends WMTPreApprovalElement {
  /// Visual style of the list item.
  final WMTPreApprovalElementStyle? style;

  /// Icon asset identifier.
  final String? icon;

  WMTPreApprovalElementListItem({
    super.id,
    super.text,
    this.style,
    this.icon,
  }) : super(type: WMTPreApprovalElementType.listItem);

  factory WMTPreApprovalElementListItem.fromJson(Map<String, dynamic> json) {
    return WMTPreApprovalElementListItem(
      id: json['id'] as String?,
      text: json['text'] as String?,
      style: WMTPreApprovalElementStyle.fromSerialized(json['style'] as String?),
      icon: json['icon'] as String?,
    );
  }
}

/// Alert element – a highlighted box with a visual style.
class WMTPreApprovalElementAlert extends WMTPreApprovalElement {
  /// Visual style of the alert.
  final WMTPreApprovalElementStyle? style;

  WMTPreApprovalElementAlert({
    super.id,
    super.text,
    this.style,
  }) : super(type: WMTPreApprovalElementType.alert);

  factory WMTPreApprovalElementAlert.fromJson(Map<String, dynamic> json) {
    return WMTPreApprovalElementAlert(
      id: json['id'] as String?,
      text: json['text'] as String?,
      style: WMTPreApprovalElementStyle.fromSerialized(json['style'] as String?),
    );
  }
}

/// Button element with action, optional actionSettings and href.
class WMTPreApprovalElementButton extends WMTPreApprovalElement {
  /// Action type for the button (LINK, MAIL, PHONE).
  final WMTPreApprovalButtonAction? action;

  /// Custom extended behavior or secondary action, for example "REJECT".
  final String? actionSettings;

  /// URL / resource reference (URL, email, phone number).
  final String? href;

  WMTPreApprovalElementButton({
    super.id,
    super.text,
    this.action,
    this.actionSettings,
    this.href,
  }) : super(type: WMTPreApprovalElementType.button);

  factory WMTPreApprovalElementButton.fromJson(Map<String, dynamic> json) {
    return WMTPreApprovalElementButton(
      id: json['id'] as String?,
      text: json['text'] as String?,
      action: WMTPreApprovalButtonAction.fromSerialized(json['action'] as String?),
      actionSettings: json['actionSettings'] as String?,
      href: json['href'] as String?,
    );
  }
}
