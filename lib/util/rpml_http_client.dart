import 'package:dio/dio.dart';
import 'package:dio/native_imp.dart';
import 'package:sentry_dio/sentry_dio.dart';

HttpClientAdapter? rpmlHttpClientAdapter;
final httpClient =
    RPMLHttpClient(BaseOptions(validateStatus: (status) => true));

class RPMLHttpClient extends DioForNative {
  RPMLHttpClient([super.baseOptions]) {
    addSentry();
    httpClientAdapter = rpmlHttpClientAdapter ?? httpClientAdapter;
  }
}
