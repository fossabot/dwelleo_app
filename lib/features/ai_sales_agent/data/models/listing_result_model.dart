import '../../domain/entities/listing_result.dart';

class ListingResultModel extends ListingResult {
  const ListingResultModel({
    required super.title,
    required super.link,
    required super.snippet,
  });

  factory ListingResultModel.fromJson(Map<String, dynamic> json) =>
      ListingResultModel(
        title: (json['title'] as String?) ?? '',
        link: (json['link'] as String?) ?? '',
        snippet: (json['snippet'] as String?) ?? '',
      );
}
