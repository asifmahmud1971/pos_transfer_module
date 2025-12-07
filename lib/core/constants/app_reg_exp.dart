class AppRegExp {
  static AppRegExp? _instance;

  AppRegExp._();
  static AppRegExp get instance => _instance ??= AppRegExp._();

  static final email = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$');
  static final strongPassword = RegExp(r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[\W_])[A-Za-z\d\W_]{8,}$');
  static final number = RegExp(r'[\d]');
  static final specialChr = RegExp(r'[~!@#$%^&*()_+`{}|<>?;:./,=\-\[\]]');
  static final capitalLetter = RegExp(r'[A-Z]');
  static final lowerLetter = RegExp(r'[a-z]');
  static final atLeast8Char = RegExp(r'.{8,}');
  static final mobile = RegExp(r'^-?\d+$');
  static final html = RegExp(r"(<[^>]*>|&\w+;)");
}
