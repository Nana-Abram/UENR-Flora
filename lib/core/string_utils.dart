// lib/core/string_utils.dart

/// Capitalizes the first character — e.g. for turning a growth-type key
/// like 'trees' into the label 'Trees'. Was reimplemented identically in
/// several screens; this is the one shared version.
String capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
