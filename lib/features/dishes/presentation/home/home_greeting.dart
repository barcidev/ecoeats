import 'package:ecoeats/i18n/gen/strings.g.dart';

enum DayPart { morning, afternoon, evening }

/// «Buenos días» until noon, «buenas tardes» until seven, then the night.
DayPart dayPartOf(DateTime time) => switch (time.hour) {
  >= 5 && < 12 => .morning,
  >= 12 && < 19 => .afternoon,
  _ => .evening,
};

/// «Jorge Andrés» → «Jorge»: one name is how people greet each other.
String? firstNameOf(String? names) {
  final first = names?.trim().split(RegExp(r'\s+')).first ?? '';
  return first.isEmpty ? null : first;
}

String greetingFor(Translations translations, DateTime now, String? names) {
  final t = translations.dishes;
  final word = switch (dayPartOf(now)) {
    .morning => t.greeting.morning,
    .afternoon => t.greeting.afternoon,
    .evening => t.greeting.evening,
  };
  final name = firstNameOf(names);
  return name == null
      ? t.greeting.plain(greeting: word)
      : t.greeting.named(greeting: word, name: name);
}

/// The question under the greeting follows the meals of the day.
String headlineFor(Translations translations, DateTime now) {
  final t = translations.dishes;
  final hour = now.hour;
  if (hour >= 5 && hour < 12) return t.headline.morning;
  if (hour >= 12 && hour < 18) return t.headline.midday;
  return t.headline.evening;
}
