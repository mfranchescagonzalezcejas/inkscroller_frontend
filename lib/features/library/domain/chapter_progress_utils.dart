import 'entities/chapter.dart';

String formatChapterNumber(double number) {
  if (number == number.truncateToDouble()) {
    return number.toInt().toString();
  }

  return number.toString();
}

List<Chapter> orderChaptersForProgress(List<Chapter> chapters) {
  final List<Chapter> ordered = List<Chapter>.from(chapters);
  ordered.sort(_compareChaptersForProgress);
  return ordered;
}

List<Chapter> chaptersUpToTarget(
  List<Chapter> chapters,
  String targetChapterId,
) {
  final List<Chapter> ordered = orderChaptersForProgress(chapters);
  final int targetIndex = ordered.indexWhere(
    (chapter) => chapter.id == targetChapterId,
  );

  if (targetIndex < 0) {
    return const <Chapter>[];
  }

  return ordered.sublist(0, targetIndex + 1);
}

int _compareChaptersForProgress(Chapter left, Chapter right) {
  final double? leftNumber = left.number;
  final double? rightNumber = right.number;

  if (leftNumber != null && rightNumber != null) {
    final int byNumber = leftNumber.compareTo(rightNumber);
    if (byNumber != 0) {
      return byNumber;
    }
  } else if (leftNumber != null) {
    return -1;
  } else if (rightNumber != null) {
    return 1;
  }

  final int byDate = _compareNullableDate(left.date, right.date);
  if (byDate != 0) {
    return byDate;
  }

  final String leftLabel = (left.title ?? left.id).trim().toLowerCase();
  final String rightLabel = (right.title ?? right.id).trim().toLowerCase();
  final int byLabel = leftLabel.compareTo(rightLabel);
  if (byLabel != 0) {
    return byLabel;
  }

  return left.id.compareTo(right.id);
}

int _compareNullableDate(DateTime? left, DateTime? right) {
  if (left != null && right != null) {
    return left.compareTo(right);
  }
  if (left != null) {
    return -1;
  }
  if (right != null) {
    return 1;
  }
  return 0;
}
