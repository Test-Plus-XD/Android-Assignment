// main.dart
import 'dart:convert';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

// Keys for persisted preferences.
const String prefKeyIsDark = 'pourrice_is_dark';
const String prefKeyIsTc = 'pourrice_is_tc';

// Entry point for the app.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PourRiceApp());
}

// Root widget that manages theme and language and persists them.
class PourRiceApp extends StatefulWidget {
  const PourRiceApp({super.key});

  @override
  State<PourRiceApp> createState() => _PourRiceAppState();
}

class _PourRiceAppState extends State<PourRiceApp> {
  // Theme state; non-nullable.
  bool isDarkMode = false;
  // Language state; false => English, true => Traditional Chinese.
  bool isTraditionalChinese = false;
  // Indicate preferences loaded.
  bool prefsLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  // Load persisted preferences asynchronously.
  Future<void> _loadPreferences() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final bool loadedDark = prefs.getBool(prefKeyIsDark) ?? false;
    final bool loadedTc = prefs.getBool(prefKeyIsTc) ?? false;
    setState(() {
      isDarkMode = loadedDark;
      isTraditionalChinese = loadedTc;
      prefsLoaded = true;
    });
  }

  // Persist theme selection and update state.
  Future<void> _toggleTheme(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(prefKeyIsDark, value);
    setState(() {
      isDarkMode = value;
    });
  }

  // Persist language selection and update state.
  Future<void> _toggleLanguage(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(prefKeyIsTc, value);
    setState(() {
      isTraditionalChinese = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Wait until preferences load to avoid flicker of default values.
    if (!prefsLoaded) {
      return const MaterialApp(home: Scaffold(body: Center(child: CircularProgressIndicator())));
    }

    return MaterialApp(
      title: 'PourRice',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.green,
        appBarTheme: const AppBarTheme(elevation: 2),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.green,
        appBarTheme: const AppBarTheme(elevation: 2),
      ),
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: MainShell(
        isDarkMode: isDarkMode,
        isTraditionalChinese: isTraditionalChinese,
        onThemeChanged: _toggleTheme,
        onLanguageChanged: _toggleLanguage,
      ),
    );
  }
}

// MainShell manages bottom navigation and provides drawer with toggles.
class MainShell extends StatefulWidget {
  final bool isDarkMode;
  final bool isTraditionalChinese;
  final ValueChanged<bool> onThemeChanged;
  final ValueChanged<bool> onLanguageChanged;

  const MainShell({
    required this.isDarkMode,
    required this.isTraditionalChinese,
    required this.onThemeChanged,
    required this.onLanguageChanged,
    super.key,
  });

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  // Current index for bottom navigation.
  int currentIndex = 0;
  // Pages for bottom navigation; index order matches bottom nav items.
  late List<Widget> pages;

  @override
  void initState() {
    super.initState();
    pages = [
      FrontPage(isTraditionalChinese: widget.isTraditionalChinese),
      RestaurantsPage(isTraditionalChinese: widget.isTraditionalChinese),
      const AccountPage(),
      const PlaceholderCartPage(),
    ];
  }

  @override
  void didUpdateWidget(covariant MainShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isTraditionalChinese != widget.isTraditionalChinese) {
      setState(() {
        pages[0] = FrontPage(isTraditionalChinese: widget.isTraditionalChinese);
        pages[1] = RestaurantsPage(isTraditionalChinese: widget.isTraditionalChinese);
      });
    }
  }

  // Switch bottom nav index.
  void _onNavTapped(int index) {
    setState(() {
      currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<String> pageTitles = widget.isTraditionalChinese
        ? ['主頁', '餐廳列表', '我的帳戶', '購物車']
        : ['Home', 'Restaurants', 'My Account', 'Cart'];

    return Scaffold(
      appBar: AppBar(title: Text(pageTitles[currentIndex])),
      drawer: AppNavDrawer(
        isTraditionalChinese: widget.isTraditionalChinese,
        isDarkMode: widget.isDarkMode,
        onThemeChanged: widget.onThemeChanged,
        onLanguageChanged: widget.onLanguageChanged,
      ),
      body: IndexedStack(index: currentIndex, children: pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: _onNavTapped,
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(icon: const Icon(Icons.home), label: widget.isTraditionalChinese ? '主頁' : 'Home'),
          BottomNavigationBarItem(icon: const Icon(Icons.restaurant), label: widget.isTraditionalChinese ? '餐廳' : 'Restaurants'),
          BottomNavigationBarItem(icon: const Icon(Icons.account_circle), label: widget.isTraditionalChinese ? '帳戶' : 'Account'),
          BottomNavigationBarItem(icon: const Icon(Icons.shopping_cart), label: widget.isTraditionalChinese ? '購物車' : 'Cart'),
        ],
      ),
    );
  }
}

