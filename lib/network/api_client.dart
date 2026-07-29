import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class ApiClient {
  static const String baseUrl = 'https://chess-warriors-worker.kattukadha3.workers.dev/api';

  Future<http.Response> get(String endpoint, {Map<String, String>? headers}) async {
    final url = Uri.parse('$baseUrl$endpoint');
    debugPrint('GET Request: $url');
    return await http.get(url, headers: headers);
  }

  Future<http.Response> post(String endpoint, {Map<String, String>? headers, Object? body}) async {
    final url = Uri.parse('$baseUrl$endpoint');
    debugPrint('POST Request: $url');
    return await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        ...?headers,
      },
      body: jsonEncode(body),
    );
  }

  Future<http.Response> put(String endpoint, {Map<String, String>? headers, Object? body}) async {
    final url = Uri.parse('$baseUrl$endpoint');
    debugPrint('PUT Request: $url');
    return await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        ...?headers,
      },
      body: jsonEncode(body),
    );
  }
}
