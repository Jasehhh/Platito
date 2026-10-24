import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/food.dart';
import '../providers/recipe_provider.dart';
import '../services/usda_service.dart';
import '../theme/app_colors.dart';
import '../widgets/empty_state.dart';
import '../widgets/gradient_header.dart';
import '../widgets/macro_bar.dart';

/// The five things the Lookup screen can show. Exactly one is active.
enum _LookupStatus { idle, loading, results, empty, error }

/// Searches USDA for an ingredient and shows its calories and protein.
class IngredientLookupScreen extends StatefulWidget {
  const IngredientLookupScreen({super.key});

  @override
  State<IngredientLookupScreen> createState() => _IngredientLookupScreenState();
}

class _IngredientLookupScreenState extends State<IngredientLookupScreen> {
  final _service = UsdaService();
  final _controller = TextEditingController();

  _LookupStatus _status = _LookupStatus.idle;
  List<Food> _foods = [];
  String _errorMessage = '';
  String _lastQuery = '';
  bool _sortByProtein = false;

  /// Goes up by one for every search. A result is only shown if its id
  /// still matches, so an older, slower search can't overwrite a newer one.
  int _searchId = 0;

  /// Waits until the user stops typing before searching (debounce).
  Timer? _debounce;
  static const _debounceDelay = Duration(milliseconds: 500);
  static const _minQueryLength = 2;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  /// Runs on every keystroke. Restarts the 500 ms timer, so the search only
  /// fires once the user has paused typing.
  void _onQueryChanged(String text) {
    _debounce?.cancel();
    final trimmed = text.trim();

    if (trimmed.isEmpty) {
      // Box cleared: drop any search still in flight and go back to idle.
      _searchId++;
      setState(() => _status = _LookupStatus.idle);
      return;
    }
    if (trimmed.length < _minQueryLength) return;

    _debounce = Timer(
      _debounceDelay,
      () => _search(trimmed, hideKeyboard: false),
    );
  }

  /// Searches right away. Used by the Enter key, the arrow button, Retry,
  /// and the debounce timer. Typing keeps the keyboard open.
  Future<void> _search(String query, {bool hideKeyboard = true}) async {
    _debounce?.cancel();
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;

    if (hideKeyboard) FocusScope.of(context).unfocus();
    _lastQuery = trimmed;
    final searchId = ++_searchId;
    setState(() => _status = _LookupStatus.loading);

    try {
      // Some USDA entries have no protein or calorie values at all. They
      // would show as "0.0 g protein, 0 kcal", so they are left out.
      final foods = (await _service.searchFoods(
        trimmed,
      )).where((food) => food.protein > 0 || food.calories > 0).toList();
      if (!mounted || searchId != _searchId) return;
      setState(() {
        _foods = foods;
        _status = foods.isEmpty ? _LookupStatus.empty : _LookupStatus.results;
      });
    } on UsdaException catch (e) {
      if (!mounted || searchId != _searchId) return;
      setState(() {
        _errorMessage = e.message;
        _status = _LookupStatus.error;
      });
    } catch (_) {
      // Anything unexpected, such as a malformed response.
      if (!mounted || searchId != _searchId) return;
      setState(() {
        _errorMessage = 'Something went wrong. Please try again.';
        _status = _LookupStatus.error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GradientHeader(
            overlap: _buildSearchBar(),
            child: const GradientHeaderTitle(
              title: 'Lookup',
              subtitle: 'Protein and calories per 100 g, from USDA',
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
              child: _buildBody(),
            ),
          ),
        ],
      ),
    );
  }

  /// Room under scrolling lists so the last item clears the floating dock.
  double get _bottomPadding => MediaQuery.paddingOf(context).bottom + 16;

