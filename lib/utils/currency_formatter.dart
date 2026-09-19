import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Centralized currency formatter strictly implementing the Indian Numbering System:
/// Examples:
/// - 50,000 (Fifty Thousand)
/// - 5,00,000 (Five Lakhs)
/// - 50,00,000 (Fifty Lakhs)
/// - 5,00,00,000 (Five Crores)
class AppCurrency {
  static final NumberFormat _inrWithSymbol = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  static final NumberFormat _inrWithoutSymbol = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '',
    decimalDigits: 0,
  );

  /// Standard NumberFormat configured for Indian Rupee format (₹#,##,###)
  static NumberFormat get formatter => _inrWithSymbol;

  /// Formats a number in the Indian numbering system.
  /// [showSymbol] defaults to true (e.g. ₹5,00,000). Set to false for "5,00,000".
  static String format(num amount, {bool showSymbol = true}) {
    if (showSymbol) {
      return _inrWithSymbol.format(amount);
    } else {
      return _inrWithoutSymbol.format(amount).trim();
    }
  }

  /// Strips all commas and whitespace, returning a parsed double or null if empty/invalid.
  static double? parseClean(String? text) {
    if (text == null) return null;
    final clean = text.replaceAll(',', '').trim();
    if (clean.isEmpty) return null;
    return double.tryParse(clean);
  }
}

/// TextInputFormatter that formats digits live using Indian currency grouping:
/// (e.g. 50000 -> 50,000; 500000 -> 5,00,000; 5000000 -> 50,00,000)
/// Correctly maintains the cursor position during typing, deleting, backspacing, and pasting.
class IndianCurrencyInputFormatter extends TextInputFormatter {
  final bool allowDecimals;
  final int maxDigits;

  IndianCurrencyInputFormatter({
    this.allowDecimals = false,
    this.maxDigits = 12, // Up to 999 Crores
  });

  /// Formats an unformatted string of digits into Indian grouping:
  /// 3 rightmost digits, followed by pairs of 2 digits separated by commas.
  static String formatIndianDigits(String digits) {
    if (digits.isEmpty) return '';
    // Strip leading zeroes except single '0'
    String clean = digits.replaceFirst(RegExp(r'^0+(?=\d)'), '');
    if (clean.isEmpty) clean = '0';

    if (clean.length <= 3) {
      return clean;
    }

    final lastThree = clean.substring(clean.length - 3);
    final remaining = clean.substring(0, clean.length - 3);

    final StringBuffer buffer = StringBuffer();
    final remLength = remaining.length;
    for (int i = 0; i < remLength; i++) {
      if (i > 0 && (remLength - i) % 2 == 0) {
        buffer.write(',');
      }
      buffer.write(remaining[i]);
    }
    buffer.write(',');
    buffer.write(lastThree);

    return buffer.toString();
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    String text = newValue.text;
    String intPart = '';
    String decPart = '';
    bool hasDot = false;

    if (allowDecimals && text.contains('.')) {
      hasDot = true;
      final parts = text.split('.');
      intPart = parts[0].replaceAll(RegExp(r'[^\d]'), '');
      if (parts.length > 1) {
        decPart = parts[1].replaceAll(RegExp(r'[^\d]'), '');
        if (decPart.length > 2) {
          decPart = decPart.substring(0, 2);
        }
      }
    } else {
      intPart = text.replaceAll(RegExp(r'[^\d]'), '');
    }

    if (intPart.length > maxDigits) {
      intPart = intPart.substring(0, maxDigits);
    }

    if (intPart.isEmpty && !hasDot) {
      return const TextEditingValue();
    }

    final formattedInt = intPart.isEmpty ? (hasDot ? '0' : '') : formatIndianDigits(intPart);
    final formattedText = hasDot ? '$formattedInt.$decPart' : formattedInt;

    // Preserve cursor position by counting digits/dots to the left of the user's cursor
    int rawDigitsBeforeCursor = 0;
    final selectionEnd = newValue.selection.end.clamp(0, newValue.text.length);
    for (int i = 0; i < selectionEnd; i++) {
      final char = newValue.text[i];
      if (RegExp(r'\d').hasMatch(char) || (char == '.' && allowDecimals)) {
        rawDigitsBeforeCursor++;
      }
    }

    int newOffset = 0;
    int matchedCount = 0;
    for (int i = 0; i < formattedText.length; i++) {
      final char = formattedText[i];
      if (RegExp(r'\d').hasMatch(char) || (char == '.' && allowDecimals)) {
        matchedCount++;
      }
      if (matchedCount == rawDigitsBeforeCursor) {
        newOffset = i + 1;
        break;
      }
    }

    if (rawDigitsBeforeCursor == 0) {
      newOffset = 0;
    } else if (matchedCount < rawDigitsBeforeCursor) {
      newOffset = formattedText.length;
    }

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(
        offset: newOffset.clamp(0, formattedText.length),
      ),
    );
  }
}

/// Convenient extension on num for quick formatting
extension IndianCurrencyFormatting on num {
  String toINR({bool showSymbol = true}) => AppCurrency.format(this, showSymbol: showSymbol);
}