// Model for restaurant.
class Restaurant {
  final String nameEn;
  final String nameTc;
  final String addressEn;
  final String addressTc;
  final String districtEn;
  final String districtTc;
  final double latitude;
  final double longitude;
  final List<String> keywordEn;
  final List<String> keywordTc;
  final String image;

  Restaurant({
    required this.nameEn,
    required this.nameTc,
    required this.addressEn,
    required this.addressTc,
    required this.districtEn,
    required this.districtTc,
    required this.latitude,
    required this.longitude,
    required this.keywordEn,
    required this.keywordTc,
    required this.image,
  });

  // Create a Restaurant object from JSON.
  factory Restaurant.fromJson(Map<String, dynamic> json) {
    return Restaurant(
      nameEn: json['Name_EN'] ?? '',
      nameTc: json['Name_TC'] ?? '',
      addressEn: json['Address_EN'] ?? '',
      addressTc: json['Address_TC'] ?? '',
      districtEn: json['District_EN'] ?? '',
      districtTc: json['District_TC'] ?? '',
      latitude: (json['Latitude'] as num).toDouble(),
      longitude: (json['Longitude'] as num).toDouble(),
      keywordEn: (json['Keyword_EN'] as List<dynamic>).map((e) => e.toString()).toList(),
      keywordTc: (json['Keyword_TC'] as List<dynamic>).map((e) => e.toString()).toList(),
      image: 'assets/images/Placeholder.png', // Default placeholder image.
    );
  }
}

// Load restaurants from JSON assets.
Future<List<Restaurant>> loadRestaurantsFromAssets() async {
  final String jsonString = await rootBundle.loadString('assets/sample_restaurants.json');
  final Map<String, dynamic> jsonMap = json.decode(jsonString) as Map<String, dynamic>;
  final List<dynamic> restaurantList = jsonMap['restaurants'] as List<dynamic>;
  return restaurantList.map((e) => Restaurant.fromJson(e as Map<String, dynamic>)).toList();
}

// FrontPage with an auto-playing carousel and visible indicators (dots).
class FrontPage extends StatefulWidget {
  final bool isTraditionalChinese;
  const FrontPage({this.isTraditionalChinese = false, super.key});

  @override
  State<FrontPage> createState() => _FrontPageState();
}

class _FrontPageState extends State<FrontPage> {
  // Controller for the carousel.
  final CarouselSliderController carouselController = CarouselSliderController();
  // Current index for indicators.
  int currentIndex = 0;
  // Cached restaurants.
  late Future<List<Restaurant>> restaurantsFuture;

  @override
  void initState() {
    super.initState();
    restaurantsFuture = loadRestaurantsFromAssets();
  }

