import 'dart:math';
import '../../models/vendor_profile.dart';

// ── Location helpers ─────────────────────────────────────────────────────────
// Relocated out of the (now-deleted) mock vendor fixtures file — these are
// real, reusable geography utilities, not mock data.

List<double>? coordsForLocation(String location) {
  final normalized = location.toLowerCase().trim();
  for (final entry in cityCoordinates.entries) {
    if (normalized.contains(entry.key)) return entry.value;
  }
  return null;
}

double vendorMatchScore(VendorProfile vendor, double coupleLat, double coupleLon) {
  final reputation = vendor.compositeScore / 100.0;
  if (vendor.latitude == null || vendor.longitude == null) {
    return reputation * 0.5;
  }
  final distKm = haversineKm(coupleLat, coupleLon, vendor.latitude!, vendor.longitude!);
  const maxDistKm = 300.0;
  final proximity = (1.0 - distKm / maxDistKm).clamp(0.0, 1.0);
  return reputation * 0.5 + proximity * 0.5;
}

double haversineKm(double lat1, double lon1, double lat2, double lon2) {
  const r = 6371.0;
  final dLat = _toRad(lat2 - lat1);
  final dLon = _toRad(lon2 - lon1);
  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(_toRad(lat1)) * cos(_toRad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
  return r * 2 * atan2(sqrt(a), sqrt(1 - a));
}

double _toRad(double deg) => deg * pi / 180;

const Map<String, List<double>> cityCoordinates = {
  // Zambia — primary markets
  'ndola': [-12.9587, 28.6366],
  'kitwe': [-12.8024, 28.2132],
  'lusaka': [-15.4167, 28.2833],
  'livingstone': [-17.8419, 25.8561],
  'kabwe': [-14.4469, 28.4464],
  'kalulushi': [-12.8403, 28.1003],
  'chingola': [-12.5348, 27.8595],
  'mufulira': [-12.5480, 28.2399],
  'solwezi': [-12.1720, 26.3900],
  'chipata': [-13.6456, 32.6475],
  'copperbelt': [-12.9587, 28.6366],
  // Neighbouring countries
  'harare': [-17.8252, 31.0335],
  'nairobi': [-1.2921, 36.8219],
  'johannesburg': [-26.2041, 28.0473],
};
