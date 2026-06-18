class HardwareBinder {
  static String generateHardwareToken(String deviceId) {
    // Simulated offline hardware signature binding
    return 'BINDER_${deviceId.hashCode}';
  }
}
