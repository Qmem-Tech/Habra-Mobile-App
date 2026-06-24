/// True when [latitude]/[longitude] are usable for a map (not null island / unset).
bool isValidMapCoordinate(double latitude, double longitude) {
  if (latitude.isNaN || longitude.isNaN) return false;
  if (latitude < -90 || latitude > 90) return false;
  if (longitude < -180 || longitude > 180) return false;
  const t = 1e-6;
  if (latitude.abs() < t && longitude.abs() < t) return false;
  return true;
}
