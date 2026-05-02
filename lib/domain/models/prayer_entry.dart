import 'prayer_type.dart';

class PrayerEntry {
  final int? id;
  final String date; // "YYYY-MM-DD"
  final PrayerType prayerType;
  final int count;
  final bool isJumuah;

  const PrayerEntry({
    this.id,
    required this.date,
    required this.prayerType,
    required this.count,
    this.isJumuah = false,
  });

  PrayerEntry copyWith({int? count, bool? isJumuah}) => PrayerEntry(
        id: id,
        date: date,
        prayerType: prayerType,
        count: count ?? this.count,
        isJumuah: isJumuah ?? this.isJumuah,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'date': date,
        'prayer_type': prayerType.name,
        'count': count,
        'is_jumuah': isJumuah ? 1 : 0,
      };

  factory PrayerEntry.fromMap(Map<String, dynamic> map) => PrayerEntry(
        id: map['id'] as int?,
        date: map['date'] as String,
        prayerType: PrayerType.fromString(map['prayer_type'] as String),
        count: map['count'] as int,
        isJumuah: (map['is_jumuah'] as int) == 1,
      );
}
