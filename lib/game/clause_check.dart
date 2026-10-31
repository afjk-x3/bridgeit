enum ClauseVerdict { ok, unsure, fail }

const _auxiliaries = {
  'am', 'is', 'are', 'was', 'were', 'be', 'been', 'being', 'has', 'have', //
  'had', 'do', 'does', 'did', 'can', 'could', 'will', 'would', 'shall',
  'should', 'may', 'might', 'must',
};

const _prepositions = {
  'to',
  'in',
  'on',
  'at',
  'with',
  'of',
  'from',
  'by',
  'for',
  'about',
  'into',
};

const _subjects = {
  'i', 'you', 'he', 'she', 'it', 'we', 'they', //
  'the', 'a', 'an', 'my', 'your', 'his', 'her', 'its', 'our', 'their',
  'this', 'that', 'these', 'those', 'there', 'some', 'many', 'every', 'each',
  'everyone', 'someone', 'anyone', 'nobody', 'people',
};

const _determiners = {
  'the', 'a', 'an', 'my', 'your', 'his', 'her', 'its', 'our', 'their', //
  'this', 'that', 'these', 'those', 'some', 'every', 'each',
};

/// Words ending in -s or -ed that are not verbs.
const _notVerbs = {
  'always',
  'as',
  'bus',
  'class',
  'glass',
  'his',
  'its',
  'news',
  'perhaps',
  'red',
  'sometimes',
  'this',
  'thus',
  'us',
  'was',
};

const _contractionVerbs = {
  'm': 'am',
  're': 'are',
  's': 'is',
  've': 'have',
  'll': 'will',
  'd': 'would',
};

/// Words that open a dependent clause (Purdue OWL's dependent markers).
const _dependentMarkers = {
  'although', 'though', 'because', 'if', 'unless', 'when', 'whenever', //
  'whether', 'while', 'whatever',
};

/// Dependent markers that are also prepositions: "after lunch we ran".
const _maybeDependent = {'after', 'before', 'since', 'until', 'as'};

const _negatedStems = {'ca': 'can', 'wo': 'will', 'sha': 'shall', 'ai': 'is'};

class _Token {
  const _Token(this.lower, {required this.capitalized});

  final String lower;
  final bool capitalized;
}

/// Decides whether a piece of text can stand as an independent clause. This is
/// a simple offline check, not a grammar parser, so it leans towards [unsure]
/// over a wrong [fail]: a student must not be blocked by a good sentence.
class ClauseChecker {
  const ClauseChecker(this._verbs, {required this.minWords});

  final Set<String> _verbs;
  final int minWords;

  /// [imperativeAllowed] accepts a command, whose subject is an understood
  /// "you": "Hurry, or you will miss it."
  ClauseVerdict check(String side, {bool imperativeAllowed = false}) {
    final core = _trim(side);
    final tokens = _tokenize(core);
    if (tokens.length < minWords) return ClauseVerdict.fail;

    // A comma means a main clause may follow: "When it rained, we ran".
    final opensDependent = !core.contains(',');
    final first = tokens.first.lower;
    if (opensDependent &&
        (_dependentMarkers.contains(first) ||
            (first == 'even' &&
                tokens.length > 1 &&
                {'though', 'if'}.contains(tokens[1].lower)))) {
      return ClauseVerdict.fail;
    }

    final verdict = _judge(tokens, imperativeAllowed);
    return verdict == ClauseVerdict.ok &&
            opensDependent &&
            _maybeDependent.contains(first)
        ? ClauseVerdict.unsure
        : verdict;
  }

  /// True when [side] opens with a verb, like a command.
  bool startsWithVerb(String side) {
    final tokens = _tokenize(_trim(side));
    return tokens.isNotEmpty && _firstVerb(tokens) == 0 && !_inverted(tokens);
  }

  /// True when the auxiliary comes before the subject: "does he drink tea".
  bool isInverted(String side) => _inverted(_tokenize(_trim(side)));

  static bool isNegative(String side) => RegExp(
    r"\b(?:not|no|never|neither|nobody|nothing|none|hardly|scarcely|barely|"
    r"seldom|rarely)\b|n't\b",
    caseSensitive: false,
  ).hasMatch(side);

  static String _trim(String side) =>
      side.replaceAll(RegExp(r'^[\s,;]+|[\s,;.!?]+$'), '');

  static bool _inverted(List<_Token> tokens) =>
      tokens.length > 1 &&
      _auxiliaries.contains(tokens[0].lower) &&
      _subjects.contains(tokens[1].lower);

  ClauseVerdict _judge(List<_Token> tokens, bool imperativeAllowed) {
    final verb = _firstVerb(tokens);
    if (verb < 0) {
      if (_prepositions.contains(tokens.first.lower)) return ClauseVerdict.fail;
      return tokens.any(_looksLikeVerb)
          ? ClauseVerdict.unsure
          : ClauseVerdict.fail;
    }

    final before = tokens.take(verb);
    if (before.any((t) => _subjects.contains(t.lower) || t.capitalized)) {
      return ClauseVerdict.ok;
    }
    if (verb == 0) {
      if (_inverted(tokens)) return ClauseVerdict.ok;
      return imperativeAllowed ? ClauseVerdict.unsure : ClauseVerdict.fail;
    }
    // A noun the lists can't know, as in "dogs like me".
    return before.any((t) => !_prepositions.contains(t.lower))
        ? ClauseVerdict.unsure
        : ClauseVerdict.fail;
  }

  /// A word right after a determiner is a noun, as in "the rain", even when
  /// the verb list has it.
  int _firstVerb(List<_Token> tokens) {
    for (var i = 0; i < tokens.length; i++) {
      final lower = tokens[i].lower;
      if (_auxiliaries.contains(lower)) return i;
      final afterDeterminer =
          i > 0 && _determiners.contains(tokens[i - 1].lower);
      if (_verbs.contains(lower) && !afterDeterminer) return i;
    }
    return -1;
  }

  bool _looksLikeVerb(_Token t) =>
      (t.lower.endsWith('ed') || t.lower.endsWith('s')) &&
      !_notVerbs.contains(t.lower);

  static List<_Token> _tokenize(String text) {
    final tokens = <_Token>[];
    for (final match in RegExp(r"[A-Za-z]+(?:'[A-Za-z]+)?").allMatches(text)) {
      final raw = match[0]!;
      final capitalized = raw[0] != raw[0].toLowerCase();
      final lower = raw.toLowerCase();
      final apostrophe = lower.indexOf("'");
      if (lower.endsWith("n't")) {
        final stem = lower.substring(0, lower.length - 3);
        tokens.add(
          _Token(_negatedStems[stem] ?? stem, capitalized: capitalized),
        );
      } else if (apostrophe > 0) {
        tokens.add(
          _Token(lower.substring(0, apostrophe), capitalized: capitalized),
        );
        final verb = _contractionVerbs[lower.substring(apostrophe + 1)];
        if (verb != null) tokens.add(_Token(verb, capitalized: false));
      } else {
        tokens.add(_Token(lower, capitalized: capitalized));
      }
    }
    return tokens;
  }
}
