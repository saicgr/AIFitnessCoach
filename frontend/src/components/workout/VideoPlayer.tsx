import { useState, useRef, useEffect, useCallback } from 'react';
import type { VideoResponse } from '../../api/client';

interface VideoPlayerProps {
  videoInfo: VideoResponse | null;
  videoLoading: boolean;
  selectedGender: 'male' | 'female';
  onGenderChange: (gender: 'male' | 'female') => void;
  exerciseName: string;
  exerciseIndex: number;
  totalExercises: number;
  muscleGroup?: string;
  isResting: boolean;
  restTimer: number | null;
  onSkipRest: () => void;
  exerciseCompleted: boolean;
}

// Get icon for muscle group
const getMuscleGroupIcon = (muscleGroup?: string) => {
  const group = muscleGroup?.toLowerCase() || '';
  if (group.includes('chest')) return '💪';
  if (group.includes('back')) return '🔙';
  if (group.includes('shoulder')) return '🤷';
  if (group.includes('leg') || group.includes('quad') || group.includes('hamstring')) return '🦵';
  if (group.includes('arm') || group.includes('bicep') || group.includes('tricep')) return '💪';
  if (group.includes('core') || group.includes('ab')) return '🎯';
  if (group.includes('glute')) return '🍑';
  return '🏋️';
};

