import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home.dart';
import 'restaurants.dart';
import 'drawer.dart';
import 'account.dart';
import 'login.dart';

// Keys for persisted preferences.
const String prefKeyIsDark = 'pourrice_is_dark';
const String prefKeyIsTc = 'pourrice_is_tc';

// Entry point for the app.
void main() async {
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
        ? ['主頁', '餐廳列表', '我的帳戶']
        : ['Home', 'Restaurants', 'My Account'];

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
        ],
      ),
    );
  }
}