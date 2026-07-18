import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class ApiService {
  static String? _token;
  static const Duration _timeout = Duration(seconds: 60);
  static const int _maxRetries = 3;

  static void setToken(String? token) => _token = token;

  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  static Future<Map<String, dynamic>> _requestWithRetry(String method, String path, {Map<String, dynamic>? body}) async {
    for (int attempt = 1; attempt <= _maxRetries; attempt++) {
      try {
        http.Response response;
        final url = Uri.parse('${ApiConfig.baseUrl}$path');

        if (method == 'GET') {
          response = await http.get(url, headers: _headers).timeout(_timeout);
        } else if (method == 'POST') {
          response = await http.post(url, headers: _headers, body: jsonEncode(body ?? {})).timeout(_timeout);
        } else if (method == 'PUT') {
          response = await http.put(url, headers: _headers, body: jsonEncode(body ?? {})).timeout(_timeout);
        } else {
          response = await http.delete(url, headers: _headers).timeout(_timeout);
        }

        return _handleResponse(response);
      } on TimeoutException {
        if (attempt == _maxRetries) {
          throw Exception('Server is waking up. Please wait and try again.');
        }
        await Future.delayed(Duration(seconds: 3 * attempt));
      } on Exception catch (e) {
        if (attempt == _maxRetries) rethrow;
        await Future.delayed(Duration(seconds: 2 * attempt));
      }
    }
    throw Exception('Failed after retries');
  }

  static Future<Map<String, dynamic>> get(String path) => _requestWithRetry('GET', path);
  static Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) => _requestWithRetry('POST', path, body: body);
  static Future<Map<String, dynamic>> put(String path, Map<String, dynamic> body) => _requestWithRetry('PUT', path, body: body);
  static Future<Map<String, dynamic>> delete(String path) => _requestWithRetry('DELETE', path);

  static Future<Map<String, dynamic>> uploadMultipart(String path, Map<String, String> fields, List<http.MultipartFile> files) async {
    final request = http.MultipartRequest('POST', Uri.parse('${ApiConfig.baseUrl}$path'));
    request.headers.addAll(_token != null ? {'Authorization': 'Bearer $_token'} : {});
    request.fields.addAll(fields);
    request.files.addAll(files);
    final streamed = await request.send().timeout(_timeout);
    final response = await http.Response.fromStream(streamed);
    return _handleResponse(response);
  }

  static Map<String, dynamic> _handleResponse(http.Response response) {
    final body = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }
    throw Exception(body['message'] ?? 'Request failed');
  }
}
