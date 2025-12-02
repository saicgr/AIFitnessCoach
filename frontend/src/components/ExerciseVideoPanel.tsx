import { useEffect, useState, useRef } from 'react';
import { motion } from 'framer-motion';
import { getExerciseVideoInfo, type VideoResponse } from '../api/client';
import type { WorkoutExercise } from '../types';

interface ExerciseVideoPanelProps {
  exercise: WorkoutExercise;
  onClose: () => void;
}

export default function ExerciseVideoPanel({ exercise, onClose }: ExerciseVideoPanelProps) {
  const [videoInfo, setVideoInfo] = useState<VideoResponse | null>(null);
  const [videoLoading, setVideoLoading] = useState(true);
  const [isPlaying, setIsPlaying] = useState(false);
  const videoRef = useRef<HTMLVideoElement>(null);

  useEffect(() => {
    const fetchVideo = async () => {
      setVideoLoading(true);
      setVideoInfo(null);
      setIsPlaying(false);

      try {
        const info = await getExerciseVideoInfo(exercise.name);
        setVideoInfo(info);
      } catch (error) {
        console.error('Error fetching exercise video:', error);
      } finally {
        setVideoLoading(false);
      }
    };

    fetchVideo();
  }, [exercise.name]);

  const togglePlayPause = () => {
    if (videoRef.current) {
      if (isPlaying) {
        videoRef.current.pause();
      } else {
        videoRef.current.play();
      }
      setIsPlaying(!isPlaying);
    }
  };

  return (
    <div className="h-full flex flex-col">
      {/* Header */}
      <div className="p-4 border-b border-white/10 flex items-center justify-between flex-shrink-0">
        <div className="flex items-center gap-3">
          <div className="p-2 bg-primary/20 rounded-xl text-primary">
            <svg className="w-5 h-5" fill="currentColor" viewBox="0 0 24 24">
              <path d="M8 5v14l11-7z" />
            </svg>
          </div>
          <div>
            <h2 className="text-lg font-semibold text-text">{exercise.name}</h2>
            <p className="text-xs text-text-secondary">Exercise Demo</p>
          </div>
        </div>
        <button
          onClick={onClose}
          className="p-2 hover:bg-white/10 rounded-xl transition-colors text-text-secondary hover:text-text"
        >
          <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
          </svg>
        </button>
      </div>

      {/* Video Section - Takes full height */}
      <div className="flex-1 relative bg-black flex items-center justify-center">
        {videoLoading ? (
          <div className="flex flex-col items-center gap-3">
            <div className="w-10 h-10 border-3 border-primary border-t-transparent rounded-full animate-spin" />
            <p className="text-text-secondary text-sm">Loading video...</p>
          </div>
        ) : videoInfo?.url ? (
          <>
            <video
              ref={videoRef}
              src={videoInfo.url}
              className="w-full h-full object-contain"
              loop
              playsInline
              onPlay={() => setIsPlaying(true)}
              onPause={() => setIsPlaying(false)}
            />
            {/* Play/Pause Overlay */}
            <button
              onClick={togglePlayPause}
              className="absolute inset-0 flex items-center justify-center group"
            >
              <motion.div
                className={`
                  w-16 h-16 rounded-full flex items-center justify-center
                  ${isPlaying ? 'bg-black/40 opacity-0 group-hover:opacity-100' : 'bg-primary shadow-lg shadow-primary/30'}
                  transition-opacity
                `}
                whileHover={{ scale: 1.1 }}
                whileTap={{ scale: 0.95 }}
              >
                {isPlaying ? (
                  <svg className="w-8 h-8 text-white" fill="currentColor" viewBox="0 0 24 24">
                    <path d="M6 19h4V5H6v14zm8-14v14h4V5h-4z" />
                  </svg>
                ) : (
                  <svg className="w-8 h-8 text-white ml-1" fill="currentColor" viewBox="0 0 24 24">
                    <path d="M8 5v14l11-7z" />
                  </svg>
                )}
              </motion.div>
            </button>
          </>
        ) : (
          <div className="text-center p-4">
            <svg className="w-12 h-12 text-text-muted mx-auto mb-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M15 10l4.553-2.276A1 1 0 0121 8.618v6.764a1 1 0 01-1.447.894L15 14M5 18h8a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v8a2 2 0 002 2z" />
            </svg>
            <p className="text-text-secondary text-sm">No video available</p>
          </div>
        )}
      </div>
    </div>
  );
}
