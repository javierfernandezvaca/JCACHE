enum JCacheManagerDataType { data, file }

class JCacheManagerData {
  Map<String, dynamic> data;
  JCacheManagerDataType dataType;
  int expiryDays;
  DateTime createdAt;
  DateTime updatedAt;

  JCacheManagerData({
    required this.data,
    required this.dataType,
    required this.expiryDays,
    required this.createdAt,
    required this.updatedAt,
  });

  static JCacheManagerData fromJson(Map<String, dynamic> jsonData) {
    return JCacheManagerData(
      data: jsonData['data'],
      dataType: jsonData['dataType'] == 'data'
          ? JCacheManagerDataType.data
          : JCacheManagerDataType.file,
      expiryDays: jsonData['expiryDays'],
      createdAt: DateTime.parse(jsonData['createdAt']),
      updatedAt: DateTime.parse(jsonData['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'data': data,
      'dataType': dataType == JCacheManagerDataType.data ? 'data' : 'file',
      'expiryDays': expiryDays,
      'createdAt': createdAt.toString(),
      'updatedAt': updatedAt.toString(),
    };
  }
}
