#!/bin/bash

# ComfyUI Setup Script for vast.ai
# This script automates the installation of ComfyUI and required dependencies

set -e

echo "🚀 Starting ComfyUI setup on vast.ai..."

# Update system
echo "📦 Updating system packages..."
apt update && apt upgrade -y

# Install dependencies
echo "📦 Installing dependencies..."
apt install -y python3 python3-pip git wget curl build-essential

# Install CUDA toolkit (if not already installed)
echo "🔧 Checking CUDA installation..."
if ! command -v nvcc &> /dev/null; then
    echo "⚠️  CUDA not found. Please ensure NVIDIA drivers are installed."
fi

# Clone ComfyUI
echo "📥 Cloning ComfyUI..."
if [ -d "ComfyUI" ]; then
    echo "⚠️  ComfyUI directory already exists. Skipping clone."
else
    git clone https://github.com/comfyanonymous/ComfyUI.git
fi

cd ComfyUI

# Install PyTorch with CUDA support
echo "📦 Installing PyTorch with CUDA..."
pip3 install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121

# Install ComfyUI requirements
echo "📦 Installing ComfyUI requirements..."
pip3 install -r requirements.txt

# Install custom nodes
echo "📦 Installing custom nodes..."
cd custom_nodes

# ComfyUI Manager
if [ ! -d "ComfyUI-Manager" ]; then
    git clone https://github.com/ltdrdata/ComfyUI-Manager.git
    cd ComfyUI-Manager
    pip3 install -r requirements.txt
    cd ..
fi

# IP-Adapter (for WAN 2.2)
if [ ! -d "IP-Adapter" ]; then
    git clone https://github.com/tencent-ailab/IP-Adapter.git
fi

cd ..

# Create necessary directories
echo "📁 Creating directories..."
mkdir -p models/checkpoints
mkdir -p models/clip
mkdir -p models/vae
mkdir -p models/unet
mkdir -p output/images
mkdir -p output/video
mkdir -p input

# Generate API token
echo "🔑 Generating API token..."
API_TOKEN=$(python3 -c "import secrets; print(secrets.token_urlsafe(32))")
echo "API Token: $API_TOKEN"
echo "⚠️  Save this token! You'll need it for n8n configuration."
echo "$API_TOKEN" > .api_token

# Setup firewall
echo "🔥 Configuring firewall..."
ufw allow 8188/tcp
ufw --force enable

echo "✅ ComfyUI setup complete!"
echo ""
echo "📝 Next steps:"
echo "1. Download models to the respective folders"
echo "2. Start ComfyUI with: python3 main.py --listen 0.0.0.0 --port 8188"
echo "3. Use the API token saved in .api_token for n8n configuration"
echo ""
echo "💡 Tip: Use 'screen' or 'tmux' to keep ComfyUI running after SSH disconnect"

