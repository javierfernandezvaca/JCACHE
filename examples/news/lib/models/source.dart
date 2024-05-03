class Source {
  /// The identifier of the news source
  final String? id;

  /// The name of the news source
  final String name;

  Source({
    this.id,
    required this.name,
  });

  Source.fromJson(Map<String, dynamic> json)
      : this(
          id: json['id'],
          name: json['name']! as String,
        );

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}
