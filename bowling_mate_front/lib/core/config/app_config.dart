class AppConfig {
  static const String baseUrl = "http://10.0.2.2:8080/"; // Spring 서버
  //static const String baseUrl = "http://host.docker.internal:8080/";
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 20);

  // Flask 경로가 필요한 경우
  static const String flaskUrl = "http://10.0.2.2:5000/";
  //static const String flaskUrl = "http://host.docker.internal:5000/";

  // Firebase 관련 상수 (필요 시 추가)
  static const String firebaseProjectId = "bowling-mate";
}