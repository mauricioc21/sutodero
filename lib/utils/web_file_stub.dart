class File {
  final String path;
  File(this.path);
  
  Future<bool> exists() async => false;
  Future<int> length() async => 0;
  Future<void> delete() async {}
  Future<List<int>> readAsBytes() async => [];
  
  String get parent => '';
}

class Directory {
  final String path;
  Directory(this.path);
  
  bool existsSync() => false;
  Future<bool> exists() async => false;
  Future<void> create({bool recursive = false}) async {}
  Future<void> delete({bool recursive = false}) async {}
}

class Platform {
  static bool get isAndroid => false;
  static bool get isIOS => false;
  static bool get isWindows => false;
  static bool get isMacOS => false;
  static bool get isLinux => false;
  static bool get isFuchsia => false;
  static String get operatingSystem => 'web';
  static Map<String, String> get environment => {};
}
