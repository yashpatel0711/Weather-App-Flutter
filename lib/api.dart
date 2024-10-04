import 'dart:convert';

import 'package:weather/constants.dart';
import 'package:http/http.dart' as http;
import 'package:weather/weathermodel.dart';


class WeatherApi {
  final String baseUrl = "http://api.weatherapi.com/v1/current.json";

  Future<ApiResponse> getCurrentWeather(String location) async {
    // Ensure `apikey` is defined in constants.dart
    String apiUrl = "$baseUrl?key=$apikey&q=$location";

    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        return ApiResponse.fromJson(jsonDecode(response.body));
      } else {
        throw Exception("Failed to load weather");
      }
    } catch (e) {
      throw Exception("Failed to load weather: $e");
    }
  }
}
