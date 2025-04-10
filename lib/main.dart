import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'dart:math' as math;
import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => BookGoalProvider(prefs)),
        ChangeNotifierProvider(create: (context) => ThemeModeProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class ThemeModeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Define the custom color schemes based on the logo
  static final _defaultLightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: const Color(0xFF4DB6AC), // Teal from book
    onPrimary: Colors.white,
    primaryContainer: const Color(0xFFB2DFDB),
    onPrimaryContainer: const Color(0xFF004D40),
    secondary: const Color(0xFFF06292), // Pink from flower (using as secondary)
    onSecondary: Colors.white,
    secondaryContainer: const Color(0xFFF8BBD0),
    onSecondaryContainer: const Color(0xFF880E4F),
    tertiary: const Color(0xFF80CBC4), // Lighter teal as tertiary
    onTertiary: Colors.black,
    tertiaryContainer: const Color(0xFFE0F2F1),
    onTertiaryContainer: const Color(0xFF004D40),
    error: const Color(0xFFF06292), // Pink from flower for errors/behind schedule
    onError: Colors.white,
    errorContainer: const Color(0xFFFCE4EC),
    onErrorContainer: const Color(0xFF880E4F),
    background: const Color(0xFFFAF3E0), // Off-white from logo background
    onBackground: const Color(0xFF37474F), // Dark grey for readability
    surface: const Color(0xFFFAF3E0), // Off-white for card surfaces etc.
    onSurface: const Color(0xFF37474F), // Dark grey for readability
    surfaceVariant: const Color(0xFFE0E0E0), // Slightly darker grey variant
    onSurfaceVariant: const Color(0xFF424242),
    outline: const Color(0xFFB0BEC5), // Muted outline color
    surfaceTint: const Color(0xFF4DB6AC), // Teal tint
    inversePrimary: const Color(0xFF80CBC4),
    inverseSurface: const Color(0xFF37474F),
    onInverseSurface: const Color(0xFFFAF3E0),
    shadow: Colors.black, // Default shadow
    scrim: Colors.black.withOpacity(0.3), // Default scrim
  );

  static final _defaultDarkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: const Color(0xFFA9C7FF),
    onPrimary: const Color(0xFF07305F),
    primaryContainer: const Color(0xFF264777),
    onPrimaryContainer: const Color(0xFFD6E3FF),
    secondary: const Color(0xFFBDC7DC),
    onSecondary: const Color(0xFF273141),
    secondaryContainer: const Color(0xFF3E4758),
    onSecondaryContainer: const Color(0xFFD9E3F9),
    tertiary: const Color(0xFFDCBCE1),
    onTertiary: const Color(0xFF3E2845),
    tertiaryContainer: const Color(0xFF563E5C),
    onTertiaryContainer: const Color(0xFFF9D8FE),
    error: const Color(0xFFFFB4AB),
    onError: const Color(0xFF690005),
    errorContainer: const Color(0xFF93000A),
    onErrorContainer: const Color(0xFFFFDAD6),
    background: const Color(0xFF111318),
    onBackground: const Color(0xFFE2E2E9),
    surface: const Color(0xFF111318),
    onSurface: const Color(0xFFE2E2E9),
    surfaceVariant: const Color(0xFF43474E),
    onSurfaceVariant: const Color(0xFFC4C6CF),
    outline: const Color(0xFF8E9099),
    surfaceTint: const Color(0xFFA9C7FF),
  );

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        return MaterialApp(
          title: 'Tale Talley',
          theme: ThemeData(
            colorScheme: lightDynamic ?? _defaultLightColorScheme,
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorScheme: darkDynamic ?? _defaultDarkColorScheme,
            useMaterial3: true,
          ),
          themeMode: context.watch<ThemeModeProvider>().themeMode,
          home: const HomePage(),
        );
      },
    );
  }
}

class BookGoalProvider extends ChangeNotifier {
  int _targetBooks = 0;
  int _currentBooks = 0;
  final SharedPreferences _prefs;

  BookGoalProvider(this._prefs) {
    _loadData();
  }

