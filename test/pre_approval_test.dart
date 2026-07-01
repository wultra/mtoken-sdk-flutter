import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mtoken_sdk_flutter/src/operations/user_operation_ui_data.dart';
import 'package:mtoken_sdk_flutter/src/operations/pre_approval_element.dart';
import 'package:mtoken_sdk_flutter/src/operations/pre_approval_controls.dart';

void main() {
  group('PreApprovalScreen', () {
    test('parses multiple screens with all element types', () {
      final json = jsonDecode(_newFormatJson) as Map<String, dynamic>;
      final uiData = WMTUserOperationUIData.fromJson(json);

      expect(uiData.preApprovalScreens, isNotNull);
      expect(uiData.preApprovalScreens!.length, 2);

      // Screen 1
      final s1 = uiData.preApprovalScreens![0];
      expect(s1.id, 'id1');
      expect(s1.type, 'WARNING');
      expect(s1.heading, 'Watch out!');
      expect(s1.message, 'You may become a victim of an attack.');
      expect(s1.backButton, true);
      expect(s1.image, 'image-label');

      // Elements
      expect(s1.elements, isNotNull);
      expect(s1.elements!.length, 3);

      // Alert element
      final e1 = s1.elements![0];
      expect(e1, isA<WMTPreApprovalElementAlert>());
      expect(e1.type, WMTPreApprovalElementType.alert);
      expect(e1.id, 'e1');
      expect(e1.text, 'Make sure the activation takes place on your device');
      expect((e1 as WMTPreApprovalElementAlert).style, WMTPreApprovalElementStyle.info);

      // Button element
      final e2 = s1.elements![1];
      expect(e2, isA<WMTPreApprovalElementButton>());
      expect(e2.type, WMTPreApprovalElementType.button);
      expect(e2.id, 'e2');
      expect(e2.text, 'Call center');
      final btn = e2 as WMTPreApprovalElementButton;
      expect(btn.action, WMTPreApprovalButtonAction.phone);
      expect(btn.actionSettings, 'REJECT');
      expect(btn.href, '+42012345678');

      // List item element
      final e3 = s1.elements![2];
      expect(e3, isA<WMTPreApprovalElementListItem>());
      expect(e3.type, WMTPreApprovalElementType.listItem);
      expect(e3.id, 'e3');
      expect(e3.text, 'You activate a new app and allow access to your accounts');
      final listItem = e3 as WMTPreApprovalElementListItem;
      expect(listItem.icon, 'icon-label');
      expect(listItem.style, isNull);

      // Controls
      expect(s1.controls, isNotNull);
      expect(s1.controls!.flip, true);
      expect(s1.controls!.axis, WMTPreApprovalButtonAxis.horizontal);
      expect(s1.controls!.decline, isNotNull);
      expect(s1.controls!.decline!.type, WMTPreApprovalDeclineType.reject);
      expect(s1.controls!.decline!.text, 'Reject Payment');
      expect(s1.controls!.approve, isNotNull);
      expect(s1.controls!.approve!.type, WMTPreApprovalApproveType.button);
      expect(s1.controls!.approve!.text, 'Approve Payment');
      expect(s1.controls!.approve!.counter, 10);

      // Screen 2
      final s2 = uiData.preApprovalScreens![1];
      expect(s2.id, 'id2');
      expect(s2.type, 'QR_SCAN');
      expect(s2.heading, 'Screen 2');
      expect(s2.message, 'Scan QR code');
      expect(s2.elements, isNull);
      expect(s2.controls, isNull);
    });

    test('handles null preApprovalScreens', () {
      final json = jsonDecode('{"flipButtons": true}') as Map<String, dynamic>;
      final uiData = WMTUserOperationUIData.fromJson(json);

      expect(uiData.preApprovalScreens, isNull);
    });

    test('handles empty elements array', () {
      final json = jsonDecode('''{
        "preApprovalScreens": [{
          "id": "s1",
          "type": "INFO",
          "heading": "Info",
          "message": "Message",
          "elements": []
        }]
      }''') as Map<String, dynamic>;
      final uiData = WMTUserOperationUIData.fromJson(json);

      expect(uiData.preApprovalScreens!.first.elements, isNotNull);
      expect(uiData.preApprovalScreens!.first.elements!.length, 0);
    });

    test('handles unknown element type gracefully', () {
      final json = jsonDecode('''{
        "preApprovalScreens": [{
          "type": "INFO",
          "heading": "Info",
          "message": "Message",
          "elements": [
            {"id": "u1", "type": "FUTURE_TYPE", "text": "Some text"}
          ]
        }]
      }''') as Map<String, dynamic>;
      final uiData = WMTUserOperationUIData.fromJson(json);

      final element = uiData.preApprovalScreens!.first.elements!.first;
      expect(element.type, WMTPreApprovalElementType.unknown);
      expect(element.id, 'u1');
      expect(element.text, 'Some text');
      // Unknown type should be base class, not a subclass
      expect(element, isNot(isA<WMTPreApprovalElementListItem>()));
      expect(element, isNot(isA<WMTPreApprovalElementAlert>()));
      expect(element, isNot(isA<WMTPreApprovalElementButton>()));
    });

    test('slider approve type is parsed correctly', () {
      final json = jsonDecode('''{
        "preApprovalScreens": [{
          "type": "WARNING",
          "heading": "Heading",
          "message": "Message",
          "controls": {
            "approve": {"type": "SLIDER", "text": "Slide to approve"}
          }
        }]
      }''') as Map<String, dynamic>;
      final uiData = WMTUserOperationUIData.fromJson(json);

      expect(uiData.preApprovalScreens!.first.controls!.approve!.type,
          WMTPreApprovalApproveType.slider);
    });

    test('button with mail action', () {
      final json = jsonDecode('''{
        "preApprovalScreens": [{
          "type": "INFO",
          "heading": "H",
          "message": "M",
          "elements": [
            {"type": "BUTTON", "action": "MAIL", "text": "Email us", "href": "support@example.com"}
          ]
        }]
      }''') as Map<String, dynamic>;
      final uiData = WMTUserOperationUIData.fromJson(json);

      final btn = uiData.preApprovalScreens!.first.elements!.first as WMTPreApprovalElementButton;
      expect(btn.action, WMTPreApprovalButtonAction.mail);
      expect(btn.href, 'support@example.com');
    });

    test('button with link action', () {
      final json = jsonDecode('''{
        "preApprovalScreens": [{
          "type": "INFO",
          "heading": "H",
          "message": "M",
          "elements": [
            {"type": "BUTTON", "action": "LINK", "text": "Visit site", "href": "https://example.com"}
          ]
        }]
      }''') as Map<String, dynamic>;
      final uiData = WMTUserOperationUIData.fromJson(json);

      final btn = uiData.preApprovalScreens!.first.elements!.first as WMTPreApprovalElementButton;
      expect(btn.action, WMTPreApprovalButtonAction.link);
      expect(btn.href, 'https://example.com');
    });

    test('vertical axis and back decline type', () {
      final json = jsonDecode('''{
        "preApprovalScreens": [{
          "type": "INFO",
          "heading": "H",
          "message": "M",
          "controls": {
            "axis": "VERTICAL",
            "decline": {"type": "BACK", "text": "Go Back"},
            "approve": {"type": "BUTTON"}
          }
        }]
      }''') as Map<String, dynamic>;
      final uiData = WMTUserOperationUIData.fromJson(json);

      final controls = uiData.preApprovalScreens!.first.controls!;
      expect(controls.axis, WMTPreApprovalButtonAxis.vertical);
      expect(controls.decline!.type, WMTPreApprovalDeclineType.back);
      expect(controls.decline!.text, 'Go Back');
    });

    test('element styles: warning and danger', () {
      final json = jsonDecode('''{
        "preApprovalScreens": [{
          "type": "WARNING",
          "heading": "H",
          "message": "M",
          "elements": [
            {"type": "LIST_ITEM", "text": "Item 1", "style": "WARNING"},
            {"type": "ALERT", "text": "Alert", "style": "DANGER"},
            {"type": "LIST_ITEM", "text": "Item 2", "style": "INFO"}
          ]
        }]
      }''') as Map<String, dynamic>;
      final uiData = WMTUserOperationUIData.fromJson(json);

      final elements = uiData.preApprovalScreens!.first.elements!;
      expect((elements[0] as WMTPreApprovalElementListItem).style, WMTPreApprovalElementStyle.warning);
      expect((elements[1] as WMTPreApprovalElementAlert).style, WMTPreApprovalElementStyle.danger);
      expect((elements[2] as WMTPreApprovalElementListItem).style, WMTPreApprovalElementStyle.info);
    });
  });

  group('PreApprovalScreen - Legacy format backward compatibility', () {
    test('legacy preApprovalScreen is converted to preApprovalScreens', () {
      final json = jsonDecode(_legacyFormatJson) as Map<String, dynamic>;
      final uiData = WMTUserOperationUIData.fromJson(json);

      expect(uiData.preApprovalScreens, isNotNull);
      expect(uiData.preApprovalScreens!.length, 1);

      final screen = uiData.preApprovalScreens!.first;
      expect(screen.type, 'WARNING');
      expect(screen.heading, 'Watch out!');
      expect(screen.message, 'You may become a victim of an attack.');
      expect(screen.image, 'fallback_image');
    });

    test('legacy items are converted to ListItem elements with fallback icon', () {
      final json = jsonDecode(_legacyFormatJson) as Map<String, dynamic>;
      final uiData = WMTUserOperationUIData.fromJson(json);
      final screen = uiData.preApprovalScreens!.first;

      expect(screen.elements, isNotNull);
      expect(screen.elements!.length, 3);

      for (int i = 0; i < 3; i++) {
        final element = screen.elements![i];
        expect(element, isA<WMTPreApprovalElementListItem>());
        expect(element.type, WMTPreApprovalElementType.listItem);
        expect(element.text, 'Item ${i + 1}');
        expect((element as WMTPreApprovalElementListItem).icon, 'fallback_icon');
      }
    });

    test('legacy SLIDER approvalType is converted to controls with flip and decline', () {
      final json = jsonDecode(_legacyFormatJson) as Map<String, dynamic>;
      final uiData = WMTUserOperationUIData.fromJson(json);
      final screen = uiData.preApprovalScreens!.first;

      expect(screen.controls, isNotNull);
      expect(screen.controls!.flip, true);
      expect(screen.controls!.decline, isNotNull);
      expect(screen.controls!.decline!.type, WMTPreApprovalDeclineType.back);
      expect(screen.controls!.approve, isNotNull);
      expect(screen.controls!.approve!.type, WMTPreApprovalApproveType.slider);
    });

    test('legacy format without items has null elements but fallback image', () {
      final json = jsonDecode('''{
        "preApprovalScreen": {
          "type": "INFO",
          "heading": "Info",
          "message": "No items here"
        }
      }''') as Map<String, dynamic>;
      final uiData = WMTUserOperationUIData.fromJson(json);

      expect(uiData.preApprovalScreens, isNotNull);
      expect(uiData.preApprovalScreens!.length, 1);
      expect(uiData.preApprovalScreens!.first.elements, isNull);
      expect(uiData.preApprovalScreens!.first.controls, isNull);
      expect(uiData.preApprovalScreens!.first.image, 'fallback_image');
    });

    test('legacy format with BUTTON approvalType has null controls', () {
      final json = jsonDecode('''{
        "preApprovalScreen": {
          "type": "INFO",
          "heading": "Info",
          "message": "Message",
          "approvalType": "BUTTON"
        }
      }''') as Map<String, dynamic>;
      final uiData = WMTUserOperationUIData.fromJson(json);
      final screen = uiData.preApprovalScreens!.first;

      expect(screen.controls, isNull);
    });

    test('legacy format with empty items has null elements but fallback image', () {
      final json = jsonDecode('''{
        "preApprovalScreen": {
          "type": "INFO",
          "heading": "Info",
          "message": "Message",
          "items": []
        }
      }''') as Map<String, dynamic>;
      final uiData = WMTUserOperationUIData.fromJson(json);

      expect(uiData.preApprovalScreens!.first.elements, isNull);
      expect(uiData.preApprovalScreens!.first.image, 'fallback_image');
    });

    test('new format takes priority over legacy', () {
      final json = jsonDecode('''{
        "preApprovalScreens": [
          {"type": "INFO", "heading": "New", "message": "New format"}
        ],
        "preApprovalScreen": {
          "type": "WARNING", "heading": "Legacy", "message": "Legacy format"
        }
      }''') as Map<String, dynamic>;
      final uiData = WMTUserOperationUIData.fromJson(json);

      expect(uiData.preApprovalScreens!.length, 1);
      expect(uiData.preApprovalScreens!.first.heading, 'New');
    });
  });

  group('PostApprovalScreen', () {
    test('unknown type throws ArgumentError', () {
      final json = jsonDecode('''{
        "postApprovalScreen": {
          "type": "FUTURE_TYPE",
          "heading": "Future",
          "message": "Some future screen"
        }
      }''') as Map<String, dynamic>;

      expect(() => WMTUserOperationUIData.fromJson(json), throwsArgumentError);
    });

    test('post approval screen still works', () {
      final json = jsonDecode('''{
        "postApprovalScreen": {
          "type": "REDIRECT",
          "heading": "Redirect",
          "message": "Redirecting...",
          "payload": {
            "redirectText": "Click here",
            "redirectUrl": "https://example.com",
            "countdown": 5
          }
        }
      }''') as Map<String, dynamic>;
      final uiData = WMTUserOperationUIData.fromJson(json);

      expect(uiData.postApprovalScreen, isNotNull);
      expect(uiData.postApprovalScreen, isA<WMTPostApprovalScreenRedirect>());
      final redirect = uiData.postApprovalScreen as WMTPostApprovalScreenRedirect;
      expect(redirect.heading, 'Redirect');
      expect(redirect.payload.redirectUrl, 'https://example.com');
      expect(redirect.payload.countdown, 5);
    });
  });
}

