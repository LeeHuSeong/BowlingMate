import 'package:shared_preferences/shared_preferences.dart';

class PreferencesHelper {
  static const _keyJwt = 'jwt';
  static const _keyUid = 'uid';
  static const _keyName = 'name';
  static const _keyEmail = 'email';
  static const _keyPhone = 'phone';

  // JWT 저장
  static Future<void> saveJwt(String jwt) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyJwt, jwt);
  }

  // UID 저장
  static Future<void> saveUid(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUid, uid);
  }

  // 이름 저장
  static Future<void> saveName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyName, name);
  }

  // 이메일 저장
  static Future<void> saveEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyEmail, email);
  }

  // 전화번호 저장
  static Future<void> savePhone(String phone) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPhone, phone);
  }

  // Getters
  static Future<String?> getJwt() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyJwt);
  }

  static Future<String?> getUid() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUid);
  }

  static Future<String?> getName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyName);
  }

  static Future<String?> getEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyEmail);
  }

  static Future<String?> getPhone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyPhone);
  }

  //전체 삭제 (로그아웃 시)
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyJwt);
    await prefs.remove(_keyUid);
    await prefs.remove(_keyName);
    await prefs.remove(_keyEmail);
    await prefs.remove(_keyPhone);
  }

  //JWT 존재 여부 간단히 확인
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_keyJwt);
    return token != null && token.isNotEmpty;
  }
}
