import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'models.dart';

class CoachException implements Exception {
  final String message;
  const CoachException(this.message);
  @override
  String toString() => message;
}

/// Talks to the Pulse AI coach (a Cloudflare Pages Function using Workers AI).
class CoachApi {
  CoachApi({http.Client? client, Uri? endpoint})
      : _client = client ?? http.Client(),
        endpoint = endpoint ?? defaultEndpoint();

  final http.Client _client;
  final Uri endpoint;

  /// On the web the API lives on the same origin; native apps use API_BASE.
  static Uri defaultEndpoint() {
    const base = String.fromEnvironment('API_BASE', defaultValue: 'https://pulse.askodev.com');
    return kIsWeb ? Uri.base.resolve('/api/coach') : Uri.parse('$base/api/coach');
  }

  Future<Map<String, dynamic>> _post(Map<String, Object> body) async {
    final http.Response res;
    try {
      res = await _client
          .post(endpoint, headers: {'content-type': 'application/json'}, body: jsonEncode(body))
          .timeout(const Duration(seconds: 40));
    } catch (_) {
      throw const CoachException('Could not reach the coach. Check your connection.');
    }
    Map<String, dynamic>? data;
    try {
      final decoded = jsonDecode(res.body);
      if (decoded is Map<String, dynamic>) data = decoded;
    } catch (_) {}
    if (res.statusCode != 200 || data == null) {
      throw CoachException(data?['error']?.toString() ?? 'The coach is unavailable right now.');
    }
    return data;
  }

  Future<Plan> plan(Profile profile) async {
    final data = await _post({'mode': 'plan', 'profile': profile.toApi()});
    final raw = data['plan'];
    if (raw is! Map<String, dynamic>) throw const CoachException('The coach sent an empty plan.');
    try {
      return Plan.fromJson(raw, fromAi: true, now: DateTime.now());
    } on FormatException {
      throw const CoachException('The coach sent an incomplete plan.');
    }
  }

  Future<String> chat(Profile profile, List<ChatMessage> messages) async {
    final data = await _post({
      'mode': 'chat',
      'profile': profile.toApi(),
      'messages': messages.map((m) => m.toJson()).toList(),
    });
    final reply = (data['reply'] ?? '').toString().trim();
    if (reply.isEmpty) throw const CoachException('The coach had nothing to say. Try again.');
    return reply;
  }
}
