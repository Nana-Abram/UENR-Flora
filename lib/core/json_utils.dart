// lib/core/json_utils.dart

/// Reads a required field out of a Supabase JSON row, throwing a clear
/// [FormatException] naming the table and field instead of letting a
/// malformed or partially-null row surface as an opaque
/// "type 'Null' is not a subtype of type 'T'" cast error three layers up.
T requireField<T>(Map<String, dynamic> map, String key, {required String table}) {
  final value = map[key];
  if (value is! T) {
    throw FormatException(
      '$table.$key: expected a $T but got ${value == null ? 'null' : value.runtimeType}',
    );
  }
  return value;
}
