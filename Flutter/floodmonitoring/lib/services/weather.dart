import 'dart:convert';
import 'package:http/http.dart' as http;

Future<Map<String, dynamic>?> loadWeather(double latitude, double longitude) async {
  try {
    String apiKey = 'dfa37345e5d4c1fa93dcb18d17f07643';
    String uri =
        'https://api.openweathermap.org/data/2.5/weather?lat=$latitude&lon=$longitude&units=metric&appid=$apiKey';

    var res = await http.get(
      Uri.parse(uri),
      headers: {"Content-Type": "application/json"},
    );

    var response = jsonDecode(res.body);
    //print(res.body);

    if (res.statusCode == 200) {
      // Create a map with the values you need
      return {
        "temperature": response['main']['temp'].toStringAsFixed(1),
        "description": response['weather'][0]['description']
            .split(' ')
            .map((word) => word[0].toUpperCase() + word.substring(1))
            .join(' '),
        "iconCode": response['weather'][0]['icon'].replaceAll(RegExp(r'[a-zA-Z]'), ''),
        "pressure": response['main']['pressure'],
      };
    } else {
      print('Failed to fetch weather: ${res.statusCode}');
      return null;
    }
  } catch (e) {
    print(e);
    return null;
  }
}