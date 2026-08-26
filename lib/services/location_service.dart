import 'package:adhan/adhan.dart';
import 'package:geolocator/geolocator.dart';
import '../models/prayer_data.dart';

class LocationService {
  static Future<Position> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied.');
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  static Future<PrayerSchedule> fetchPrayerSchedule() async {
    final position = await _determinePosition();
    final coordinates = Coordinates(position.latitude, position.longitude);

    final params = CalculationMethod.muslim_world_league.getParameters();
    params.madhab = Madhab.shafi;

    final date = DateComponents.from(DateTime.now());
    final prayerTimes = PrayerTimes(coordinates, date, params);

    final qiblaAngle = Qibla(coordinates).direction;

    const makkahLat = 21.4225;
    const makkahLng = 39.8262;
    final distanceMeters = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      makkahLat,
      makkahLng,
    );

    return PrayerSchedule(
      prayerTimes: prayerTimes,
      qiblaAngle: qiblaAngle,
      distanceToMakkahKm: distanceMeters / 1000.0,
    );
  }
}