class Config {
  static const String apiBaseUrl = 'http://192.168.0.253:3000'; //Kaen
  // ใช้ IP หรือ URL ที่สามารถเข้าถึงได้จากอุปกรณ์ของคุณ
  // static const String apiBaseUrl = 'http://172.20.43.69:3000'; // RIM

  static const String signinUrl = '$apiBaseUrl/signin';
  static const String loginUrl = '$apiBaseUrl/login';
}