  @override
  Widget build(BuildContext context) {
    final String heading = widget.isTraditionalChinese ? '精選素食餐廳' : 'Featured Vegan Restaurants';
    final String browseLabel = widget.isTraditionalChinese ? '瀏覽所有餐廳' : 'Browse All Restaurants';

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Text(heading, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          SizedBox(
            height: 260,
            child: FutureBuilder<List<Restaurant>>(
              future: restaurantsFuture,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final restaurants = snapshot.data!;
                  if (restaurants.isEmpty) {
                    return Center(child: Text(widget.isTraditionalChinese ? '沒有餐廳' : 'No restaurants'));
                  }

                  return Column(
                    children: [
                      // CarouselSlider builder.
                      Expanded(
                        child: CarouselSlider.builder(
                          carouselController: carouselController,
                          itemCount: restaurants.length,
                          itemBuilder: (context, index, realIndex) {
                            final restaurant = restaurants[index];
                            final String displayName = widget.isTraditionalChinese ? restaurant.nameTc : restaurant.nameEn;
                            return Card(
                              clipBehavior: Clip.hardEdge,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => RestaurantDetailPage(restaurant: restaurant, isTraditionalChinese: widget.isTraditionalChinese)),
                                  );
                                },
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(child: Image.asset(restaurant.image, fit: BoxFit.cover)),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                          options: CarouselOptions(
                            height: double.infinity,
                            autoPlay: true,
                            autoPlayInterval: const Duration(seconds: 4),
                            enlargeCenterPage: true,
                            viewportFraction: 0.92,
                            enableInfiniteScroll: true,
                            onPageChanged: (index, reason) {
                              setState(() {
                                currentIndex = index;
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Dots indicators.
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(restaurants.length, (index) {
                          final bool active = index == currentIndex;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: active ? 12 : 8,
                            height: active ? 12 : 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: active ? Theme.of(context).colorScheme.secondary : Colors.grey.shade400,
                            ),
                          );
                        }),
                      ),
                    ],
                  );
                } else if (snapshot.hasError) {
                  return Center(child: Text(widget.isTraditionalChinese ? '載入錯誤' : 'Error loading restaurants'));
                } else {
                  return const Center(child: CircularProgressIndicator());
                }
              },
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            icon: const Icon(Icons.restaurant_menu),
            label: Text(browseLabel),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => RestaurantsPage(isTraditionalChinese: widget.isTraditionalChinese)));
            },
          ),
          const SizedBox(height: 12),
          const Text('PourRice — vegan restaurant finder.'),
        ],
      ),
    );
  }
}

// Navigation drawer with theme and language toggles and in-drawer app icon.
class AppNavDrawer extends StatelessWidget {
  final bool isTraditionalChinese;
  final bool isDarkMode;
  final ValueChanged<bool> onThemeChanged;
  final ValueChanged<bool> onLanguageChanged;

  const AppNavDrawer({
    required this.isTraditionalChinese,
    required this.isDarkMode,
    required this.onThemeChanged,
    required this.onLanguageChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final String homeLabel = isTraditionalChinese ? '主頁' : 'Home';
    final String allLabel = isTraditionalChinese ? '所有餐廳' : 'All Restaurants';
    final String accountLabel = isTraditionalChinese ? '我的帳戶' : 'My Account';
    final String loginLabel = isTraditionalChinese ? '登入 / 註冊' : 'Login / Register';
    final String themeLabel = isTraditionalChinese ? '深色模式' : 'Dark theme';
    final String languageLabel = isTraditionalChinese ? 'EN|TC' : '英|繁';

    // Choose the app icon image to display in the drawer header.
    final String appIconPath = isDarkMode ? 'assets/images/App-Dark.png' : 'assets/images/App-Light.png';

    return Drawer(
      child: Column(
        children: [
          // DrawerHeader with icon image and app title; use BoxFit.contain to keep square image intact.
          DrawerHeader(
            decoration: BoxDecoration(color: Colors.green.withOpacity(0.5)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // App icon displayed inside a square container without cropping.
                Container(
                  width: 200,
                  height: 200,
                  padding: const EdgeInsets.all(4),
                  child: Image.asset(appIconPath, fit: BoxFit.contain),
                ),
              ],
            ),
          ),
          ListTile(leading: const Icon(Icons.home), title: Text(homeLabel), onTap: () => Navigator.popUntil(context, (route) => route.isFirst)),
          ListTile(leading: const Icon(Icons.restaurant), title: Text(allLabel), onTap: () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (_) => RestaurantsPage(isTraditionalChinese: isTraditionalChinese)));
          }),
          ListTile(leading: const Icon(Icons.account_circle), title: Text(accountLabel), onTap: () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (_) => const AccountPage()));
          }),
          ListTile(leading: const Icon(Icons.login), title: Text(loginLabel), onTap: () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginPage()));
          }),
          const Spacer(),
          // Theme toggle persisted by root via callback.
          SwitchListTile(value: isDarkMode, title: Text(themeLabel), secondary: const Icon(Icons.brightness_6), onChanged: onThemeChanged),
          // Language toggle persisted by root via callback.
          SwitchListTile(value: isTraditionalChinese, title: Text(languageLabel), secondary: const Icon(Icons.language), onChanged: onLanguageChanged),
        ],
      ),
    );
  }
}

