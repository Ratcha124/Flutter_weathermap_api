import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:latlong2/latlong.dart';
import '../config/api_config.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  Map<String, dynamic>? weatherData;
  bool isLoading = false;
  final TextEditingController cityController = TextEditingController();

  Future<void> fetchWeather(String city) async {
    setState(() => isLoading = true);

    final url =
        "https://api.openweathermap.org/data/2.5/weather?q=$city&appid=${ApiConfig.apiKey}&units=metric&lang=th";

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        setState(() {
          weatherData = json.decode(response.body);
          isLoading = false;
        });
      } else {
        print("Error: ${response.body}");
        setState(() {
          weatherData = null;
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error: $e");
      setState(() {
        weatherData = null;
        isLoading = false;
      });
    }
  }

  Color getBackgroundColor(String mainWeather) {
    switch (mainWeather.toLowerCase()) {
      case "clear":
        return Colors.lightBlueAccent;
      case "clouds":
        return Colors.blueGrey;
      case "rain":
        return Colors.indigo;
      case "thunderstorm":
        return Colors.deepPurple;
      case "snow":
        return Colors.cyanAccent;
      default:
        return Colors.blue;
    }
  }

  Widget buildWeatherAnimation(String weather) {
    switch (weather.toLowerCase()) {
      case "clear":
        return Lottie.asset("assets/animations/sunny.json", height: 150);
      case "rain":
        return Lottie.asset("assets/animations/rain.json", height: 150);
      case "clouds":
        return Lottie.asset("assets/animations/cloudy.json", height: 150);
      default:
        return Lottie.asset("assets/animations/cloudy.json", height: 150);
    }
  }

  @override
  void initState() {
    super.initState();
    fetchWeather("Bangkok"); // ค่าเริ่มต้น
  }

  @override
  Widget build(BuildContext context) {
    final mainWeather =
        weatherData?["weather"]?[0]?["main"]?.toString() ?? "clear";

    return Scaffold(
      backgroundColor: getBackgroundColor(mainWeather),
      appBar: AppBar(
        title: const Text("พยากรณ์อากาศ"),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 🔍 Search City
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: cityController,
                    decoration: InputDecoration(
                      hintText: "พิมพ์ชื่อเมือง เช่น Chiang Mai",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 12),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    final city = cityController.text.trim();
                    if (city.isNotEmpty) {
                      fetchWeather(city);
                    }
                  },
                  child: const Text("ค้นหา"),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 🔄 Loading or Weather Data
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : weatherData == null
                      ? const Center(child: Text("ไม่พบข้อมูล กรุณาลองใหม่"))
                      : Column(
                          children: [
                            Text(
                              weatherData!["name"],
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            buildWeatherAnimation(mainWeather),
                            Text(
                              "${weatherData!["main"]["temp"]} °C",
                              style: const TextStyle(
                                fontSize: 40,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "ความชื้น: ${weatherData!["main"]["humidity"]}%",
                              style: const TextStyle(
                                  fontSize: 18, color: Colors.white),
                            ),
                            Text(
                              "สภาพ: ${weatherData!["weather"][0]["description"]}",
                              style: const TextStyle(
                                  fontSize: 18, color: Colors.white),
                            ),
                            const SizedBox(height: 20),

                            // 🌍 Map
                            Expanded(
                              child: fm.FlutterMap(
                                options: fm.MapOptions(
                                  initialCenter: LatLng(
                                    weatherData!["coord"]["lat"],
                                    weatherData!["coord"]["lon"],
                                  ),
                                  initialZoom: 10,
                                ),
                                children: [
                                  fm.TileLayer(
                                    urlTemplate:
                                        "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                                    userAgentPackageName: 'com.example.app',
                                  ),
                                  fm.MarkerLayer(
                                    markers: [
                                      fm.Marker(
                                        point: LatLng(
                                          weatherData!["coord"]["lat"],
                                          weatherData!["coord"]["lon"],
                                        ),
                                        width: 40,
                                        height: 40,
                                        child: const Icon(
                                          Icons.location_on,
                                          color: Colors.red,
                                          size: 40,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
