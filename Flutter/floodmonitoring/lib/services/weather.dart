import 'dart:convert';
import 'package:http/http.dart' as http;

import 'global.dart';

/// Fetches current weather data from OpenWeatherMap based on geographic coordinates.
Future<Map<String, dynamic>?> loadWeather(double latitude, double longitude) async {
  try {
    // Construct the API request URL with metric units and the stored API key
    String uri =
        'https://api.openweathermap.org/data/2.5/weather?lat=$latitude&lon=$longitude&units=metric&appid=$weatherAPIKey';

    var res = await http.get(
      Uri.parse(uri),
      headers: {"Content-Type": "application/json"},
    );

    var response = jsonDecode(res.body);

    if (res.statusCode == 200) {
      // Extract and format weather details for the UI
      return {
        // Round temperature to one decimal place
        "temperature": response['main']['temp'].toStringAsFixed(1),

        // Convert description to Title Case (e.g., "clear sky" to "Clear Sky")
        "description": response['weather'][0]['description']
            .split(' ')
            .map((word) => word[0].toUpperCase() + word.substring(1))
            .join(' '),

        // Extract numeric icon code by removing day/night suffix letters
        "iconCode": response['weather'][0]['icon'].replaceAll(RegExp(r'[a-zA-Z]'), ''),

        "pressure": response['main']['pressure'],
      };
    } else {
      print('Failed to fetch weather: ${res.statusCode}');
      return null;
    }
  } catch (e) {
    // Log any connection or parsing errors
    print(e);
    return null;
  }
}