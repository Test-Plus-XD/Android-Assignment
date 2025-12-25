import 'restaurant.dart';

/// Enhanced search response with pagination metadata
///
/// Contains search results with full pagination support from Algolia
class SearchResponse {
  final List<Restaurant> hits;
  final int nbHits;
  final int page;
  final int nbPages;
  final int hitsPerPage;
  final String? processingTimeMS;

  SearchResponse({
    required this.hits,
    required this.nbHits,
    required this.page,
    required this.nbPages,
    required this.hitsPerPage,
    this.processingTimeMS,
  });

  factory SearchResponse.fromJson(Map<String, dynamic> json) {
    return SearchResponse(
      hits: (json['hits'] as List?)
              ?.map((hit) => Restaurant.fromJson(hit as Map<String, dynamic>))
              .toList() ??
          [],
      nbHits: json['nbHits'] ?? 0,
      page: json['page'] ?? 0,
      nbPages: json['nbPages'] ?? 0,
      hitsPerPage: json['hitsPerPage'] ?? 20,
      processingTimeMS: json['processingTimeMS']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hits': hits.map((h) => h.toJson()).toList(),
      'nbHits': nbHits,
      'page': page,
      'nbPages': nbPages,
      'hitsPerPage': hitsPerPage,
      if (processingTimeMS != null) 'processingTimeMS': processingTimeMS,
    };
  }

  bool get hasNextPage => page < nbPages - 1;
  bool get hasPreviousPage => page > 0;
  bool get isEmpty => hits.isEmpty;
  bool get isNotEmpty => hits.isNotEmpty;
}

/// Facet value with count for filtering
///
/// Used for discovering available filter options and their counts
class FacetValue {
  final String value;
  final int count;

  FacetValue({
    required this.value,
    required this.count,
  });

  factory FacetValue.fromJson(Map<String, dynamic> json) {
    return FacetValue(
      value: json['value'] ?? '',
      count: json['count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'value': value,
      'count': count,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FacetValue &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => '$value ($count)';
}

/// Advanced search request with all filter options
///
/// Supports combining text search, filters, and geo-location search
class AdvancedSearchRequest {
  final String? query;
  final List<String>? districts;
  final List<String>? keywords;
  final int page;
  final int hitsPerPage;
  final String? aroundLatLng; // "lat,lng" format
  final int? aroundRadius; // in meters
  final Map<String, dynamic>? filters; // Custom filters

  AdvancedSearchRequest({
    this.query,
    this.districts,
    this.keywords,
    this.page = 0,
    this.hitsPerPage = 20,
    this.aroundLatLng,
    this.aroundRadius,
    this.filters,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {
      'page': page,
      'hitsPerPage': hitsPerPage,
    };

    if (query != null && query!.isNotEmpty) {
      json['query'] = query;
    }
    if (districts != null && districts!.isNotEmpty) {
      json['districts'] = districts;
    }
    if (keywords != null && keywords!.isNotEmpty) {
      json['keywords'] = keywords;
    }
    if (aroundLatLng != null) {
      json['aroundLatLng'] = aroundLatLng;
    }
    if (aroundRadius != null) {
      json['aroundRadius'] = aroundRadius;
    }
    if (filters != null && filters!.isNotEmpty) {
      json['filters'] = filters;
    }

    return json;
  }

  Map<String, String> toQueryParameters() {
    final Map<String, String> params = {
      'page': page.toString(),
      'hitsPerPage': hitsPerPage.toString(),
    };

    if (query != null && query!.isNotEmpty) {
      params['query'] = query!;
    }
    if (districts != null && districts!.isNotEmpty) {
      params['districts'] = districts!.join(',');
    }
    if (keywords != null && keywords!.isNotEmpty) {
      params['keywords'] = keywords!.join(',');
    }
    if (aroundLatLng != null) {
      params['aroundLatLng'] = aroundLatLng!;
    }
    if (aroundRadius != null) {
      params['aroundRadius'] = aroundRadius.toString();
    }

    return params;
  }
}
