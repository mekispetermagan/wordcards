import "dart:math";

enum Language {eng, hun, lug, nyn}

Language decode(String langCode) {
  langCode = langCode.trim().toLowerCase();
  return switch(langCode) {
    "eng" => Language.eng,
    "hun" => Language.hun,
    "lug" => Language.lug,
    "nyn" => Language.nyn,
    _     => throw FormatException("Unknown language code: $langCode"),
  };
}

class PhraseCluster {
  final Map<Language, List<String>> _items;

  PhraseCluster(Map<Language, List<String>> items)
      : assert(items.isNotEmpty, 'items must not be empty'),
        _items = {
          for (final e in items.entries)
            e.key: List.unmodifiable(e.value)
        };

  factory PhraseCluster.fromJson(Map<String, dynamic> item) {
    final Map<Language, List<String>> result = {};

    for (final entry in item.entries) {
      final lang = decode(entry.key);
      final value = entry.value;

      if (value is! List) {
        throw FormatException(
          'Expected a list of strings for key "${entry.key}".',
        );
      }

      final phrases = value.map((e) {
        if (e is! String) {
          throw FormatException(
            'All phrases for "${entry.key}" must be strings.',
          );
        }
        return e;
      }).toList();

      if (phrases.isEmpty) {
        throw FormatException(
          'Phrase list for "${entry.key}" must not be empty.',
        );
      }

      result[lang] = phrases;
    }

    if (result.isEmpty) {
      throw const FormatException('PhraseCluster has no valid language entries.');
    }

    return PhraseCluster(result);
  }

  List<String>? phrasesOf(Language lang) => _items[lang];

  bool hasLanguage(Language lang) => _items.containsKey(lang);

  bool hasNonEmpty(Language lang) =>
      _items[lang]?.isNotEmpty ?? false;

  bool supportsPair(Language source, Language target) =>
      hasNonEmpty(source) && hasNonEmpty(target);

  String pickPhrase(Language lang, Random random) {
    final List<String>? phrases = _items[lang];
    assert (phrases != null && phrases.isNotEmpty, "No phrase for $lang!");
    final nonNull = phrases!;
    return nonNull[random.nextInt(nonNull.length)];
  }

} // PhraseCluster

class PhraseCardExercise {
  final Language sourceLang;
  final Language targetLang;
  final String sourceText;
  final List<String> targetTexts;
  final int correctIndex;
  PhraseCardExercise({
    required this.sourceLang,
    required this.sourceText,
    required this.targetLang,
    required List<String> targetTexts,
    required this.correctIndex,
    })
    : assert(targetTexts.isNotEmpty, 'targetTexts must not be empty'),
      assert(
        0 <= correctIndex && correctIndex < targetTexts.length,
        'correctIndex out of range',
      ),
      targetTexts = List.unmodifiable(targetTexts);
} // PhraseCardExercise

class PhraseCardManager {
  final List<PhraseCluster> phraseStock;
  final Language sourceLang;
  final Language targetLang;
  final int _optionsLength;
  final Random _random;

  PhraseCardManager({
    required List<PhraseCluster> phraseStock,
    required this.sourceLang,
    required this.targetLang,
    int optionsLength = 4,
    Random? random,
  })
  : assert(
      1 < optionsLength,
      "At least two options are needed."
    ),
    assert(
      optionsLength <= phraseStock.length,
      "Phrase stock does not provide enough options.",
    ),
    assert(
      phraseStock.every(
        (cluster) => cluster.hasNonEmpty(sourceLang),
      ),
      'Each cluster must have a non-empty list for source language.',
    ),
    assert(
      phraseStock.every(
        (cluster) => cluster.hasNonEmpty(targetLang),
      ),
      'Each cluster must have a non-empty list for target language.',
    ),
    phraseStock = List.unmodifiable(phraseStock),
    _optionsLength = optionsLength,
    _random = random ?? Random();

  PhraseCardExercise getExercise() {
    T drawRandom<T>(List<T> list) {
      final T result = list[_random.nextInt(list.length)];
      list.remove(result);
      return result;
    }

    final clusters = [...phraseStock];
    final solutionCluster = drawRandom(clusters);
    final String sourceText = solutionCluster.pickPhrase(sourceLang, _random);
    final String solutionText = solutionCluster.pickPhrase(targetLang, _random);
    final int correctIndex = _random.nextInt(_optionsLength);
    final List<String> targetTexts = [
      for (int i = 0; i < _optionsLength; i++) i == correctIndex
        ? solutionText
        : drawRandom(clusters).pickPhrase(targetLang, _random)
    ];
    return PhraseCardExercise(
      sourceLang: sourceLang,
      sourceText: sourceText,
      targetLang: targetLang,
      targetTexts: targetTexts,
      correctIndex: correctIndex
    );
  }

} // PhraseCardManager