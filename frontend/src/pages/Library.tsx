import { useState, useEffect } from 'react';
import { createPortal } from 'react-dom';
import { useNavigate } from 'react-router-dom';
import { useQuery } from '@tanstack/react-query';
import { motion, AnimatePresence } from 'framer-motion';
import {
  getBodyParts,
  getLibraryExercises,
  getProgramCategories,
  getLibraryPrograms,
  type LibraryExercise,
  type LibraryProgram,
  type BodyPartCount,
  type ProgramCategoryCount,
} from '../api/client';
import { GlassCard } from '../components/ui';
import { DashboardLayout } from '../components/layout';

// Icons
const Icons = {
  Back: () => (
    <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 19l-7-7 7-7" />
    </svg>
  ),
  Search: () => (
    <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
    </svg>
  ),
  Dumbbell: () => (
    <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 6h2v12H4zM18 6h2v12h-2zM6 9h12v6H6z" />
    </svg>
  ),
  Calendar: () => (
    <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
    </svg>
  ),
  Play: () => (
    <svg className="w-5 h-5" fill="currentColor" viewBox="0 0 24 24">
      <path d="M8 5v14l11-7z" />
    </svg>
  ),
  Star: () => (
    <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M11.049 2.927c.3-.921 1.603-.921 1.902 0l1.519 4.674a1 1 0 00.95.69h4.915c.969 0 1.371 1.24.588 1.81l-3.976 2.888a1 1 0 00-.363 1.118l1.518 4.674c.3.922-.755 1.688-1.538 1.118l-3.976-2.888a1 1 0 00-1.176 0l-3.976 2.888c-.783.57-1.838-.197-1.538-1.118l1.518-4.674a1 1 0 00-.363-1.118l-3.976-2.888c-.784-.57-.38-1.81.588-1.81h4.914a1 1 0 00.951-.69l1.519-4.674z" />
    </svg>
  ),
  Clock: () => (
    <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
    </svg>
  ),
  Close: () => (
    <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
    </svg>
  ),
  ChevronDown: () => (
    <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" />
    </svg>
  ),
};

// Body part colors - text colors for badges
const bodyPartColors: Record<string, string> = {
  'Chest': 'bg-red-500/20 text-red-400 border-red-500/30',
  'Back': 'bg-blue-500/20 text-blue-400 border-blue-500/30',
  'Shoulders': 'bg-purple-500/20 text-purple-400 border-purple-500/30',
  'Biceps': 'bg-orange-500/20 text-orange-400 border-orange-500/30',
  'Triceps': 'bg-pink-500/20 text-pink-400 border-pink-500/30',
  'Core': 'bg-green-500/20 text-green-400 border-green-500/30',
  'Quadriceps': 'bg-cyan-500/20 text-cyan-400 border-cyan-500/30',
  'Hamstrings': 'bg-teal-500/20 text-teal-400 border-teal-500/30',
  'Glutes': 'bg-indigo-500/20 text-indigo-400 border-indigo-500/30',
  'Calves': 'bg-amber-500/20 text-amber-400 border-amber-500/30',
  'Forearms': 'bg-lime-500/20 text-lime-400 border-lime-500/30',
  'Hips': 'bg-rose-500/20 text-rose-400 border-rose-500/30',
  'Lower Back': 'bg-sky-500/20 text-sky-400 border-sky-500/30',
  'Neck': 'bg-violet-500/20 text-violet-400 border-violet-500/30',
  'Other': 'bg-gray-500/20 text-gray-400 border-gray-500/30',
};

