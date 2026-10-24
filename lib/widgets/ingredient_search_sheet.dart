import 'package:flutter/material.dart';

import '../models/food.dart';
import '../services/usda_service.dart';
import '../theme/app_colors.dart';
import 'cost_badge.dart';
import 'empty_state.dart';

/// Bottom sheet that searches USDA and returns the chosen [Food].
/// Open it with [IngredientSearchSheet.show]; it returns null if the
/// user closes the sheet without choosing.
class IngredientSearchSheet extends StatefulWidget {
  const IngredientSearchSheet({super.key});

  static Future<Food?> show(BuildContext context) {
    return showModalBottomSheet<Food>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (context) => const IngredientSearchSheet(),
    );
  }

  @override
  State<IngredientSearchSheet> createState() => _IngredientSearchSheetState();
}

class _IngredientSearchSheetState extends State<IngredientSearchSheet> {
  final _service = UsdaService();
  final _controller = TextEditingController();

  List<Food> _foods = [];
  bool _isLoading = false;
  bool _hasSearched = false;
  String? _errorMessage;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _controller.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final foods = await _service.searchFoods(query);
      if (!mounted) return;
      setState(() {
        _foods = foods;
        _hasSearched = true;
      });
    } on UsdaException catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Keeps the sheet above the keyboard.
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(18, 14, 18, 18 + keyboard),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.7,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Choose an ingredient',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              autofocus: true,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _search(),
              decoration: InputDecoration(
                hintText: 'Search USDA, e.g. egg',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: Padding(
                  padding: const EdgeInsets.all(6),
                  child: IconButton.filled(
                    tooltip: 'Search',
                    onPressed: _search,
                    icon: const Icon(Icons.arrow_forward, color: Colors.white),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(child: _buildResults()),
          ],
        ),
      ),
    );
  }

  Widget _buildResults() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return SingleChildScrollView(
        child: EmptyState(
          icon: Icons.wifi_off,
          title: _errorMessage!,
          actionLabel: 'Retry',
          onAction: _search,
        ),
      );
    }
    if (!_hasSearched) {
      return const SingleChildScrollView(
        child: EmptyState(
          icon: Icons.manage_search,
          title: 'Search for an ingredient',
          message: 'Its USDA nutrition is used to total your recipe.',
        ),
      );
    }
    if (_foods.isEmpty) {
      return const SingleChildScrollView(
        child: EmptyState(
          icon: Icons.search_off,
          title: 'No results',
          message: 'Try egg or chicken.',
        ),
      );
    }

    return ListView.separated(
      itemCount: _foods.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final food = _foods[index];
        return Material(
          color: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: AppColors.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            // Returns the chosen food to the form.
            onTap: () => Navigator.pop(context, food),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      food.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CostBadge(
                    icon: Icons.fitness_center,
                    label: '${food.protein.toStringAsFixed(1)} g / 100 g',
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
