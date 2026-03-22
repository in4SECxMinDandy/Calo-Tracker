import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final apiKey = 'AIzaSyCun3O3F9Am9a9zyCEYUMh2UPQNqbE97nE';
  final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent?key=$apiKey');
  
  final requestBody = {
    'contents': [
      {
        'role': 'user',
        'parts': [{'text': 'Bạn là ai? Trả lời bằng JSON {"reply": "câu trả lời", "action": "CHAT"}'}]
      }
    ],
    'generationConfig': {
      'temperature': 0.3,
      'responseMimeType': 'application/json',
    },
  };

  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(requestBody),
  );

  // ignore: avoid_print
  print('Status code: ${response.statusCode}');
  // ignore: avoid_print
  print('Body: ${response.body}');
}
