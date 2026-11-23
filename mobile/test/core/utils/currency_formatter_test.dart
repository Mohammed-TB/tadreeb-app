import 'package:flutter_test/flutter_test.dart';
import 'package:project_1/core/utils/currency_formatter.dart';

void main() {
  test('uses Yemeni rial as the single configured currency', () {
    expect(AppCurrency.current.code, 'YER');
    expect(AppCurrency.current.name, 'ريال يمني');
    expect(AppCurrency.current.symbol, 'ر.ي');
  });

  test('formats amounts with a consistent symbol and requested precision', () {
    expect(CurrencyFormatter.format(1250), '1,250 ر.ي');
    expect(CurrencyFormatter.format(1250.5, decimalDigits: 2), '1,250.50 ر.ي');
  });
}
