import 'package:dio/dio.dart';
import '../utils/preferences_helper.dart';

class JwtInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final jwt = await PreferencesHelper.getJwt();
    if (jwt != null) {
      options.headers['Authorization'] = 'Bearer $jwt';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      await PreferencesHelper.clearAll();
      // TODO: 라우터로 로그인 화면 복귀 로직 추가 예정
    }
    handler.next(err);
  }
}
