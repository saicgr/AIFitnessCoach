#!/bin/bash

# AI Fitness Coach - Start Script
# Starts both backend (Python/FastAPI) and frontend (React/Vite)

set -e

# Load nvm if available
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

echo "🚀 AI Fitness Coach - Starting Services..."
echo ""

# Kill any existing processes on our ports
echo "🧹 Cleaning up old processes..."
lsof -ti:8000 2>/dev/null | xargs kill -9 2>/dev/null || true
lsof -ti:3000 2>/dev/null | xargs kill -9 2>/dev/null || true

# Create a session reset marker with timestamp
# Frontend will detect this and clear localStorage
echo "🔄 Marking session for reset..."
RESET_MARKER_FILE="frontend/public/session-reset.json"
echo "{\"resetAt\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\", \"version\": \"$(date +%s)\"}" > "$RESET_MARKER_FILE"

# Create named pipes for log prefixing
BACKEND_PIPE=$(mktemp -u)
FRONTEND_PIPE=$(mktemp -u)
mkfifo "$BACKEND_PIPE"
mkfifo "$FRONTEND_PIPE"

# Cleanup function
cleanup() {
    echo ""
    echo "🛑 Stopping all services..."
    kill $BACKEND_PID $FRONTEND_PID 2>/dev/null || true
    rm -f "$BACKEND_PIPE" "$FRONTEND_PIPE"
    exit 0
}

# Trap Ctrl+C to kill both processes
trap cleanup INT TERM

# Start log prefixers (adds [BACKEND] or [FRONTEND] prefix to each line)
sed 's/^/[BACKEND]  /' < "$BACKEND_PIPE" &
sed 's/^/[FRONTEND] /' < "$FRONTEND_PIPE" &

# Start backend with unbuffered output
echo "⚙️  Starting Python backend on port 8000..."
cd backend
PYTHONUNBUFFERED=1 python3 -m uvicorn main:app --reload --host 0.0.0.0 --port 8000 --log-level info > "$BACKEND_PIPE" 2>&1 &
BACKEND_PID=$!
cd ..

# Wait for backend to be ready
echo "⏳ Waiting for backend to start..."
sleep 3

# Start frontend
echo "⚙️  Starting React frontend on port 3000..."
cd frontend
npm run dev > "$FRONTEND_PIPE" 2>&1 &
FRONTEND_PID=$!
cd ..

# Wait for frontend to start
sleep 3

echo ""
echo "✅ Services started!"
echo "============================================"
echo "Frontend:  http://localhost:3000"
echo "Backend:   http://localhost:8000"
echo "API Docs:  http://localhost:8000/docs"
echo "============================================"
echo ""
echo "💡 To run workout generation test manually:"
echo "   cd backend && python3 test_workout_generation.py"
echo ""
echo "📋 All logs will appear below with [BACKEND] or [FRONTEND] prefix"
echo "Press Ctrl+C to stop all services"
echo ""

# Wait for either process to exit
wait $BACKEND_PID $FRONTEND_PID
