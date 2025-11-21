import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:convert';
import 'phrasecard_logic.dart';
import 'rotating_hue_image.dart';

enum Status {title, language, idle, correct, incorrect, ended}

class GemImage extends StatelessWidget {
  final double delta;
  const GemImage({this.delta = 0, super.key});

  @override
  Widget build(BuildContext context) {
    return RotatingHueImage(
      image:Image(image: AssetImage("images/gem.png")),
      startingAngle: delta,
    );
  }
}

class LanguageMenu extends StatelessWidget {
  final void Function(Set<Language>) onSelect;
  final Language? selected;

  const LanguageMenu({
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
        visualDensity: VisualDensity(horizontal: 3, vertical: 1),
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

class ScoreArea extends StatelessWidget {
  final int score;
  const ScoreArea({required this.score, super.key});

  @override
  Widget build(BuildContext context) {
    return RotatingHue(
      rotationSpeed: 24,
      child: Wrap(
        children: [
          for (int i=0; i<score; i++) GemImage(delta: i*60)
        ],
      ),
    );
  }
}

class TitleScreen extends StatelessWidget {
  final VoidCallback? onStart;

  const TitleScreen({required this.onStart, super.key});

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
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 36,
                )
              ),
              (onStart == null)
                ? CircularProgressIndicator()
                : TextButton(
                  onPressed: onStart,
                  style: ButtonStyle(
                    backgroundColor: WidgetStatePropertyAll(colorScheme.primary),
                    foregroundColor: WidgetStatePropertyAll(colorScheme.onPrimary),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      "Start",
                      style: TextStyle(
                        fontSize: 24,
                      )
                      ),
                  ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

class LanguageScreen extends StatelessWidget {
  final void Function(Set<Language>) onSourceSelect;
  final void Function(Set<Language>) onTargetSelect;
  final Language? selectedSource;
  final Language? selectedTarget;

  const LanguageScreen({
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
                  LanguageMenu(
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
                  LanguageMenu(
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

class GameScreen extends StatelessWidget {
  final PhraseCardExercise? exercise;
  final void Function(int)? onSubmit;
  final int score;
  final int? correctHighlightIndex;
  final int? incorrectHighlightIndex;

  const GameScreen({
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
                ScoreArea(score: score),
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

class EndScreen extends StatelessWidget {
  EndScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(child: Text("How did you get here?"),);
  }
}

class App extends StatelessWidget {
  const App({super.key});

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
  late PhraseCardManager _manager;
  Status _status = Status.title;
  late Future<List<PhraseCluster>> _dataFuture;
  int _score = 0;
  Language? sourceLanguage;
  Language? targetLanguage;
  List<PhraseCluster>? _phraseStock;
  PhraseCardExercise? _currentExercise;
  int? _selectedIndex;
  final AudioPlayer _correctPlayer = AudioPlayer()
    ..setReleaseMode(ReleaseMode.stop);
  final AudioPlayer _incorrectPlayer = AudioPlayer()
    ..setReleaseMode(ReleaseMode.stop);

  @override
  void initState() {
    super.initState();
    _dataFuture = loadDataAsset("data/data.json");
  }

  void _createExercise() {
    _currentExercise = _manager.getExercise();
  }

  void _onStart() {
    setState(() => _status = Status.language);
  }

  void _onSourceSelect(Set<Language>langSet) {
    setState((){
      if (langSet.isNotEmpty) {sourceLanguage = langSet.single;}
    });
    _checkLanguageSelection();
  }

  void _onTargetSelect(Set<Language>langSet) {
    setState((){
      if (langSet.isNotEmpty) {targetLanguage = langSet.single;}
    });
    _checkLanguageSelection();
  }

  Future<void> _checkLanguageSelection() async {
    final sl = sourceLanguage;
    final tl = targetLanguage;
    if (sl == null || tl == null) {return;}
    // At this point data has to be loaded; _phraseStock cannot be null.
    final stock = _phraseStock!;
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) {return;}
    setState(() {
      _manager = PhraseCardManager(
        phraseStock: stock,
        sourceLang: sl,
        targetLang: tl,
        optionsLength: 3,
      );
      _createExercise();
      _status = Status.idle;
    });
  }

  Future<void> _onSubmit(int i) async {
    _selectedIndex = i;
    if (_selectedIndex == _currentExercise!.correctIndex) {
      setState(() {
        _status = Status.correct;
        _score++;
      });
      _correctPlayer.stop();
      _correctPlayer.play(AssetSource("audio/correct.mp3"));
    } else {
      setState(() {
        _status = Status.incorrect;
      _createExercise();
      });
      _incorrectPlayer.stop();
      _incorrectPlayer.play(AssetSource("audio/incorrect.mp3"));
    }
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) {return;}
    setState(() {
      _status = Status.idle;
      _selectedIndex = null;
      _createExercise();
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
        _phraseStock = data;
        return switch(_status) {
          Status.title => TitleScreen(onStart: _onStart),
          Status.language => LanguageScreen(
            onSourceSelect: _onSourceSelect,
            onTargetSelect: _onTargetSelect,
            selectedSource: sourceLanguage,
            selectedTarget: targetLanguage,
          ),
          Status.idle => GameScreen(
            exercise: _currentExercise,
            onSubmit: _onSubmit,
            score: _score,
          ),
          Status.correct
            => GameScreen(
              exercise: _currentExercise,
              onSubmit: null,
              score: _score,
              correctHighlightIndex: _currentExercise!.correctIndex,
            ),
          Status.incorrect
            => GameScreen(
              exercise: _currentExercise,
              onSubmit: null,
              score: _score,
              correctHighlightIndex: _currentExercise!.correctIndex,
              incorrectHighlightIndex: _selectedIndex,
            ),
          Status.ended => EndScreen(),
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
  runApp(const App());
}
