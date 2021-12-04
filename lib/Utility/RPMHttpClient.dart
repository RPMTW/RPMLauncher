import 'package:dio/adapter.dart';
import 'package:dio/dio.dart';
import 'package:dio/native_imp.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

typedef Adapter<T> = Future<Response<T>>? Function(
    RequestOptions requestOptions)?;
Adapter? rpmHttpClientAdapter;

class RPMHttpClient extends DioForNative {
  RPMHttpClient({BaseOptions? baseOptions}) {
    options = baseOptions ?? BaseOptions();
    httpClientAdapter = DefaultHttpClientAdapter();
  }

  @override
  Future<Response<T>> fetch<T>(RequestOptions requestOptions) async {
    bool exceptionThrown = false;
    Response<T>? response;
    final stopwatch = Stopwatch();
    stopwatch.start();

    try {
      response = (await (rpmHttpClientAdapter?.call(requestOptions) ??
          super.fetch(requestOptions))) as Response<T>;
    } catch (e) {
      exceptionThrown = true;
      rethrow;
    } finally {
      stopwatch.stop();

      Breadcrumb breadcrumb = Breadcrumb.http(
        level: exceptionThrown ? SentryLevel.error : SentryLevel.info,
        url: requestOptions.uri,
        method: requestOptions.method,
        statusCode: response?.statusCode,
        requestDuration: stopwatch.elapsed,
        reason: response?.statusMessage,
        timestamp: DateTime.now(),
      );

      Sentry.addBreadcrumb(breadcrumb);
    }

    return response;
  }
}
