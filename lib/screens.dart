import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'phrasecard_logic.dart';
import 'rotating_hue_image.dart';

/// Shared primary call-to-action button wired to the app's color scheme.
class _PrimaryActionButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;

  const _PrimaryActionButton({required this.text, required this.onPressed});

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
        child: Text(text, style: TextStyle(fontSize: 30)),
      ),
    );
  }
}

/// Title/result illustration, switching asset paths between web and mobile
///  builds.
class _CoverImage extends StatelessWidget {
  const _CoverImage();
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

/// Single gem icon with animated hue rotation, used to visualise collected
///  points.
class GemImage extends StatelessWidget {
  final double angleOffset;
  const GemImage({this.angleOffset = 0, super.key});

  @override
  Widget build(BuildContext context) {
    return RotatingHueImage(
      image: Image(
        image: AssetImage(kIsWeb ? "images/gem.png" : "assets/images/gem.png"),
      ),
      startingAngle: angleOffset,
    );
  }
}

/// Vertical segmented control for picking a single [Language] (or none) via
///  a common callback.
class _LanguageSelector extends StatelessWidget {
  final void Function(Set<Language>) onSelect;
  final Language? selected;

  const _LanguageSelector({required this.onSelect, required this.selected});

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
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        visualDensity: VisualDensity(horizontal: 4, vertical: 1),
        backgroundColor: WidgetStatePropertyAll(colorScheme.primaryContainer),
        foregroundColor: WidgetStatePropertyAll(colorScheme.onPrimaryContainer),
        textStyle: WidgetStatePropertyAll(TextStyle(fontSize: 18)),
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
    );
  }
}

/// Vertical segmented control for picking a single [Language] (or none) via
///  a common callback.
class _ScoreArea extends StatelessWidget {
  final int score;
  const _ScoreArea({required this.score});

  @override
  Widget build(BuildContext context) {
    return RotatingHue(
      rotationSpeed: 24,
      child: Wrap(
        children: [
          for (int i = 0; i < score; i++) GemImage(angleOffset: i * 60),
        ],
      ),
    );
  }
}

/// Intro screen; doubles as a loading state when [onStart] is null, showing
///  a spinner instead of the button.
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
                textAlign: TextAlign.center,
                style: TextStyle(color: colorScheme.onSurface, fontSize: 36),
              ),
              _CoverImage(),
              (onStart == null)
                  ? CircularProgressIndicator()
                  : _PrimaryActionButton(text: "Start", onPressed: onStart),
            ],
          ),
        ),
      ),
    );
  }
}

/// Screen for choosing source and target languages before the first exercise
/// round.
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
    super.key,
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
                style: TextStyle(color: colorScheme.onSurface, fontSize: 36),
              ),
              Column(
                children: [
                  Text(
                    "Source language:",
                    style: TextStyle(
                      fontSize: 24,
                      color: colorScheme.onSurface,
                    ),
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
                    ),
                  ),
                  _LanguageSelector(
                    onSelect: onTargetSelect,
                    selected: selectedTarget,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Core exercise UI: renders the current phrase, options, score, and optional
///  feedback highlights.
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
    super.key,
  });

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
                          ),
                        ),
                      ),
                    ),
                    for (int i = 0; i < e.targetTexts.length; i++)
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
                              ),
                            ),
                          ),
                        ),
                      ),
                    _ScoreArea(score: score),
                  ],
                ),
              ),
            ),
          )
        : Scaffold(body: Center(child: Text("Uh oh, no exercise...")));
  }
}

/// Summary screen showing score, percentage, and streak, with a single entry
///  point to restart.
class ResultScreen extends StatelessWidget {
  final int score;
  final int round;
  final int streak;
  final VoidCallback onReset;

  const ResultScreen({
    required this.score,
    required this.round,
    required this.streak,
    required this.onReset,
    super.key,
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
              "making $scoreRate% today. Your streak is $streak days. "
              "See you tomorrow, or...",
              style: TextStyle(fontSize: 24, color: colorScheme.onSurface),
            ),
            _CoverImage(),
            _PrimaryActionButton(text: "Play again", onPressed: onReset),
          ],
        ),
      ),
    );
  }
}
