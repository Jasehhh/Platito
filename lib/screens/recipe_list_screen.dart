import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/recipe.dart';
import '../providers/recipe_provider.dart';
import '../utils/constants.dart';
import '../widgets/circle_icon_button.dart';
import '../widgets/empty_state.dart';
import '../widgets/gradient_header.dart';
import '../widgets/recipe_value_card.dart';

/// Route argument that opens [RecipeListScreen] in search mode:
/// Navigator.pushNamed(context, Routes.recipeList,
///     arguments: const RecipeSearchArgs()).
class RecipeSearchArgs {
  const RecipeSearchArgs({this.autofocus = true});

  /// Whether the search field gets focus right away, which opens the
  /// keyboard.
  final bool autofocus;
}

/// Recipes in one category, or all recipes when the route argument is null.
/// Opened from Home with:
/// Navigator.pushNamed(context, Routes.recipeList, arguments: category).
/// A [RecipeSearchArgs] argument opens it in search mode instead.
class RecipeListScreen extends StatefulWidget {
  const RecipeListScreen({super.key});

  @override
  State<RecipeListScreen> createState() => _RecipeListScreenState();
}

class _RecipeListScreenState extends State<RecipeListScreen> {
  RecipeSort _sort = RecipeSort.proteinPerPeso;
  final _searchController = TextEditingController();
  String _query = '';

  /// Category picked in search mode. Null means "All".
  String? _category;

  static const _sortLabels = {
    RecipeSort.proteinPerPeso: 'Best value',
    RecipeSort.protein: 'Protein',
    RecipeSort.cost: 'Cheapest',
  };

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final arguments = ModalRoute.of(context)?.settings.arguments;
    final search = arguments is RecipeSearchArgs ? arguments : null;
    final category = search != null
        ? _category
        : (arguments is String ? arguments : null);
    final provider = context.watch<RecipeProvider>();
    final recipes = provider.sortRecipes(
      _matchingRecipes(provider, category),
      _sort,
    );

    String title = category ?? 'All recipes';
    if (search != null) title = 'Search';

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTopBar(context, title, recipes.length),
            if (search != null) ...[
              _buildSearchField(search.autofocus),
              _buildCategoryChips(),
            ],
            _buildSortChips(),
            Expanded(
              child: _buildBody(context, provider, recipes, search != null),
            ),
          ],
        ),
      ),
    );
  }

  /// DESIGN.md 6.3 centered bar: back button, title with a count, and an
  /// empty 40 px space on the right so the title stays centered.
  Widget _buildTopBar(BuildContext context, String title, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 6),
      child: Row(
        children: [
          CircleIconButton(
            icon: Icons.chevron_left,
            tooltip: 'Back',
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  count == 1 ? '1 recipe' : '$count recipes',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  /// Recipes in [category] (all recipes when null), including the user's
  /// own, whose name contains the search text. Case doesn't matter.
  List<Recipe> _matchingRecipes(RecipeProvider provider, String? category) {
    final recipes = category == null
        ? provider.recipes
        : provider.recipesByCategory(category);
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return recipes;
    return recipes
        .where((recipe) => recipe.name.toLowerCase().contains(query))
        .toList();
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _query = '');
  }

  /// White search field in the same style as the Lookup search bar, with
  /// a clear button once there is text.
  Widget _buildSearchField(bool autofocus) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 4),
      child: SizedBox(
        height: 52,
        child: HeaderBar(
          child: TextField(
            controller: _searchController,
            autofocus: autofocus,
            textInputAction: TextInputAction.search,
            textAlignVertical: TextAlignVertical.center,
            onChanged: (value) => setState(() => _query = value),
            decoration: InputDecoration(
              hintText: 'Search recipes',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear',
                      onPressed: _clearSearch,
                      icon: const Icon(Icons.close),
                    ),
              // The white bar already draws the box, so the field has none.
              filled: false,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
      ),
    );
  }

  /// Single-select category filter for search mode. "All" is a null
  /// category.
  Widget _buildCategoryChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
      child: Row(
        children: [
          for (final category in [null, ...recipeCategories]) ...[
            ChoiceChip(
              label: Text(category ?? 'All'),
              selected: _category == category,
              onSelected: (_) => setState(() => _category = category),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  Widget _buildSortChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      child: Row(
        children: [
          for (final entry in _sortLabels.entries) ...[
            ChoiceChip(
              label: Text(entry.value),
              selected: _sort == entry.key,
              onSelected: (_) => setState(() => _sort = entry.key),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    RecipeProvider provider,
    List<Recipe> recipes,
    bool isSearching,
  ) {
    if (provider.isLoading && provider.recipes.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (recipes.isEmpty && isSearching) {
      return const SingleChildScrollView(
        padding: EdgeInsets.all(18),
        child: EmptyState(
          icon: Icons.search_off,
          title: 'No recipes found',
          message: 'Try a shorter word or pick another category.',
        ),
      );
    }
    if (recipes.isEmpty) {
      return const SingleChildScrollView(
        padding: EdgeInsets.all(18),
        child: EmptyState(
          icon: Icons.restaurant_menu,
          title: 'No recipes here yet',
          message: 'Add your own budget meal from My Recipes.',
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
      itemCount: recipes.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) => RecipeValueCard(
        recipe: recipes[index],
        onTap: () => Navigator.pushNamed(
          context,
          Routes.recipeDetail,
          arguments: recipes[index],
        ),
      ),
    );
  }
}
