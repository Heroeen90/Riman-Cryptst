import '../utils/riman_x_service.dart';

class ThreatMatrixAnalytics {
  static double calculateThreatScore() {
    final activities = RimanXService().activities;
    if (activities.isEmpty) return 0.0;
    
    int highSeverity = activities.where((a) => a.severity == 'critical').length;
    return (highSeverity / activities.length) * 100.0;
  }
}
