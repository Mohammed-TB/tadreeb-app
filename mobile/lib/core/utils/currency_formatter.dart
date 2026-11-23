import 'package:intl/intl.dart';

class CurrencyDefinition {
  const CurrencyDefinition({
    required this.code,
    required this.symbol,
    required this.name,
    required this.fractionDigits,
  });

  final String code;
  final String symbol;
  final String name;
  final int fractionDigits;
}

class AppCurrency {
  AppCurrency._();

  static const defaultCode = 'YER';
  static const definitions = <String, CurrencyDefinition>{
    'YER': CurrencyDefinition(
      code: 'YER',
      symbol: 'ر.ي',
      name: 'ريال يمني',
      fractionDigits: 2,
    ),
  };

  static CurrencyDefinition get current => byCode(defaultCode);

  static CurrencyDefinition byCode(String code) {
    final currency = definitions[code];
    if (currency == null) {
      throw ArgumentError.value(code, 'code', 'Unsupported currency code');
    }
    return currency;
  }
}

class CurrencyFormatter {
  CurrencyFormatter._();

  static String format(
    num amount, {
    String currencyCode = AppCurrency.defaultCode,
    int? decimalDigits,
  }) {
    final currency = AppCurrency.byCode(currencyCode);
    final digits =
        decimalDigits ??
        (amount == amount.roundToDouble() ? 0 : currency.fractionDigits);
    if (digits < 0 || digits > 6) {
      throw ArgumentError.value(digits, 'decimalDigits');
    }

    final fractionPattern = digits == 0
        ? ''
        : '.${List.filled(digits, '0').join()}';
    final number = NumberFormat('#,##0$fractionPattern', 'en').format(amount);
    return '$number ${currency.symbol}';
  }
}
