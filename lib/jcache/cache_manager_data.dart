enum JCacheManagerDataType { data, file }

class JCacheManagerData {
  String originalKey;
  Map<String, dynamic> data;
  JCacheManagerDataType dataType;
  Duration expiryDuration;
  DateTime createdAt;
  DateTime updatedAt;

  JCacheManagerData({
    required this.originalKey,
    required this.data,
    required this.dataType,
    required this.expiryDuration,
    required this.createdAt,
    required this.updatedAt,
  });

  static JCacheManagerData fromJson(Map<String, dynamic> jsonData) {
    return JCacheManagerData(
      originalKey: jsonData['originalKey'] as String,
      data: jsonData['data'] as Map<String, dynamic>,
      dataType: jsonData['dataType'] == 'data'
          ? JCacheManagerDataType.data
          : JCacheManagerDataType.file,
      expiryDuration: Duration(
        milliseconds: jsonData['expiryDuration'],
      ),
      createdAt: DateTime.parse(jsonData['createdAt'] as String),
      updatedAt: DateTime.parse(jsonData['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'originalKey': originalKey,
      'data': data,
      'dataType': dataType == JCacheManagerDataType.data ? 'data' : 'file',
      'expiryDuration': expiryDuration.inMilliseconds,
      'createdAt': createdAt.toString(),
      'updatedAt': updatedAt.toString(),
    };
  }
}
