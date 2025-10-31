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
  bool isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  void _onLoginStateChanged(bool loggedIn) {
    setState(() {
      isLoggedIn = loggedIn;
    });
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

    // ---------- Subtle green accents ----------
    // Light-mode subtle green tint for header/nav (very soft).
    const Color lightHeaderTint = Color(0xFFEFF7EF); // very light green background tint
    const Color lightAccent = Color(0xFF2E7D32); // main green for icons and highlights (Green 700)
    const Color lightInnerTint = Color(0xFFF1FBF3); // cards and surfaces with a touch of green

    // Dark-mode subtle green tint for header/nav (dimmed).
    const Color darkHeaderTint = Color(0xFF083016); // dim green header in dark mode
    const Color darkAccent = Color(0xFF66BB6A); // lighter green accent in dark mode
    const Color darkInnerTint = Color(0xFF0C2416); // dark card surface with green hint

    // ---------- Light theme (Material 3) with explicit colours ----------
    final ThemeData lightTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      // Build a color scheme but keep the primary subtle so it doesn't dominate.
      colorScheme: ColorScheme.fromSeed(
        seedColor: lightAccent,
        brightness: Brightness.light,
      ).copyWith(
        primary: lightAccent,
        secondary: lightAccent,
        surface: lightInnerTint,
        background: Colors.white,
        onPrimary: Colors.white,
        onSurface: Colors.black87,
        onBackground: Colors.black87,
      ),
      // AppBar uses a very light green tint as background with green icons.
      appBarTheme: const AppBarTheme(
        backgroundColor: lightHeaderTint,
        foregroundColor: lightAccent,
        elevation: 1,
        centerTitle: false,
      ),
      // Bottom navigation bar uses same subtle header tint and green icons when selected.
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: lightHeaderTint,
        selectedItemColor: lightAccent,
        unselectedItemColor: Colors.black54,
        showUnselectedLabels: true,
      ),
      // Revert drawer styling to default (do not override background).
      drawerTheme: const DrawerThemeData(),
      // Card theme uses a very faint green surface rather than outline borders.
      cardTheme: const CardThemeData(
        color: lightInnerTint,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
        margin: EdgeInsets.zero,
      ),
      // Icon theme uses accent green so icons appear in green rather than outlines.
      iconTheme: const IconThemeData(color: lightAccent),
      // Elevated button uses green fill.
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: lightAccent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      // Text button uses subtle green for interactive labels.
      textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: lightAccent)),
      // Floating action button matches accent.
      floatingActionButtonTheme: const FloatingActionButtonThemeData(backgroundColor: lightAccent),
    );

    // ---------- Dark theme (Material 3) with explicit colours ----------
    final ThemeData darkTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(seedColor: darkAccent, brightness: Brightness.dark).copyWith(
        primary: darkAccent,
        secondary: darkAccent,
        surface: darkInnerTint,
        background: const Color(0xFF070B08),
        onPrimary: Colors.white,
        onSurface: Colors.white70,
        onBackground: Colors.white70,
      ),
      // AppBar uses dim green header tint and white text/icons.
      appBarTheme: AppBarTheme(
        backgroundColor: darkHeaderTint,
        foregroundColor: Colors.white,
        elevation: 1,
        centerTitle: false,
      ),
      // Bottom navigation uses dim header tint and light icons.
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: darkHeaderTint,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        showUnselectedLabels: true,
      ),
      // Revert drawer styling to default dark surface.
      drawerTheme: const DrawerThemeData(),
      // Card surface uses a dark green-tinted surface, not just outline.
      cardTheme: const CardThemeData(
        color: darkInnerTint,
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
        margin: EdgeInsets.zero,
      ),
      // Icons use the dark accent tint where appropriate.
      iconTheme: const IconThemeData(color: darkAccent),
      // Buttons in dark mode use slightly deeper green.
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: darkAccent,
          foregroundColor: Colors.black87,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: darkAccent)),
      floatingActionButtonTheme: FloatingActionButtonThemeData(backgroundColor: darkAccent),
    );

    return MaterialApp(
      title: 'PourRice',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: isLoggedIn
          ? MainShell(
              isDarkMode: isDarkMode,
              isTraditionalChinese: isTraditionalChinese,
              onThemeChanged: _toggleTheme,
              onLanguageChanged: _toggleLanguage,
              isLoggedIn: isLoggedIn,
              onLoginStateChanged: _onLoginStateChanged,
            )
          : LoginPage(
              onLoginStateChanged: _onLoginStateChanged,
              isTraditionalChinese: isTraditionalChinese,
            ),
    );
  }
}

// MainShell manages bottom navigation and provides drawer with toggles.
class MainShell extends StatefulWidget {
  final bool isDarkMode;
  final bool isTraditionalChinese;
  final bool isLoggedIn;
  final ValueChanged<bool> onThemeChanged;
  final ValueChanged<bool> onLanguageChanged;
  final ValueChanged<bool> onLoginStateChanged;

  const MainShell({
    required this.isDarkMode,
    required this.isTraditionalChinese,
    required this.onThemeChanged,
    required this.onLanguageChanged,
    required this.isLoggedIn,
    required this.onLoginStateChanged,
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
      AccountPage(onLoginStateChanged: widget.onLoginStateChanged),
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
        onLoginStateChanged: widget.onLoginStateChanged,
        isLoggedIn: widget.isLoggedIn,
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
