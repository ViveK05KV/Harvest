/// Formats a decimal for pre-filling a text field: whole numbers show with
/// no decimal point (`12` not `12.0`), fractional values keep their digits.
String trimZeros(double value) {
  return value == value.roundToDouble() ? value.toStringAsFixed(0) : value.toString();
}
