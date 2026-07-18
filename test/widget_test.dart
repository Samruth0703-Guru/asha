import 'dart:io';
import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:asha_care_plus/main.dart';

class MockHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return MockHttpClient();
  }
}

class MockHttpClient implements HttpClient {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #getUrl ||
        invocation.memberName == #get ||
        invocation.memberName == #post ||
        invocation.memberName == #postUrl ||
        invocation.memberName == #put ||
        invocation.memberName == #putUrl ||
        invocation.memberName == #delete ||
        invocation.memberName == #deleteUrl ||
        invocation.memberName == #patch ||
        invocation.memberName == #patchUrl ||
        invocation.memberName == #open ||
        invocation.memberName == #openUrl) {
      return Future.value(MockHttpClientRequest());
    }
    return null;
  }
}

class MockHttpClientRequest implements HttpClientRequest {
  @override
  final HttpHeaders headers = MockHttpHeaders();

  @override
  Future<HttpClientResponse> get done => Future.value(MockHttpClientResponse());

  @override
  Future<HttpClientResponse> close() => Future.value(MockHttpClientResponse());

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #close || invocation.memberName == #done) {
      return Future.value(MockHttpClientResponse());
    }
    return null;
  }
}


class MockHttpHeaders implements HttpHeaders {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class MockHttpClientResponse extends Stream<List<int>> implements HttpClientResponse {
  static const List<int> _transparentImage = [
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
    0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
    0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
    0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
    0x42, 0x60, 0x82
  ];

  @override
  int get statusCode => 200;

  @override
  int get contentLength => _transparentImage.length;

  @override
  HttpClientResponseCompressionState get compressionState => HttpClientResponseCompressionState.notCompressed;

  @override
  bool get isRedirect => false;

  @override
  bool get persistentConnection => true;

  @override
  List<RedirectInfo> get redirects => const [];

  @override
  List<Cookie> get cookies => const [];

  @override
  final HttpHeaders headers = MockHttpHeaders();

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.fromIterable([_transparentImage]).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  Future<HttpClientResponse> redirect([String? method, Uri? url, bool? followRedirects]) {
    return Future.error(StateError("Redirect not supported"));
  }

  @override
  Future<Socket> detachSocket() {
    return Future.error(StateError("Detach socket not supported"));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}


void main() {
  setUpAll(() {
    HttpOverrides.global = MockHttpOverrides();
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('App starts smoke test', (WidgetTester tester) async {
    await tester.runAsync(() async {
      await runZonedGuarded(() async {
        // Build our app and trigger a frame.
        await tester.pumpWidget(
          const ProviderScope(
            child: AshaCareApp(),
          ),
        );

        // Verify that the app widget is pumped successfully
        expect(find.byType(AshaCareApp), findsOneWidget);
      }, (error, stack) {
        if (error.toString().contains('google_fonts') || error.toString().contains('font') || error.toString().contains('Inter-')) {
          // Ignore font loading errors in tests
          print('Ignored expected font loading exception: $error');
        } else {
          throw error;
        }
      });
    });
  });
}
