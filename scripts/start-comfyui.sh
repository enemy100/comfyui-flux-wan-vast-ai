#!/bin/bash

# Start ComfyUI with proper configuration
# Usage: ./start-comfyui.sh [--token YOUR_TOKEN]

set -e

cd "$(dirname "$0")/../ComfyUI" || cd ComfyUI || { echo "❌ ComfyUI directory not found!"; exit 1; }

# Check for API token
API_TOKEN=""
if [ -f ".api_token" ]; then
    API_TOKEN=$(cat .api_token)
fi

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --token)
            API_TOKEN="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

echo "🚀 Starting ComfyUI..."

# Check if ComfyUI is already running
if pgrep -f "main.py" > /dev/null; then
    echo "⚠️  ComfyUI is already running!"
    read -p "Do you want to stop it and restart? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        pkill -f "main.py"
        sleep 2
    else
        exit 0
    fi
fi

# Start ComfyUI
if [ -n "$API_TOKEN" ]; then
    echo "🔑 Using API token for authentication"
    python3 main.py --listen 0.0.0.0 --port 8188 --enable-cors-header "*" &
else
    echo "⚠️  No API token provided. Starting without authentication."
    python3 main.py --listen 0.0.0.0 --port 8188 --enable-cors-header "*" &
fi

echo "✅ ComfyUI started!"
echo "📡 Access at: http://$(hostname -I | awk '{print $1}'):8188"
echo "💡 Use 'screen -r' or 'tmux attach' to reconnect if using screen/tmux"

