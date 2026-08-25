import 'package:flutter/material.dart';

class SemanticColors {
  SemanticColors._();

  static const Color income = Color(0xFF3D7A63);
  static const Color incomeDark = Color(0xFF72B49A);
  static const Color incomeSoft = Color(0x183D7A63);

  static const Color expense = Color(0xFFA45757);
  static const Color expenseDark = Color(0xFFD17B7B);
  static const Color expenseSoft = Color(0x18A45757);

  static const Color transfer = Color(0xFF59647A);
  static const Color transferDark = Color(0xFF9AA6BE);
  static const Color transferSoft = Color(0x1859647A);

  static Color incomeFor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? incomeDark : income;

  static Color expenseFor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? expenseDark : expense;

  static Color transferFor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? transferDark : transfer;

  static Color incomeSoftFor(BuildContext context) => incomeSoft;
  static Color expenseSoftFor(BuildContext context) => expenseSoft;
  static Color transferSoftFor(BuildContext context) => transferSoft;
}
