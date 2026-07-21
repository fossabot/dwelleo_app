/// One organic search result from Serper — a Dwelleo listing or page.
class ListingResult {
  final String title;
  final String link;
  final String snippet;

  const ListingResult({
    required this.title,
    required this.link,
    required this.snippet,
  });
}
