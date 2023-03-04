import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';
import 'package:sentry_dio/sentry_dio.dart';

HttpClientAdapter? rpmlHttpClientAdapter;
final httpClient =
    RPMLHttpClient(BaseOptions(validateStatus: (status) => true));

class RPMLHttpClient extends DioForNative {
  RPMLHttpClient([super.baseOptions]) {
    addSentry();
    httpClientAdapter = rpmlHttpClientAdapter ?? httpClientAdapter;
    interceptors.add(RetryInterceptor(
      dio: this,
      logPrint: print,
    ));
  }
}