// Format time as MM:SS or H:MM:SS
const formatTime = (seconds: number) => {
  const hours = Math.floor(seconds / 3600);
  const mins = Math.floor((seconds % 3600) / 60);
  const secs = seconds % 60;
  if (hours > 0) {
    return `${hours}:${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
  }
  return `${mins}:${secs.toString().padStart(2, '0')}`;
};

export default function VideoPlayer({
  videoInfo,
  videoLoading,
  selectedGender,
  onGenderChange,
  exerciseName,
  exerciseIndex,
  totalExercises,
  muscleGroup,
  isResting,
  restTimer,
  onSkipRest,
  exerciseCompleted,
}: VideoPlayerProps) {
  const videoRef = useRef<HTMLVideoElement>(null);
  const [isPlaying, setIsPlaying] = useState(true);
  const [isMuted, setIsMuted] = useState(true);

  // Sync video element state with our state when video loads or changes
  useEffect(() => {
    const video = videoRef.current;
    if (!video) return;

    const handlePlay = () => setIsPlaying(true);
    const handlePause = () => setIsPlaying(false);
    const handleVolumeChange = () => setIsMuted(video.muted);

    video.addEventListener('play', handlePlay);
    video.addEventListener('pause', handlePause);
    video.addEventListener('volumechange', handleVolumeChange);

    // Reset state when new video loads
    setIsPlaying(true);
    setIsMuted(true);

    return () => {
      video.removeEventListener('play', handlePlay);
      video.removeEventListener('pause', handlePause);
      video.removeEventListener('volumechange', handleVolumeChange);
    };
  }, [videoInfo?.url]);

  const togglePlay = useCallback(() => {
    const video = videoRef.current;
    if (!video) return;

    if (video.paused) {
      video.play().catch((err) => {
        console.warn('Video play failed:', err);
      });
    } else {
      video.pause();
    }
  }, []);

  const toggleMute = useCallback(() => {
    const video = videoRef.current;
    if (!video) return;

    video.muted = !video.muted;
  }, []);

  return (
    <div className="relative w-full h-full bg-black">
      {/* Male/Female Toggle - only show if both variants exist */}
      {videoInfo?.has_male && videoInfo?.has_female && (
        <div className="absolute top-4 right-4 z-10 flex bg-black/50 backdrop-blur rounded-full p-1">
          <button
            type="button"
            onClick={() => onGenderChange('male')}
            className={`px-3 py-1 rounded-full text-sm font-medium transition-colors ${
              selectedGender === 'male' ? 'bg-primary text-white' : 'text-white/60 hover:text-white'
            }`}
          >
            Male
          </button>
          <button
            type="button"
            onClick={() => onGenderChange('female')}
            className={`px-3 py-1 rounded-full text-sm font-medium transition-colors ${
              selectedGender === 'female' ? 'bg-primary text-white' : 'text-white/60 hover:text-white'
            }`}
          >
            Female
          </button>
        </div>
      )}

      {/* Exercise video or Placeholder */}
      {videoInfo?.url ? (
        <>
          <video
            ref={videoRef}
            key={videoInfo.url}
            src={videoInfo.url}
            autoPlay
            loop
            muted
            playsInline
            className="w-full h-full object-contain bg-black"
          />
          {/* Video Controls */}
          <div className="absolute bottom-4 right-4 flex gap-2 z-20">
            <button
              type="button"
              onClick={togglePlay}
              className="bg-black/70 backdrop-blur-sm p-3 rounded-full text-white hover:bg-black/90 transition-colors shadow-lg"
              aria-label={isPlaying ? 'Pause video' : 'Play video'}
            >
              {isPlaying ? (
                <svg className="w-6 h-6" fill="currentColor" viewBox="0 0 24 24">
                  <path d="M6 19h4V5H6v14zm8-14v14h4V5h-4z" />
                </svg>
              ) : (
                <svg className="w-6 h-6" fill="currentColor" viewBox="0 0 24 24">
                  <path d="M8 5v14l11-7z" />
                </svg>
              )}
            </button>
            <button
              type="button"
              onClick={toggleMute}
              className="bg-black/70 backdrop-blur-sm p-3 rounded-full text-white hover:bg-black/90 transition-colors shadow-lg"
              aria-label={isMuted ? 'Unmute video' : 'Mute video'}
            >
              {isMuted ? (
                <svg className="w-6 h-6" fill="currentColor" viewBox="0 0 24 24">
                  <path d="M16.5 12c0-1.77-1.02-3.29-2.5-4.03v2.21l2.45 2.45c.03-.2.05-.41.05-.63zm2.5 0c0 .94-.2 1.82-.54 2.64l1.51 1.51C20.63 14.91 21 13.5 21 12c0-4.28-2.99-7.86-7-8.77v2.06c2.89.86 5 3.54 5 6.71zM4.27 3L3 4.27 7.73 9H3v6h4l5 5v-6.73l4.25 4.25c-.67.52-1.42.93-2.25 1.18v2.06c1.38-.31 2.63-.95 3.69-1.81L19.73 21 21 19.73l-9-9L4.27 3zM12 4L9.91 6.09 12 8.18V4z" />
                </svg>
              ) : (
                <svg className="w-6 h-6" fill="currentColor" viewBox="0 0 24 24">
                  <path d="M3 9v6h4l5 5V4L7 9H3zm13.5 3c0-1.77-1.02-3.29-2.5-4.03v8.05c1.48-.73 2.5-2.25 2.5-4.02zM14 3.23v2.06c2.89.86 5 3.54 5 6.71s-2.11 5.85-5 6.71v2.06c4.01-.91 7-4.49 7-8.77s-2.99-7.86-7-8.77z" />
                </svg>
              )}
            </button>
          </div>
        </>
      ) : (
        <div className="w-full h-full bg-gradient-to-br from-primary/30 via-surface to-cyan-900/30 flex flex-col items-center justify-center">
          {videoLoading ? (
            <>
              <div className="w-16 h-16 border-4 border-primary border-t-transparent rounded-full animate-spin mb-4" />
              <p className="text-white/60 text-lg">Loading video...</p>
            </>
          ) : (
            <>
              <div className="text-8xl mb-6 opacity-80">{getMuscleGroupIcon(muscleGroup)}</div>
              <h1 className="text-3xl font-bold text-white text-center px-8 mb-2">{exerciseName}</h1>
              <p className="text-white/60 text-lg">{muscleGroup || 'Full Body'}</p>
              <p className="text-white/40 text-sm mt-4">
                Exercise {exerciseIndex + 1} of {totalExercises}
              </p>
            </>
          )}
        </div>
      )}

      {/* Rest Timer Overlay */}
      {isResting && restTimer !== null && (
        <div className="absolute inset-0 bg-black/70 flex flex-col items-center justify-center z-20">
          <p className="text-white/60 text-lg mb-2">Rest Time</p>
          <div className="text-7xl font-bold text-white font-mono mb-6">
            {formatTime(restTimer)}
          </div>
          <button
            type="button"
            onClick={onSkipRest}
            className="px-8 py-3 bg-white/10 hover:bg-white/20 text-white rounded-full transition-colors text-lg"
          >
            Skip Rest
          </button>
        </div>
      )}

      {/* Exercise completed badge */}
      {exerciseCompleted && !isResting && (
        <div className="absolute top-4 left-1/2 -translate-x-1/2 z-10">
          <div className="bg-emerald-500 text-white px-4 py-2 rounded-full font-semibold flex items-center gap-2 shadow-lg shadow-emerald-500/30">
            <svg className="w-5 h-5" fill="currentColor" viewBox="0 0 20 20">
              <path fillRule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clipRule="evenodd" />
            </svg>
            Exercise Complete
          </div>
        </div>
      )}
    </div>
  );
}