  int get targetBooks => _targetBooks;
  int get currentBooks => _currentBooks;

  void _loadData() {
    _targetBooks = _prefs.getInt('targetBooks') ?? 0;
    _currentBooks = _prefs.getInt('currentBooks') ?? 0;
    notifyListeners();
  }

  Future<void> setTargetBooks(int value) async {
    _targetBooks = value;
    await _prefs.setInt('targetBooks', value);
    notifyListeners();
  }

  Future<void> setCurrentBooks(int value) async {
    _currentBooks = value;
    await _prefs.setInt('currentBooks', value);
    notifyListeners();
  }

  Map<String, dynamic> calculateProgress() {
    final now = DateTime.now();
    final startOfYear = DateTime(now.year, 1, 1);
    final endOfYear = DateTime(now.year, 12, 31);
    
    final daysElapsed = now.difference(startOfYear).inDays;
    final totalDays = endOfYear.difference(startOfYear).inDays;
    
    // Avoid division by zero
    if (_targetBooks == 0) {
      return {
        'isOnTrack': true,
        'difference': 0,
        'currentRate': 0.0,
        'estimatedYearEnd': 0,
      };
    }
    
    final expectedBooks = (_targetBooks * daysElapsed / totalDays).round();
    final difference = _currentBooks - expectedBooks;
    
    // Calculate current reading rate (books per day)
    final booksPerDay = daysElapsed > 0 ? _currentBooks / daysElapsed : 0.0;
    
    // Estimate total books by year end at current rate
    final estimatedYearEnd = (booksPerDay * totalDays).round();
    
    return {
      'isOnTrack': difference >= 0,
      'difference': difference.abs(),
      'currentRate': booksPerDay,
      'estimatedYearEnd': estimatedYearEnd,
    };
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late TextEditingController _targetBooksController;
  late TextEditingController _booksReadController;
  late FocusNode _targetBooksFocusNode;
  late FocusNode _booksReadFocusNode;
  String _targetBooksText = '';
  String _booksReadText = '';
  int _targetBooks = 0;
  int _currentBooks = 0;
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    _targetBooksController = TextEditingController(text: _targetBooks.toString());
    _booksReadController = TextEditingController(text: _currentBooks.toString());
    _targetBooksFocusNode = FocusNode();
    _booksReadFocusNode = FocusNode();
    _targetBooksText = _targetBooks.toString();
    _booksReadText = _currentBooks.toString();
  }

