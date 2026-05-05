int calculateAge(DateTime birthDate) {
  final now = DateTime.now();
  var age = now.year - birthDate.year;

  if (now.month < birthDate.month ||
      (now.month == birthDate.month && now.day < birthDate.day)) {
    age--;
  }

  return age;
}

DateTime? parseBirthDate(String input) {
  final parts = input.trim().split(".");
  if (parts.length != 3) return null;

  final day = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  final year = int.tryParse(parts[2]);

  if (day == null || month == null || year == null) return null;

  final parsed = DateTime.tryParse(
    "${year.toString().padLeft(4, "0")}-${month.toString().padLeft(2, "0")}-${day.toString().padLeft(2, "0")}",
  );

  if (parsed == null) return null;
  if (parsed.day != day || parsed.month != month || parsed.year != year) {
    return null;
  }

  return parsed;
}