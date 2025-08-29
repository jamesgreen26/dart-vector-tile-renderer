import 'dart:ui';

class LabelSpace {
  final Rect space;
  final List<_LabelRect> _occupied = [];
  final Set<String> texts = {};

  LabelSpace(this.space);

  bool canAccept(String? text) =>
      text != null && text.isNotEmpty && !texts.contains(text);

  bool canOccupy(String text, Rect rect) =>
      canAccept(text) &&
      space.containsCompletely(rect) &&
      !_occupied.any((existing) => existing.space.overlaps(rect));

  void occupy(String text, Rect box) {
    final boxWithMargin = Rect.fromLTRB(box.left - margin, box.top - margin,
        box.right + (2 * margin), box.bottom + (2 * margin));
    _occupied.add(_LabelRect(text, boxWithMargin));
    texts.add(text);
  }

  // Debug version of canAccept with print statements
  bool canAcceptDebug(String? text) {
    print('=== canAcceptDebug Debug Info ===');
    print('Input text: $text');
    print('text != null: ${text != null}');
    print(
        'text.isNotEmpty: ${text != null ? text.isNotEmpty : 'N/A (text is null)'}');
    print('texts.contains(text): ${texts.contains(text)}');
    print('Current texts set: $texts');
    print('texts set size: ${texts.length}');

    final result = text != null && text.isNotEmpty && !texts.contains(text);
    print('Final canAccept result: $result');
    print('================================');

    return result;
  }

  // Debug version of canOccupy with print statements
  bool canOccupyDebug(String text, Rect rect) {
    // Calculate all variables first
    final canAcceptResult = canAccept(text);
    final spaceContains = space.containsCompletely(rect);
    final spaceContainsTopLeft = space.contains(rect.topLeft);
    final spaceContainsBottomRight = space.contains(rect.bottomRight);

    // Check overlaps with existing occupied rects
    bool hasOverlap = false;
    final List<MapEntry<int, bool>> overlapResults = [];
    for (int i = 0; i < _occupied.length; i++) {
      final existing = _occupied[i];
      final overlaps = existing.space.overlaps(rect);
      overlapResults.add(MapEntry(i, overlaps));
      if (overlaps) {
        hasOverlap = true;
      }
    }

    final result = canAcceptResult && spaceContains && !hasOverlap;

    // Now print all the information
    print('=== canOccupyDebug Debug Info ===');
    print('Input text: "$text"');
    print('Input rect: $rect');
    print('  - rect.left: ${rect.left}');
    print('  - rect.top: ${rect.top}');
    print('  - rect.right: ${rect.right}');
    print('  - rect.bottom: ${rect.bottom}');
    print('  - rect.width: ${rect.width}');
    print('  - rect.height: ${rect.height}');

    print('Label space: $space');
    print('  - space.left: ${space.left}');
    print('  - space.top: ${space.top}');
    print('  - space.right: ${space.right}');
    print('  - space.bottom: ${space.bottom}');
    print('  - space.width: ${space.width}');
    print('  - space.height: ${space.height}');

    print('canAccept("$text") result: $canAcceptResult');

    print('space.containsCompletely(rect): $spaceContains');
    print('  - space.contains(rect.topLeft): $spaceContainsTopLeft');
    print('  - space.contains(rect.bottomRight): $spaceContainsBottomRight');

    print('Number of occupied rects: ${_occupied.length}');
    for (final entry in overlapResults) {
      final i = entry.key;
      final overlaps = entry.value;
      final existing = _occupied[i];
      print('Occupied rect $i: "${existing.text}" at ${existing.space}');
      print('  - overlaps with input rect: $overlaps');
    }
    print('Any overlaps found: $hasOverlap');

    print('Final canOccupy result: $result');
    print('  - canAccept: $canAcceptResult');
    print('  - spaceContains: $spaceContains');
    print('  - !hasOverlap: ${!hasOverlap}');
    print('=================================');

    return result;
  }
}

extension _RectExtension on Rect {
  bool containsCompletely(Rect other) =>
      contains(other.topLeft) && contains(other.bottomRight);
}

const margin = 2.0;

class _LabelRect {
  final Rect space;
  final String text;
  _LabelRect(this.text, this.space);
}
