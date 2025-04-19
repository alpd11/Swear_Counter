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

class SwearWord {
  final String word;
  final String category;

  SwearWord({
    required this.word,
    required this.category,
  });

  factory SwearWord.fromJson(Map<String, dynamic> json) {
    return SwearWord(
      word: json['word'],
      category: json['category'],
    );
  }
}

class SwearAnalysis {
  final int totalSwearCount;
  final List<SwearWord> swearWords;
  final List<LLMSwearCategory> categories;
  final String originalText;

  SwearAnalysis({
    required this.totalSwearCount,
    required this.swearWords,
    required this.categories,
    required this.originalText,
  });

  factory SwearAnalysis.fromJson(Map<String, dynamic> json) {
    return SwearAnalysis(
      totalSwearCount: json['totalSwearCount'],
      swearWords: (json['swearWords'] as List)
          .map((w) => SwearWord.fromJson(w))
          .toList(),
      categories: (json['categories'] as List)
          .map((c) => LLMSwearCategory.fromJson(c))
          .toList(),
      originalText: json['originalText'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalSwearCount': totalSwearCount,
      'swearWords': swearWords.map((w) => {'word': w.word, 'category': w.category}).toList(),
      'categories': categories.map((c) => c.toJson()).toList(),
      'originalText': originalText,
    };
  }
}

class LLMService {
  String? get _apiKey => dotenv.env['OPENAI_API_KEY'];

  Future<int> countSwearWords(String text) async {
    if (text.isEmpty) {
      print('Text is empty, skipping analysis');
      return 0;
    }
    
    try {
      final analysis = await analyzeText(text);
      return analysis.totalSwearCount;
    } catch (e) {
      print('Error counting swear words: $e');
      return 0;
    }
  }

  Future<SwearAnalysis> analyzeText(String text) async {
    print('Analyzing text: "$text"');
    
    if (_apiKey == null || _apiKey!.isEmpty) {
      print('ERROR: OpenAI API key is missing or empty');
      return SwearAnalysis(
        totalSwearCount: 0,
        swearWords: [],
        categories: [],
        originalText: text,
      );
    }
    
    final prompt = '''
Analyze this text for swear words. Count EVERY INDIVIDUAL swear word, not just if the sentence contains swearing.
Return a JSON response with the following structure:
{
  "totalSwearCount": number,
  "swearWords": [
    {
      "word": "string",
      "category": "string (one of: 'Insults', 'Profanity', 'Slurs', 'Mild Swears', 'Other')"
    }
  ],
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

    try {
      print('Sending request to OpenAI API with key: ${_apiKey!.substring(0, 10)}...');
      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          "model": "gpt-3.5-turbo",
          "messages": [
            {"role": "system", "content": "You are a swear word analyzer. Count EVERY SINGLE swear word in text, not just whether text contains swearing."},
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
        
        try {
          final jsonResponse = jsonDecode(content);
          return SwearAnalysis.fromJson(jsonResponse);
        } catch (e) {
          print('Error parsing JSON response: $e');
          print('Response content was: $content');
          return SwearAnalysis(
            totalSwearCount: 0,
            swearWords: [],
            categories: [],
            originalText: text,
          );
        }
      } else {
        print("LLM API error (${response.statusCode}): ${response.body}");
        return SwearAnalysis(
          totalSwearCount: 0,
          swearWords: [],
          categories: [],
          originalText: text,
        );
      }
    } catch (e) {
      print('Error during API call: $e');
      return SwearAnalysis(
        totalSwearCount: 0,
        swearWords: [],
        categories: [],
        originalText: text,
      );
    }
  }
}
