/*
 * Copyright 2015 Workiva Inc.
 *
 *  Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *  http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 */

library w_transport.tool.server.handlers.test.http.download_handler;

import 'dart:async';
import 'dart:io';

import 'package:shelf/shelf.dart' as shelf;

import '../../../handler.dart';

/// Always responds with a 200 OK and send a large
/// file in the response body to simulate a download.
class DownloadHandler extends Handler {
  DownloadHandler() : super() {
    enableCors();
  }

  Future<shelf.Response> get(shelf.Request request) async {
    File file = new File('tool/server/handlers/test/http/file.txt');
    Stream downloadStream = file.openRead();
    return new shelf.Response.ok(downloadStream,
        headers: {'Content-Length': file.lengthSync().toString()});
  }
}
