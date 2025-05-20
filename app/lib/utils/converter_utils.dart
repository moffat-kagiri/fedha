class ConverterUtils {
  // Enum Converters
  static String profileTypeToJson(ProfileType type) => type.name;
  static ProfileType profileTypeFromJson(String json) =>
      ProfileType.values.firstWhere((e) => e.name == json);

  // Date Converters
  static DateTime parseBackendDate(String json) =>
      DateTime.parse(json).toLocal();
  static String formatForBackend(DateTime date) =>
      date.toUtc().toIso8601String();
}
