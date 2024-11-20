import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
//import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import '../DataBaseHelp.dart';
import '../constants.dart';
import 'package:numberpicker/numberpicker.dart';
//import 'package:flutter_switch/flutter_switch.dart';
import 'package:geocoding/geocoding.dart';
import 'package:palette_generator/palette_generator.dart';

void main() {
  runApp(const WeatherApp());
}

class WeatherApp extends StatelessWidget {
  const WeatherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Weather Outfit Recommendation',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  //final TextEditingController _citySearchController = TextEditingController();
  //List<String> _filteredCities = [];
  final Constants _constants = Constants();
  static const String apikey = '88c85587b2874510aff31914243010';
  String location = '';
  bool _isLocationSetManually = false;
  String weatherIcon = '';
  int temperature = 0;
  num windSpeed = 0;
  int humidity = 0;
  int cloud = 0;
  int maxTemp = 0;
  int minTemp = 0;
  String currentDate = '';
  bool isCelsius = true;
  String gender = 'Male'; // Default gender

  //Comfort values lower values at C
  int scorchComfort = 30;
  int hotComfort = 26;
  int mildComfort = 17;
  int chillyComfort = 8;
  int coldComfort = -4;
  int frigidComfort = -5;

  Timer? _weatherUpdateTimer;

  List dailyWeatherForecast = [];

  String currentWeatherStatus = '';
  Map<String, Map<String, List<File>>> imagesByCategory = {
    'Top': {'cold': [], 'mild': [], 'hot': []},
    'Bottom': {'cold': [], 'mild': [], 'hot': []},
    'Footwear': {'cold': [], 'mild': [], 'hot': []},
    'Accessories': {'cold': [], 'mild': [], 'hot': []},
    'Coats': {'cold': [], 'mild': []}, // New category
    'Hats': {'cold': [], 'mild': [], 'hot': []}, // New category
    'WeatherAccessories': {'rainy': [], 'snowy': []}, // New category
  };

  String adviceText = "";
  Map<String, Map<String, dynamic>> outfitRecommendation = {
    'Top': {'item': '', 'image': null},
    'Bottom': {'item': '', 'image': null},
    'Footwear': {'item': '', 'image': null},
    'Accessories': {'item': '', 'image': null},
  };
  bool isDayTime = true;

  String searchWeatherAPI =
      'https://api.weatherapi.com/v1/forecast.json?key=$apikey&days=7&q=';

  // Outfit categories for Male
  Map<String, List<String>> maleOutfits = {
    'cold_footwear': [
      "Boots",
      "Hiking Boots",
      "Leather Shoes",
      "Winter Sneakers",
      "High Tops"
    ],
    'cold_top': ["Jacket", "Parka", "Overcoat", "Sweater", "Hoodie"],
    'cold_accessories': [
      "Beanie",
      "Scarf",
      "Gloves",
      "Thermal Base Layers",
      "Ear Muffs"
    ],
    'cold_bottoms': [
      "Jeans",
      "Sweatpants",
      "Corduroy Pants",
      "Khakis",
      "Thermal Leggings"
    ],
    'mild_footwear': [
      "Sneakers",
      "Loafers",
      "Dress Shoes",
      "Boat Shoes",
      "Canvas Shoes"
    ],
    'mild_top': [
      "Long-Sleeve Shirt",
      "Light Jacket",
      "Sweatshirt",
      "Polo Shirt",
      "Henley"
    ],
    'mild_accessories': [
      "Baseball Cap",
      "Watch",
      "Light Scarf",
      "Sunglasses",
      "Bracelet"
    ],
    'mild_bottoms': ["Jeans", "Chinos", "Cargo Pants", "Joggers", "Slacks"],
    'hot_footwear': [
      "Flip-Flops",
      "Sandals",
      "Sneakers",
      "Canvas Shoes",
      "Boat Shoes"
    ],
    'hot_top': [
      "T-Shirt",
      "Tank Top",
      "Short-Sleeve Shirt",
      "Polo Shirt",
      "Linen Shirt"
    ],
    'hot_accessories': [
      "Sunglasses",
      "Hat",
      "Water Bottle",
      "Lightweight Backpack",
      "Sunscreen"
    ],
    'hot_bottoms': [
      "Shorts",
      "Swim Trunks",
      "Lightweight Pants",
      "Cargo Shorts",
      "Linen Pants"
    ],
  };

  // Outfit categories for Female
  Map<String, List<String>> femaleOutfits = {
    'cold_footwear': [
      "Boots",
      "Ankle Boots",
      "Uggs",
      "Winter Sneakers",
      "Knee-High Boots"
    ],
    'cold_top': ["Jacket", "Parka", "Coat", "Sweater", "Cardigan"],
    'cold_accessories': [
      "Beanie",
      "Scarf",
      "Gloves",
      "Thermal Base Layers",
      "Ear Muffs"
    ],
    'cold_bottoms': [
      "Jeans",
      "Leggings",
      "Sweatpants",
      "Thermal Leggings",
      "Skirt with Tights"
    ],
    'mild_footwear': ["Sneakers", "Flats", "Ankle Boots", "Loafers", "Wedges"],
    'mild_top': [
      "Blouse",
      "Long-Sleeve Shirt",
      "Light Jacket",
      "Sweater",
      "Cardigan"
    ],
    'mild_accessories': [
      "Sunglasses",
      "Watch",
      "Light Scarf",
      "Handbag",
      "Hat"
    ],
    'mild_bottoms': ["Jeans", "Skirt", "Dress Pants", "Culottes", "Leggings"],
    'hot_footwear': [
      "Sandals",
      "Flip-Flops",
      "Flats",
      "Sneakers",
      "Espadrilles"
    ],
    'hot_top': [
      "Tank Top",
      "T-Shirt",
      "Blouse",
      "Sleeveless Dress",
      "Crop Top"
    ],
    'hot_accessories': [
      "Sunglasses",
      "Hat",
      "Water Bottle",
      "Lightweight Bag",
      "Sunscreen"
    ],
    'hot_bottoms': ["Shorts", "Skirt", "Dress", "Capris", "Lightweight Pants"],
  };

