import 'dart:io';
import 'package:path_provider/path_provider.dart';

class ScopedStorageManager {
  static Future<Directory> getSecureDirectory() async {
    return await getApplicationDocumentsDirectory();
  }

  static Future<void> flushResource(List<int> data) async {
    // Manually clear by overwriting and nullifying
    data.fillRange(0, data.length, 0);
  }
}
