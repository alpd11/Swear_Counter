import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class LLMService {
  final _apiKey = dotenv.env['OPENAI_API_KEY'];

  Future<bool> containsSwearing(String text) async {
    final prompt = "Does this sentence contain any profanity or swear words? Reply with 'yes' or 'no'.\n\n\"$text\"";

    final response = await http.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      },
      body: jsonEncode({
        "model": "gpt-3.5-turbo",
        "messages": [
          {"role": "user", "content": prompt}
        ],
        "max_tokens": 5,
        "temperature": 0.0,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final reply = data['choices'][0]['message']['content'].toString().toLowerCase();
      return reply.contains("yes");
    } else {
      print("LLM API error: ${response.body}");
      return false;
    }
  }
}
