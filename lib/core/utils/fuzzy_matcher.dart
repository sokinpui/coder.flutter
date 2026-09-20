class ScoredMatch<T> {
  const ScoredMatch({
    required this.item,
    required this.score,
    required this.index,
  });

  final T item;
  final int score;
  final int index;
}

class FuzzyMatcher {
  static List<T> match<T>({
    required String query,
    required List<T> items,
    required List<String> Function(T item) targetSelector,
  }) {
    final cleanQuery = query.trim().toLowerCase();
    if (cleanQuery.isEmpty) {
      return items;
    }

    final terms = cleanQuery
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .toList();
    if (terms.isEmpty) {
      return items;
    }

    final scored = <ScoredMatch<T>>[];
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      final targets = targetSelector(
        item,
      ).map((t) => t.toLowerCase()).where((t) => t.isNotEmpty).toList();

      final score = scoreItem(terms, targets);
      if (score != null) {
        scored.add(ScoredMatch(item: item, score: score, index: i));
      }
    }

    scored.sort((a, b) {
      final cmp = b.score.compareTo(a.score);
      if (cmp != 0) return cmp;
      return a.index.compareTo(b.index);
    });

    return scored.map((s) => s.item).toList();
  }

  static int? scoreItem(List<String> terms, List<String> targets) {
    if (terms.isEmpty || targets.isEmpty) {
      return null;
    }

    var totalScore = 0;
    for (final term in terms) {
      int? bestTermScore;
      for (final target in targets) {
        final score = computeScore(term, target);
        if (score == null) continue;
        if (bestTermScore == null || score > bestTermScore) {
          bestTermScore = score;
        }
      }
      if (bestTermScore == null) {
        return null;
      }
      totalScore += bestTermScore;
    }

    return totalScore;
  }

  static int? computeScore(String query, String target) {
    if (query.isEmpty) return 0;
    if (target.isEmpty) return null;

    if (query == target) return 10000;
    if (target.startsWith(query)) {
      return 5000 + (100 - target.length.clamp(0, 100));
    }

    final subIndex = target.indexOf(query);
    if (subIndex != -1) {
      return 3000 - subIndex * 10 + (100 - target.length.clamp(0, 100));
    }

    var qIdx = 0;
    var tIdx = 0;
    var score = 0;
    var consecutive = 0;
    var firstMatchIdx = -1;
    var lastMatchIdx = -1;

    while (qIdx < query.length && tIdx < target.length) {
      if (query[qIdx] == target[tIdx]) {
        if (firstMatchIdx == -1) firstMatchIdx = tIdx;
        lastMatchIdx = tIdx;

        var charScore = 10;
        if (tIdx == 0) {
          charScore += 30;
        } else {
          final prev = target[tIdx - 1];
          if (prev == '/' ||
              prev == '-' ||
              prev == '_' ||
              prev == '.' ||
              prev == ' ') {
            charScore += 25;
          }
        }

        if (consecutive > 0) {
          charScore += consecutive * 15;
        }
        consecutive++;
        score += charScore;
        qIdx++;
      } else {
        consecutive = 0;
      }
      tIdx++;
    }

    if (qIdx < query.length) {
      return null;
    }

    final spread = (lastMatchIdx - firstMatchIdx + 1) - query.length;
    score -= spread * 2;
    return score;
  }
}
