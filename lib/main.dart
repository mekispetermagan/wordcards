import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:convert';
import 'phrasecard_logic.dart';
import 'rotating_hue_image.dart';

enum ExerciseStatus {title, language, idle, correct, incorrect, result}

class _PrimaryActionButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;

  const _PrimaryActionButton({
    required this.text,
    required this.onPressed,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return TextButton(
      onPressed: onPressed,
      style: ButtonStyle(
        backgroundColor: WidgetStatePropertyAll(colorScheme.primaryContainer),
        foregroundColor: WidgetStatePropertyAll(colorScheme.onPrimaryContainer),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 30,
          )
          ),
      ),
      );
  }
}

class _CoverImage extends StatelessWidget {
  const _CoverImage({super.key});
  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: 400),
      child: Image(
      image: AssetImage(
        kIsWeb
          ? "images/black_girl_white_boy.png"
          : "assets/images/black_girl_white_boy.png",
      ),
      fit: BoxFit.contain,
      ),
    );
  }
}

class _GemImage extends StatelessWidget {
  final double angleOffset;
  const _GemImage({this.angleOffset = 0, super.key});

  @override
  Widget build(BuildContext context) {
    return RotatingHueImage(
      image:Image(image: AssetImage(
        kIsWeb ? "images/gem.png" : "assets/images/gem.png"
      )),
      startingAngle: angleOffset,
    );
  }
}

class _LanguageSelector extends StatelessWidget {
  final void Function(Set<Language>) onSelect;
  final Language? selected;

  const _LanguageSelector({
    required this.onSelect,
    required this.selected,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final s = selected;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return SegmentedButton<Language>(
      onSelectionChanged: onSelect,
      direction: Axis.vertical,
      selected: s != null ? {s} : {},
      emptySelectionAllowed: true,
      style: ButtonStyle(
        // padding: WidgetStatePropertyAll(
        //   EdgeInsets.symmetric(horizontal: 24, vertical: 36),
        // ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        visualDensity: VisualDensity(horizontal: 4, vertical: 1),
        backgroundColor: WidgetStatePropertyAll(colorScheme.primaryContainer),
        foregroundColor: WidgetStatePropertyAll(colorScheme.onPrimaryContainer),
        textStyle: WidgetStatePropertyAll(TextStyle(
          fontSize: 18,
        )),
      ),
      segments: <ButtonSegment<Language>>[
        ButtonSegment(
          icon: Text("🇬🇧"),
          value: Language.eng,
          label: Text("English"),
          ),
        ButtonSegment(
          icon: Text("🇭🇺"),
          value: Language.hun,
          label: Text("Hungarian"),
          ),
        ButtonSegment(
          icon: Text("🇺🇬"),
          value: Language.lug,
          label: Text("Luganda"),
          ),
        ButtonSegment(
          icon: Text("🇺🇬"),
          value: Language.nyn,
          label: Text("Runyankore"),
          ),
      ],
    ) ;
  }
}

class _ScoreArea extends StatelessWidget {
  final int score;
  const _ScoreArea({required this.score, super.key});

  @override
  Widget build(BuildContext context) {
    return RotatingHue(
      rotationSpeed: 24,
      child: Wrap(
        children: [
          for (int i=0; i<score; i++) _GemImage(angleOffset: i*60)
        ],
      ),
    );
  }
}

class _TitleScreen extends StatelessWidget {
  final VoidCallback? onStart;

  const _TitleScreen({required this.onStart, super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SizedBox.expand(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              Text(
                "Practice Your Language Skills!",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 36,
                )
              ),
              _CoverImage(),
              (onStart == null)
                ? CircularProgressIndicator()
                : _PrimaryActionButton(text: "Start", onPressed: onStart)
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageScreen extends StatelessWidget {
  final void Function(Set<Language>) onSourceSelect;
  final void Function(Set<Language>) onTargetSelect;
  final Language? selectedSource;
  final Language? selectedTarget;

  const _LanguageScreen({
    required this.onSourceSelect,
    required this.onTargetSelect,
    required this.selectedSource,
    required this.selectedTarget,
    super.key
    });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text(
                "Choose languages!",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 36,
                )
              ),
              Column(
                children: [
                  Text(
                    "Source language:",
                    style: TextStyle(
                      fontSize: 24,
                      color: colorScheme.onSurface,
                    )
                  ),
                  _LanguageSelector(
                    onSelect: onSourceSelect,
                    selected: selectedSource,
                    ),
                ],
              ),
              Column(
                children: [
                  Text(
                    "Target language:",
                    style: TextStyle(
                      fontSize: 24,
                      color: colorScheme.onSurface,
                    )
                  ),
                  _LanguageSelector(
                    onSelect: onTargetSelect,
                    selected: selectedTarget,
                    ),
                ],
              ),
            ]
          ),
        ),
      ),
    );
  }
}

class _GameScreen extends StatelessWidget {
  final PhraseCardExercise? exercise;
  final void Function(int)? onSubmit;
  final int score;
  final int? correctHighlightIndex;
  final int? incorrectHighlightIndex;

