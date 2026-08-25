import 'package:flutter/material.dart';

class SemanticColors {
  SemanticColors._();

  static const Color income = Color(0xFF3D7A63);
  static const Color incomeDark = Color(0xFF72B49A);
  static const Color incomeSoftLight = Color(0xFFEAF4EF);
  static const Color incomeSoftDark = Color(0xFF182622);

  static const Color expense = Color(0xFFA45757);
  static const Color expenseDark = Color(0xFFD17B7B);
  static const Color expenseSoftLight = Color(0xFFF7ECEC);
  static const Color expenseSoftDark = Color(0xFF2A2023);

  static const Color transfer = Color(0xFF59647A);
  static const Color transferDark = Color(0xFF9AA6BE);
  static const Color transferSoftLight = Color(0xFFEEF0F4);
  static const Color transferSoftDark = Color(0xFF222631);

  static Color incomeFor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? incomeDark : income;

  static Color expenseFor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? expenseDark : expense;

  static Color transferFor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? transferDark : transfer;

  static Color incomeSoftFor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? incomeSoftDark : incomeSoftLight;

  static Color expenseSoftFor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? expenseSoftDark : expenseSoftLight;

  static Color transferSoftFor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? transferSoftDark : transferSoftLight;
}
