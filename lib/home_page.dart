import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:jiffy/jiffy.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    _determinePosition();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: weatherMap != null
            ? Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Align(
                          alignment: Alignment.centerRight,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text("${Jiffy(DateTime.now()).format("MMM do yy")}, ${Jiffy(DateTime.now()).format("h:mm")}",
                                style: const TextStyle(fontSize: 16, color: Colors.black),
                              ),
                              Text("${weatherMap!["name"]}", style: const TextStyle(fontSize: 16, color: Colors.black),),
                            ],
                          )),
                      Center(
                        child: Column(
                          children: [
                            Image.network("https://th.bing.com/th/id/OIP.KOhzhOJQ4AHmN25RM2zFbAHaFP?pid=ImgDet&rs=1", height: 90, width: 100,),
                            Text("${forecastMap!["list"][0]["main"]["temp"]}°", style: const TextStyle(fontSize: 50, color: Colors.black),),
                          ],
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Feeles like ${forecastMap!["list"][0]["main"]["feels_like"]}°", style: const TextStyle(fontSize: 16, color: Colors.black),),
                            Text("${forecastMap!["list"][0]["weather"][0]["description"]}", style: const TextStyle(fontSize: 16, color: Colors.black)),
                          ],
                        ),
                      ),
                      Center(
                        child: Column(
                          children: [
                            Text("Humidity :${forecastMap!["list"][0]["main"]["humidity"]}, Pressure ${forecastMap!["list"][0]["main"]["pressure"]}", style: const TextStyle(fontSize: 16, color: Colors.black),),
                            Text("Sunset ${Jiffy("${DateTime.fromMillisecondsSinceEpoch(weatherMap!["sys"]["sunset"] * 1000)}").format("h:mm:a")}, Sunrise ${Jiffy("${DateTime.fromMillisecondsSinceEpoch(weatherMap!["sys"]["sunrise"] * 1000)}").format("h:mm:a")}", style: const TextStyle(fontSize: 16, color: Colors.black),),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 200,
                        width: double.infinity,
                        child: ListView.builder(
                          shrinkWrap: true,
                          scrollDirection: Axis.horizontal,
                          itemCount: forecastMap!.length,
                          itemBuilder: (context, index) {
                            return Container(
                              width: 90,
                              margin: const EdgeInsets.only(right: 8),
                              height: double.infinity,
                              color: Colors.blueGrey,
                              child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    Text(Jiffy(forecastMap!["list"][index]["dt_txt"]).format("EEE, h:mm"), style: const TextStyle(fontSize: 16, color: Colors.black),),
                                    Image.network("https://th.bing.com/th/id/OIP.KOhzhOJQ4AHmN25RM2zFbAHaFP?pid=ImgDet&rs=1", height: 70, width: 71,),
                                    Text("${forecastMap!["list"][index]["main"]["temp_min"]}/${forecastMap!["list"][index]["main"]["temp_max"]}", style: const TextStyle(fontSize: 12, color: Colors.black),),
                                    Text("${forecastMap!["list"][index]["weather"][0]["description"]}", style: const TextStyle(fontSize: 12, color: Colors.black),),
                                  ]
                              ),
                            );
                          },
                        ),
                      )
                    ]),
              )
            : const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
       Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
         Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
       Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    position = await Geolocator.getCurrentPosition();
    setState(() {
      latitude = position.latitude;
      longitude = position.longitude;
    });

    fetchWeatherData();

    print("Out latitude is $latitude and longitude is $longitude");
  }

  fetchWeatherData() async {
    var weatherResponce = await http.get(Uri.parse(
        "https://api.openweathermap.org/data/2.5/weather?lat=$latitude&lon=$longitude&exclude=hourly%2Cdaily&appid=cc93193086a048993d938d8583ede38a&fbclid=IwAR1rg9BHqDzqxJia8bplKeuzaNLUVMWNCsfmGjp1-IHI0hpsrGe7Hnq5FMI"));
    var forecastResponce = await http.get(Uri.parse(
        "https://api.openweathermap.org/data/2.5/forecast?lat=$latitude&lon=$longitude&units=metric&appid=cc93193086a048993d938d8583ede38a&fbclid=IwAR3Hr9_sSo-ju9Us4-W-MpsVaeQyp10SZvo84iTiJ7WjrqTNSkbxRURH5RQ"));
    setState(() {
      weatherMap = Map<String, dynamic>.from(jsonDecode(weatherResponce.body));
      forecastMap = Map<String, dynamic>.from(jsonDecode(forecastResponce.body));
    });
    print("Weather Body:: ${weatherResponce.body}");
    print("Weather Body:: ${forecastResponce.body}");
  }

  Map<String, dynamic>? weatherMap;
  Map<String, dynamic>? forecastMap;

  late Position position;
  double? latitude, longitude;
}