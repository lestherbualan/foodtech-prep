/// Represents a selectable subject group for timed exam configuration.
class ExamSubject {
  const ExamSubject({
    required this.id,
    required this.label,
    required this.subtitle,
    this.icon,
  });

  /// `null` means "All Subjects".
  final String? id;
  final String label;
  final String subtitle;
  final String? icon;

  bool get isAll => id == null;

  /// Maps a full subject name to its abbreviation (e.g. "Food Laws and Regulations" → "FLR").
  static String abbreviate(String fullName) {
    return _nameToAbbr[fullName] ?? fullName;
  }

  static const Map<String, String> _nameToAbbr = {
    'Physical, Chemical, Biological, and Microbiological Principles': 'PCBMP',
    'Food Processing, Preservation, and Food Engineering': 'FPPE',
    'Quality Systems and Sensory Evaluation of Food': 'QSSEF',
    'Food Laws and Regulations': 'FLR',
  };

  static const List<ExamSubject> options = [
    ExamSubject(
      id: null,
      label: 'All Subjects',
      subtitle: 'Mixed timed exam across all major board exam subject groups',
    ),
    ExamSubject(
      id: 'PCBMP',
      label: 'PCBMP',
      subtitle:
          'Physical, Chemical, Biological, and Microbiological Principles',
    ),
    ExamSubject(
      id: 'FPPE',
      label: 'FPPE',
      subtitle: 'Food Processing, Preservation, and Food Engineering',
    ),
    ExamSubject(
      id: 'QSSEF',
      label: 'QSSEF',
      subtitle: 'Quality Systems and Sensory Evaluation of Food',
    ),
    ExamSubject(id: 'FLR', label: 'FLR', subtitle: 'Food Laws and Regulations'),
  ];
}
