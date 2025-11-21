import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  const appId = 'V9HMGL1VIZ';
  const searchKey = '563754aa2e02b4838af055fbf37f09b5';
  const indexName = 'Restaurants';

  final url = Uri.parse(
      'https://$appId-dsn.algolia.net/1/indexes/$indexName/query'
  );

  try {
    final response = await http.post(
      url,
      headers: {
        'X-Algolia-API-Key': searchKey,
        'X-Algolia-Application-Id': appId,
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'query': '',
        'hitsPerPage': 5,
      }),
    );

    print('Status: ${response.statusCode}');
    print('Body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print('✅ Algolia working! Found ${data['nbHits']} restaurants');
    } else {
      print('❌ Algolia error: ${response.statusCode}');
    }
  } catch (e) {
    print('❌ Exception: $e');
  }
}