  /// White search field sitting on the header's bottom edge.
  Widget _buildSearchBar() {
    return HeaderBar(
      child: TextField(
        controller: _controller,
        textInputAction: TextInputAction.search,
        textAlignVertical: TextAlignVertical.center,
        onChanged: _onQueryChanged,
        onSubmitted: _search,
        decoration: InputDecoration(
          hintText: 'Search an ingredient, e.g. egg',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: Padding(
            padding: const EdgeInsets.all(6),
            child: IconButton.filled(
              tooltip: 'Search',
              onPressed: () => _search(_controller.text),
              icon: const Icon(Icons.arrow_forward, color: Colors.white),
            ),
          ),
          // The white bar already draws the box, so the field has none.
          filled: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }

  /// Common gym ingredients and their USDA ids, which the built-in recipes
  /// already use, so their nutrition is loaded by RecipeProvider.
  static const _quickPicks = [
    (label: 'Mung beans (dry)', query: 'Mung beans', fdcId: 174256),
    (label: 'Chicken breast', query: 'Chicken breast', fdcId: 171077),
    (label: 'Sardines', query: 'Sardines', fdcId: 175140),
    (label: 'Milkfish', query: 'Milkfish', fdcId: 173675),
    (label: 'Canned tuna', query: 'Canned tuna', fdcId: 334194),
    (label: 'Tofu', query: 'Tofu', fdcId: 172475),
    (label: 'Ground pork', query: 'Ground pork', fdcId: 167902),
    (label: 'Egg', query: 'Egg', fdcId: 171287),
  ];

  void _searchSuggestion(String text) {
    _controller.text = text;
    _search(text);
  }

  /// Results in USDA's order, or with the most protein per 100 g first.
  List<Food> get _sortedFoods {
    if (!_sortByProtein) return _foods;
    return [..._foods]..sort((a, b) => b.protein.compareTo(a.protein));
  }

  Widget _buildBody() {
    return switch (_status) {
      _LookupStatus.idle => _buildSuggestions(),
      _LookupStatus.loading => const Center(child: CircularProgressIndicator()),
      _LookupStatus.results => _buildResults(),
      _LookupStatus.empty => SingleChildScrollView(
        child: EmptyState(
          icon: Icons.search_off,
          title: 'No results',
          message: 'Nothing found for "$_lastQuery". Try egg or chicken.',
        ),
      ),
      _LookupStatus.error => SingleChildScrollView(
        child: EmptyState(
          icon: Icons.wifi_off,
          title: _errorMessage,
          actionLabel: 'Retry',
          onAction: () => _search(_lastQuery),
        ),
      ),
    };
  }

  /// Idle state: the quick picks ranked by protein per 100 g. Falls back
  /// to plain chips while the USDA data is still loading or unavailable.
  Widget _buildSuggestions() {
    final provider = context.watch<RecipeProvider>();
    final allLoaded = _quickPicks.every(
      (pick) => provider.foodFor(pick.fdcId) != null,
    );

    return ListView(
      padding: EdgeInsets.only(bottom: _bottomPadding),
      children: [
        const Text(
          'Protein per 100 g',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        const Text(
          'Common gym ingredients from the USDA data behind the recipes. '
          'Tap one to look it up.',
          style: TextStyle(fontSize: 13, color: AppColors.textMuted),
        ),
        const SizedBox(height: 12),
        if (allLoaded)
          _buildRanking(provider)
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final pick in _quickPicks)
                ActionChip(
                  label: Text(pick.query),
                  onPressed: () => _searchSuggestion(pick.query),
                ),
            ],
          ),
      ],
    );
  }

  /// One white panel with a row per ingredient, highest protein first.
  /// Each bar is scaled to the top ingredient. Only called once every
  /// quick pick has its USDA food, so the ! below is safe.
  Widget _buildRanking(RecipeProvider provider) {
    double proteinOf(int fdcId) => provider.foodFor(fdcId)!.protein;
    final sorted = [..._quickPicks]
      ..sort((a, b) => proteinOf(b.fdcId).compareTo(proteinOf(a.fdcId)));
    final top = proteinOf(sorted.first.fdcId);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(18),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < sorted.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            _RankingRow(
              label: sorted[i].label,
              protein: proteinOf(sorted[i].fdcId),
              fraction: top == 0 ? 0 : proteinOf(sorted[i].fdcId) / top,
              onTap: () => _searchSuggestion(sorted[i].query),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResults() {
    final foods = _sortedFoods;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '${foods.length} results',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textMuted,
                ),
              ),
            ),
            ChoiceChip(
              label: const Text('Best match'),
              selected: !_sortByProtein,
              onSelected: (_) => setState(() => _sortByProtein = false),
            ),
            const SizedBox(width: 8),
            ChoiceChip(
              label: const Text('Most protein'),
              selected: _sortByProtein,
              onSelected: (_) => setState(() => _sortByProtein = true),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.only(bottom: _bottomPadding),
            itemCount: foods.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) =>
                _FoodResultCard(food: foods[index]),
          ),
        ),
      ],
    );
  }
}

/// One search result. The protein per 100 g is the large number on the
/// left, since that is what a gym user compares first. The bar shows how
/// much of the calories come from protein.
class _FoodResultCard extends StatelessWidget {
  const _FoodResultCard({required this.food});

  final Food food;

  @override
  Widget build(BuildContext context) {
    // Protein has 4 kcal per gram.
    final proteinShare = food.calories == 0
        ? 0.0
        : food.protein * 4 / food.calories;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 72,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    Text(
                      food.protein.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    const Text(
                      'g protein',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      food.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${food.calories.round()} kcal per 100 g',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          MacroBar(
            label: 'Protein',
            value: '${(proteinShare * 100).clamp(0, 100).round()}% kcal',
            fraction: proteinShare,
          ),
        ],
      ),
    );
  }
}

/// One ingredient in the protein ranking: name, a bar scaled to the top
/// ingredient, and grams of protein per 100 g.
class _RankingRow extends StatelessWidget {
  const _RankingRow({
    required this.label,
    required this.protein,
    required this.fraction,
    required this.onTap,
  });

  final String label;
  final double protein;
  final double fraction;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            SizedBox(
              width: 128,
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: fraction.clamp(0.0, 1.0),
                  minHeight: 10,
                  backgroundColor: const Color(0xFFE3EAE6),
                  color: AppColors.primary,
                ),
              ),
            ),
            SizedBox(
              width: 64,
              child: Text(
                "${protein.toStringAsFixed(1)} g",
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryDark,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
