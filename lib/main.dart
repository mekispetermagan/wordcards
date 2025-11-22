import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:convert';
import 'phrasecard_logic.dart';
import 'screens.dart';

/// High-level UI states driving which screen the exercise flow shows.
enum ExerciseStatus { title, language, idle, correct, incorrect, result }

/// Root [MaterialApp] configuring Material 3, color scheme, Montserrat text
///  theme, and [HomePage].
class _App extends StatelessWidget {
  const _App();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Phrasecard app",
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.dark,
        ),
        textTheme: GoogleFonts.montserratTextTheme(),
      ),
      home: const HomePage(title: "PhraseCard exercise"),
    );
  }
}

/// Top-level stateful shell for the phrase-card exercise state machine.
class HomePage extends StatefulWidget {
  final String title;

  const HomePage({required this.title, super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  ExerciseStatus _status = ExerciseStatus.title;
  late Future<List<PhraseCluster>> _dataFuture;
  List<PhraseCluster>? _phraseStock;
  Language? _sourceLanguage;
  Language? _targetLanguage;
  late PhraseCardManager _exerciseManager;
  PhraseCardExercise? _currentExercise;
  int _round = 0;
  int _score = 0;
  int? _selectedIndex;
  final AudioPlayer _correctPlayer = AudioPlayer()
    ..setReleaseMode(ReleaseMode.stop);
  final AudioPlayer _incorrectPlayer = AudioPlayer()
    ..setReleaseMode(ReleaseMode.stop);
  int _streak = 1;

  @override
  void initState() {
    super.initState();
    _updateStreakData();
    _dataFuture = loadDataAsset(
      kIsWeb ? "data/data.json" : "assets/data/data.json",
    );
  }

  @override
  void dispose() {
    _correctPlayer.dispose();
    _incorrectPlayer.dispose();
    super.dispose();
  }

  /// Reads and updates the daily play streak
  /// (same-day = keep, next-day = +1, ≥2-day gap or parse failure = reset).
  Future<void> _updateStreakData() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final SharedPreferencesAsync prefs = SharedPreferencesAsync();
    final String? lastPlayedTimeRaw = await prefs.getString("lastPlayedTime");
    final int? oldStreak = await prefs.getInt("streak");

    if (lastPlayedTimeRaw == null || oldStreak == null) {
      _streak = 1;
    } else {
      try {
        final DateTime lastPlayedTime = DateTime.parse(lastPlayedTimeRaw);
        final lastPlayedDate = DateTime(
          lastPlayedTime.year,
          lastPlayedTime.month,
          lastPlayedTime.day,
        );
        _streak = switch (today.difference(lastPlayedDate)) {
          < const Duration(days: 1) => oldStreak,
          < const Duration(days: 2) => oldStreak + 1,
          _ => 1,
        };
      } catch (_) {
        _streak = 1;
      }
    }

    await prefs.setInt("streak", _streak);
    await prefs.setString("lastPlayedTime", today.toIso8601String());
  }

  void _createExercise() {
    _currentExercise = _exerciseManager.getExercise();
  }

  void _onStart() {
    setState(() => _status = ExerciseStatus.language);
  }

  void _onSourceSelect(Set<Language> langSet) {
    setState(() {
      if (langSet.isNotEmpty) {
        _sourceLanguage = langSet.single;
      }
    });
    _checkLanguageSelection();
  }

  void _onTargetSelect(Set<Language> langSet) {
    setState(() {
      if (langSet.isNotEmpty) {
        _targetLanguage = langSet.single;
      }
    });
    _checkLanguageSelection();
  }

  /// When both languages are selected, initialises [PhraseCardManager],
  ///  creates the first exercise, and enters idle state.
  Future<void> _checkLanguageSelection() async {
    final sl = _sourceLanguage;
    final tl = _targetLanguage;
    if (sl == null || tl == null) {
      return;
    }
    // Data has been loaded by the FutureBuilder above; [_phraseStock] is
    // guaranteed non-null here.
    final stock = _phraseStock!;
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) {
      return;
    }
    setState(() {
      _exerciseManager = PhraseCardManager(
        phraseStock: stock,
        sourceLang: sl,
        targetLang: tl,
        optionsLength: 3,
      );
      _createExercise();
      _status = ExerciseStatus.idle;
    });
  }