// Program category colors
const categoryColors: Record<string, string> = {
  'Celebrity Workout': 'from-yellow-500/20 to-yellow-600/20 border-yellow-500/30',
  'Sport Training': 'from-green-500/20 to-green-600/20 border-green-500/30',
  'Goal-Based': 'from-blue-500/20 to-blue-600/20 border-blue-500/30',
  'Specialized Training': 'from-purple-500/20 to-purple-600/20 border-purple-500/30',
  "Women's Health": 'from-pink-500/20 to-pink-600/20 border-pink-500/30',
  'Yoga': 'from-teal-500/20 to-teal-600/20 border-teal-500/30',
  "Men's Health": 'from-indigo-500/20 to-indigo-600/20 border-indigo-500/30',
  'Pain Management': 'from-red-500/20 to-red-600/20 border-red-500/30',
  'Stretching': 'from-cyan-500/20 to-cyan-600/20 border-cyan-500/30',
};

// Compact Exercise Card Component
function ExerciseCard({
  exercise,
  isSelected,
  onClick,
}: {
  exercise: LibraryExercise;
  isSelected: boolean;
  onClick: () => void;
}) {
  return (
    <motion.div
      layout
      onClick={onClick}
      className={`
        relative p-3 rounded-xl cursor-pointer transition-all
        ${isSelected
          ? 'bg-primary/20 border-2 border-primary/50 ring-2 ring-primary/20'
          : 'bg-white/5 border border-white/10 hover:bg-white/10 hover:border-white/20'
        }
      `}
      whileHover={{ scale: 1.02 }}
      whileTap={{ scale: 0.98 }}
    >
      <div className="flex items-center gap-3">
        {/* Thumbnail */}
        <div className="w-12 h-12 rounded-lg bg-gradient-to-br from-primary/20 to-secondary/20 flex items-center justify-center flex-shrink-0 overflow-hidden">
          {exercise.gif_url ? (
            <img
              src={exercise.gif_url}
              alt=""
              className="w-full h-full object-cover"
            />
          ) : (
            <Icons.Dumbbell />
          )}
        </div>

        {/* Info */}
        <div className="flex-1 min-w-0">
          <h3 className="font-medium text-sm text-text truncate leading-tight">
            {exercise.name.replace(/_/g, ' ').replace(/Female|Male/gi, '').trim()}
          </h3>
          <span className={`inline-block text-xs px-1.5 py-0.5 rounded mt-1 ${bodyPartColors[exercise.body_part] || bodyPartColors['Other']}`}>
            {exercise.body_part}
          </span>
        </div>

        {/* Video indicator */}
        {exercise.video_url && (
          <div className="w-6 h-6 rounded-full bg-primary/30 flex items-center justify-center flex-shrink-0">
            <Icons.Play />
          </div>
        )}
      </div>
    </motion.div>
  );
}

