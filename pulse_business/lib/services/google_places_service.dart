// pulse_business/lib/services/google_places_service.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:path_provider/path_provider.dart';

/// Lightweight model for autocomplete predictions
class PlacePrediction {
  final String placeId;
  final String name;
  final String fullAddress;
  final String secondaryText;

  PlacePrediction({
    required this.placeId,
    required this.name,
    required this.fullAddress,
    required this.secondaryText,
  });

  factory PlacePrediction.fromNewApi(Map<String, dynamic> json) {
    final text = json['text']?['text'] ?? '';
    final structured = json['structuredFormat'] ?? {};
    final mainText = structured['mainText']?['text'] ?? text;
    final secondary = structured['secondaryText']?['text'] ?? '';

    return PlacePrediction(
      placeId: json['placeId'] ?? '',
      name: mainText,
      fullAddress: text,
      secondaryText: secondary,
    );
  }
}

/// Full place details returned after user selects a prediction
class PlaceDetails {
  final String name;
  final String? streetNumber;
  final String? streetName;
  final String? city;
  final String? postalCode;
  final String? country;
  final String? phone;
  final String? website;
  final double? lat;
  final double? lng;
  final List<String>? weekdayHours;
  final String? photoReference; // e.g. "places/ChIJ.../photos/abc123"
  final String? category;
  final String? description; // From Google's editorialSummary

  PlaceDetails({
    required this.name,
    this.streetNumber,
    this.streetName,
    this.city,
    this.postalCode,
    this.country,
    this.phone,
    this.website,
    this.lat,
    this.lng,
    this.weekdayHours,
    this.photoReference,
    this.category,
    this.description,
  });

  factory PlaceDetails.fromNewApi(Map<String, dynamic> json) {
    final location = json['location'];
    final components = json['addressComponents'] as List<dynamic>? ?? [];
    final hours = json['regularOpeningHours'];
    final photos = json['photos'] as List<dynamic>?;
    final types = json['types'] as List<dynamic>? ?? [];

    String? getComponent(String type) {
      try {
        final comp = components.firstWhere(
          (c) => (c['types'] as List).contains(type),
        );
        return comp['longText'] as String?;
      } catch (_) {
        return null;
      }
    }

    List<String>? weekdayText;
    if (hours != null && hours['weekdayDescriptions'] != null) {
      weekdayText = (hours['weekdayDescriptions'] as List<dynamic>)
          .map((h) => h.toString())
          .toList();
    }

    return PlaceDetails(
      name: json['displayName']?['text'] ?? '',
      streetNumber: getComponent('street_number'),
      streetName: getComponent('route'),
      city: getComponent('locality') ?? getComponent('sublocality'),
      postalCode: getComponent('postal_code'),
      country: getComponent('country'),
      phone: json['nationalPhoneNumber'] ?? json['internationalPhoneNumber'],
      website: json['websiteUri'],
      lat: location?['latitude']?.toDouble(),
      lng: location?['longitude']?.toDouble(),
      weekdayHours: weekdayText,
      photoReference: photos != null && photos.isNotEmpty
          ? photos[0]['name'] as String?
          : null,
      category: _mapGoogleTypeToPulseCategory(types),
      description: json['editorialSummary']?['text'],
    );
  }

  String get formattedHours {
    if (weekdayHours == null || weekdayHours!.isEmpty) return '';
    return weekdayHours!.join('\n');
  }

  static String? _mapGoogleTypeToPulseCategory(List<dynamic> types) {
    for (final type in types) {
      switch (type.toString()) {
        case 'restaurant':
        case 'meal_delivery':
        case 'meal_takeaway':
          return 'Restaurant';
        case 'cafe':
        case 'coffee_shop':
          return 'Cafe';
        case 'bar':
        case 'night_club':
          return 'Entertainment';
        case 'hair_salon':
        case 'beauty_salon':
        case 'spa':
          return 'Salon';
        case 'gym':
        case 'fitness_center':
          return 'Fitness';
        case 'store':
        case 'clothing_store':
        case 'shopping_mall':
          return 'Shop';
        case 'amusement_center':
        case 'bowling_alley':
        case 'movie_theater':
          return 'Activity';
      }
    }
    return null;
  }
}

class GooglePlacesService {
  // ============================================================
  // ⚠️  Replace with your Google Maps API key.
  //     In Google Cloud Console, enable "Places API (New)"
  // ============================================================
  static const String _apiKey = 'AIzaSyB140RkQcA2eKLs58sFD-rCvZJt4LAAZI8';

  static const String _baseUrl = 'https://places.googleapis.com/v1';

  Timer? _debounceTimer;