  /*Future<List<String>> _getCitySuggestions(String query) async {
    final dbHelper = DatabaseHelper();
    final cities = await dbHelper.getCities();
    return cities
        .where((city) => city.toLowerCase().startsWith(query.toLowerCase()))
        .toList();
  }*/

  void fetchWeatherData(String searchText) async {
    try {
      var apiUrl = Uri.parse('$searchWeatherAPI$searchText');

      var searchResult = await http.get(apiUrl);
      if (searchResult.statusCode == 200) {
        final weatherData = json.decode(searchResult.body);

        var locationData = weatherData["location"];

        setState(() {
          location = getShortLocationName(locationData["name"]);

          var parsedDate = DateTime.now();
          var newDate = DateFormat('MMMMEEEEd').format(parsedDate);
          currentDate = newDate;

          var currentWeather = weatherData["current"];

          currentWeatherStatus = currentWeather["condition"]["text"];
          weatherIcon = currentWeather["condition"]["icon"];

          temperature = isCelsius
              ? currentWeather["temp_c"].toInt()
              : currentWeather["temp_f"].toInt();
          windSpeed = isCelsius
              ? currentWeather["wind_kph"]
              : currentWeather["wind_mph"];
          humidity = currentWeather["humidity"].toInt();
          cloud = currentWeather["cloud"].toInt();

          var forecastList = weatherData["forecast"]["forecastday"];
          var todayForecast = forecastList[0];

          maxTemp = isCelsius
              ? todayForecast["day"]["maxtemp_c"].toInt()
              : todayForecast["day"]["maxtemp_f"].toInt();
          minTemp = isCelsius
              ? todayForecast["day"]["mintemp_c"].toInt()
              : todayForecast["day"]["mintemp_f"].toInt();

          dailyWeatherForecast = forecastList;

          isDayTime = currentWeather["is_day"] == 1;
        });

        // Generate outfit recommendation after weather data is fetched
        generateOutfitRecommendation();
        // Call _getCurrentLocation to update the location
        await _getCurrentLocation();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load weather data')),
        );
      }
    } catch (e) {
      print('Error fetching weather data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load weather data: $e')),
      );
    }
  }

  void generateOutfitRecommendation() {
    String selectedTop = '';
    String selectedBottom = '';
    String selectedFootwear = '';
    String selectedAccessory = '';
    String additionalAdvice = '';

    Map<String, List<String>> outfits =
        gender == 'Male' ? maleOutfits : femaleOutfits;

    // Temperature thresholds in both Celsius and Fahrenheit
    int coldThreshold = isCelsius ? 10 : 50;
    int mildThreshold = isCelsius ? 25 : 77;

    //ADD IN COMFORT THRESHOLD HERE
    // int coldThreshold = isCelsius ? coldComfort : (coldComfort*(9/5)+32);
    // int mildThreshold = isCelsius ? mildComfort : (mildComfort*(9/5)+32);
    // int chillyThreshold = isCelsius ? chillyComfort : (chillyComfort*(9/5)+32);
    // int hotThreshold = isCelsius ? hotComfort : (hotComfort*(9/5)+32);

    // Determine weather conditions
    String weatherStatus = currentWeatherStatus.toLowerCase();
    bool isRaining = weatherStatus.contains('rain');
    bool isSnowing = weatherStatus.contains('snow');
    bool isDrizzling = weatherStatus.contains('drizzle');
    bool isClear = weatherStatus.contains('clear');
    bool isCloudy =
        weatherStatus.contains('cloud') || weatherStatus.contains('overcast');
    bool isPartlyCloudy = weatherStatus.contains('partly cloudy');

    /*bool isLightRain = isRaining && weatherStatus.contains('light');
    bool isHeavyRain = isRaining && weatherStatus.contains('heavy');
    bool isLightSnow = isSnowing && weatherStatus.contains('light');
    bool isHeavySnow = isSnowing && weatherStatus.contains('heavy');*/

    String tempCategory = '';
    String advice = '';

    // Determine temperature category
    if (temperature <= coldThreshold) {
      tempCategory = 'cold';
      advice = "Dress warmly in layers suitable for cold weather.";
    } else if (temperature > coldThreshold && temperature <= mildThreshold) {
      tempCategory = 'mild';
      advice = "Dress in layers suitable for mild weather.";
    } else {
      tempCategory = 'hot';
      advice = "It's warm outside. Wear light clothing and stay hydrated.";
    }

    // Select outfit based on temperature category
    selectedTop = getRandomItem(outfits['${tempCategory}_top'] ?? []);
    selectedBottom = getRandomItem(outfits['${tempCategory}_bottoms'] ?? []);
    selectedFootwear = getRandomItem(outfits['${tempCategory}_footwear'] ?? []);
    selectedAccessory =
        getRandomItem(outfits['${tempCategory}_accessories'] ?? []);

    // Now, select images from user uploads
    File? selectedTopImage;
    File? selectedBottomImage;
    File? selectedFootwearImage;
    File? selectedAccessoryImage;

    if (imagesByCategory['Top']?[tempCategory]?.isNotEmpty ?? false) {
      selectedTopImage = getRandomItem(imagesByCategory['Top']![tempCategory]!);
    }

    if (imagesByCategory['Bottom']?[tempCategory]?.isNotEmpty ?? false) {
      selectedBottomImage =
          getRandomItem(imagesByCategory['Bottom']![tempCategory]!);
    }

    if (imagesByCategory['Footwear']?[tempCategory]?.isNotEmpty ?? false) {
      selectedFootwearImage =
          getRandomItem(imagesByCategory['Footwear']![tempCategory]!);
    }

    if (imagesByCategory['Accessories']?[tempCategory]?.isNotEmpty ?? false) {
      selectedAccessoryImage =
          getRandomItem(imagesByCategory['Accessories']![tempCategory]!);
    }

    // Adjust outfit and advice based on weather conditions
    if (isRaining || isSnowing || isDrizzling) {
      if (isRaining) {
        // Raining
        selectedAccessory +=
            selectedAccessory.isNotEmpty ? ', Umbrella' : 'Umbrella';
        if (tempCategory == 'cold') {
          advice =
              "Wear waterproof and insulated gear to stay dry in the rain.";
        } else if (tempCategory == 'mild') {
          advice = "Prepare for rain with appropriate waterproof outerwear.";
        } else {
          advice = "Wear lightweight clothing with rain protection.";
        }
      } else if (isSnowing) {
        // Snowing
        selectedFootwear = "Snow Boots";
        advice = "Dress warmly with insulated layers. Wear snow boots.";
      } else if (isDrizzling) {
        // Drizzling
        selectedAccessory +=
            selectedAccessory.isNotEmpty ? ', Umbrella' : 'Umbrella';
        advice = "Wear light waterproof gear for drizzles.";
      }
    } else if (isCloudy || isPartlyCloudy) {
      if (tempCategory == 'cold') {
        advice = "Dress warmly, but in layers that allow for flexible changes.";
      } else if (tempCategory == 'mild') {
        advice = "It's mild but cloudy. Dress in light layers.";
      } else {
        advice = "It’s warm but cloudy. Wear light, comfortable clothing.";
      }
    } else if (isClear) {
      if (tempCategory == 'cold') {
        advice = "It's cold and clear. Wear warm, comfortable clothes.";
      } else if (tempCategory == 'mild') {
        advice = "Mild and clear. Wear light, comfortable clothing.";
      } else {
        advice =
            "Stay cool and protect yourself from the sun with light fabrics and sun protection.";
      }
    } else {
      advice = "Dress appropriately for the weather.";
    }

    // Consider wind speed
    num windThreshold = isCelsius ? 40 : 25; // Adjust thresholds as needed
    if (windSpeed > windThreshold) {
      selectedAccessory +=
          ', ' + getRandomItem(["Windbreaker", "Jacket", "Scarf"]);
      additionalAdvice += " It's windy. Wear wind-resistant outerwear.";
    }

    // Consider time of day
    if (!isDayTime) {
      selectedAccessory += ', ' + getRandomItem(["Jacket", "Sweater"]);
      additionalAdvice +=
          " Temperatures may drop at night. Carry an extra layer.";
    }

    // Consider humidity levels
    if (humidity > 80) {
      selectedTop += '${' (' + getRandomItem(["Linen", "Cotton"])})';
      selectedBottom += '${' (' + getRandomItem(["Linen", "Cotton"])})';
      additionalAdvice += " It's humid. Wear breathable fabrics to stay cool.";
    }

    // Combine advice texts
    adviceText = advice + additionalAdvice;

    setState(() {
      outfitRecommendation = {
        'Top': {'item': selectedTop, 'image': selectedTopImage},
        'Bottom': {'item': selectedBottom, 'image': selectedBottomImage},
        'Footwear': {'item': selectedFootwear, 'image': selectedFootwearImage},
        'Accessories': {
          'item': selectedAccessory,
          'image': selectedAccessoryImage
        },
      };
    });
  }

  // Helper function to get a random item from a list
  dynamic getRandomItem(List<dynamic> items) {
    if (items.isNotEmpty) {
      return items[math.Random().nextInt(items.length)];
    } else {
      return null;
    }
  }

  // Function to map weather descriptions to local asset icons
  String getAssetIcon(String weatherDescription) {
    String description = weatherDescription.toLowerCase();

    if (description.contains('sunny') || description.contains('clear')) {
      return 'assets/sunny.png';
    } else if (description.contains('partly cloudy')) {
      return 'assets/partlycloudy.png';
    } else if (description.contains('cloudy')) {
      return 'assets/cloudy.png';
    } else if (description.contains('overcast')) {
      return 'assets/overcast.png';
    } else if (description.contains('mist') ||
        description.contains('fog') ||
        description.contains('freezing fog')) {
      return 'assets/fog.png';
    } else if (description.contains('drizzle')) {
      return 'assets/patchylightdrizzle.png';
    } else if (description.contains('light rain')) {
      return 'assets/lightrain.png';
    } else if (description.contains('moderate rain')) {
      return 'assets/moderaterain.png';
    } else if (description.contains('heavy rain')) {
      return 'assets/heavyrain.png';
    } else if (description.contains('thunder')) {
      return 'assets/thunder.png';
    } else if (description.contains('snow')) {
      return 'assets/snow.png';
    } else {
      // Default icon
      return 'assets/cloud.png';
    }
  }

  String getBackgroundImage() {
    String timeOfDay = isDayTime ? 'day' : 'night';
    String weatherCondition;

    if (currentWeatherStatus.toLowerCase().contains('thunder')) {
      weatherCondition = 'storm';
    } else if (currentWeatherStatus.toLowerCase().contains('rain')) {
      weatherCondition = 'rainy';
    } else if (currentWeatherStatus.toLowerCase().contains('snow')) {
      weatherCondition = 'snow';
    } else if (currentWeatherStatus.toLowerCase().contains('mist') ||
        currentWeatherStatus.toLowerCase().contains('fog')) {
      weatherCondition = 'mist';
    } else if (currentWeatherStatus.toLowerCase().contains('clear')) {
      weatherCondition = 'clear';
    } else if (currentWeatherStatus.toLowerCase().contains('cloud')) {
      weatherCondition = 'cloudy';
    } else {
      weatherCondition = 'default';
    }

    return 'assets/${timeOfDay}_$weatherCondition.jpg';
  }

  static String getShortLocationName(String s) {
    List<String> wordList = s.split(" ");

    if (wordList.isNotEmpty) {
      if (wordList.length > 1) {
        return '${wordList[0]} ${wordList[1]}';
      } else {
        return wordList[0];
      }
    } else {
      return " ";
    }
  }

  int convertTemperature(num temp) {
    return temp.toInt();
  }

  String getTemperatureUnit() {
    return isCelsius ? '°C' : '°F';
  }

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadImages();
    _getCurrentLocation().then((_) {
      fetchWeatherData(location);
    });

    _weatherUpdateTimer = Timer.periodic(const Duration(minutes: 15), (timer) {
      // Every 15 minutes refresh the weather data
      fetchWeatherData(location);
    });
  }

  @override
  void dispose() {
    _weatherUpdateTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      gender = prefs.getString('gender') ?? 'Male';
      isCelsius = prefs.getBool('isCelsius') ?? true;
      // comfortThreshold //////////////////////////////////////////////////////
      scorchComfort = prefs.getInt('scorchComfort') ?? 30;
      hotComfort = prefs.getInt('hotComfort') ?? 26;
      mildComfort = prefs.getInt('mildComfort') ?? 17;
      chillyComfort = prefs.getInt('chillyComfort') ?? 8;
      coldComfort = prefs.getInt('coldComfort') ?? -4;
      frigidComfort = prefs.getInt('frigidComfort') ?? -5;
      //////////////////////////////////////////////////////////////////////////
    });
  }

  Future<void> _saveGender(String selectedGender) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('gender', selectedGender);
  }

  Future<void> _saveTemperatureUnit(bool value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isCelsius', value);
  }

  //////////////////////////////////////////////////////////////////////////////
  //save threshold

  Future<void> _saveScorchComfort(int value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('scorchComfort', value);
  }

  Future<void> _saveHotComfort(int value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('hotComfort', value);
  }

  Future<void> _saveMildComfort(int value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('mildComfort', value);
  }

  Future<void> _saveChillyComfort(int value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('chillyComfort', value);
  }

  Future<void> _saveColdComfort(int value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('ColdComfort', value);
  }

  Future<void> _saveFrigidComfort(int value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('frigidComfort', value);
  }

  // Save threshold
  //////////////////////////////////////////////////////////////////////////////

  Future<void> _loadImages() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      ['Top', 'Bottom', 'Footwear', 'Accessories'].forEach((category) {
        ['cold', 'mild', 'hot'].forEach((subCategory) {
          String key = 'images_${category}_$subCategory';
          List<String>? paths = prefs.getStringList(key);
          if (paths != null) {
            imagesByCategory[category]![subCategory] =
                paths.map((path) => File(path)).toList();
          }
        });
      });
    });
  }

  void _updateImages(Map<String, Map<String, List<File>>> images) {
    setState(() {
      imagesByCategory = images;
    });
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: SystemUiOverlay.values);
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: Drawer(
        // ... existing Drawer code ...
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: _constants.primaryColor,
              ),
              child: const Text(
                'Menu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            // ... other ListTiles ...
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () async {
                Navigator.pop(context);
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SettingsPage(
                      isCelsius: isCelsius,
                      gender: gender,

                      // comfort threshold /////////////////////////////////////
                      scorchComfort: scorchComfort,
                      hotComfort: hotComfort,
                      mildComfort: mildComfort,
                      chillyComfort: chillyComfort,
                      coldComfort: coldComfort,
                      frigidComfort: frigidComfort,
                      onSettingsChanged: (bool tempUnit,
                          String selectedGender,
                          int scorchComfortThreshold,
                          int hotComfortThreshold,
                          int mildComfortThreshold,
                          int chillyComfortThreshold,
                          int coldComfortThreshold,
                          int frigidComfortThreshold) {
                        setState(() {
                          isCelsius = tempUnit;
                          gender = selectedGender;

                          // comfort threshold /////////////////////////////////
                          scorchComfort = scorchComfortThreshold;
                          hotComfort = hotComfortThreshold;
                          mildComfort = mildComfortThreshold;
                          chillyComfort = chillyComfortThreshold;
                          coldComfort = coldComfortThreshold;
                          frigidComfort = frigidComfortThreshold;
                          //////////////////////////////////////////////////////

                          fetchWeatherData(location); // Refresh data
                        });
                      },
                    ),
                  ),
                );
                await _saveTemperatureUnit(isCelsius);
                await _saveGender(gender);
                await _saveScorchComfort(scorchComfort);
                await _saveHotComfort(hotComfort);
                await _saveMildComfort(mildComfort);
                await _saveChillyComfort(chillyComfort);
                await _saveColdComfort(coldComfort);
                await _saveFrigidComfort(frigidComfort);
                //comfort threshold
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Upload Photos'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UploadPhotoPage(
                      onImagesPicked: _updateImages,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.image),
              title: const Text('Wardrobe'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const WardrobePage(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('3-Day Forecast'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ForecastPage(forecastData: dailyWeatherForecast),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // Background Image
            Container(
              width: size.width,
              height: size.height,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(getBackgroundImage()),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SingleChildScrollView(
              child: Container(
                width: size.width,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                // Add a semi-transparent overlay if needed
                color: Colors.black.withOpacity(0.3),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Weather Information Card
                    Card(
                      color: Colors.transparent,
                      elevation: 0,
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 10),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          children: [
                            // Top Row with Menu and Location
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Align(
                                  alignment: Alignment.topLeft,
                                  child: Builder(
                                    builder: (context) => IconButton(
                                      icon: Image.asset(
                                        "assets/menu.png",
                                        width: 40,
                                        height: 40,
                                        color: Colors.white,
                                      ),
                                      onPressed: () {
                                        Scaffold.of(context).openDrawer();
                                      },
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Image.asset(
                                            "assets/pin.png",
                                            width: 20,
                                            color: Colors.white,
                                          ),
                                          const SizedBox(width: 2),
                                          Text(
                                            location,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 16.0,
                                            ),
                                          ),
                                          IconButton(
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      LocationSearchPage(
                                                    onLocationSelected: (String
                                                        selectedLocation) {
                                                      setState(() {
                                                        location =
                                                            selectedLocation;
                                                        _isLocationSetManually =
                                                            true; // Set the flag
                                                      });
                                                      fetchWeatherData(
                                                          location);
                                                    },
                                                  ),
                                                ),
                                              );
                                            },
                                            icon: const Icon(
                                              Icons.keyboard_arrow_down,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        currentDate,
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 14.0,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            // Weather Icon and Temperature
                            Center(
                              child: Column(
                                children: [
                                  SizedBox(
                                    width: 80,
                                    height: 80,
                                    child: Image.asset(
                                      getAssetIcon(currentWeatherStatus),
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    currentWeatherStatus,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 20,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'Feels Like: ${convertTemperature(temperature)}${getTemperatureUnit()}',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 20,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'H: ${convertTemperature(maxTemp)}${getTemperatureUnit()}  L: ${convertTemperature(minTemp)}${getTemperatureUnit()}',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            // Additional Weather Details
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 40),
                              child: Column(
                                children: [
                                  const SizedBox(height: 20),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      WeatherItem(
                                        value: windSpeed,
                                        unit: isCelsius ? 'kph' : 'mph',
                                        imageUrl: 'assets/windspeed.png',
                                      ),
                                      WeatherItem(
                                        value: humidity,
                                        unit: '%',
                                        imageUrl: 'assets/humidity.png',
                                      ),
                                      WeatherItem(
                                        value: cloud,
                                        unit: '%',
                                        imageUrl: 'assets/cloud.png',
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Outfit Recommendation Card
                    Card(
                      color: Colors.transparent,
                      elevation: 0,
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          children: [
                            const SizedBox(height: 25),
                            TextButton(
                              onPressed: temperature != 0
                                  ? () {
                                      generateOutfitRecommendation();
                                    }
                                  : null,
                              child: Container(
                                width: 150,
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color:
                                      _constants.primaryColor.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'New Outfit',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontSize: 25,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            // Display outfit items
                            Column(
                              children: [
                                // First Row: Top and Footwear
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _buildOutfitItem(
                                        'Top', outfitRecommendation['Top']!),
                                    _buildOutfitItem('Footwear',
                                        outfitRecommendation['Footwear']!),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                // Second Row: Bottom and Accessories
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _buildOutfitItem('Bottom',
                                        outfitRecommendation['Bottom']!),
                                    _buildOutfitItem('Accessories',
                                        outfitRecommendation['Accessories']!),
                                  ],
                                ),
                                // Weather Description
                                const SizedBox(height: 20),
                                Text(
                                  adviceText,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    color: Colors.white,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOutfitItem(String category, Map<String, dynamic> itemData) {
    String item = itemData['item'] ?? '';
    File? image = itemData['image'];

    return Column(
      children: [
        Text(
          category,
          style: const TextStyle(
              fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18),
        ),
        const SizedBox(height: 8),
        image != null
            ? Image.file(
                image,
                width: 150,
                height: 150,
                fit: BoxFit.cover,
              )
            : Container(
                width: 150,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _constants.primaryColor.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item,
                  style: const TextStyle(fontSize: 16, color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
      ],
    );
  }

  Future<void> _getCurrentLocation() async {
    if (_isLocationSetManually) return; // Check the flag

    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    List<Placemark> placemarks =
        await placemarkFromCoordinates(position.latitude, position.longitude);
    Placemark place = placemarks[0];

    setState(() {
      location = place.locality ?? "Unknown location";
    });
  }
}

class WeatherItem extends StatelessWidget {
  final num value;
  final String unit;
  final String imageUrl;

  const WeatherItem({
    super.key,
    required this.value,
    required this.unit,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          constraints: const BoxConstraints(
            maxHeight: 50,
            maxWidth: 50,
          ),
          child: Image.asset(imageUrl, color: Colors.white),
        ),
        const SizedBox(
          height: 8.0,
        ),
        Text(
          '$value $unit',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

// redo the categories  make a category for footwear, shirts, sub categories for the weather
// categories shown on the main page only correlate with the weather
class WardrobePage extends StatefulWidget {
  const WardrobePage({super.key});

  @override
  State<WardrobePage> createState() => _WardrobePageState();
}

class _WardrobePageState extends State<WardrobePage> {
  Map<String, Map<String, List<File>>> imagesByCategory = {
    // Add more temp categories
    'Top': {'cold': [], 'mild': [], 'hot': []},
    'Bottom': {'cold': [], 'mild': [], 'hot': []},
    'Footwear': {'cold': [], 'mild': [], 'hot': []},
    'Accessories': {'cold': [], 'mild': [], 'hot': []},
  };

  final List<String> categories = ['Top', 'Bottom', 'Footwear', 'Accessories'];
  final List<String> tempCategories = [
    'cold',
    'mild',
    'hot'
  ]; // Add additional temp categories

  @override
  void initState() {
    super.initState();
    _loadImages();
  }

  Future<void> _loadImages() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      categories.forEach((category) {
        tempCategories.forEach((subCategory) {
          String key = 'images_${category}_$subCategory';
          List<String>? paths = prefs.getStringList(key);
          if (paths != null) {
            imagesByCategory[category]![subCategory] =
                paths.map((path) => File(path)).toList();
          }
        });
      });
    });
  }

  Widget _buildCategoryContent(String category) {
    return ExpansionTile(
      title: Text(
        category,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      children: tempCategories.map((subCategory) {
        return _buildSubCategoryContent(category, subCategory);
      }).toList(),
    );
  }

  Widget _buildSubCategoryContent(String category, String subCategory) {
    List<File>? images = imagesByCategory[category]?[subCategory];
    return ExpansionTile(
      title: Text(
        subCategory[0].toUpperCase() + subCategory.substring(1),
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      children: [
        images != null && images.isNotEmpty
            ? GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                ),
                itemCount: images.length,
                itemBuilder: (context, index) {
                  return Image.file(images[index], fit: BoxFit.cover);
                },
              )
            : const Center(
                child: Text('No images in this subcategory'),
              ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wardrobe'),
      ),
      body: ListView(
        children: categories.map((category) {
          return _buildCategoryContent(category);
        }).toList(),
      ),
    );
  }
}

class SettingsPage extends StatefulWidget {
  final bool isCelsius;
  final String gender;

  // Comfort thresholds
  final int scorchComfort;
  final int hotComfort;
  final int mildComfort;
  final int chillyComfort;
  final int coldComfort;
  final int frigidComfort;

  final void Function(bool, String, int, int, int, int, int, int)
      onSettingsChanged;

  const SettingsPage({
    super.key,
    required this.isCelsius,
    required this.gender,
    required this.scorchComfort,
    required this.hotComfort,
    required this.mildComfort,
    required this.chillyComfort,
    required this.coldComfort,
    required this.frigidComfort,
    required this.onSettingsChanged,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late bool _isCelsius;
  late String _selectedGender;

  // Comfort thresholds
  late int _scorchComfort;
  late int _hotComfort;
  late int _mildComfort;
  late int _chillyComfort;
  late int _coldComfort;
  late int _frigidComfort;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      _isCelsius = prefs.getBool('isCelsius') ?? widget.isCelsius;
      _selectedGender = prefs.getString('gender') ?? widget.gender;
      _scorchComfort = prefs.getInt('scorchComfort') ?? widget.scorchComfort;
      _hotComfort = prefs.getInt('hotComfort') ?? widget.hotComfort;
      _mildComfort = prefs.getInt('mildComfort') ?? widget.mildComfort;
      _chillyComfort = prefs.getInt('chillyComfort') ?? widget.chillyComfort;
      _coldComfort = prefs.getInt('coldComfort') ?? widget.coldComfort;
      _frigidComfort = prefs.getInt('frigidComfort') ?? widget.frigidComfort;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool('isCelsius', _isCelsius);
    await prefs.setString('gender', _selectedGender);
    await prefs.setInt('scorchComfort', _scorchComfort);
    await prefs.setInt('hotComfort', _hotComfort);
    await prefs.setInt('mildComfort', _mildComfort);
    await prefs.setInt('chillyComfort', _chillyComfort);
    await prefs.setInt('coldComfort', _coldComfort);
    await prefs.setInt('frigidComfort', _frigidComfort);

    widget.onSettingsChanged(
      _isCelsius,
      _selectedGender,
      _scorchComfort,
      _hotComfort,
      _mildComfort,
      _chillyComfort,
      _coldComfort,
      _frigidComfort,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Settings saved! Comfort thresholds are in ${_isCelsius ? 'Celsius' : 'Fahrenheit'}.'),
      ),
    );
  }

  int convertToDisplayedUnit(int tempInCelsius) {
    return _isCelsius ? tempInCelsius : (tempInCelsius * 9 / 5 + 32).toInt();
  }

  int convertToCelsius(int tempInDisplayedUnit) {
    return _isCelsius
        ? tempInDisplayedUnit
        : (tempInDisplayedUnit - 32) * 5 ~/ 9;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              ListTile(
                title: const Text("Temperature Unit"),
                subtitle: Text(
                  "Choose your preferred unit for temperature. "
                  "All comfort thresholds will be displayed in ${_isCelsius ? 'Celsius' : 'Fahrenheit'}.",
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('°F', style: TextStyle(fontSize: 16)),
                    Switch(
                      value: _isCelsius,
                      activeColor: Colors.orange,
                      onChanged: (value) {
                        setState(() {
                          _isCelsius = value;
                        });
                      },
                    ),
                    const Text('°C', style: TextStyle(fontSize: 16)),
                  ],
                ),
              ),
              const Divider(),
              ListTile(
                title: const Text("Gender"),
                subtitle:
                    const Text("Select your gender for personalized settings."),
                trailing: DropdownButton<String>(
                  value: _selectedGender,
                  items: <String>['Male', 'Female']
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedGender = newValue!;
                    });
                  },
                ),
              ),
              const Divider(),
              ListTile(title: Text("Set the temperatures (${_isCelsius ? '°C' : '°F'}) where. . ."),),
              ListTile(
                title: const Text("Scorching:"),
                subtitle: const Text(
                  ". . . above which you feel scorching hot.",
                ),
                trailing: NumberPicker(
                  minValue: _isCelsius ? -15 : convertToDisplayedUnit(-15),
                  maxValue: _isCelsius ? 45 : convertToDisplayedUnit(45),
                  value: convertToDisplayedUnit(_scorchComfort),
                  onChanged: (value) =>
                      setState(() => _scorchComfort = convertToCelsius(value)),
                ),
              ),
              ListTile(
                title: const Text("Hot:"),
                subtitle: const Text(
                  ". . . you feel hot but comfortable.",
                ),
                trailing: NumberPicker(
                  minValue: _isCelsius ? -15 : convertToDisplayedUnit(-15),
                  maxValue: _isCelsius ? 45 : convertToDisplayedUnit(45),
                  value: convertToDisplayedUnit(_hotComfort),
                  onChanged: (value) =>
                      setState(() => _hotComfort = convertToCelsius(value)),
                ),
              ),
              ListTile(
                title: const Text("Mild:"),
                subtitle: const Text(
                  ". . . you feel most comfortable.",
                ),
                trailing: NumberPicker(
                  minValue: _isCelsius ? -15 : convertToDisplayedUnit(-15),
                  maxValue: _isCelsius ? 45 : convertToDisplayedUnit(45),
                  value: convertToDisplayedUnit(_mildComfort),
                  onChanged: (value) =>
                      setState(() => _mildComfort = convertToCelsius(value)),
                ),
              ),
              ListTile(
                title: const Text("Chilly:"),
                subtitle: const Text(
                  ". . . you feel chilly but manageable.",
                ),
                trailing: NumberPicker(
                  minValue: _isCelsius ? -15 : convertToDisplayedUnit(-15),
                  maxValue: _isCelsius ? 45 : convertToDisplayedUnit(45),
                  value: convertToDisplayedUnit(_chillyComfort),
                  onChanged: (value) =>
                      setState(() => _chillyComfort = convertToCelsius(value)),
                ),
              ),
              ListTile(
                title: const Text("Cold:"),
                subtitle: const Text(
                  ". . . you feel cold but tolerable.",
                ),
                trailing: NumberPicker(
                  minValue: _isCelsius ? -15 : convertToDisplayedUnit(-15),
                  maxValue: _isCelsius ? 45 : convertToDisplayedUnit(45),
                  value: convertToDisplayedUnit(_coldComfort),
                  onChanged: (value) =>
                      setState(() => _coldComfort = convertToCelsius(value)),
                ),
              ),
              ListTile(
                title: const Text("Frigid:"),
                subtitle: const Text(
                  ". . . below which you feel frigid.",
                ),
                trailing: NumberPicker(
                  minValue: _isCelsius ? -15 : convertToDisplayedUnit(-15),
                  maxValue: _isCelsius ? 45 : convertToDisplayedUnit(45),
                  value: convertToDisplayedUnit(_frigidComfort),
                  onChanged: (value) =>
                      setState(() => _frigidComfort = convertToCelsius(value)),
                ),
              ),
              const Divider(),
              ElevatedButton(
                onPressed: _saveSettings,
                child: const Text("Save Settings"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class UploadPhotoPage extends StatefulWidget {
  final ValueChanged<Map<String, Map<String, List<File>>>> onImagesPicked;

  const UploadPhotoPage({super.key, required this.onImagesPicked});

  @override
  State<UploadPhotoPage> createState() => _UploadPhotoPageState();
}

class ImageColors extends StatefulWidget {
  const ImageColors({super.key, required this.image, required this.imageSize});
  final ImageProvider image;
  final Size imageSize;

  @override
  State<ImageColors> createState() => _ImageColorsState();
}

//const Color _clothingColor = Colors.white; // sets the default before any color is grabbed

class _ImageColorsState extends State<ImageColors> {
  PaletteGenerator? paletteGenerator;
  Color defaultColor = Colors.white;

  Map<String, Map<String, List<File>>> imagesByCategory = {
    'Top': {'cold': [], 'mild': [], 'hot': []},
    'Bottom': {'cold': [], 'mild': [], 'hot': []},
    'Footwear': {'cold': [], 'mild': [], 'hot': []},
    'Accessories': {'cold': [], 'mild': [], 'hot': []},
  };

  final List<String> categories = ['Top', 'Bottom', 'Footwear', 'Accessories'];
  final List<String> tempCategories = ['cold', 'mild', 'hot'];

  void generateColors() async {
    paletteGenerator = await PaletteGenerator.fromImageProvider(
      widget.image,
      size: widget.imageSize,
      region:
          Rect.fromLTRB(0, 0, widget.imageSize.width, widget.imageSize.height),
    );
  }

  @override
  void initState() {
    generateColors();
    _loadImages();
    super.initState();
  }

  Future<void> _loadImages() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      categories.forEach((category) {
        tempCategories.forEach((subCategory) {
          String key = 'images_${category}_$subCategory';
          List<String>? paths = prefs.getStringList(key);
          if (paths != null) {
            imagesByCategory[category]![subCategory] =
                paths.map((path) => File(path)).toList();
          }
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: paletteGenerator != null
          ? paletteGenerator!.dominantColor != null
              ? paletteGenerator!.dominantColor!.color
              : defaultColor
          : defaultColor,
      body: Center(
        child: Image(
          image: widget.image,
          width: widget.imageSize.width,
          height: widget.imageSize.height,
        ),
      ),
    );
  }
}

class _UploadPhotoPageState extends State<UploadPhotoPage> {
  Map<String, Map<String, List<File>>> imagesByCategory = {
    'Top': {'cold': [], 'mild': [], 'hot': []},
    'Bottom': {'cold': [], 'mild': [], 'hot': []},
    'Footwear': {'cold': [], 'mild': [], 'hot': []},
    'Accessories': {'cold': [], 'mild': [], 'hot': []},
  };

  final List<String> categories = ['Top', 'Bottom', 'Footwear', 'Accessories'];
  final List<String> tempCategories = ['cold', 'mild', 'hot'];

  @override
  void initState() {
    super.initState();
    _loadImages();
  }

  Future<void> _loadImages() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      categories.forEach((category) {
        tempCategories.forEach((subCategory) {
          String key = 'images_${category}_$subCategory';
          List<String>? paths = prefs.getStringList(key);
          if (paths != null) {
            imagesByCategory[category]![subCategory] =
                paths.map((path) => File(path)).toList();
          }
        });
      });
    });
  }

  Future<void> _saveImages() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    categories.forEach((category) {
      tempCategories.forEach((subCategory) {
        String key = 'images_${category}_$subCategory';
        List<String> paths = imagesByCategory[category]?[subCategory]
                ?.map((file) => file.path)
                .toList() ??
            [];
        prefs.setStringList(key, paths);
      });
    });
  }

  Future<void> _pickImage(String category, String subCategory) async {
    try {
      final pickedFile =
          await ImagePicker().pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          imagesByCategory[category]![subCategory]?.add(File(pickedFile.path));
        });
        await _saveImages();
        widget.onImagesPicked(imagesByCategory);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No image selected')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: $e')),
      );
    }
  }

  void _removeImage(String category, String subCategory, int index) async {
    setState(() {
      imagesByCategory[category]?[subCategory]?.removeAt(index);
    });
    await _saveImages();
    widget.onImagesPicked(imagesByCategory);
  }

  Widget _buildCategoryContent(String category) {
    return ExpansionTile(
      title: Text(
        category,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      children: tempCategories.map((subCategory) {
        return _buildSubCategoryContent(category, subCategory);
      }).toList(),
    );
  }

  Widget _buildSubCategoryContent(String category, String subCategory) {
    List<File>? images = imagesByCategory[category]?[subCategory];
    return ExpansionTile(
      title: Text(
        subCategory[0].toUpperCase() + subCategory.substring(1),
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      children: [
        images != null && images.isNotEmpty
            ? GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                ),
                itemCount: images.length,
                itemBuilder: (context, index) {
                  return Stack(
                    children: [
                      Image.file(images[index], fit: BoxFit.cover),
                      Positioned(
                        right: 0,
                        top: 0,
                        child: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            _removeImage(category, subCategory, index);
                          },
                        ),
                      ),
                    ],
                  );
                },
              )
            : const Center(
                child: Text('No images in this subcategory'),
              ),
        ElevatedButton(
          onPressed: () => _pickImage(category, subCategory),
          child: const Text('Upload Photo'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Photos'),
      ),
      body: ListView(
        children: categories.map((category) {
          return _buildCategoryContent(category);
        }).toList(),
      ),
    );
  }
}

class ForecastPage extends StatefulWidget {
  final List forecastData;

  const ForecastPage({Key? key, required this.forecastData}) : super(key: key);

  @override
  _ForecastPageState createState() => _ForecastPageState();
}

class _ForecastPageState extends State<ForecastPage> {
  bool isCelsius = true;

  @override
  void initState() {
    super.initState();
    _loadTemperatureUnit();
  }

  // Load temperature unit from SharedPreferences
  Future<void> _loadTemperatureUnit() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isCelsius = prefs.getBool('isCelsius') ?? true;
    });
  }

  // Convert temperature
  int convertTemperature(num temp) {
    return temp.toInt();
  }

  // Get temperature unit symbol
  String getTemperatureUnit() {
    return isCelsius ? '°C' : '°F';
  }

  // Function to map weather descriptions to local asset icons
  String getAssetIcon(String weatherDescription) {
    String description = weatherDescription.toLowerCase();

    if (description.contains('sunny') || description.contains('clear')) {
      return 'assets/sunny.png';
    } else if (description.contains('partly cloudy')) {
      return 'assets/partlycloudy.png';
    } else if (description.contains('cloudy')) {
      return 'assets/cloudy.png';
    } else if (description.contains('overcast')) {
      return 'assets/overcast.png';
    } else if (description.contains('mist') ||
        description.contains('fog') ||
        description.contains('freezing fog')) {
      return 'assets/fog.png';
    } else if (description.contains('drizzle')) {
      return 'assets/patchylightdrizzle.png';
    } else if (description.contains('light rain')) {
      return 'assets/lightrain.png';
    } else if (description.contains('moderate rain')) {
      return 'assets/moderaterain.png';
    } else if (description.contains('heavy rain')) {
      return 'assets/heavyrain.png';
    } else if (description.contains('thunder')) {
      return 'assets/thunder.png';
    } else if (description.contains('snow')) {
      return 'assets/snow.png';
    } else {
      return 'assets/cloud.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('3-Day Forecast')),
      body: Container(
        color: Colors.lightBlueAccent.withOpacity(0.2),
        child: ListView.builder(
          itemCount: widget.forecastData.length,
          itemBuilder: (context, index) {
            var dayForecast = widget.forecastData[index];
            var date = DateFormat('EEEE, MMM d')
                .format(DateTime.parse(dayForecast["date"]));
            var dayData = dayForecast["day"];
            var maxTemp =
                isCelsius ? dayData["maxtemp_c"] : dayData["maxtemp_f"];
            var minTemp =
                isCelsius ? dayData["mintemp_c"] : dayData["mintemp_f"];
            var condition = dayData["condition"]["text"];

            return Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
              elevation: 5,
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Image.asset(
                      getAssetIcon(condition),
                      width: 50,
                      height: 50,
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(date,
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87)),
                          const SizedBox(height: 5),
                          Text(condition,
                              style: TextStyle(
                                  fontSize: 16, color: Colors.grey[700])),
                          const SizedBox(height: 5),
                          Text(
                              'Max: ${convertTemperature(maxTemp)}${getTemperatureUnit()}, Min: ${convertTemperature(minTemp)}${getTemperatureUnit()}',
                              style: const TextStyle(
                                  fontSize: 16, color: Colors.black87)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class LocationSearchPage extends StatefulWidget {
  final Function(String) onLocationSelected;

  const LocationSearchPage({super.key, required this.onLocationSelected});

  @override
  _LocationSearchPageState createState() => _LocationSearchPageState();
}

class _LocationSearchPageState extends State<LocationSearchPage> {
  //final TextEditingController _searchController = TextEditingController();
  List<String> _previousLocations = [];
  final csvHelper = CSVHelper();

  @override
  void initState() {
    super.initState();
    _loadPreviousLocations();
  }

  Future<void> _loadPreviousLocations() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _previousLocations = prefs.getStringList('previousLocations') ?? [];
    });
  }

  Future<void> _addLocation(String location) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (!_previousLocations.contains(location)) {
      _previousLocations.insert(0, location); // Add to the beginning
      if (_previousLocations.length > 5) {
        _previousLocations.removeLast(); // Keep only the latest 5
      }
      await prefs.setStringList('previousLocations', _previousLocations);
    }
  }

  Future<void> _removeLocation(int index) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _previousLocations.removeAt(index);
    });
    await prefs.setStringList('previousLocations', _previousLocations);
  }

  void _onLocationSelected(String location) async {
    await _addLocation(location);
    widget.onLocationSelected(location);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Location'),
      ),
      body: Column(
        children: [
          // Search bar with Autocomplete
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: FutureBuilder<List<Map<String, String>>>(
              future: csvHelper.getCitySuggestions(''),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done &&
                    snapshot.hasData) {
                  return Autocomplete<Map<String, String>>(
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text.isEmpty) {
                        return const Iterable<Map<String, String>>.empty();
                      }
                      return snapshot.data!.where((Map<String, String> option) {
                        return option['city']!
                            .toLowerCase()
                            .contains(textEditingValue.text.toLowerCase());
                      });
                    },
                    displayStringForOption: (Map<String, String> option) =>
                        '${option['city']}, ${option['state_name']}',
                    onSelected: (Map<String, String> selection) {
                      _onLocationSelected(
                          '${selection['city']}, ${selection['state_name']}');
                    },
                    fieldViewBuilder: (BuildContext context,
                        TextEditingController fieldTextEditingController,
                        FocusNode fieldFocusNode,
                        VoidCallback onFieldSubmitted) {
                      return TextField(
                        controller: fieldTextEditingController,
                        focusNode: fieldFocusNode,
                        decoration: InputDecoration(
                          hintText: 'Search city e.g. Fairfax',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              fieldTextEditingController.clear();
                            },
                          ),
                        ),
                      );
                    },
                  );
                } else {
                  return const CircularProgressIndicator();
                }
              },
            ),
          ),
          const SizedBox(height: 10),
          // Previous locations
          Expanded(
            child: _previousLocations.isNotEmpty
                ? ListView.builder(
                    itemCount: _previousLocations.length,
                    itemBuilder: (context, index) {
                      final location = _previousLocations[index];
                      return Dismissible(
                        key: Key(location),
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.only(left: 20.0),
                          child: const Icon(
                            Icons.delete,
                            color: Colors.white,
                          ),
                        ),
                        secondaryBackground: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20.0),
                          child: const Icon(
                            Icons.delete,
                            color: Colors.white,
                          ),
                        ),
                        onDismissed: (direction) {
                          _removeLocation(index);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('$location removed')),
                          );
                        },
                        child: ListTile(
                          leading: const Icon(Icons.location_city),
                          title: Text(location),
                          onTap: () {
                            _onLocationSelected(location);
                          },
                        ),
                      );
                    },
                  )
                : const Center(
                    child: Text('No previous locations'),
                  ),
          ),
        ],
      ),
    );
  }
}
