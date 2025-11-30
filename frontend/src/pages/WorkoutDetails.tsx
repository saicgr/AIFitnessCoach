import { useEffect } from 'react';
import { useParams, useNavigate, Link } from 'react-router-dom';
import { useQuery, useMutation } from '@tanstack/react-query';
import { getWorkout, deleteWorkout } from '../api/client';
import { useAppStore } from '../store';
import type { Workout } from '../types';
import { GlassCard } from '../components/ui';

export default function WorkoutDetails() {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const { setCurrentWorkout, removeWorkout, setActiveWorkoutId } = useAppStore();

  const { data: workout, isLoading } = useQuery<Workout>({
    queryKey: ['workout', id],
    queryFn: () => getWorkout(id!),
    enabled: !!id,
  });

  useEffect(() => {
    if (workout) {
      setCurrentWorkout(workout);
    }
  }, [workout, setCurrentWorkout]);

  const deleteMutation = useMutation({
    mutationFn: () => deleteWorkout(id!),
    onSuccess: () => {
      removeWorkout(id!);
      navigate('/');
    },
  });

  const handleStartWorkout = () => {
    if (workout) {
      setActiveWorkoutId(workout.id);
      navigate(`/workout/${workout.id}/active`);
    }
  };

  if (isLoading) {
    return (
      <div className="min-h-screen bg-background flex items-center justify-center">
        <div className="text-text-secondary">Loading workout...</div>
      </div>
    );
  }

  if (!workout) {
    return (
      <div className="min-h-screen bg-background flex items-center justify-center">
        <div className="text-center">
          <p className="text-text-secondary mb-4">Workout not found</p>
          <Link to="/" className="text-primary font-semibold hover:underline">
            Go back home
          </Link>
        </div>
      </div>
    );
  }

  const isCompleted = !!workout.completed_at;

  return (
    <div className="min-h-screen bg-background">
      {/* Header */}
      <header className="bg-primary text-white p-6">
        <div className="max-w-2xl mx-auto">
          <button
            onClick={() => navigate('/')}
            className="text-white/70 hover:text-white mb-2 flex items-center gap-1"
          >
            ← Back
          </button>
          <h1 className="text-2xl font-bold">{workout.name}</h1>
          <div className="flex gap-3 mt-2 text-white/80">
            <span className="capitalize">{workout.type}</span>
            <span>•</span>
            <span className="capitalize">{workout.difficulty}</span>
            <span>•</span>
            <span>{workout.duration_minutes} min</span>
          </div>
          {isCompleted && (
            <span className="inline-block mt-2 px-3 py-1 bg-secondary text-white text-sm rounded-full">
              Completed
            </span>
          )}
        </div>
      </header>

      <main className="max-w-2xl mx-auto p-4 space-y-6">
        {/* Action Buttons */}
        {!isCompleted && (
          <div className="flex gap-3">
            <button
              onClick={handleStartWorkout}
              className="flex-1 py-4 px-6 bg-primary text-white rounded-xl font-semibold hover:bg-primary-dark"
            >
              Start Workout
            </button>
            <Link
              to="/chat"
              className="py-4 px-6 bg-secondary text-white rounded-xl font-semibold hover:bg-secondary/90"
            >
              Modify with AI
            </Link>
          </div>
        )}

        {/* Exercises */}
        <section>
          <h2 className="text-lg font-bold text-primary mb-4">
            Exercises ({workout.exercises.length})
          </h2>
          <div className="space-y-3">
            {workout.exercises.map((exercise, index) => (
              <GlassCard
                key={index}
                className="p-4"
              >
                <div className="flex justify-between items-start">
                  <div>
                    <div className="flex items-center gap-2">
                      <span className="w-6 h-6 bg-primary/20 text-primary rounded-full flex items-center justify-center text-sm font-semibold">
                        {index + 1}
                      </span>
                      <h3 className="font-semibold text-text">{exercise.name}</h3>
                    </div>
                    <div className="mt-2 text-sm text-text-secondary ml-8">
                      {exercise.sets} sets × {exercise.reps} reps
                      {exercise.weight && ` @ ${exercise.weight} lbs`}
                    </div>
                  </div>
                  <div className="text-sm text-text-muted">
                    Rest: {exercise.rest_seconds}s
                  </div>
                </div>
                {exercise.notes && (
                  <p className="mt-2 text-sm text-text-muted ml-8 italic">
                    {exercise.notes}
                  </p>
                )}
              </GlassCard>
            ))}
          </div>
        </section>

        {/* Notes */}
        {workout.notes && (
          <GlassCard className="p-4">
            <h2 className="font-semibold text-text mb-2">Notes</h2>
            <p className="text-text-secondary">{workout.notes}</p>
          </GlassCard>
        )}

        {/* Delete Button */}
        <button
          onClick={() => {
            if (confirm('Are you sure you want to delete this workout?')) {
              deleteMutation.mutate();
            }
          }}
          disabled={deleteMutation.isPending}
          className="w-full py-3 text-coral hover:bg-coral/10 rounded-xl transition-colors"
        >
          {deleteMutation.isPending ? 'Deleting...' : 'Delete Workout'}
        </button>
      </main>
    </div>
  );
}
