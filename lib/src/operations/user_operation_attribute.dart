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

import '../core/logger.dart';

/// Operation Attribute can be visualized as "1 row in operation screen".
/// 
/// Every type of the attribute has it's own "strongly typed" implementation.
class WMTUserOperationAttribute {

  /// ID (type) of the label. This is highly depended on the backend
  /// and can be used to change the appearance of the label.
  final String id;

  /// Type of the operation.
  /// 
  /// If the type is for example `WMTOperationAttribute.amount`, you can retype the instance to `WMTOperationAttributeAmount`.
  final WMTAttributeType type;

  /// Value of the attribute.
  final String label;

  WMTUserOperationAttribute({
    required this.id,
    required this.type,
    required this.label,
  });

  /// Factory method to create an instance of the attribute based on the type.
  factory WMTUserOperationAttribute.fromJson(Map<String, dynamic> json) {
    final type = WMTAttributeType.fromSerialized(json['type'] as String);
    switch (type) {
      case WMTAttributeType.amount: return WMTOperationAttributeAmount.fromJson(json);
      case WMTAttributeType.amountConversion: return WMTOperationAttributeAmountConversion.fromJson(json);
      case WMTAttributeType.keyValue: return WMTOperationAttributeKeyValue.fromJson(json);
      case WMTAttributeType.note: return WMTOperationAttributeNote.fromJson(json);
      case WMTAttributeType.heading: return WMTOperationAttributeHeading.fromJson(json);
      case WMTAttributeType.image: return WMTOperationAttributeImage.fromJson(json);
      case WMTAttributeType.unknown:
        // Fallback to a generic attribute if type is unknown
        return WMTUserOperationAttribute(
          id: json['id'] as String,
          type: WMTAttributeType.unknown,
          label: json['label'] as String,
        );
    }
  }
}

/// Attribute type. Based on this type, proper class should be chosen for unboxing.
enum WMTAttributeType {

  /// Amount, like "100.00 CZK."
  amount("AMOUNT"),
  /// Currency conversion, for example when changing money from USD to EUR.
  amountConversion("AMOUNT_CONVERSION"),
  /// Any key value pair.
  keyValue("KEY_VALUE"),
  /// Just like KEY_VALUE, emphasizing that the value is a note or message.
  note("NOTE"),
  /// Single highlighted text, written in a larger font, used as a section heading.
  heading("HEADING"),
  /// For image displaying.
  image("IMAGE"),
  /// Fallback type for attributes that do not match any specific type.
  unknown("UNKNOWN");

  final String _serialized;
  const WMTAttributeType(this._serialized);

  /// Returns the [WMTAttributeType] for the given serialized value, or null if not found.
  static WMTAttributeType fromSerialized(String serialized) {
    return WMTAttributeType.values.firstWhere(
      (type) => type._serialized == serialized,
      orElse: ()  {
        Log.error("Unknown WMTAttributeType serialized value: $serialized");
        return WMTAttributeType.unknown; // Fallback to unknown if not found
      }
    );
  }
}

/// Amount attribute is 1 row in operation, that represents "Payment Amount".
class WMTOperationAttributeAmount extends WMTUserOperationAttribute {
  
  /// Formatted amount for presentation.
  /// 
  /// This property will be properly formatted based on the response language.
  /// For example when amount is 100 and the acceptLanguage is "cs" for czech,
  /// the amountFormatted will be "100,00"
  final String? amountFormatted;

  /// Formatted currency to the locale based on acceptLanguage.
  ///
  /// For example when the currency is CZK, this property will be "Kč".
  final String? currencyFormatted;

  /// Payment amount.
  final double? amount;

  /// Currency.
  final String? currency;

  /// Formatted value and currency to the locale based on acceptLanguage.
  /// 
  /// Both amount and currency are formatted, String will show e.g. "€" in front of the amount
  /// or "EUR" behind the amount depending on the locale.
  final String? valueFormatted;

  WMTOperationAttributeAmount({
    required super.id,
    required super.label,
    this.amountFormatted,
    this.currencyFormatted,
    this.amount,
    this.currency,
    this.valueFormatted,
  }) : super(
      type: WMTAttributeType.amount
  );

  factory WMTOperationAttributeAmount.fromJson(Map<String, dynamic> json) {
    return WMTOperationAttributeAmount(
      id: json['id'] as String,
      label: json['label'] as String,
      amountFormatted: json['amountFormatted'] as String?,
      currencyFormatted: json['currencyFormatted'] as String?,
      amount: (json['amount'] as num?)?.toDouble(),
      currency: json['currency'] as String?,
      valueFormatted: json['valueFormatted'] as String?,
    );
  }
}

/// Attribute that describes generic key-value row to display.
class WMTOperationAttributeKeyValue extends WMTUserOperationAttribute {
  
  /// Value of the attribute.
  final String value;

  WMTOperationAttributeKeyValue({
    required super.id,
    required super.label,
    required this.value,
  }) : super(
      type: WMTAttributeType.keyValue
  );

  factory WMTOperationAttributeKeyValue.fromJson(Map<String, dynamic> json) {
    return WMTOperationAttributeKeyValue(
      id: json['id'] as String,
      label: json['label'] as String,
      value: json['value'] as String,
    );
  }
}

// Attribute that describes note, that should be handled as "long text message"
class WMTOperationAttributeNote extends WMTUserOperationAttribute {
  
  /// Note text.
  final String note;

