import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/food.dart';

/// Thrown when the USDA API returns an error or the key is missing.
class UsdaException implements Exception {
  const UsdaException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Talks to the USDA FoodData Central API.
/// Screens and providers call this class instead of using http directly,
/// so all API code lives in one place.
///
/// Callers only need to catch UsdaException. It covers a missing API key,
/// a bad status code, no internet connection, and a timeout.
class UsdaService {
  /// [client] can be replaced with a fake in tests.
  UsdaService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const _host = 'api.nal.usda.gov';
  static const _searchPath = '/fdc/v1/foods/search';
  static const _timeout = Duration(seconds: 10);

  /// Read at build time from keys.json via --dart-define-from-file,
  /// so the key is never written in the code or committed to GitHub.
  static const _apiKey = String.fromEnvironment('USDA_API_KEY');

  /// Searches USDA for foods matching [query].
  /// Only Foundation and SR Legacy foods are requested, so results are
  /// plain ingredients (egg, chicken) instead of branded products.
  Future<List<Food>> searchFoods(String query, {int pageSize = 20}) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return [];

    if (_apiKey.isEmpty) {
      throw const UsdaException(
        'Missing USDA API key. Run with --dart-define-from-file=keys.json.',
      );
    }

    final url = Uri.https(_host, _searchPath, {
      'query': trimmed,
      'pageSize': '$pageSize',
      'dataType': 'Foundation,SR Legacy',
      'api_key': _apiKey,
    });

    // These errors are rethrown as UsdaException because the original
    // ClientException message contains the full URL, including the API key.
    final http.Response response;
    try {
      response = await _client.get(url).timeout(_timeout);
    } on TimeoutException {
      throw const UsdaException('USDA request timed out. Try again.');
    } on http.ClientException {
      throw const UsdaException('No internet connection.');
    }

    if (response.statusCode != 200) {
      throw UsdaException(
        'USDA request failed (status ${response.statusCode}).',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final foods = data['foods'] as List<dynamic>? ?? [];
    return foods
        .map((item) => Food.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
