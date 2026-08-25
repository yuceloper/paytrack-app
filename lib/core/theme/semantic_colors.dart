import 'package:flutter/material.dart';

class SemanticColors {
  SemanticColors._();

  static const Color income = Color(0xFF3D7A63);
  static const Color incomeDark = Color(0xFF72B49A);

  static const Color expense = Color(0xFFA45757);
  static const Color expenseDark = Color(0xFFD17B7B);

  static const Color transfer = Color(0xFF59647A);
  static const Color transferDark = Color(0xFF9AA6BE);

  static Color incomeFor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? incomeDark : income;

  static Color expenseFor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? expenseDark : expense;

  static Color transferFor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? transferDark : transfer;

  static Color incomeSoftFor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF1B2B25)
          : const Color(0xFFEAF4EF);

  static Color expenseSoftFor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF302121)
          : const Color(0xFFF7ECEC);

  static Color transferSoftFor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF242832)
          : const Color(0xFFEEF0F4);
}
