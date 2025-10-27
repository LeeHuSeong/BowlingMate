import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../utils/preferences_helper.dart';

class DioClient {
  late Dio dio;

  DioClient() {
    dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.baseUrl,
        connectTimeout: AppConfig.connectTimeout,
        receiveTimeout: AppConfig.receiveTimeout,
        headers: {'Content-Type': 'application/json'},
      ),
    )..interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await PreferencesHelper.getJwt();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) {
        print('Dio Error: ${error.message}');
        return handler.next(error);
      },
    ));
  }
}
