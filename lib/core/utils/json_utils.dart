/// Reads a required non-null [String] field from decoded JSON, throwing a
/// descriptive [FormatException] instead of letting a bare cast fail with an
/// uncatchable-by-type `TypeError` — callers can catch `FormatException`
/// alongside `DioException` and surface it as a typed, user-facing error.
String requireString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is String) return value;
  throw FormatException('Expected required field "$key" to be a String, got: $value');
}

/// Reads a required non-null [num] field from decoded JSON. See [requireString].
num requireNum(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is num) return value;
  throw FormatException('Expected required field "$key" to be a num, got: $value');
}

/// Reads a required non-null nested JSON object from decoded JSON. See [requireString].
Map<String, dynamic> requireMap(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is Map<String, dynamic>) return value;
  throw FormatException('Expected required field "$key" to be a Map, got: $value');
}
