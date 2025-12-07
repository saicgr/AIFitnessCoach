# Drag and Drop Workout Swapping Implementation

## Overview
Successfully implemented drag and drop functionality for swapping workout dates in the AI Fitness Coach app using @dnd-kit library.

## Changes Made

### 1. Dependencies Installed
```bash
npm install @dnd-kit/core @dnd-kit/sortable @dnd-kit/utilities
```

**Packages added:**
- `@dnd-kit/core` - Core drag and drop functionality
- `@dnd-kit/sortable` - Sortable utilities
- `@dnd-kit/utilities` - Helper utilities for transforms

---

### 2. Backend Changes

#### File: `/backend/models/schemas.py`
**Added SwapWorkoutsRequest schema:**
```python
class SwapWorkoutsRequest(BaseModel):
    workout_id: int
    new_date: str  # ISO date, e.g., "2024-11-25"
    reason: Optional[str] = None
```

#### File: `/backend/api/v1/workouts_db.py`
**Added `/swap` endpoint:**
- **Route:** `POST /api/v1/workouts-db/swap`
- **Functionality:**
  - Moves a workout to a new date
  - If another workout exists on the target date, swaps their dates
  - Logs the swap with reason for audit trail
  - Uses `workout_changes` table to track all date changes
  - Updates `last_modified_at` and `last_modified_method` fields

**Key Features:**
- Atomic swapping (both workouts updated in transaction)
- Detailed logging of changes for AI coach context
- Proper error handling with 404 for missing workouts
- Date comparison uses SQL range queries for accuracy

---

### 3. Frontend Changes

#### File: `/frontend/src/api/client.ts`
**Added swapWorkout API function:**
```typescript
export const swapWorkout = async (params: {
  workout_id: number;
  new_date: string;
  reason?: string;
}): Promise<{ success: boolean; old_date: string; new_date: string; swapped_with?: number }> => {
  const { data } = await api.post('/workouts-db/swap', params);
  return data;
};
```

#### File: `/frontend/src/components/DraggableWorkout.tsx`
**New component for draggable workout cards:**
- Uses `useDraggable` hook from @dnd-kit
- Handles drag transforms with CSS utilities
- Shows visual feedback (opacity) during drag
- Passes workout data to drop handler

#### File: `/frontend/src/components/DroppableDay.tsx`
**New component for droppable day containers:**
- Uses `useDroppable` hook from @dnd-kit
- Visual feedback when hovering (ring and background color)
- Passes date information to drag handler

#### File: `/frontend/src/components/WorkoutTimelineWithDnD.tsx`
**New enhanced timeline component with drag and drop:**

**Key Features:**
- `DndContext` wrapper with `closestCenter` collision detection
- Drag start/end handlers to manage state
- `DragOverlay` for smooth dragging experience
- Reason modal for capturing why user moved the workout
- Integration with React Query for automatic data refresh
- Prevents moving workout to same date
- Loading states during swap operation

**Components:**
- `WorkoutCard` - Displays workout information
- `DraggableWorkoutCard` - Wraps WorkoutCard with drag functionality
- `DroppableDayWrapper` - Makes each day a valid drop target
- `RestDayCard` - Shows when no workout scheduled
- `ReasonModal` - Captures user's reason for moving workout

#### File: `/frontend/src/pages/Home.tsx`
**Updated import:**
```typescript
import WorkoutTimeline from '../components/WorkoutTimelineWithDnD';
```

---

## How It Works

### User Flow:
1. User sees their weekly workout schedule
2. User clicks and holds on a workout card
3. Workout card follows cursor with visual feedback
4. Droppable areas highlight when hovering
5. User drops workout on a different day
6. Modal appears asking for reason
7. User enters reason (optional) and confirms
8. Backend swaps the workouts
9. UI refreshes with new schedule

### Technical Flow:
1. **Drag Start:**
   - `handleDragStart` captures the dragged workout
   - Active workout stored in state for overlay

2. **Drag Over:**
   - Droppable days highlight via `isOver` state
   - Visual ring and background color applied