  /// Search for business establishments as user types.
  /// Uses the Places API (New) Autocomplete endpoint.
  Future<List<PlacePrediction>> getAutocomplete({
    required String query,
    double? lat,
    double? lng,
  }) async {
    if (query.length < 2) return [];

    try {
      final body = <String, dynamic>{
        'input': query,
        'includedPrimaryTypes': ['establishment'],
        'includedRegionCodes': ['ca'], // Restrict to Canada
      };

      // Bias results toward user's current location
      if (lat != null && lng != null) {
        body['locationBias'] = {
          'circle': {
            'center': {'latitude': lat, 'longitude': lng},
            'radius': 10000.0, // 10km
          },
        };
      }

      debugPrint('🔍 Places Autocomplete (New): "$query"');

      final response = await http.post(
        Uri.parse('$_baseUrl/places:autocomplete'),
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': _apiKey,
        },
        body: json.encode(body),
      );

      if (response.statusCode != 200) {
        debugPrint('❌ Places API error: ${response.statusCode} - ${response.body}');
        return [];
      }

      final data = json.decode(response.body);
      final suggestions = data['suggestions'] as List<dynamic>? ?? [];

      final predictions = suggestions
          .where((s) => s['placePrediction'] != null)
          .map((s) => PlacePrediction.fromNewApi(s['placePrediction']))
          .toList();

      debugPrint('✅ Found ${predictions.length} results');
      return predictions;
    } catch (e) {
      debugPrint('❌ Autocomplete error: $e');
      return [];
    }
  }

  /// Debounced version - call this from the UI for live-as-you-type search
  void searchWithDebounce({
    required String query,
    required Function(List<PlacePrediction>) onResults,
    double? lat,
    double? lng,
    Duration delay = const Duration(milliseconds: 300),
  }) {
    _debounceTimer?.cancel();

    if (query.length < 2) {
      onResults([]);
      return;
    }

    _debounceTimer = Timer(delay, () async {
      final results = await getAutocomplete(
        query: query,
        lat: lat,
        lng: lng,
      );
      onResults(results);
    });
  }

  /// Fetch full details for a selected place using Places API (New).
  Future<PlaceDetails?> getPlaceDetails(String placeId) async {
    try {
      // Field mask tells the API exactly what data to return
      const fieldMask = [
        'displayName',
        'addressComponents',
        'nationalPhoneNumber',
        'internationalPhoneNumber',
        'websiteUri',
        'location',
        'regularOpeningHours',
        'photos',
        'types',
        'editorialSummary',
      ];

      final uri = Uri.parse('$_baseUrl/places/$placeId');

      debugPrint('📍 Fetching place details (New API) for: $placeId');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': _apiKey,
          'X-Goog-FieldMask': fieldMask.join(','),
        },
      );

      if (response.statusCode != 200) {
        debugPrint('❌ Place Details error: ${response.statusCode} - ${response.body}');
        return null;
      }

      final data = json.decode(response.body);
      final details = PlaceDetails.fromNewApi(data);

      debugPrint('✅ Got details: ${details.name} | ${details.phone} | ${details.city}');
      return details;
    } catch (e) {
      debugPrint('❌ Place Details error: $e');
      return null;
    }
  }

  /// Download a place photo and save as a temp file.
  /// [photoReference] is the photo resource name from PlaceDetails,
  /// e.g. "places/ChIJ.../photos/abc123"
  /// Returns a File suitable for your existing image upload flow.
  Future<File?> downloadPlacePhoto(String photoReference, {int maxHeight = 800}) async {
    try {
      final uri = Uri.parse(
        '$_baseUrl/$photoReference/media'
        '?maxHeightPx=$maxHeight&key=$_apiKey'
        '&skipHttpRedirect=true',
      );

      debugPrint('📸 Fetching place photo...');
      final response = await http.get(uri);

      if (response.statusCode != 200) {
        debugPrint('❌ Photo metadata error: ${response.statusCode}');
        return null;
      }

      // The response contains a JSON with the photoUri
      final data = json.decode(response.body);
      final photoUrl = data['photoUri'] as String?;

      if (photoUrl == null) {
        debugPrint('❌ No photoUri in response');
        return null;
      }

      // Download the actual image
      final imageResponse = await http.get(Uri.parse(photoUrl));
      if (imageResponse.statusCode != 200) {
        debugPrint('❌ Photo download error: ${imageResponse.statusCode}');
        return null;
      }

      // Save to temp file
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/place_photo_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await file.writeAsBytes(imageResponse.bodyBytes);

      debugPrint('✅ Photo saved: ${file.path}');
      return file;
    } catch (e) {
      debugPrint('❌ Photo download error: $e');
      return null;
    }
  }

  /// Get the user's current position for location biasing.
  Future<Position?> getCurrentPosition() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        final requested = await Geolocator.requestPermission();
        if (requested == LocationPermission.denied ||
            requested == LocationPermission.deniedForever) {
          return null;
        }
      }
      return await Geolocator.getCurrentPosition();
    } catch (e) {
      debugPrint('📍 Location not available for bias: $e');
      return null;
    }
  }

  void dispose() {
    _debounceTimer?.cancel();
  }
}