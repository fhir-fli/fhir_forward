import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';

Future<void> main() async {
  /// If the "PORT" environment variable is set, lisconfig['clientApis'][element]ten to it. Otherwise, 8080.
  /// https://cloud.google.com/run/docs/reference/container-contract#port
  final port = int.parse(Platform.environment['PORT'] ?? '8080');

  /// Instantiate Controller to Listen
  final FhirForwardController fhirForwardController = FhirForwardController();

  /// Create server
  /// See https://pub.dev/documentation/shelf/latest/shelf_io/serve.html
  final server = await shelf_io.serve(
    /// See https://pub.dev/documentation/shelf/latest/shelf/logRequests.html
    fhirForwardController.handler,
    InternetAddress.anyIPv4, // Allows external connections
    port,
  );

  server.autoCompress = true;

  /// Server on message
  print('☀️ Serving at http://${server.address.host}:${server.port} ☀️');
}

class FhirForwardController {
  ///Define our getter for our handler
  Handler get handler {
    final router = Router();

    /// Define our route
    router.all('/', (Request request) async {
      if (!request.url.toString().startsWith('?url=')) {
        return Response.badRequest();
      } else {
        try {
          final Uri url =
              Uri.parse(request.url.toString().replaceFirst('?url=', ''));
          final Map<String, String> headers = {};
          final headerValues = [
            'connection',
            'accept',
            'accept-encoding',
            'content-type'
          ];
          for (final value in headerValues) {
            if (request.headers[value] != null) {
              headers.addAll({value: request.headers[value]!});
            }
          }

          final String body = await request.readAsString();
          final Encoding? encoding = request.encoding;
          http.Response? response;

          switch (request.method.toUpperCase()) {
            case 'GET':
              response = await http.get(url, headers: headers);

            case 'HEAD':
              response = await http.head(url, headers: headers);
            case 'POST':
              response = await http.post(url,
                  headers: headers, body: body, encoding: encoding);
            case 'PUT':
              response = await http.put(url,
                  headers: headers, body: body, encoding: encoding);
            case 'DELETE':
              response = await http.delete(url,
                  headers: headers, body: body, encoding: encoding);
            case 'PATCH':
              response = await http.patch(url,
                  headers: headers, body: body, encoding: encoding);
          }
          if (response == null) {
            return Response.notFound('Page not found');
          } else {
            final newHeaders = response.headers;
            newHeaders.removeWhere((key, value) =>
                key == 'transfer-encoding' || key == 'content-encoding');

            return Response(
              response.statusCode,
              headers: newHeaders,
              body: response.body,
            );
          }
        } catch (e, s) {
          return Response.internalServerError(body: '$e\n$s');
        }
      }
    });

    ///You can catch all verbs and use a URL-parameter with a regular expression
    ///that matches everything to catch app.
    router.all('/<ignored|.*>', (Request request) {
      return Response.notFound('Page not found');
    });

    return router;
  }
}
