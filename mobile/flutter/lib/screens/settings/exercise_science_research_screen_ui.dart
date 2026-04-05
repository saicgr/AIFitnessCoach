part of 'exercise_science_research_screen.dart';

/// Methods extracted from _ExerciseScienceResearchScreenState
extension __ExerciseScienceResearchScreenStateExt on _ExerciseScienceResearchScreenState {

  Widget _buildFeedDataSection({
    required Color elevated,
    required Color cardBorder,
    required Color textPrimary,
    required Color textSecondary,
    required Color textMuted,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.purple.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.cloud_upload_outlined,
                  color: AppColors.purple,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'Feed Data to RAG',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Explanation
          Text(
            'Feed your own research papers, exercise databases, and training methodologies into our RAG (Retrieval-Augmented Generation) system. This allows the AI coach to draw from even more high-quality sources when generating your personalized workout plans, making suggestions smarter and more tailored to cutting-edge science.',
            style: TextStyle(
              fontSize: 13,
              color: textSecondary,
              height: 1.6,
            ),
          ),

          const SizedBox(height: 16),

          // How it works
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.info.withValues(alpha: 0.15),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.lightbulb_outline, size: 14, color: AppColors.info),
                    const SizedBox(width: 6),
                    Text(
                      'How it works',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.info,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Upload PDFs, articles, or text files containing exercise science research. Our system processes and indexes the content, making it available as context for the AI when generating your workouts.',
                  style: TextStyle(
                    fontSize: 12,
                    color: textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Human validation note
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.success.withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.verified_user, size: 16, color: AppColors.success),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Every submitted source is reviewed and validated by a human before being added to the knowledge base.',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.success,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Warnings
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.error.withValues(alpha: 0.15),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, size: 14, color: AppColors.error),
                    const SizedBox(width: 6),
                    Text(
                      'Important guidelines',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.error,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _buildWarningItem(
                  Icons.person_off,
                  'Never feed personal or private data',
                  'Do not upload documents containing personal health records, medical history, or any identifying information.',
                  textSecondary,
                ),
                const SizedBox(height: 8),
                _buildWarningItem(
                  Icons.copyright,
                  'Never feed copyrighted material',
                  'Only upload content you have the rights to share, such as open-access papers or your own written material.',
                  textSecondary,
                ),
                const SizedBox(height: 8),
                _buildWarningItem(
                  Icons.block,
                  'Never feed misleading or wrongful data',
                  'Only upload credible, peer-reviewed, or well-sourced exercise science. Incorrect data degrades AI quality for everyone.',
                  textSecondary,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Grayed out Upload button
          SizedBox(
            width: double.infinity,
            child: AbsorbPointer(
              absorbing: true,
              child: Opacity(
                opacity: 0.4,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.purple.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.purple.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.upload_file, color: AppColors.purple, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Upload Data',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.purple,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

}
