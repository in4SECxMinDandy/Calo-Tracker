import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final apiKey = 'sk-proj-69981a1c7a6c4bb3ad6f5c34f274cadd';
  final url = Uri.parse('https://taphoaapi.info.vn/v1/messages');
  
  final requestBody = {
    'model': 'claude-haiku-4-5-20251001',
    'system': 'Bạn là trợ lý dinh dưỡng.',
    'messages': [
      {
        'role': 'user',
        'content': 'Tôi vừa ăn 1 bát phở, hãy trả lời bằng JSON {"reply": "...", "action": "LOG", "log_data": {"food_name":"Phở","calories":400}}'
      },
      {
        'role': 'assistant',
        'content': '{'
      }
    ],
    'max_tokens': 1000,
    'temperature': 0.3,
  };

  final response = await http.post(
    url,
    headers: {
      'Content-Type': 'application/json',
      'x-api-key': apiKey,
      'Authorization': 'Bearer $apiKey',
      'anthropic-version': '2023-06-01',
    },
    body: jsonEncode(requestBody),
  );

  // ignore: avoid_print
  print('Status code: ${response.statusCode}');
  // ignore: avoid_print
  print('Body: ${response.body}');
}
