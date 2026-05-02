import 'package:adhan/adhan.dart';
import '../models/prayer_type.dart';

class PrayerTimeService {
  /// Returns today's prayer times given stored settings values.
  /// Returns null if city settings are missing.
  static Map<PrayerType, DateTime>? calculate({
    required String? cityLat,
    required String? cityLng,
    required String? method,
    required String? madhab,
    required String? highLatRule,
  }) {
    final lat = double.tryParse(cityLat ?? '');
    final lng = double.tryParse(cityLng ?? '');
    if (lat == null || lng == null) return null;

    final coordinates = Coordinates(lat, lng);
    final now = DateTime.now();
    final dateComponents = DateComponents.from(now);

    final calcMethod = _parseMethod(method ?? 'MuslimWorldLeague');
    final params = calcMethod.getParameters();
    params.madhab = _parseMadhab(madhab ?? 'Shafi');

    final hlr = _parseHighLatRule(highLatRule ?? 'angleBased');
    if (hlr != null) params.highLatitudeRule = hlr;

    final times = PrayerTimes(coordinates, dateComponents, params);

    return {
      PrayerType.fajr: times.fajr,
      PrayerType.dhuhr: times.dhuhr,
      PrayerType.asr: times.asr,
      PrayerType.maghrib: times.maghrib,
      PrayerType.isha: times.isha,
    };
  }

  static CalculationMethod _parseMethod(String s) {
    switch (s) {
      case 'NorthAmerica':
        return CalculationMethod.north_america;
      case 'Egyptian':
        return CalculationMethod.egyptian;
      case 'UmmAlQura':
        return CalculationMethod.umm_al_qura;
      case 'Karachi':
        return CalculationMethod.karachi;
      case 'Gulf':
      case 'Dubai':
        return CalculationMethod.dubai;
      case 'MoonsightingCommittee':
        return CalculationMethod.moon_sighting_committee;
      case 'Kuwait':
        return CalculationMethod.kuwait;
      case 'Qatar':
        return CalculationMethod.qatar;
      case 'Singapore':
        return CalculationMethod.singapore;
      case 'Turkey':
        return CalculationMethod.turkey;
      case 'Tehran':
        return CalculationMethod.tehran;
      case 'MuslimWorldLeague':
      default:
        return CalculationMethod.muslim_world_league;
    }
  }

  static Madhab _parseMadhab(String s) {
    return s == 'Hanafi' ? Madhab.hanafi : Madhab.shafi;
  }

  // Returns null for 'angleBased' since adhan Dart has no angleBased rule —
  // leaving highLatitudeRule unset uses the method's default (angle-based math).
  static HighLatitudeRule? _parseHighLatRule(String s) {
    switch (s) {
      case 'middleOfNight':
        return HighLatitudeRule.middle_of_the_night;
      case 'seventhOfNight':
        return HighLatitudeRule.seventh_of_the_night;
      case 'twilightAngle':
        return HighLatitudeRule.twilight_angle;
      default:
        return null;
    }
  }
}
