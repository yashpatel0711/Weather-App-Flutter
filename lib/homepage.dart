import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:weather/api.dart';
import 'package:weather/weathermodel.dart';
import 'package:intl/intl.dart'; // Add this package for date and time formatting

String apikey = "91f08273b6d84f33a09160911240309"; // Your Weather API key

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Weather',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const Homepage(),
    );
  }
}

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  ApiResponse? response;
  bool inProgress = false;
  List<String> citySuggestions = []; // List to hold city suggestions

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildSearchWidget(),
              const SizedBox(height: 20),
              if (inProgress)
                const CircularProgressIndicator()
              else
                Expanded(
                  child: SingleChildScrollView(
                    child: _buildWeatherWidget(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchWidget() {
    return Autocomplete<String>(
      optionsBuilder: (TextEditingValue textEditingValue) async {
        if (textEditingValue.text == '') {
          return const Iterable<String>.empty();
        }
        return await _getCitySuggestions(textEditingValue.text);
      },
      onSelected: (String city) {
        _getWeatherData(city);
      },
      fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
        return TextField(
          controller: textEditingController,
          focusNode: focusNode,
          decoration: const InputDecoration(
            hintText: 'Search any location',
          ),
          onSubmitted: (value) {
            _getWeatherData(value);
          },
        );
      },
    );
  }

  Future<Iterable<String>> _getCitySuggestions(String query) async {
    // Build the URL for the Weather API city search endpoint
    String citySearchUrl = 'http://api.weatherapi.com/v1/search.json?key=$apikey&q=$query';

    try {
      final response = await http.get(Uri.parse(citySearchUrl));

      if (response.statusCode == 200) {
        // Decode the JSON response
        List<dynamic> data = jsonDecode(response.body);

        // Map the city names from the data
        List<String> cities = data.map((item) => item['name'].toString()).toList();

        return cities;
      } else {
        throw Exception("Failed to fetch city suggestions");
      }
    } catch (e) {
      return const Iterable<String>.empty();
    }
  }

  Widget _buildWeatherWidget() {
    if (response == null) {
      return const Text("Search for the location to get weather data");
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Icon(
                Icons.location_on,
                size: 50,
              ),
              Text(
                response?.location?.name ?? "",
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w300,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                response?.location?.country ?? "",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  "${response?.current?.tempC?.toString() ?? ""}°C",
                  style: const TextStyle(
                    fontSize: 60,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                response?.current?.condition?.text ?? "",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          Center(
            child: SizedBox(
              height: 200,
              width: 200,
              child: Image.network(
                "https:${response?.current?.condition?.icon}".replaceAll("120x120", "200x200"),
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(height: 40),
          Card(
            elevation: 4,
            color: Colors.white,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _dataAndTitleWidget("Humidity", response?.current?.humidity?.toString() ?? ""),
                    _dataAndTitleWidget("Wind Speed", "${response?.current?.windKph?.toString() ?? ""} km/h"),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _dataAndTitleWidget("UV", response?.current?.uv?.toString() ?? ""),
                    _dataAndTitleWidget("Precipitation", "${response?.current?.precipMm?.toString() ?? ""} mm"),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _dataAndTitleWidget("Local Time", _formatTime(response?.location?.localtime ?? "")),
                    _dataAndTitleWidget("Local Date", _formatDate(response?.location?.localtime ?? "")),
                  ],
                ),
              ],
            ),
          ),
        ],
      );
    }
  }

  Widget _dataAndTitleWidget(String title, String data) {
    return Padding(
      padding: const EdgeInsets.all(18.0),
      child: Column(
        children: [
          Text(
            data,
            style: const TextStyle(
              fontSize: 22,
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String localtime) {
    try {
      DateTime dateTime = DateTime.parse(localtime);
      return DateFormat.yMMMMd().format(dateTime); // Format the date as Month Day, Year
    } catch (e) {
      return "N/A"; // Return this if parsing fails
    }
  }

  String _formatTime(String localtime) {
    try {
      DateTime dateTime = DateTime.parse(localtime);
      return DateFormat.jm().format(dateTime); // Format the time as AM/PM
    } catch (e) {
      return "N/A"; // Return this if parsing fails
    }
  }

  _getWeatherData(String location) async {
    setState(() {
      inProgress = true;
    });

    try {
      response = await WeatherApi().getCurrentWeather(location);
    } catch (e) {
      // Handle error here if needed
    } finally {
      setState(() {
        inProgress = false;
      });
    }
  }
}

class WeatherApi {
  final String baseUrl = "http://api.weatherapi.com/v1/current.json";

  Future<ApiResponse> getCurrentWeather(String location) async {
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
