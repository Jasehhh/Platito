import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/recipe.dart';
import '../providers/recipe_provider.dart';
import '../theme/app_colors.dart';
import '../utils/constants.dart';
import '../widgets/circle_icon_button.dart';
import '../widgets/ingredient_search_sheet.dart';

/// Add/Edit Recipe form. Opened with
/// Navigator.pushNamed(context, Routes.recipeForm) to create a recipe, or
/// with `arguments: recipe` to edit that recipe.
class RecipeFormScreen extends StatefulWidget {
  const RecipeFormScreen({super.key});

  @override
  State<RecipeFormScreen> createState() => _RecipeFormScreenState();
}

/// The form state of one ingredient row before it becomes a
/// RecipeIngredient. [name] and [fdcId] come from the USDA search sheet.
class _IngredientDraft {
  _IngredientDraft({
    this.name,
    this.fdcId,
    String grams = '',
    String price = '',
  }) : gramsController = TextEditingController(text: grams),
       priceController = TextEditingController(text: price);

  String? name;
  int? fdcId;
  final TextEditingController gramsController;
  final TextEditingController priceController;

  void dispose() {
    gramsController.dispose();
    priceController.dispose();
  }
}

class _RecipeFormScreenState extends State<RecipeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _servingsController = TextEditingController(text: '1');
  final _stepsController = TextEditingController();
  final List<_IngredientDraft> _ingredients = [];

  String _category = recipeCategories.first;

  /// The recipe being edited, or null when creating a new one.
  Recipe? _editing;

  /// Set after the first Save tap, so ingredient errors only show then.
  bool _submitted = false;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Route arguments are only available once the context is ready, so
    // the form is filled here instead of in initState, and only once.
    if (_initialized) return;
    _initialized = true;

    final recipe = ModalRoute.of(context)?.settings.arguments as Recipe?;
    if (recipe == null) {
      _ingredients.add(_IngredientDraft());
      return;
    }
    _editing = recipe;
    _nameController.text = recipe.name;
    _servingsController.text = '${recipe.servings}';
    _stepsController.text = recipe.steps.join('\n');
    _category = recipe.category;
    for (final ingredient in recipe.ingredients) {
      _ingredients.add(
        _IngredientDraft(
          name: ingredient.name,
          fdcId: ingredient.fdcId,
          grams: _formatNumber(ingredient.grams),
          price: _formatNumber(ingredient.price),
        ),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _servingsController.dispose();
    _stepsController.dispose();
    for (final draft in _ingredients) {
      draft.dispose();
    }
    super.dispose();
  }

  /// Shows 150.0 as "150" and 12.5 as "12.5".
  static String _formatNumber(double value) {
    return value == value.roundToDouble() ? value.toStringAsFixed(0) : '$value';
  }

  // Validators return an error message, or null when the value is fine.
  static String? _required(String? value) {
    return (value == null || value.trim().isEmpty) ? 'Required' : null;
  }

  static String? _aboveZero(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    final number = double.tryParse(value.trim());
    if (number == null) return 'Enter a number';
    if (number <= 0) return 'Must be above 0';
    return null;
  }

  static String? _wholeAboveZero(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    final number = int.tryParse(value.trim());
    if (number == null) return 'Enter a whole number';
    if (number <= 0) return 'Must be above 0';
    return null;
  }

  static String? _zeroOrMore(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    final number = double.tryParse(value.trim());
    if (number == null) return 'Enter a number';
    if (number < 0) return 'Must be 0 or more';
    return null;
  }

  Future<void> _chooseIngredient(_IngredientDraft draft) async {
    final food = await IngredientSearchSheet.show(context);
    if (food == null) return;
    setState(() {
      draft.name = food.name;
      draft.fdcId = food.fdcId;
    });
  }

  void _addIngredient() {
    setState(() => _ingredients.add(_IngredientDraft()));
  }

  void _removeIngredient(_IngredientDraft draft) {
    setState(() => _ingredients.remove(draft));
    // Dispose after this frame, once the row's text fields are gone.
    WidgetsBinding.instance.addPostFrameCallback((_) => draft.dispose());
  }

  Future<void> _save() async {
    setState(() => _submitted = true);
    final fieldsValid = _formKey.currentState!.validate();
    final ingredientsChosen =
        _ingredients.isNotEmpty &&
        _ingredients.every((draft) => draft.fdcId != null);
    if (!fieldsValid || !ingredientsChosen) return;

    final recipe = Recipe(
      // A new recipe gets a unique id from the current time.
      id: _editing?.id ?? 'user-${DateTime.now().microsecondsSinceEpoch}',
      name: _nameController.text.trim(),
      category: _category,
      servings: int.parse(_servingsController.text.trim()),
      emoji: _editing?.emoji ?? '🍽️',
      ingredients: [
        for (final draft in _ingredients)
          RecipeIngredient(
            name: draft.name!,
            fdcId: draft.fdcId!,
            grams: double.parse(draft.gramsController.text.trim()),
            price: double.parse(draft.priceController.text.trim()),
          ),
      ],
      steps: _stepsController.text
          .split('\n')
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toList(),
    );

    final provider = context.read<RecipeProvider>();
    final navigator = Navigator.of(context);
    if (_editing == null) {
      await provider.addRecipe(recipe);
    } else {
      await provider.updateRecipe(recipe);
    }
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildFormBar(context),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
                  children: [
                    TextFormField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Recipe name',
                      ),
                      validator: _required,
                    ),
                    const _Label('Category'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final category in recipeCategories)
                          ChoiceChip(
                            label: Text(category),
                            selected: _category == category,
                            onSelected: (_) =>
                                setState(() => _category = category),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _servingsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Servings'),
                      validator: _wholeAboveZero,
                    ),
                    const _Label('Ingredients'),
                    for (final draft in _ingredients)
                      _buildIngredientRow(draft),
                    if (_submitted && _ingredients.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: Text(
                          'Add at least one ingredient',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.error,
                          ),
                        ),
                      ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: _addIngredient,
                        icon: const Icon(Icons.add),
                        label: const Text('Add ingredient'),
                      ),
                    ),
                    const _Label('Steps'),
                    TextFormField(
                      controller: _stepsController,
                      minLines: 4,
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      decoration: const InputDecoration(
                        hintText: 'One step per line',
                        alignLabelWithHint: true,
                      ),
                      validator: _required,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      // DESIGN.md 6.5: Save is pinned at the bottom with a top border.
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
        child: SafeArea(
          top: false,
          child: FilledButton(
            onPressed: _save,
            child: Text(_editing == null ? 'Save recipe' : 'Save changes'),
          ),
        ),
      ),
    );
  }

  /// DESIGN.md 6.5 form bar: close button, centered title, empty space.
  Widget _buildFormBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 6),
      child: Row(
        children: [
          CircleIconButton(
            icon: Icons.close,
            tooltip: 'Close',
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text(
              _editing == null ? 'New Recipe' : 'Edit Recipe',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  /// One ingredient: a USDA picker on top, then grams, price, and remove.
  Widget _buildIngredientRow(_IngredientDraft draft) {
    final missingFood = _submitted && draft.fdcId == null;
    return Container(
      // The key keeps each row's field state with its own draft when a row
      // above it is removed.
      key: ObjectKey(draft),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => _chooseIngredient(draft),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'Ingredient',
                suffixIcon: const Icon(Icons.search),
                errorText: missingFood ? 'Choose an ingredient' : null,
              ),
              child: Text(
                draft.name ?? 'Tap to search USDA',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: draft.name == null
                      ? AppColors.textMuted
                      : AppColors.textPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  controller: draft.gramsController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Grams'),
                  validator: _aboveZero,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: draft.priceController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Price',
                    prefixText: '₱ ',
                  ),
                  validator: _zeroOrMore,
                ),
              ),
              IconButton(
                tooltip: 'Remove ingredient',
                onPressed: () => _removeIngredient(draft),
                icon: const Icon(
                  Icons.remove_circle_outline,
                  color: AppColors.iconInactive,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 10),
      child: Text(
        text,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }
}