  const _GameScreen({
    required this.exercise,
    required this.onSubmit,
    required this.score,
    this.correctHighlightIndex,
    this.incorrectHighlightIndex,
    super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final e = exercise;
    final onS = onSubmit;
    return e != null
      ? Scaffold(
        body: SizedBox.expand(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 24,
              horizontal: 48,
              ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Card(
                  color: colorScheme.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      e.sourceText,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        color: colorScheme.onPrimaryContainer,
                      )
                      ),
                  )
                ),
                for (int i=0; i<e.targetTexts.length; i++)
                  InkWell(
                    onTap: onS != null ? () => onS(i) : null,
                    child: Card(
                      color: correctHighlightIndex == i
                        ? colorScheme.tertiaryContainer
                        : incorrectHighlightIndex == i
                          ? colorScheme.errorContainer
                          : colorScheme.secondaryContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          e.targetTexts[i],
                        textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            color: correctHighlightIndex == i
                              ? colorScheme.onTertiaryContainer
                              : incorrectHighlightIndex == i
                                ? colorScheme.onErrorContainer
                                : colorScheme.onSecondaryContainer,
                          )
                          ),
                      )
                    ),
                  ),
                _ScoreArea(score: score),
              ],
            ),
          ),
        ),
      )
      : Scaffold(
        body: Center(child: Text("Uh oh, no exercise..."),),
      );
  }
}

class _ResultScreen extends StatelessWidget {
  final int score;
  final int round;
  final VoidCallback onReset;

  const _ResultScreen({
    required this.score,
    required this.round,
    required this.onReset,
    super.key
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final int scoreRate = (score / round * 100).round();
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Text(
              "Thanks for playing! You collected $score gems in $round rounds, "
              "making $scoreRate% today. See you tomorrow, or...",
              style: TextStyle(
                fontSize: 24,
                color: colorScheme.onSurface,
              ),
            ),
            _CoverImage(),
            _PrimaryActionButton(text: "Play again", onPressed: onReset),
          ],
        ),
      ),
    );
  }
}

class _App extends StatelessWidget {
  const _App({super.key});

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

  @override
  void initState() {
    super.initState();
    _dataFuture = loadDataAsset(
      kIsWeb ? "data/data.json" : "assets/data/data.json"
      );
  }

  @override
  void dispose() {
    _correctPlayer.dispose();
    _incorrectPlayer.dispose();
    super.dispose();
  }

  void _createExercise() {
    _currentExercise = _exerciseManager.getExercise();
  }

  void _onStart() {
    setState(() => _status = ExerciseStatus.language);
  }

  void _onSourceSelect(Set<Language>langSet) {
    setState((){
      if (langSet.isNotEmpty) {_sourceLanguage = langSet.single;}
    });
    _checkLanguageSelection();
  }

  void _onTargetSelect(Set<Language>langSet) {
    setState((){
      if (langSet.isNotEmpty) {_targetLanguage = langSet.single;}
    });
    _checkLanguageSelection();
  }

  Future<void> _checkLanguageSelection() async {
    final sl = _sourceLanguage;
    final tl = _targetLanguage;
    if (sl == null || tl == null) {return;}
    // At this point data has to be loaded; _phraseStock cannot be null.
    final stock = _phraseStock!;
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) {return;}
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
    if (!mounted) {return;}
    _round++;
    if (_round<12) {
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
          return _TitleScreen(onStart: null);
        }
        // error screen
        if (snapshot.hasError) {
          return Center(child: Text("Uh oh...${snapshot.error}"));
        }
        // all other screens
        final data = snapshot.data;
        if (data == null) return Center(child: Text("Uh oh..."));
        _phraseStock ??= data;
        return switch(_status) {
          ExerciseStatus.title => _TitleScreen(onStart: _onStart),
          ExerciseStatus.language => _LanguageScreen(
            onSourceSelect: _onSourceSelect,
            onTargetSelect: _onTargetSelect,
            selectedSource: _sourceLanguage,
            selectedTarget: _targetLanguage,
          ),
          ExerciseStatus.idle => _GameScreen(
            exercise: _currentExercise,
            onSubmit: _onSubmit,
            score: _score,
          ),
          ExerciseStatus.correct
            => _GameScreen(
              exercise: _currentExercise,
              onSubmit: null,
              score: _score,
              correctHighlightIndex: _currentExercise!.correctIndex,
            ),
          ExerciseStatus.incorrect
            => _GameScreen(
              exercise: _currentExercise,
              onSubmit: null,
              score: _score,
              correctHighlightIndex: _currentExercise!.correctIndex,
              incorrectHighlightIndex: _selectedIndex,
            ),
          ExerciseStatus.result => _ResultScreen(
            score: _score,
            round: _round,
            onReset: _onReset,
          ),
        };
      }

    );
  }
}


// Reads data from assets
Future<List<PhraseCluster>> loadDataAsset(String assetPath) async {
  final text = await rootBundle.loadString(assetPath);
  final decoded = jsonDecode(text);
  // malformed json: not a list
  if (decoded is! List) {
    throw const FormatException('Top-level JSON must be a list.');
  }


  return decoded.map((e) {
    // malformed json: items are not maps with string keys
    if (e is! Map<String, dynamic>) {
      throw const FormatException('Each item in the list must be an object.');
    }
    return PhraseCluster.fromJson(e);
    }).cast<PhraseCluster>().toList();
}

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;
  runApp(const _App());
}
