// Copyright 2015 Workiva Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

@TestOn('vm || browser')
library w_transport.test.unit.http.request_test;

import 'dart:async';
import 'dart:convert';

import 'package:test/test.dart';
import 'package:w_transport/w_transport.dart';
import 'package:w_transport/w_transport_mock.dart';

import '../../naming.dart';

void main() {
  Naming naming = new Naming()
    ..testType = testTypeUnit
    ..topic = topicHttp;

  group(naming.toString(), () {
    _runCommonRequestSuiteFor('FormRequest', ({bool withBody: false}) {
      if (!withBody) return new FormRequest();
      return new FormRequest()..fields['field'] = 'value';
    });
    _runCommonRequestSuiteFor('JsonRequest', ({bool withBody: false}) {
      if (!withBody) return new JsonRequest();
      return new JsonRequest()
        ..body = [
          {'field': 'value'}
        ];
    });
    _runCommonRequestSuiteFor('MultipartRequest', ({bool withBody}) {
      // Multipart requests can't be empty.
      return new MultipartRequest()..fields['field'] = 'value';
    });
    _runCommonRequestSuiteFor('Request', ({bool withBody: false}) {
      if (!withBody) return new Request();
      return new Request()..body = 'body';
    });
    _runCommonRequestSuiteFor('StreamedRequest', ({bool withBody: false}) {
      if (!withBody) return new StreamedRequest();
      return new StreamedRequest()
        ..body = new Stream.fromIterable([UTF8.encode('bytes')])
        ..contentLength = UTF8.encode('bytes').length;
    });
  });
}

