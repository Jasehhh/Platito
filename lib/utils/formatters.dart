/// Text formats shared by the recipe screens, so "₱55" and "1.06 g/₱"
/// look the same everywhere.
String formatPesos(double amount) {
  // Whole pesos read cleaner; keep centavos only when there are some.
  if (amount == amount.roundToDouble()) return '₱${amount.toStringAsFixed(0)}';
  return '₱${amount.toStringAsFixed(2)}';
}

String formatProteinPerPeso(double value) => '${value.toStringAsFixed(2)} g/₱';

/// Card caption for one serving, e.g. "24 g protein · ₱55". When nutrition
/// is unavailable, only the cost is shown.
String recipeCaption(double? proteinPerServing, double costPerServing) {
  final cost = formatPesos(costPerServing.roundToDouble());
  if (proteinPerServing == null) return '$cost per serving';
  return '${proteinPerServing.round()} g protein · $cost';
}