  WMTOperationAttributeNote({
    required super.id,
    required super.label,
    required this.note,
  }) : super(
      type: WMTAttributeType.note
  );

  factory WMTOperationAttributeNote.fromJson(Map<String, dynamic> json) {
    return WMTOperationAttributeNote(
      id: json['id'] as String,
      label: json['label'] as String,
      note: json['note'] as String,
    );
  }
}

/// Heading. This attribute has no value. It only acts as a "section separator".
class WMTOperationAttributeHeading extends WMTUserOperationAttribute {

  WMTOperationAttributeHeading({
    required super.id,
    required super.label,
  }) : super(
      type: WMTAttributeType.heading
  );

  factory WMTOperationAttributeHeading.fromJson(Map<String, dynamic> json) {
    return WMTOperationAttributeHeading(
      id: json['id'] as String,
      label: json['label'] as String,
    );
  }
}

/// Image that might be "opened" on tap/click.
class WMTOperationAttributeImage extends WMTUserOperationAttribute {

  /// Image thumbnail url to the public internet.
  final String thumbnailUrl;

  /// Full-size image that should be displayed on thumbnail click (when not null).
  /// Url to the public internet.
  final String? originalUrl;

  WMTOperationAttributeImage({
    required super.id,
    required super.label,
    required this.thumbnailUrl,
    this.originalUrl,
  }) : super(
      type: WMTAttributeType.image
  );

  factory WMTOperationAttributeImage.fromJson(Map<String, dynamic> json) {
    return WMTOperationAttributeImage(
      id: json['id'] as String,
      label: json['label'] as String,
      thumbnailUrl: json['thumbnailUrl'] as String,
      originalUrl: json['originalUrl'] as String?,
    );
  }
}

/// Conversion attribute is 1 row in operation, that represents "Money Conversion".
class WMTOperationAttributeAmountConversion extends WMTUserOperationAttribute {
  
  /// If the conversion is dynamic and the application should refresh it periodically.
  /// 
  /// This is just a hint for the application UI. This SDK does not offer feature to periodically
  /// refresh conversion rate.
  final bool isDynamic;

    /// Formatted amount for presentation.
    /// 
    /// This property will be properly formatted based on the response language.
    /// For example when amount is 100 and the acceptLanguage is "cs" for czech,
    /// the amountFormatted will be "100,00".
  final String? sourceAmountFormatted;

  /// Formatted currency to the locale based on acceptLanguage.
  /// 
  /// For example when the currency is CZK, this property will be "Kč".
  final String? sourceCurrencyFormatted;

  /// Payment amount.
  /// 
  /// Amount might not be precise (due to floating point conversion during deserialization from json)
  /// use amountFormatted property instead when available.
  final double? sourceAmount;

  /// Source currency.
  final String? sourceCurrency;

  /// Formatted currency and amount to the locale based on acceptLanguage.
  /// 
  /// Both amount and currency are formatted, String will show e.g. "€" in front of the amount
  /// or "EUR" behind the amount depending on locale.
  final String? sourceValueFormatted;

  /// Formatted amount for presentation.
  /// 
  /// This property will be properly formatted based on the response language.
  /// For example when amount is 100 and the acceptLanguage is "cs" for czech,
  /// the amountFormatted will be "100,00".
  final String? targetAmountFormatted;

  /// Formatted currency to the locale based on acceptLanguage.
  /// 
  /// For example when the currency is CZK, this property will be "Kč".
  final String? targetCurrencyFormatted;

  /// Payment amount.
  /// 
  /// Amount might not be precise (due to floating point conversion during deserialization from json)
  /// use amountFormatted property instead when available.
  final double? targetAmount;

  /// Target currency.
  final String? targetCurrency;

  /// Formatted currency and amount to the locale based on acceptLanguage.
  /// 
  /// Both amount and currency are formatted, String will show e.g. "€" in front of the amount
  /// or "EUR" behind the amount depending on locale.
  final String? targetValueFormatted;

  WMTOperationAttributeAmountConversion({
    required super.id,
    required super.label,
    required this.isDynamic,
    this.sourceAmountFormatted,
    this.sourceCurrencyFormatted,
    this.sourceAmount,
    this.sourceCurrency,
    this.sourceValueFormatted,
    this.targetAmountFormatted,
    this.targetCurrencyFormatted,
    this.targetAmount,
    this.targetCurrency,
    this.targetValueFormatted,
  }) : super(
      type: WMTAttributeType.amountConversion
  );

  factory WMTOperationAttributeAmountConversion.fromJson(Map<String, dynamic> json) {
    return WMTOperationAttributeAmountConversion(
      id: json['id'] as String,
      label: json['label'] as String,
      isDynamic: json['dynamic'] as bool,
      sourceAmountFormatted: json['sourceAmountFormatted'] as String?,
      sourceCurrencyFormatted: json['sourceCurrencyFormatted'] as String?,
      sourceAmount: (json['sourceAmount'] as num?)?.toDouble(),
      sourceCurrency: json['sourceCurrency'] as String?,
      sourceValueFormatted: json['sourceValueFormatted'] as String?,
      targetAmountFormatted: json['targetAmountFormatted'] as String?,
      targetCurrencyFormatted: json['targetCurrencyFormatted'] as String?,
      targetAmount: (json['targetAmount'] as double?),
      targetCurrency: json['targetCurrency'] as String?,
      targetValueFormatted: json['targetValueFormatted'] as String?,
    );
  }
}