void _runCommonRequestSuiteFor(
    String name, BaseRequest requestFactory({bool withBody})) {
  group(name, () {
    Uri requestUri = Uri.parse('/mock/request');
    Map requestHeaders = {'x-custom': 'header'};

    setUp(() {
      MockTransports.reset();
      configureWTransportForTest();
    });

    tearDown(() {
      MockTransports.verifyNoOutstandingExceptions();
    });

    test('DELETE', () async {
      MockTransports.http.expect('DELETE', requestUri);
      await requestFactory().delete(uri: requestUri);
    });

    test('DELETE with headers', () async {
      MockTransports.http.expect('DELETE', requestUri, headers: requestHeaders);
      await requestFactory().delete(uri: requestUri, headers: requestHeaders);
    });

    test('GET', () async {
      MockTransports.http.expect('GET', requestUri);
      await requestFactory().get(uri: requestUri);
    });

    test('GET with headers', () async {
      MockTransports.http.expect('GET', requestUri, headers: requestHeaders);
      await requestFactory().get(uri: requestUri, headers: requestHeaders);
    });

    test('HEAD', () async {
      MockTransports.http.expect('HEAD', requestUri);
      await requestFactory().head(uri: requestUri);
    });

    test('HEAD with headers', () async {
      MockTransports.http.expect('HEAD', requestUri, headers: requestHeaders);
      await requestFactory().head(uri: requestUri, headers: requestHeaders);
    });

    test('OPTIONS', () async {
      MockTransports.http.expect('OPTIONS', requestUri);
      await requestFactory().options(uri: requestUri);
    });

    test('OPTIONS with headers', () async {
      MockTransports.http
          .expect('OPTIONS', requestUri, headers: requestHeaders);
      await requestFactory().options(uri: requestUri, headers: requestHeaders);
    });

    test('PATCH', () async {
      MockTransports.http.expect('PATCH', requestUri);
      await requestFactory().patch(uri: requestUri);
    });

    test('PATCH with headers', () async {
      MockTransports.http.expect('PATCH', requestUri, headers: requestHeaders);
      await requestFactory().patch(uri: requestUri, headers: requestHeaders);
    });

    test('POST', () async {
      MockTransports.http.expect('POST', requestUri);
      await requestFactory().post(uri: requestUri);
    });

    test('POST with headers', () async {
      MockTransports.http.expect('POST', requestUri, headers: requestHeaders);
      await requestFactory().post(uri: requestUri, headers: requestHeaders);
    });

    test('PUT', () async {
      MockTransports.http.expect('PUT', requestUri);
      await requestFactory().put(uri: requestUri);
    });

    test('PUT with headers', () async {
      MockTransports.http.expect('PUT', requestUri, headers: requestHeaders);
      await requestFactory().put(uri: requestUri, headers: requestHeaders);
    });

    test('custom HTTP method', () async {
      MockTransports.http.expect('COPY', requestUri);
      await requestFactory().send('COPY', uri: requestUri);
    });

    test('custom HTTP method with headers', () async {
      MockTransports.http.expect('COPY', requestUri, headers: requestHeaders);
      await requestFactory()
          .send('COPY', uri: requestUri, headers: requestHeaders);
    });

    test('DELETE (streamed)', () async {
      MockTransports.http.expect('DELETE', requestUri);
      await requestFactory().streamDelete(uri: requestUri);
    });

    test('GET (streamed)', () async {
      MockTransports.http.expect('GET', requestUri);
      await requestFactory().streamGet(uri: requestUri);
    });

    test('HEAD (streamed)', () async {
      MockTransports.http.expect('HEAD', requestUri);
      await requestFactory().streamHead(uri: requestUri);
    });

    test('OPTIONS (streamed)', () async {
      MockTransports.http.expect('OPTIONS', requestUri);
      await requestFactory().streamOptions(uri: requestUri);
    });

    test('PATCH (streamed)', () async {
      MockTransports.http.expect('PATCH', requestUri);
      await requestFactory().streamPatch(uri: requestUri);
    });

    test('POST (streamed)', () async {
      MockTransports.http.expect('POST', requestUri);
      await requestFactory().streamPost(uri: requestUri);
    });

    test('PUT (streamed)', () async {
      MockTransports.http.expect('PUT', requestUri);
      await requestFactory().streamPut(uri: requestUri);
    });

    test('custom HTTP method (streamed)', () async {
      MockTransports.http.expect('COPY', requestUri);
      await requestFactory().streamSend('COPY', uri: requestUri);
    });

    test('URI should be required', () async {
      expect(requestFactory().get(), throwsStateError);
    });

    test(
        'URI and data should be accepted as parameters to a request dispatch method',
        () async {
      Completer dataCompleter = new Completer();
      MockTransports.http.when(requestUri, (FinalizedRequest request) async {
        if (request.body is HttpBody) {
          dataCompleter.complete((request.body as HttpBody).asString());
        } else {
          dataCompleter.complete(
              UTF8.decode(await (request.body as StreamedHttpBody).toBytes()));
        }

        return new MockResponse.ok();
      });
      await requestFactory(withBody: true).post(uri: requestUri);
      expect(await dataCompleter.future, isNotEmpty);
    });

    test('headers given to dispatch method should be merged with existing ones',
        () async {
      MockTransports.http.expect('GET', requestUri,
          headers: {'x-one': '1', 'x-two': '2', 'x-three': '3'});
      BaseRequest request = requestFactory()
        ..headers = {'x-one': '1', 'x-two': '0'}
        ..uri = requestUri;
      await request.get(headers: {'x-two': '2', 'x-three': '3'});
    });

    test('request cancellation prior to dispatch should cancel request',
        () async {
      BaseRequest request = requestFactory();
      request.abort();
      expect(request.get(uri: requestUri),
          throwsA(new isInstanceOf<RequestException>()));
    });

    test(
        'request cancellation after dispatch but prior to resolution should cancel request',
        () async {
      BaseRequest request = requestFactory();
      Future future = request.get(uri: requestUri);
      await new Future.delayed(new Duration(milliseconds: 500));
      request.abort();
      expect(future, throwsA(new isInstanceOf<RequestException>()));
    });

    test('request cancellation after request has succeeded should do nothing',
        () async {
      MockTransports.http.expect('GET', requestUri);
      BaseRequest request = requestFactory();
      await request.get(uri: requestUri);
      request.abort();
    });

    test('request cancellation after request has failed should do nothing',
        () async {
      MockTransports.http.expect('GET', requestUri, failWith: new Exception());
      BaseRequest request = requestFactory();
      Future future = request.get(uri: requestUri);
      expect(future, throwsA(new isInstanceOf<RequestException>()));
      try {
        await future;
      } catch (e) {}
      request.abort();
    });

    test('request cancellation should accept a custom error', () async {
      BaseRequest request = requestFactory();
      request.abort(new Exception('custom error'));
      expect(request.get(uri: requestUri), throwsA(predicate((error) {
        return error is RequestException &&
            error.toString().contains('custom error');
      })));
    });

    test('should wrap an unexpected exception in RequestException', () async {
      BaseRequest request = requestFactory();
      MockTransports.http.causeFailureOnOpen(request);
      expect(request.get(uri: requestUri),
          throwsA(new isInstanceOf<RequestException>()));
    });

    test('should throw if status code is non-200', () async {
      Uri uri = Uri.parse('/test');
      MockTransports.http.expect('GET', uri,
          respondWith: new MockResponse.internalServerError());
      BaseRequest request = requestFactory();
      expect(
          request.get(uri: uri), throwsA(new isInstanceOf<RequestException>()));
    });

    test('headers should be unmodifiable once sent', () async {
      Uri uri = Uri.parse('/test');
      MockTransports.http.expect('GET', uri);
      BaseRequest request = requestFactory()
        ..uri = uri
        ..headers = {'x-custom': 'value'};
      await request.get();
      expect(() {
        request.headers['x-custom'] = 'changed';
      }, throwsUnsupportedError);
      expect(() {
        request.headers = {'x-custom': 'new'};
      }, throwsStateError);
    });

    test('withCredentials flag should be unmodifiable once sent', () async {
      Uri uri = Uri.parse('/test');
      MockTransports.http.expect('GET', uri);
      BaseRequest request = requestFactory();
      await request.get(uri: uri);
      expect(() {
        request.withCredentials = true;
      }, throwsStateError);
    });

    test('request can only be sent once', () async {
      Uri uri = Uri.parse('/test');
      MockTransports.http.expect('GET', uri);
      BaseRequest request = requestFactory();
      Future first = request.get(uri: uri);
      expect(request.get(uri: uri), throwsStateError);
      await first;
    });

    test('requestInterceptor allows async modification of request', () async {
      Uri uri = Uri.parse('/test');
      MockTransports.http
          .expect('GET', uri, headers: {'x-intercepted': 'true'});
      BaseRequest request = requestFactory();
      request.requestInterceptor = (BaseRequest request) async {
        request.headers['x-intercepted'] = 'true';
      };
      await request.get(uri: uri);
    });

    test(
        'if requestInterceptor throws, the request should fail with that exception',
        () async {
      BaseRequest request = requestFactory();
      var exception = new Exception('interceptor failure');

      request.requestInterceptor = (BaseRequest request) async {
        throw exception;
      };
      expect(request.get(uri: Uri.parse('/test')), throwsA(equals(exception)));
    });

    test('setting requestInterceptor throws if request has been sent',
        () async {
      Uri uri = Uri.parse('/test');
      MockTransports.http.expect('GET', uri);
      BaseRequest request = requestFactory();
      await request.get(uri: uri);
      expect(() {
        request.requestInterceptor = (request) async {};
      }, throwsStateError);
    });

    test('responseInterceptor gets FinalizedRequest', () async {
      Uri uri = Uri.parse('/test');
      MockTransports.http.expect('GET', uri);
      BaseRequest request = requestFactory();
      request.responseInterceptor =
          (FinalizedRequest request, response, [exception]) async {
        expect(request.method, equals('GET'));
        expect(request.uri, equals(uri));
      };
      await request.get(uri: uri);
    });

    test('responseInterceptor gets BaseResponse', () async {
      Uri uri = Uri.parse('/test');
      MockResponse mockResponse = new MockResponse.ok(body: 'original');
      MockTransports.http.expect('GET', uri, respondWith: mockResponse);
      BaseRequest request = requestFactory();
      request.responseInterceptor =
          (request, BaseResponse response, [exception]) async {
        expect(response, new isInstanceOf<Response>());
        expect((response as Response).body.asString(), equals('original'));
      };
      await request.get(uri: uri);
    });

    test('responseInterceptor gets no RequestException on successful request',
        () async {
      Uri uri = Uri.parse('/test');
      MockTransports.http.expect('GET', uri);
      BaseRequest request = requestFactory();
      request.responseInterceptor = (request, response, [exception]) async {
        expect(exception, isNull);
      };
      await request.get(uri: uri);
    });

    test('responseInterceptor gets RequestException on failed request',
        () async {
      Uri uri = Uri.parse('/test');
      MockTransports.http
          .expect('GET', uri, failWith: new Exception('mock failure'));
      BaseRequest request = requestFactory();
      request.responseInterceptor =
          (request, response, [RequestException exception]) async {
        expect(exception, isNotNull);
        expect(exception.toString(), contains('mock failure'));
      };
      expect(request.get(uri: uri), throws);
    });

    test('responseInterceptor allows replacement of BaseResponse', () async {
      Uri uri = Uri.parse('/test');
      MockResponse mockResponse = new MockResponse.ok(body: 'original');
      MockTransports.http.expect('GET', uri, respondWith: mockResponse);
      BaseRequest request = requestFactory();
      request.responseInterceptor =
          (request, BaseResponse response, [exception]) async {
        return new Response.fromString(
            response.status, response.statusText, response.headers, 'modified');
      };
      Response response = await request.get(uri: uri);
      expect(response.body.asString(), equals('modified'));
    });

    test(
        'if responseInterceptor throws, the error should be wrapped in a RequestException',
        () async {
      Uri uri = Uri.parse('/test');
      MockTransports.http.expect('GET', uri);
      BaseRequest request = requestFactory();
      request.responseInterceptor = (request, response, [exception]) async {
        throw new Exception('interceptor failure');
      };
      expect(request.get(uri: uri), throwsA(predicate((error) {
        return error is RequestException &&
            error.toString().contains('interceptor failure');
      })));
    });

    test('setting responseInterceptor throws if request has been sent',
        () async {
      Uri uri = Uri.parse('/test');
      MockTransports.http.expect('GET', uri);
      BaseRequest request = requestFactory();
      await request.get(uri: uri);
      expect(() {
        request.responseInterceptor = (request, response, [exception]) async {};
      }, throwsStateError);
    });

    test('timeoutThreshold is not enforced if not set', () async {
      Uri uri = Uri.parse('/test');
      BaseRequest request = requestFactory();
      Future future = request.get(uri: uri);
      await new Future.delayed(new Duration(milliseconds: 250));
      MockTransports.http.completeRequest(request);
      await future;
    });

    test('timeoutThreshold does nothing if request completes in time',
        () async {
      Uri uri = Uri.parse('/test');
      BaseRequest request = requestFactory()
        ..timeoutThreshold = new Duration(milliseconds: 500);
      Future future = request.get(uri: uri);
      await new Future.delayed(new Duration(milliseconds: 250));
      MockTransports.http.completeRequest(request);
      await future;
    });

    test('timeoutThreshold cancels the request if exceeded', () async {
      Uri uri = Uri.parse('/test');
      BaseRequest request = requestFactory()
        ..timeoutThreshold = new Duration(milliseconds: 500);
      expect(request.get(uri: uri), throwsA(predicate((error) {
        return error is RequestException && error.error is TimeoutException;
      })));
    });

    test('configure() should throw if called after request has been sent',
        () async {
      Uri uri = Uri.parse('/test');
      MockTransports.http.expect('GET', uri);
      BaseRequest request = requestFactory();
      await request.get(uri: uri);
      expect(() {
        request.configure((_) {});
      }, throwsStateError);
    });

    test('toString()', () async {
      Uri uri = Uri.parse('/test');
      MockTransports.http.expect('GET', uri);
      BaseRequest request = requestFactory();
      await request.get(uri: uri);
      expect(request.toString(), contains('GET'));
      expect(request.toString(), contains(uri.toString()));
      expect(request.toString(), contains(request.contentType.toString()));
    });
  });
}