// Exercise Detail Modal Component (renders in portal)
function ExerciseDetailModal({
  exercise,
  onClose,
}: {
  exercise: LibraryExercise;
  onClose: () => void;
}) {
  const [videoUrl, setVideoUrl] = useState<string | null>(null);
  const [videoLoading, setVideoLoading] = useState(false);
  const [videoError, setVideoError] = useState<string | null>(null);

  // Fetch presigned URL for video
  useEffect(() => {
    const fetchVideoUrl = async () => {
      if (!exercise.video_url) return;

      setVideoLoading(true);
      setVideoError(null);

      try {
        // Use the video-by-exercise endpoint which handles S3 presigned URLs
        // Use original_name (with gender suffix) for video lookup
        const response = await fetch(
          `/api/v1/videos/by-exercise/${encodeURIComponent(exercise.original_name || exercise.name)}`
        );

        if (response.ok) {
          const data = await response.json();
          setVideoUrl(data.url);
        } else {
          setVideoError('Video not available');
        }
      } catch (err) {
        console.error('Failed to fetch video URL:', err);
        setVideoError('Failed to load video');
      } finally {
        setVideoLoading(false);
      }
    };

    fetchVideoUrl();
  }, [exercise.original_name, exercise.name, exercise.video_url]);

  // Close on escape key
  useEffect(() => {
    const handleEscape = (e: KeyboardEvent) => {
      if (e.key === 'Escape') onClose();
    };
    document.addEventListener('keydown', handleEscape);
    return () => document.removeEventListener('keydown', handleEscape);
  }, [onClose]);

  // Prevent body scroll when modal is open
  useEffect(() => {
    document.body.style.overflow = 'hidden';
    return () => {
      document.body.style.overflow = 'unset';
    };
  }, []);

  const modalContent = (
    <motion.div
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0 }}
      className="fixed inset-0 z-[9999] flex items-center justify-center p-4"
      onClick={onClose}
    >
      {/* Backdrop */}
      <div className="absolute inset-0 bg-black/80 backdrop-blur-sm" />

      {/* Modal Content */}
      <motion.div
        initial={{ opacity: 0, scale: 0.95, y: 20 }}
        animate={{ opacity: 1, scale: 1, y: 0 }}
        exit={{ opacity: 0, scale: 0.95, y: 20 }}
        transition={{ type: 'spring', damping: 25, stiffness: 300 }}
        className="relative w-full max-w-4xl max-h-[90vh] overflow-hidden rounded-2xl bg-background border border-white/10 shadow-2xl"
        onClick={(e) => e.stopPropagation()}
      >
        {/* Header */}
        <div className="sticky top-0 z-10 bg-background/95 backdrop-blur-sm border-b border-white/10 p-4">
          <div className="flex items-start justify-between">
            <div>
              <h2 className="text-xl font-bold text-text">
                {exercise.name.replace(/_/g, ' ').replace(/Female|Male/gi, '').trim()}
              </h2>
              <div className="flex items-center gap-2 mt-1 flex-wrap">
                <span className={`text-xs px-2 py-0.5 rounded ${bodyPartColors[exercise.body_part] || bodyPartColors['Other']}`}>
                  {exercise.body_part}
                </span>
                {exercise.equipment && (
                  <span className="text-xs text-text-muted bg-white/5 px-2 py-0.5 rounded">
                    {exercise.equipment}
                  </span>
                )}
                {exercise.target_muscle && (
                  <span className="text-xs text-text-secondary">
                    Target: {exercise.target_muscle}
                  </span>
                )}
              </div>
            </div>
            <button
              onClick={onClose}
              className="p-2 hover:bg-white/10 rounded-lg transition-colors text-text-muted hover:text-text"
            >
              <Icons.Close />
            </button>
          </div>
        </div>

        {/* Content */}
        <div className="p-4 overflow-y-auto max-h-[calc(90vh-80px)]">
          <div className="grid md:grid-cols-2 gap-4 md:gap-6">
            {/* Video Preview - Mobile: 9:16 aspect, Desktop: 16:9 */}
            <div className="aspect-[9/16] md:aspect-video bg-black/40 rounded-xl overflow-hidden flex items-center justify-center">
              {videoLoading ? (
                <div className="text-center text-text-muted">
                  <div className="animate-spin w-8 h-8 border-2 border-primary border-t-transparent rounded-full mx-auto mb-2" />
                  <p className="text-sm">Loading video...</p>
                </div>
              ) : videoUrl ? (
                <video
                  src={videoUrl}
                  controls
                  autoPlay
                  loop
                  muted
                  playsInline
                  className="w-full h-full object-contain"
                >
                  Your browser does not support video playback.
                </video>
              ) : exercise.gif_url ? (
                <img
                  src={exercise.gif_url}
                  alt={exercise.name}
                  className="w-full h-full object-contain"
                />
              ) : videoError ? (
                <div className="text-center text-text-muted">
                  <div className="w-16 h-16 bg-white/10 rounded-full flex items-center justify-center mx-auto mb-2">
                    <Icons.Dumbbell />
                  </div>
                  <p className="text-sm">{videoError}</p>
                </div>
              ) : (
                <div className="text-center text-text-muted">
                  <div className="w-16 h-16 bg-white/10 rounded-full flex items-center justify-center mx-auto mb-2">
                    <Icons.Dumbbell />
                  </div>
                  <p className="text-sm">No preview available</p>
                </div>
              )}
            </div>

            {/* Instructions */}
            <div className="flex flex-col">
              <h3 className="font-semibold text-text mb-3 flex items-center gap-2">
                <span className="w-6 h-6 rounded-full bg-primary/20 flex items-center justify-center text-xs text-primary">
                  📋
                </span>
                Instructions
              </h3>
              <div className="flex-1 overflow-y-auto max-h-[400px] pr-2">
                {exercise.instructions ? (
                  <div className="space-y-3">
                    {exercise.instructions.split(/\n\n|\d+\.\s/).filter(Boolean).map((step, idx) => (
                      <div key={idx} className="flex gap-3">
                        <span className="w-6 h-6 rounded-full bg-primary/20 flex items-center justify-center text-xs text-primary flex-shrink-0 mt-0.5">
                          {idx + 1}
                        </span>
                        <p className="text-sm text-text-secondary leading-relaxed">
                          {step.trim()}
                        </p>
                      </div>
                    ))}
                  </div>
                ) : (
                  <p className="text-sm text-text-muted italic">
                    No instructions available for this exercise.
                  </p>
                )}
              </div>
            </div>
          </div>
        </div>
      </motion.div>
    </motion.div>
  );

  return createPortal(modalContent, document.body);
}

