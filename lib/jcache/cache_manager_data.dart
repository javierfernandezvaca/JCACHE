enum JCacheManagerDataType { data, file }

class JCacheManagerData {
  Map<String, dynamic> data;
  DateTime lastAccessed;
  int expiryInDays;
  JCacheManagerDataType dataType;

  JCacheManagerData({
    required this.data,
    required this.lastAccessed,
    required this.expiryInDays,
    required this.dataType,
  });

  static JCacheManagerData fromJson(Map<String, dynamic> jsonData) {
    return JCacheManagerData(
      data: jsonData['data'],
      lastAccessed: DateTime.parse(jsonData['lastAccessed']),
      expiryInDays: jsonData['expiryInDays'],
      dataType: jsonData['dataType'] == 'data'
          ? JCacheManagerDataType.data
          : JCacheManagerDataType.file,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'data': data,
      'lastAccessed': lastAccessed.toString(),
      'expiryInDays': expiryInDays,
      'dataType': dataType == JCacheManagerDataType.data ? 'data' : 'file',
    };
  }
}
