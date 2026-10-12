import 'dart:async';

import 'package:flutter/material.dart';

import '../models/food.dart';
import '../services/usda_service.dart';
import '../widgets/empty_state.dart';

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
      final foods = await _service.searchFoods(trimmed);
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              _buildHeader(context),
              const SizedBox(height: 16),
              _buildSearchField(context),
              const SizedBox(height: 16),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  /// DESIGN.md 6.2 "Large title": Display title with a caption below.
  Widget _buildHeader(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Lookup',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 2),
        Text(
          'Nutrition per 100 g from USDA',
          style: TextStyle(fontSize: 12, color: muted),
        ),
      ],
    );
  }

  Widget _buildSearchField(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return TextField(
      controller: _controller,
      textInputAction: TextInputAction.search,
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
            icon: const Icon(Icons.arrow_forward),
          ),
        ),
        filled: true,
        fillColor: colors.surfaceContainerLowest,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Widget _buildBody() {
    return switch (_status) {
      _LookupStatus.idle => const SingleChildScrollView(
        child: EmptyState(
          icon: Icons.manage_search,
          title: 'Look up any ingredient',
          message:
              'Type a food like egg, chicken, or rice to see its calories '
              'and protein.',
        ),
      ),
      _LookupStatus.loading => const Center(child: CircularProgressIndicator()),
      _LookupStatus.results => ListView.separated(
        padding: const EdgeInsets.only(bottom: 16),
        itemCount: _foods.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) => _FoodResultCard(food: _foods[index]),
      ),
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
}

/// One search result: food name, kcal per 100 g, and a protein badge.
class _FoodResultCard extends StatelessWidget {
  const _FoodResultCard({required this.food});

  final Food food;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        border: Border.all(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
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
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _ProteinBadge(grams: food.protein),
        ],
      ),
    );
  }
}

/// Pill showing grams of protein per 100 g (DESIGN.md ValueBadge style).
class _ProteinBadge extends StatelessWidget {
  const _ProteinBadge({required this.grams});

  final double grams;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.fitness_center,
            size: 12,
            color: colors.onPrimaryContainer,
          ),
          const SizedBox(width: 4),
          Text(
            '${grams.toStringAsFixed(1)} g protein',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
              color: colors.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }
}