// Program Card Component
function ProgramCard({ program }: { program: LibraryProgram }) {
  return (
    <GlassCard className="p-4 hover:scale-[1.02] transition-all cursor-pointer">
      <div className="flex items-start justify-between mb-3">
        <div className="flex-1 min-w-0">
          <h3 className="font-semibold text-text truncate">{program.name}</h3>
          {program.celebrity_name && (
            <p className="text-sm text-secondary flex items-center gap-1">
              <Icons.Star />
              {program.celebrity_name}
            </p>
          )}
        </div>
        <span className={`text-xs px-2 py-1 rounded-full bg-gradient-to-r ${categoryColors[program.category] || 'from-gray-500/20 to-gray-600/20'}`}>
          {program.category}
        </span>
      </div>

      {program.short_description && (
        <p className="text-sm text-text-secondary mb-3 line-clamp-2">
          {program.short_description}
        </p>
      )}

      <div className="flex flex-wrap items-center gap-3 text-sm text-text-muted">
        {program.duration_weeks && (
          <span className="flex items-center gap-1">
            <Icons.Calendar />
            {program.duration_weeks} weeks
          </span>
        )}
        {program.sessions_per_week && (
          <span className="flex items-center gap-1">
            <Icons.Dumbbell />
            {program.sessions_per_week}x/week
          </span>
        )}
        {program.session_duration_minutes && (
          <span className="flex items-center gap-1">
            <Icons.Clock />
            {program.session_duration_minutes} min
          </span>
        )}
        {program.difficulty_level && (
          <span className="px-2 py-0.5 rounded bg-white/10">
            {program.difficulty_level}
          </span>
        )}
      </div>

      {program.goals && program.goals.length > 0 && (
        <div className="flex flex-wrap gap-1 mt-3">
          {program.goals.slice(0, 3).map((goal, idx) => (
            <span
              key={idx}
              className="text-xs px-2 py-0.5 rounded-full bg-accent/20 text-accent"
            >
              {goal}
            </span>
          ))}
        </div>
      )}
    </GlassCard>
  );
}

// Filter Chip Component
function FilterChip({
  label,
  count,
  active,
  onClick,
  colorClass,
}: {
  label: string;
  count?: number;
  active: boolean;
  onClick: () => void;
  colorClass?: string;
}) {
  return (
    <button
      onClick={onClick}
      className={`
        px-3 py-1.5 rounded-full text-sm font-medium transition-all whitespace-nowrap
        ${active
          ? `bg-gradient-to-r ${colorClass || 'from-primary/30 to-primary/20'} border border-primary/40 text-white`
          : 'bg-white/5 border border-white/10 text-text-secondary hover:bg-white/10 hover:text-text'
        }
      `}
    >
      {label}
      {count !== undefined && (
        <span className={`ml-1 ${active ? 'text-white/70' : 'text-text-muted'}`}>
          ({count})
        </span>
      )}
    </button>
  );
}