// Restaurants page that lists all restaurants.
class RestaurantsPage extends StatelessWidget {
  final bool isTraditionalChinese;
  const RestaurantsPage({this.isTraditionalChinese = false, super.key});

  @override
  Widget build(BuildContext context) {
    final String title = isTraditionalChinese ? '餐廳列表' : 'All Restaurants';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: FutureBuilder<List<Restaurant>>(
        future: loadRestaurantsFromAssets(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final restaurants = snapshot.data!;
            return ListView.builder(
              itemCount: restaurants.length,
              itemBuilder: (context, index) {
                final restaurant = restaurants[index];
                final String displayName = isTraditionalChinese ? restaurant.nameTc : restaurant.nameEn;
                return Card(
                  child: ListTile(
                    leading: Image.asset(restaurant.image, width: 64, fit: BoxFit.cover),
                    title: Text(displayName),
                    subtitle: Text(isTraditionalChinese ? restaurant.districtTc : restaurant.districtEn),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => RestaurantDetailPage(restaurant: restaurant, isTraditionalChinese: isTraditionalChinese)));
                    },
                  ),
                );
              },
            );
          } else if (snapshot.hasError) {
            return Center(child: Text(isTraditionalChinese ? '載入錯誤' : 'Error loading restaurants'));
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}

// Restaurant detail page.
class RestaurantDetailPage extends StatelessWidget {
  final Restaurant restaurant;
  final bool isTraditionalChinese;
  const RestaurantDetailPage({required this.restaurant, this.isTraditionalChinese = false, super.key});

  @override
  Widget build(BuildContext context) {
    final String displayName = isTraditionalChinese ? restaurant.nameTc : restaurant.nameEn;
    final String address = isTraditionalChinese ? restaurant.addressTc : restaurant.addressEn;
    final String district = isTraditionalChinese ? restaurant.districtTc : restaurant.districtEn;
    final String keywords = isTraditionalChinese ? restaurant.keywordTc.join(', ') : restaurant.keywordEn.join(', ');

    return Scaffold(
      appBar: AppBar(title: Text(displayName)),
      body: ListView(
        children: [
          Image.asset(restaurant.image, height: 240, fit: BoxFit.cover),
          Padding(padding: const EdgeInsets.all(12.0), child: Text(displayName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
          ListTile(leading: const Icon(Icons.location_on), title: Text(address)),
          ListTile(leading: const Icon(Icons.map), title: Text('${isTraditionalChinese ? '地區' : 'District'}: $district')),
          ListTile(leading: const Icon(Icons.label), title: Text('${isTraditionalChinese ? '關鍵字' : 'Keywords'}: $keywords')),
          ListTile(leading: const Icon(Icons.gps_fixed), title: Text('${isTraditionalChinese ? '緯度' : 'Latitude'}: ${restaurant.latitude}'), subtitle: Text('${isTraditionalChinese ? '經度' : 'Longitude'}: ${restaurant.longitude}')),
        ],
      ),
    );
  }
}

// Account page placeholder.
class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: const Text('My Account')), body: const Center(child: Text('Account features coming soon')));
  }
}

// Cart placeholder page.
class PlaceholderCartPage extends StatelessWidget {
  const PlaceholderCartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: const Text('Cart')), body: const Center(child: Text('Cart is empty (demo)')));
  }
}

// Login page placeholder.
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login / Register')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            TextFormField(decoration: const InputDecoration(labelText: 'Email')),
            TextFormField(decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Login demo only'))), child: const Text('Login')),
          ],
        ),
      ),
    );
  }
}