/// Converts a number to Indian Rupee words format.
/// Example: 1234.50 => "One Thousand Two Hundred Thirty Four Rupees and Fifty Paise Only"
String rupeeToWords(double amount) {
  if (amount == 0) return 'Zero Rupees Only';

  final rupees = amount.truncate();
  final paise = ((amount - rupees) * 100).round();

  String rupeeWords = '';
  String paiseWords = '';

  if (rupees > 0) {
    rupeeWords = _convertToIndianWords(rupees);
    rupeeWords = rupees == 1 ? 'One Rupee' : '$rupeeWords Rupees';
  }

  if (paise > 0) {
    paiseWords = _getTens(paise.toString().padLeft(2, '0'));
    paiseWords = paise == 1 ? 'and One Paisa' : 'and $paiseWords Paise';
  }

  return '${rupeeWords.isNotEmpty ? rupeeWords : ""}${paiseWords.isNotEmpty ? " $paiseWords" : ""} Only'
      .trim();
}

String _convertToIndianWords(int number) {
  if (number == 0) return '';

  const places = ['', ' Thousand ', ' Lakh ', ' Crore ', ' Arab '];

  String result = '';
  // First, get the last 3 digits (hundreds)
  final hundreds = number % 1000;
  if (hundreds > 0) {
    result = _getHundreds(hundreds.toString());
  }

  number ~/= 1000;

  // Then process in groups of 2 (Indian numbering system)
  int placeIndex = 1;
  while (number > 0) {
    final twoDigits = number % 100;
    if (twoDigits > 0) {
      result = '${_getHundreds(twoDigits.toString())}${places[placeIndex]}$result';
    }
    number ~/= 100;
    placeIndex++;
    if (placeIndex >= places.length) break;
  }

  return result.trim();
}

String _getHundreds(String numberStr) {
  final number = int.parse(numberStr);
  if (number == 0) return '';

  final padded = number.toString().padLeft(3, '0');
  String result = '';

  // Hundreds place
  final h = int.parse(padded[padded.length - 3]);
  if (h > 0) {
    result = '${_getDigit(h)} Hundred ';
  }

  // Tens and ones
  final tensStr = padded.substring(padded.length - 2);
  final t = int.parse(tensStr[0]);
  if (t > 0) {
    result += _getTens(tensStr);
  } else {
    final o = int.parse(tensStr[1]);
    result += _getDigit(o);
  }

  return result.trim();
}

String _getTens(String tensText) {
  final value = int.parse(tensText);
  if (value < 10) return _getDigit(value);

  if (value >= 10 && value <= 19) {
    const teens = {
      10: 'Ten', 11: 'Eleven', 12: 'Twelve', 13: 'Thirteen',
      14: 'Fourteen', 15: 'Fifteen', 16: 'Sixteen', 17: 'Seventeen',
      18: 'Eighteen', 19: 'Nineteen',
    };
    return teens[value] ?? '';
  }

  const tens = {
    2: 'Twenty', 3: 'Thirty', 4: 'Forty', 5: 'Fifty',
    6: 'Sixty', 7: 'Seventy', 8: 'Eighty', 9: 'Ninety',
  };

  final t = int.parse(tensText[0]);
  final o = int.parse(tensText[1]);
  return '${tens[t] ?? ""}${o > 0 ? " ${_getDigit(o)}" : ""}';
}

String _getDigit(int digit) {
  const digits = {
    1: 'One', 2: 'Two', 3: 'Three', 4: 'Four', 5: 'Five',
    6: 'Six', 7: 'Seven', 8: 'Eight', 9: 'Nine',
  };
  return digits[digit] ?? '';
}