const _newFormatJson = '''{
  "flipButtons": true,
  "blockApprovalOnCall": false,
  "preApprovalScreens": [
    {
      "id": "id1",
      "type": "WARNING",
      "backButton": true,
      "image": "image-label",
      "heading": "Watch out!",
      "message": "You may become a victim of an attack.",
      "elements": [
        {
          "id": "e1",
          "type": "ALERT",
          "style": "INFO",
          "text": "Make sure the activation takes place on your device"
        },
        {
          "id": "e2",
          "type": "BUTTON",
          "action": "PHONE",
          "actionSettings": "REJECT",
          "text": "Call center",
          "href": "+42012345678"
        },
        {
          "id": "e3",
          "type": "LIST_ITEM",
          "icon": "icon-label",
          "text": "You activate a new app and allow access to your accounts"
        }
      ],
      "controls": {
        "flip": true,
        "axis": "HORIZONTAL",
        "decline": {
          "type": "REJECT",
          "text": "Reject Payment"
        },
        "approve": {
          "type": "BUTTON",
          "text": "Approve Payment",
          "counter": 10
        }
      }
    },
    {
      "id": "id2",
      "type": "QR_SCAN",
      "heading": "Screen 2",
      "message": "Scan QR code"
    }
  ]
}''';

const _legacyFormatJson = '''{
  "flipButtons": true,
  "blockApprovalOnCall": false,
  "preApprovalScreen": {
    "type": "WARNING",
    "heading": "Watch out!",
    "message": "You may become a victim of an attack.",
    "items": ["Item 1", "Item 2", "Item 3"],
    "approvalType": "SLIDER"
  }
}''';
