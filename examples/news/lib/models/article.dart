import 'package:news/models/source.dart';

class Article {
  /// The identifier id and a display name name for the source this article came from
  final Source source;

  /// The author of the article
  final String? author;

  /// The headline or title of the article
  final String title;

  /// A description or snippet from the article
  final String? description;

  /// The direct URL to the article
  final String url;

  /// The URL to a relevant image for the article
  final String? urlToImage;

  /// The date and time that the article was published, in UTC (+000)
  final DateTime publishedAt;

  Article({
    required this.source,
    this.author,
    required this.title,
    this.description,
    required this.url,
    this.urlToImage,
    required this.publishedAt,
  });

  Article.fromJson(Map<String, dynamic> json)
      : this(
          source: Source.fromJson(json['source']),
          author: json['author'],
          title: json['title']! as String,
          description: json['description'],
          url: json['url']! as String,
          urlToImage: json['urlToImage'],
          publishedAt: DateTime.parse(json['publishedAt']! as String),
        );

  Map<String, dynamic> toJson() {
    return {
      'source': source.toJson(),
      'author': author,
      'title': title,
      'description': description,
      'url': url,
      'urlToImage': urlToImage,
      'publishedAt': publishedAt,
    };
  }
}