  /// Handles answer submission: updates score/status, plays feedback audio,
  ///  and advances rounds or enters the result screen.
  Future<void> _onSubmit(int i) async {
    _selectedIndex = i;
    if (_selectedIndex == _currentExercise!.correctIndex) {
      setState(() {
        _status = ExerciseStatus.correct;
        _score++;
      });
      _correctPlayer.stop();
      _correctPlayer.play(AssetSource("audio/correct.mp3"));
    } else {
      setState(() {
        _status = ExerciseStatus.incorrect;
      });
      _incorrectPlayer.stop();
      _incorrectPlayer.play(AssetSource("audio/incorrect.mp3"));
    }
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) {
      return;
    }
    _round++;
    if (_round < 12) {
      setState(() {
        _status = ExerciseStatus.idle;
        _selectedIndex = null;
        _createExercise();
      });
    } else {
      setState(() {
        _status = ExerciseStatus.result;
      });
    }
  }

  void _onReset() {
    setState(() {
      _round = 0;
      _score = 0;
      _sourceLanguage = null;
      _targetLanguage = null;
      _currentExercise = null;
      _selectedIndex = null;
      _status = ExerciseStatus.language;
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<PhraseCluster>>(
      future: _dataFuture,
      builder: (context, snapshot) {
        // title screen with loading symbol
        if (snapshot.connectionState == ConnectionState.waiting) {
          return TitleScreen(onStart: null);
        }
        // error screen
        if (snapshot.hasError) {
          return Center(child: Text("Uh oh...${snapshot.error}"));
        }
        // all other screens
        final data = snapshot.data;
        if (data == null) return Center(child: Text("Uh oh..."));
        _phraseStock ??= data;
        return switch (_status) {
          ExerciseStatus.title => TitleScreen(onStart: _onStart),
          ExerciseStatus.language => LanguageScreen(
            onSourceSelect: _onSourceSelect,
            onTargetSelect: _onTargetSelect,
            selectedSource: _sourceLanguage,
            selectedTarget: _targetLanguage,
          ),
          ExerciseStatus.idle => GameScreen(
            exercise: _currentExercise,
            onSubmit: _onSubmit,
            score: _score,
          ),
          ExerciseStatus.correct => GameScreen(
            exercise: _currentExercise,
            onSubmit: null,
            score: _score,
            correctHighlightIndex: _currentExercise!.correctIndex,
          ),
          ExerciseStatus.incorrect => GameScreen(
            exercise: _currentExercise,
            onSubmit: null,
            score: _score,
            correctHighlightIndex: _currentExercise!.correctIndex,
            incorrectHighlightIndex: _selectedIndex,
          ),
          ExerciseStatus.result => ResultScreen(
            score: _score,
            round: _round,
            streak: _streak,
            onReset: _onReset,
          ),
        };
      },
    );
  }
}

/// Loads phrase clusters from a JSON asset and validates that it is a list of
///  object maps.
Future<List<PhraseCluster>> loadDataAsset(String assetPath) async {
  final text = await rootBundle.loadString(assetPath);
  final decoded = jsonDecode(text);
  // malformed json: not a list
  if (decoded is! List) {
    throw const FormatException('Top-level JSON must be a list.');
  }

  return decoded
      .map((e) {
        // malformed json: items are not maps with string keys
        if (e is! Map<String, dynamic>) {
          throw const FormatException(
            'Each item in the list must be an object.',
          );
        }
        return PhraseCluster.fromJson(e);
      })
      .cast<PhraseCluster>()
      .toList();
}

/// Entry point: force GoogleFonts to use bundled assets only (offline-safe)
///  and start the app.
void main() {
  LicenseRegistry.addLicense(() async* {
    final String license = await rootBundle.loadString('fonts/OFL.txt');
    yield LicenseEntryWithLineBreaks(<String>['google_fonts'], license);
  });

  GoogleFonts.config.allowRuntimeFetching = false;
  runApp(const _App());
}
