import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paywise/utils/currency_formatter.dart';

void main() {
  group('AppCurrency Indian Number Formatting Tests', () {
    test('formats thousands correctly (50,000)', () {
      expect(AppCurrency.format(50000), '₹50,000');
      expect(AppCurrency.format(50000, showSymbol: false), '50,000');
    });

    test('formats Lakhs correctly with Indian comma grouping (5,00,000)', () {
      expect(AppCurrency.format(500000), '₹5,00,000');
      expect(AppCurrency.format(500000, showSymbol: false), '5,00,000');
    });

    test('formats Ten Lakhs correctly (50,00,000)', () {
      expect(AppCurrency.format(5000000), '₹50,00,000');
      expect(AppCurrency.format(5000000, showSymbol: false), '50,00,000');
    });

    test('formats Crores correctly (5,00,00,000)', () {
      expect(AppCurrency.format(50000000), '₹5,00,00,000');
      expect(AppCurrency.format(50000000, showSymbol: false), '5,00,00,000');
    });

    test('num.toINR extension works correctly', () {
      expect(50000.toINR(), '₹50,000');
      expect(500000.toINR(), '₹5,00,000');
      expect(5000000.toINR(showSymbol: false), '50,00,000');
    });

    test('AppCurrency.parseClean strips commas and parses accurately', () {
      expect(AppCurrency.parseClean('50,000'), 50000.0);
      expect(AppCurrency.parseClean('5,00,000'), 500000.0);
      expect(AppCurrency.parseClean('50,00,000'), 5000000.0);
      expect(AppCurrency.parseClean('5,00,00,000'), 50000000.0);
      expect(AppCurrency.parseClean(''), isNull);
      expect(AppCurrency.parseClean(null), isNull);
      expect(AppCurrency.parseClean('abc'), isNull);
    });

    test('IndianCurrencyInputFormatter formats live typing with Indian commas', () {
      final formatter = IndianCurrencyInputFormatter();

      // Typing 500
      var res = formatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(text: '500', selection: TextSelection(baseOffset: 3, extentOffset: 3)),
      );
      expect(res.text, '500');
      expect(res.selection.baseOffset, 3);

      // Typing 5000 -> 5,000
      res = formatter.formatEditUpdate(
        res,
        const TextEditingValue(text: '5000', selection: TextSelection(baseOffset: 4, extentOffset: 4)),
      );
      expect(res.text, '5,000');
      expect(res.selection.baseOffset, 5);

      // Typing 50000 -> 50,000
      res = formatter.formatEditUpdate(
        res,
        const TextEditingValue(text: '50000', selection: TextSelection(baseOffset: 5, extentOffset: 5)),
      );
      expect(res.text, '50,000');
      expect(res.selection.baseOffset, 6);

      // Typing 500000 -> 5,00,000 (Lakhs)
      res = formatter.formatEditUpdate(
        res,
        const TextEditingValue(text: '500000', selection: TextSelection(baseOffset: 6, extentOffset: 6)),
      );
      expect(res.text, '5,00,000');
      expect(res.selection.baseOffset, 8);

      // Typing 5000000 -> 50,00,000 (Ten Lakhs)
      res = formatter.formatEditUpdate(
        res,
        const TextEditingValue(text: '5000000', selection: TextSelection(baseOffset: 7, extentOffset: 7)),
      );
      expect(res.text, '50,00,000');
      expect(res.selection.baseOffset, 9);

      // Typing 50000000 -> 5,00,00,000 (Crores)
      res = formatter.formatEditUpdate(
        res,
        const TextEditingValue(text: '50000000', selection: TextSelection(baseOffset: 8, extentOffset: 8)),
      );
      expect(res.text, '5,00,00,000');
      expect(res.selection.baseOffset, 11);
    });
  });
}