3. **Drag End:**
   - `handleDragEnd` receives source and target
   - Validation: Same date check
   - Shows reason modal

4. **Swap Confirmation:**
   - User provides reason
   - `swapMutation` calls backend API
   - Backend swaps dates and logs change
   - Query invalidation refreshes data

5. **UI Update:**
   - React Query refetches workouts
   - Timeline re-renders with new schedule
   - Modal closes and state resets

---

## Database Changes

The swap operation logs to `workout_changes` table:

```sql
INSERT INTO workout_changes (
    workout_id,
    user_id,
    change_type,
    field_changed,
    old_value,
    new_value,
    change_source,
    change_reason
) VALUES (...)
```

**Fields logged:**
- `change_type`: "date_swap"
- `field_changed`: "scheduled_date"
- `old_value`: Previous date (JSON)
- `new_value`: New date (JSON)
- `change_source`: "user_drag_drop"
- `change_reason`: User's provided reason

This data is valuable for:
- AI coach understanding user preferences
- Identifying patterns in workout scheduling
- Providing personalized recommendations

---

## Error Handling

### Backend:
- 404 if workout not found
- 500 for database errors
- Proper logging at all stages

### Frontend:
- Alert on swap failure
- Loading states during operation
- Query invalidation on success
- Graceful modal dismissal

---

## Testing Checklist

- [x] Install dependencies successfully
- [x] Backend endpoint accepts POST requests
- [x] Swap logic works for two workouts
- [x] Swap logic works when target date is empty
- [x] Reason is logged to database
- [x] Frontend shows draggable cursor
- [x] Drop zones highlight on hover
- [x] Modal appears after drop
- [x] Workout list refreshes after swap
- [x] Error handling works

---

## Files Modified

### Backend (3 files):
1. `/backend/models/schemas.py` - Added SwapWorkoutsRequest
2. `/backend/api/v1/workouts_db.py` - Added /swap endpoint

### Frontend (3 new files, 2 modified):
1. `/frontend/src/api/client.ts` - Added swapWorkout function
2. `/frontend/src/components/DraggableWorkout.tsx` - NEW
3. `/frontend/src/components/DroppableDay.tsx` - NEW
4. `/frontend/src/components/WorkoutTimelineWithDnD.tsx` - NEW
5. `/frontend/src/pages/Home.tsx` - Updated import
6. `/frontend/package.json` - Added dependencies

---

## Commands to Run

```bash
# Install dependencies (already done)
cd frontend && npm install @dnd-kit/core @dnd-kit/sortable @dnd-kit/utilities

# Run the app
# Terminal 1 - Backend
cd backend && uvicorn main:app --reload

# Terminal 2 - Frontend
cd frontend && npm run dev
```

---

## API Endpoint Documentation

### POST /api/v1/workouts-db/swap

**Request Body:**
```json
{
  "workout_id": 123,
  "new_date": "2024-11-25",
  "reason": "I have a meeting on the original day"
}
```

**Response:**
```json
{
  "success": true,
  "old_date": "2024-11-24",
  "new_date": "2024-11-25",
  "swapped_with": 124
}
```

**Error Responses:**
- 404: Workout not found
- 500: Internal server error

---

## Future Enhancements

Potential improvements:
1. Drag and drop between weeks (long-distance dragging)
2. Multi-select for moving multiple workouts
3. Undo/redo functionality
4. Drag to delete (drag to trash icon)
5. Visual calendar view with drag and drop
6. Mobile touch support optimization
7. Accessibility improvements (keyboard navigation)
8. Animation improvements for smoother transitions

---

## Notes

- The implementation follows the project's CLAUDE.md guidelines
- All error handling is in place
- Logging uses the project's emoji prefix system
- The swap endpoint integrates with existing RAG system for AI context
- No mock data - all real API integration
- Modern React patterns used (hooks, React Query)
- TypeScript for type safety

---

**Implementation Status:** ✅ COMPLETE
**Last Updated:** 2025-11-24
