part of 'exercise_science_research_screen.dart';


/// Data model for a research paper card.
class _ResearchPaper {
  final IconData icon;
  final Color color;
  final String title;
  final String authors;
  final String journal;
  final String year;
  final String summary;
  final List<String> keyFindings;
  final String howWeUseIt;

  const _ResearchPaper({
    required this.icon,
    required this.color,
    required this.title,
    required this.authors,
    required this.journal,
    required this.year,
    required this.summary,
    required this.keyFindings,
    required this.howWeUseIt,
  });
}

