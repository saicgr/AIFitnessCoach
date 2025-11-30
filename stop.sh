#!/bin/bash

# AI Fitness Coach - Stop Script
# Stops all running backend and frontend servers

echo "🛑 AI Fitness Coach - Stopping Services..."
echo ""

# Kill backend (port 8000)
BACKEND_PIDS=$(lsof -ti:8000 2>/dev/null)
if [ -n "$BACKEND_PIDS" ]; then
    echo "⚙️  Stopping backend (port 8000)..."
    echo "$BACKEND_PIDS" | xargs kill -9 2>/dev/null
    echo "   ✅ Backend stopped"
else
    echo "   ℹ️  Backend not running"
fi

# Kill frontend (port 3000)
FRONTEND_PIDS=$(lsof -ti:3000 2>/dev/null)
if [ -n "$FRONTEND_PIDS" ]; then
    echo "⚙️  Stopping frontend (port 3000)..."
    echo "$FRONTEND_PIDS" | xargs kill -9 2>/dev/null
    echo "   ✅ Frontend stopped"
else
    echo "   ℹ️  Frontend not running"
fi

# Kill any uvicorn processes
UVICORN_PIDS=$(pgrep -f "uvicorn main:app" 2>/dev/null)
if [ -n "$UVICORN_PIDS" ]; then
    echo "⚙️  Stopping uvicorn processes..."
    echo "$UVICORN_PIDS" | xargs kill -9 2>/dev/null
    echo "   ✅ Uvicorn stopped"
fi

# Kill any vite processes
VITE_PIDS=$(pgrep -f "vite" 2>/dev/null)
if [ -n "$VITE_PIDS" ]; then
    echo "⚙️  Stopping vite processes..."
    echo "$VITE_PIDS" | xargs kill -9 2>/dev/null
    echo "   ✅ Vite stopped"
fi

echo ""
echo "✅ All services stopped!"