export default function Library() {
  const navigate = useNavigate();
  const [activeTab, setActiveTab] = useState<'exercises' | 'programs'>('exercises');
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedBodyPart, setSelectedBodyPart] = useState<string | null>(null);
  const [selectedCategory, setSelectedCategory] = useState<string | null>(null);
  const [selectedExercise, setSelectedExercise] = useState<LibraryExercise | null>(null);

  // Fetch body parts
  const { data: bodyParts, isLoading: loadingBodyParts } = useQuery({
    queryKey: ['library', 'body-parts'],
    queryFn: getBodyParts,
  });

  // Fetch program categories
  const { data: categories, isLoading: loadingCategories } = useQuery({
    queryKey: ['library', 'categories'],
    queryFn: getProgramCategories,
  });

  // Fetch exercises with filters
  const { data: exercises, isLoading: loadingExercises } = useQuery({
    queryKey: ['library', 'exercises', selectedBodyPart, searchQuery],
    queryFn: () => getLibraryExercises({
      body_part: selectedBodyPart || undefined,
      search: searchQuery || undefined,
      limit: 2000,  // Increased to show all deduplicated exercises (~1872)
    }),
    enabled: activeTab === 'exercises',
  });

  // Fetch programs with filters
  const { data: programs, isLoading: loadingPrograms } = useQuery({
    queryKey: ['library', 'programs', selectedCategory, searchQuery],
    queryFn: () => getLibraryPrograms({
      category: selectedCategory || undefined,
      search: searchQuery || undefined,
      limit: 50,
    }),
    enabled: activeTab === 'programs',
  });

  const isLoading = activeTab === 'exercises'
    ? loadingExercises || loadingBodyParts
    : loadingPrograms || loadingCategories;

  // Close exercise detail when changing filters
  useEffect(() => {
    setSelectedExercise(null);
  }, [selectedBodyPart, searchQuery, activeTab]);

  return (
    <DashboardLayout>
      <div className="space-y-4">
        {/* Header */}
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-4">
            <button
              onClick={() => navigate('/')}
              className="p-2 hover:bg-white/10 rounded-xl transition-colors text-text-secondary hover:text-text"
            >
              <Icons.Back />
            </button>
            <div>
              <h1 className="text-2xl font-bold text-text">Library</h1>
              <p className="text-sm text-text-secondary">
                Browse exercises and workout programs
              </p>
            </div>
          </div>
        </div>

        {/* Tab Switcher */}
        <div className="flex gap-2 p-1 bg-white/5 rounded-xl">
          <button
            onClick={() => {
              setActiveTab('exercises');
              setSearchQuery('');
              setSelectedExercise(null);
            }}
            className={`flex-1 flex items-center justify-center gap-2 px-4 py-2.5 rounded-lg font-medium transition-all ${
              activeTab === 'exercises'
                ? 'bg-primary text-white shadow-lg'
                : 'text-text-secondary hover:text-text hover:bg-white/5'
            }`}
          >
            <Icons.Dumbbell />
            Exercises
          </button>
          <button
            onClick={() => {
              setActiveTab('programs');
              setSearchQuery('');
              setSelectedExercise(null);
            }}
            className={`flex-1 flex items-center justify-center gap-2 px-4 py-2.5 rounded-lg font-medium transition-all ${
              activeTab === 'programs'
                ? 'bg-secondary text-white shadow-lg'
                : 'text-text-secondary hover:text-text hover:bg-white/5'
            }`}
          >
            <Icons.Calendar />
            Programs
          </button>
        </div>

        {/* Search Bar */}
        <div className="relative">
          <input
            type="text"
            placeholder={activeTab === 'exercises' ? 'Search exercises...' : 'Search programs...'}
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="w-full pl-10 pr-4 py-3 bg-white/5 border border-white/10 rounded-xl text-text placeholder:text-text-muted focus:outline-none focus:border-primary/50 focus:ring-1 focus:ring-primary/50"
          />
          <div className="absolute left-3 top-1/2 -translate-y-1/2 text-text-muted">
            <Icons.Search />
          </div>
        </div>

        {/* Filters */}
        <div className="overflow-x-auto pb-2 -mx-4 px-4">
          <div className="flex gap-2">
            {activeTab === 'exercises' ? (
              <>
                <FilterChip
                  label="All"
                  active={!selectedBodyPart}
                  onClick={() => setSelectedBodyPart(null)}
                />
                {bodyParts?.map((bp: BodyPartCount) => (
                  <FilterChip
                    key={bp.name}
                    label={bp.name}
                    count={bp.count}
                    active={selectedBodyPart === bp.name}
                    onClick={() => setSelectedBodyPart(bp.name)}
                    colorClass={bodyPartColors[bp.name]}
                  />
                ))}
              </>
            ) : (
              <>
                <FilterChip
                  label="All"
                  active={!selectedCategory}
                  onClick={() => setSelectedCategory(null)}
                />
                {categories?.map((cat: ProgramCategoryCount) => (
                  <FilterChip
                    key={cat.name}
                    label={cat.name}
                    count={cat.count}
                    active={selectedCategory === cat.name}
                    onClick={() => setSelectedCategory(cat.name)}
                    colorClass={categoryColors[cat.name]}
                  />
                ))}
              </>
            )}
          </div>
        </div>

        {/* Content */}
        {isLoading ? (
          <div className="flex items-center justify-center py-12">
            <div className="animate-spin w-8 h-8 border-2 border-primary border-t-transparent rounded-full" />
          </div>
        ) : activeTab === 'exercises' ? (
          <>
            {/* Exercise count */}
            <div className="text-sm text-text-muted">
              {exercises?.length || 0} exercises found
            </div>

            {/* Exercise Grid */}
            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-2">
              {exercises && exercises.length > 0 ? (
                exercises.map((exercise: LibraryExercise) => (
                  <ExerciseCard
                    key={exercise.id}
                    exercise={exercise}
                    isSelected={selectedExercise?.id === exercise.id}
                    onClick={() => setSelectedExercise(
                      selectedExercise?.id === exercise.id ? null : exercise
                    )}
                  />
                ))
              ) : (
                <div className="col-span-full">
                  <GlassCard className="p-8 text-center">
                    <div className="w-16 h-16 bg-primary/20 rounded-full flex items-center justify-center mx-auto mb-4">
                      <Icons.Dumbbell />
                    </div>
                    <h3 className="font-semibold text-text mb-2">No exercises found</h3>
                    <p className="text-text-secondary text-sm">
                      Try adjusting your search or filters
                    </p>
                  </GlassCard>
                </div>
              )}
            </div>

            {/* Exercise Detail Modal - renders via portal */}
            <AnimatePresence>
              {selectedExercise && (
                <ExerciseDetailModal
                  exercise={selectedExercise}
                  onClose={() => setSelectedExercise(null)}
                />
              )}
            </AnimatePresence>
          </>
        ) : (
          <div className="space-y-3">
            {programs && programs.length > 0 ? (
              programs.map((program: LibraryProgram) => (
                <ProgramCard key={program.id} program={program} />
              ))
            ) : (
              <GlassCard className="p-8 text-center">
                <div className="w-16 h-16 bg-secondary/20 rounded-full flex items-center justify-center mx-auto mb-4">
                  <Icons.Calendar />
                </div>
                <h3 className="font-semibold text-text mb-2">No programs found</h3>
                <p className="text-text-secondary text-sm">
                  Try adjusting your search or filters
                </p>
              </GlassCard>
            )}
          </div>
        )}
      </div>
    </DashboardLayout>
  );
}