  @override
  void dispose() {
    _targetBooksController.dispose();
    _booksReadController.dispose();
    _targetBooksFocusNode.dispose();
    _booksReadFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final provider = Provider.of<BookGoalProvider>(context);
    final progress = provider.calculateProgress();
    final themeProvider = Provider.of<ThemeModeProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode : Icons.dark_mode,
              color: colorScheme.onSurface,
            ),
            onPressed: () {
              themeProvider.toggleTheme();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          height: 160,
                          child: Image.asset('assets/logo.png'),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Tale Talley',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Card(
                  color: colorScheme.surface,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        _buildInputField(
                          context: context,
                          label: 'Target Books for Year',
                          value: provider.targetBooks,
                          onChanged: provider.setTargetBooks,
                        ),
                        const SizedBox(height: 16),
                        _buildInputField(
                          context: context,
                          label: 'Books Read So Far',
                          value: provider.currentBooks,
                          onChanged: provider.setCurrentBooks,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Card(
                  color: colorScheme.surface,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          height: 160,
                          width: 160,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: CustomPaint(
                              painter: _CustomPainter(
                                progress: provider.targetBooks > 0 
                                    ? (provider.currentBooks / provider.targetBooks).clamp(0.0, 1.0)
                                    : 0.0,
                                isOnTrack: progress['isOnTrack'] as bool,
                                colorScheme: colorScheme,
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      provider.targetBooks > 0
                                          ? '${((provider.currentBooks / provider.targetBooks).clamp(0.0, 1.0) * 100).toInt()}%'
                                          : '0%',
                                      style: TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        color: colorScheme.onSurface,
                                      ),
                                    ),
                                    Text(
                                      '${provider.currentBooks} / ${provider.targetBooks}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: colorScheme.onSurface.withOpacity(0.7),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        Divider(
                          height: 24,
                          color: colorScheme.surfaceVariant,
                        ),
                        Text(
                          'Progress Status',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          progress['isOnTrack'] as bool
                              ? 'You are on track! 🎉'
                              : 'You are behind schedule 😅',
                          style: TextStyle(
                            fontSize: 16,
                            color: progress['isOnTrack'] as bool
                                ? colorScheme.primary
                                : colorScheme.error,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'You are ${progress["difference"]} books ${progress['isOnTrack'] as bool ? "ahead of" : "behind"} schedule',
                          style: TextStyle(
                            fontSize: 14,
                            color: colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Current reading rate: ${progress["currentRate"].toStringAsFixed(2)} books per day',
                          style: TextStyle(
                            fontSize: 14,
                            color: colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Projected books by year end: ${progress["estimatedYearEnd"]}',
                          style: TextStyle(
                            fontSize: 14,
                            color: colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required BuildContext context,
    required String label,
    required int value,
    required Function(int) onChanged,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isTargetBooks = label == 'Target Books for Year';
    final controller = isTargetBooks ? _targetBooksController : _booksReadController;
    final focusNode = isTargetBooks ? _targetBooksFocusNode : _booksReadFocusNode;
    final textValue = isTargetBooks ? _targetBooksText : _booksReadText;

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: colorScheme.onSurface.withOpacity(0.87),
            ),
          ),
        ),
        SizedBox(
          width: 100,
          child: TextFormField(
            focusNode: focusNode,
            keyboardType: TextInputType.number,
            controller: controller,
            inputFormatters: [NumericInputFormatter()],
            onChanged: (value) {
              setState(() {
                if (isTargetBooks) {
                  _targetBooksText = value;
                  final newValue = int.tryParse(value) ?? 0;
                  Provider.of<BookGoalProvider>(context, listen: false).setTargetBooks(newValue);
                } else {
                  _booksReadText = value;
                  final newValue = int.tryParse(value) ?? 0;
                  Provider.of<BookGoalProvider>(context, listen: false).setCurrentBooks(newValue);
                }
              });
            },
            style: TextStyle(color: colorScheme.onSurface),
            decoration: InputDecoration(
              labelText: isTargetBooks ? 'Target Books' : 'Books Read',
              border: OutlineInputBorder(),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: colorScheme.primary),
              ),
              labelStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.6)),
            ),
          ),
        ),
      ],
    );
  }

  void _updateProgress() {
    setState(() {
      _targetBooks = int.tryParse(_targetBooksText) ?? 0;
      _currentBooks = int.tryParse(_booksReadText) ?? 0;
      _progress = _currentBooks / _targetBooks;
      _saveProgress();
    });
  }

  void _saveProgress() {
    // Save the progress to SharedPreferences
    SharedPreferences.getInstance().then((prefs) {
      prefs.setInt('targetBooks', _targetBooks);
      prefs.setInt('currentBooks', _currentBooks);
    });
  }
}

class _CustomPainter extends CustomPainter {
  final double progress;
  final bool isOnTrack;
  final ColorScheme colorScheme;

  _CustomPainter({
    required this.progress,
    required this.isOnTrack,
    required this.colorScheme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = size.width / 15.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background circle
    final backgroundPaint = Paint()
      ..color = colorScheme.surfaceVariant
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = isOnTrack ? colorScheme.primary : colorScheme.error
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    final old = oldDelegate as _CustomPainter;
    return old.progress != progress || old.isOnTrack != isOnTrack;
  }
}

class NumericInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    // Only allow digits
    if (newValue.text.isEmpty) {
      return newValue;
    }
    final int? number = int.tryParse(newValue.text);
    if (number == null) {
      return oldValue; // Reject the change if not a number
    }
    return newValue; // Accept the change
  }
} 