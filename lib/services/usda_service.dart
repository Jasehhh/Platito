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
  static const _foodsPath = '/fdc/v1/foods';

  /// USDA sometimes takes over 10 s on the first request of a session.
  static const _timeout = Duration(seconds: 20);

  /// USDA accepts at most 20 fdcIds in one /fdc/v1/foods request.
  static const _maxIdsPerRequest = 20;

  /// Nutrient numbers for protein, fat, carbs, kcal, and the two Atwater
  /// energy values. Asking only for these keeps the response small.
  static const _nutrientNumbers = '203,204,205,208,957,958';

  /// Read at build time from keys.json via --dart-define-from-file,
  /// so the key is never written in the code or committed to GitHub.
  static const _apiKey = String.fromEnvironment('USDA_API_KEY');

  /// Searches USDA for foods matching [query].
  /// Only Foundation and SR Legacy foods are requested, so results are
  /// plain ingredients (egg, chicken) instead of branded products.
  Future<List<Food>> searchFoods(String query, {int pageSize = 20}) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return [];

    final url = Uri.https(_host, _searchPath, {
      'query': trimmed,
      'pageSize': '$pageSize',
      'dataType': 'Foundation,SR Legacy',
      'api_key': _requireApiKey(),
    });

    final data = await _getJson(url) as Map<String, dynamic>;
    final foods = data['foods'] as List<dynamic>? ?? [];
    return foods
        .map((item) => Food.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// Looks up foods by their USDA [ids], for example the fdcIds of every
  /// recipe ingredient. IDs are sent in groups of 20. Unknown IDs are
  /// left out of the result instead of causing an error.
  Future<List<Food>> getFoodsByIds(List<int> ids) async {
    if (ids.isEmpty) return [];
    final apiKey = _requireApiKey();

    final requests = <Future<dynamic>>[];
    for (var start = 0; start < ids.length; start += _maxIdsPerRequest) {
      final end = start + _maxIdsPerRequest < ids.length
          ? start + _maxIdsPerRequest
          : ids.length;
      final url = Uri.https(_host, _foodsPath, {
        'fdcIds': ids.sublist(start, end).join(','),
        'nutrients': _nutrientNumbers,
        'api_key': apiKey,
      });
      requests.add(_getJson(url));
    }

    // Each group returns a JSON list of foods. Future.wait runs the
    // groups at the same time and fails if any one of them fails.
    final responses = await Future.wait(requests);
    return [
      for (final list in responses)
        for (final item in list as List<dynamic>)
          Food.fromDetailJson(item as Map<String, dynamic>),
    ];
  }

  String _requireApiKey() {
    if (_apiKey.isEmpty) {
      throw const UsdaException(
        'Missing USDA API key. Run with --dart-define-from-file=keys.json.',
      );
    }
    return _apiKey;
  }

  /// Sends a GET request to [url] and returns the decoded JSON body.
  Future<dynamic> _getJson(Uri url) async {
    // These errors are rethrown as UsdaException because the original
    // ClientException message contains the full URL, including the API key.
    final http.Response response;
    try {
      response = await _client.get(url).timeout(_timeout);
    } on TimeoutException {
      throw const UsdaException('The request timed out. Please try again.');
    } on http.ClientException {
      throw const UsdaException("Can't reach USDA. Check your connection.");
    }

    if (response.statusCode != 200) {
      throw UsdaException(
        'USDA request failed (status ${response.statusCode}).',
      );
    }

    return jsonDecode(response.body);
  }
}
