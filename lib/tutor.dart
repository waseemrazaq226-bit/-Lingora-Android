import 'dart:async';
import 'dart:convert';
import 'dart:io';

class TutorClient {
  TutorClient(this.endpoint, this.accessCode);
  final Uri endpoint;
  final String accessCode;
  static Uri? parseEndpoint(String text) {
    final uri = Uri.tryParse(text.trim());
    if (uri == null || uri.scheme != 'https' || !uri.hasAuthority ||
        uri.host.isEmpty || uri.userInfo.isNotEmpty || uri.hasQuery || uri.hasFragment) {
      return null;
    }
    return uri;
  }

  Future<String> send(Map<String, Object> input) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
    try {
      return await _request(client, input).timeout(const Duration(seconds: 26));
    } on SocketException {
      throw const TutorError('Check your internet connection, then retry.');
    } on TimeoutException {
      throw const TutorError('Lumi took too long to reply. You can retry.');
    } on FormatException {
      throw const TutorError('The tutor service returned an unreadable reply.');
    } on HttpException {
      throw const TutorError('The connection closed. You can retry.');
    } on HandshakeException {
      throw const TutorError('The tutor server’s HTTPS certificate could not be verified.');
    } finally {
      client.close(force: true);
    }
  }

  Future<String> _request(HttpClient client, Map<String, Object> input) async {
    final base = endpoint.path.replaceFirst(RegExp(r'/+$'), '');
    final request = await client.postUrl(endpoint.replace(path: '$base/v1/tutor'));
    request.followRedirects = false;
    request.headers.contentType = ContentType.json;
    request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $accessCode');
    request.write(jsonEncode(input));
    final response = await request.close();
    final raw = await utf8.decoder.bind(response).join();
    final body = jsonDecode(raw);
    if (body is Map<String, dynamic>) {
      final content = body['content'];
      if (response.statusCode == 200 && body['generated'] == true && content is String) {
        return content;
      }
      final message = body['error'];
      if (message is String) throw TutorError(message);
    }
    throw const TutorError('Lumi is unavailable. You can retry.');
  }
}

class TutorError implements Exception {
  const TutorError(this.message);
  final String message;
}
