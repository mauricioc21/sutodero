// Stub for dart:io when running on Web
class File {
  File(String path);
  Future<void> writeAsBytes(List<int> bytes) async {
    throw UnsupportedError('File operations are not supported on Web');
  }
  String get path => '';
}

class Directory {
  Directory(String path);
  String get path => '';
  static Directory get systemTemp => Directory('');
}
