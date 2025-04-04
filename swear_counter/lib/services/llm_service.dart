import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class LLMSwearCategory {
  final String category;
  final int count;
  final List<String> examples;

  LLMSwearCategory({
    required this.category,
    required this.count,
    required this.examples,
  });

  factory LLMSwearCategory.fromJson(Map<String, dynamic> json) {
    return LLMSwearCategory(
      category: json['category'],
      count: json['count'],
      examples: List<String>.from(json['examples']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'count': count,
      'examples': examples,
    };
  }
}

class SwearAnalysis {
  final bool containsSwearing;
  final List<LLMSwearCategory> categories;
  final String originalText;

  SwearAnalysis({
    required this.containsSwearing,
    required this.categories,
    required this.originalText,
  });

  factory SwearAnalysis.fromJson(Map<String, dynamic> json) {
    return SwearAnalysis(
      containsSwearing: json['containsSwearing'],
      categories: (json['categories'] as List)
          .map((c) => LLMSwearCategory.fromJson(c))
          .toList(),
      originalText: json['originalText'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'containsSwearing': containsSwearing,
      'categories': categories.map((c) => c.toJson()).toList(),
      'originalText': originalText,
    };
  }
}

class LLMService {
  final _apiKey = dotenv.env['OPENAI_API_KEY'];

  Future<bool> containsSwearing(String text) async {
    final analysis = await analyzeText(text);
    return analysis.containsSwearing;
  }

  Future<SwearAnalysis> analyzeText(String text) async {
    print('Analyzing text: "$text"');
    final prompt = '''
Analyze this text for swear words and categorize them. Return a JSON response with the following structure:
{
  "containsSwearing": boolean,
  "categories": [
    {
      "category": "string (one of: 'Insults', 'Profanity', 'Slurs', 'Mild Swears', 'Other')",
      "count": number,
      "examples": ["string"]
    }
  ],
  "originalText": "string"
}

Categories should be:
- Insults: Personal attacks or derogatory terms
- Profanity: Strong swear words
- Slurs: Discriminatory or offensive terms
- Mild Swears: Light or common swear words
- Other: Any other inappropriate language

Text to analyze: "$text"
''';

    final response = await http.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      },
      body: jsonEncode({
        "model": "gpt-3.5-turbo",
        "messages": [
          {"role": "system", "content": "You are a swear word analyzer. Analyze text and categorize swear words."},
          {"role": "user", "content": prompt}
        ],
        "temperature": 0.0,
      }),
    );

    print('LLM API response status: ${response.statusCode}');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final content = data['choices'][0]['message']['content'];
      print('LLM API response content: $content');
      final jsonResponse = jsonDecode(content);
      return SwearAnalysis.fromJson(jsonResponse);
    } else {
      print("LLM API error: ${response.body}");
      return SwearAnalysis(
        containsSwearing: false,
        categories: [],
        originalText: text,
      );
    }
  }
}
