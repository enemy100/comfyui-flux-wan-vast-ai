# ComfyUI Flux & WAN 2.2 Setup on vast.ai

Complete guide and automated scripts to set up ComfyUI with Flux 1.dev and WAN 2.2 models on vast.ai for automated video generation.

## 🎯 Overview

This repository contains scripts and documentation to deploy ComfyUI with Flux and WAN 2.2 models on vast.ai, providing a cost-effective GPU solution for video generation workflows.

> **Related Projects**:
> - [n8n ComfyUI Video Generation Workflow](https://github.com/enemy100/n8n-comfyui-workflow) - The automation workflow that uses this infrastructure
> - [n8n ComfyUI Integration Guide](https://github.com/enemy100/n8n-comfyui-integration) - How to connect n8n with this ComfyUI instance

## 🖥️ Recommended Hardware

### Minimum Requirements
- **GPU**: RTX 3060 12GB (works with FP8 models)
- **Storage**: 100GB+ disk space
- **RAM**: 16GB+

### Recommended for Best Performance
- **GPU**: RTX 4090 24GB (tested and recommended)
- **Storage**: 100GB+ disk space
- **RAM**: 32GB+

> **Cost Comparison**: Renting an RTX 4090 24GB on [vast.ai](https://cloud.vast.ai/?ref_id=350820) is significantly cheaper than using services like VEO 3.1, Runway Gen-3, Sora 2, etc., while providing full control over the infrastructure.
>
> <img width="823" height="118" alt="image" src="https://github.com/user-attachments/assets/01e3ea93-00e5-49ae-81a8-016541269601" />

>
> 💡 **Support this project**: Use our [referral link](https://cloud.vast.ai/?ref_id=350820) when signing up for vast.ai!

## 🚀 Quick Start

### 1. Create Account on vast.ai

1. Sign up at [vast.ai using our referral link](https://cloud.vast.ai/?ref_id=350820) (helps support this project)
2. Add payment method
3. Navigate to **Create** → **Instance**

### 2. Select GPU Instance

**Recommended Configuration:**
- **GPU**: RTX 4090 24GB (or RTX 3060 12GB minimum)
- **Disk Space**: 100GB+ (200GB recommended)
- **Location**: Choose closest to your location for lower latency

**Filter Settings:**
- GPU: `RTX 4090` or `RTX 3060`
- VRAM: `>= 12GB`
- Disk: `>= 100GB`
- Reliability: `> 95%`

### 3. Automated Setup

Once the instance is created, SSH into it and run:

```bash
# Clone this repository
git clone https://github.com/enemy100/comfyui-flux-wan-vast-ai.git
cd comfyui-flux-wan-vast-ai

# Make scripts executable
chmod +x scripts/*.sh

# Run the automated setup
./scripts/setup-comfyui.sh
```

This script will:
- Install all system dependencies
- Clone and configure ComfyUI
- Install required custom nodes
- Configure all necessary folders
- Generate API token

**Note**: The setup script prepares the environment. To download models, you can either:

**Option A: Use the download scripts** (Recommended)
```bash
# After setup-comfyui.sh completes
cd ComfyUI
chmod +x ../download-modelos-flux.sh ../download-modelos-wan22.sh
../download-modelos-flux.sh .
../download-modelos-wan22.sh .
```

The download scripts are interactive and will:
- Check available disk space
- Download models from HuggingFace
- Install custom nodes automatically
- Verify file integrity
- Show progress and summaries

**Option B: Download manually** from HuggingFace repositories (see [Installed Models](#-installed-models) section for links)

### 4. Manual Setup (Alternative)

If you prefer manual setup:

1. **Install ComfyUI** following the [official documentation](https://github.com/comfyanonymous/ComfyUI)
2. **Use the download scripts** provided in this repository:
   ```bash
   ./download-modelos-flux.sh /path/to/ComfyUI
   ./download-modelos-wan22.sh /path/to/ComfyUI
   ```
3. **Or download models manually** from HuggingFace (see [Installed Models](#-installed-models) section for direct links)

## 📦 Installed Models

The setup script installs the following FP8 models. You can also use the provided download scripts for manual installation:

### Flux Models (Required for Image Generation)

**Location**: `ComfyUI/models/`

#### Diffusion Models (UNET)
- **`models/diffusion_models/flux1-krea-dev_fp8_scaled.safetensors`** (Required)
  - Main Flux model for image generation
  - Recommended for portraits/people
  - Source: [Comfy-Org/FLUX.1-Krea-dev_ComfyUI](https://huggingface.co/Comfy-Org/FLUX.1-Krea-dev_ComfyUI)
- **`models/unet/flux1-dev-fp8.safetensors`** (Optional, ~23GB)
  - Alternative Flux model, more versatile
  - For GPUs with 16GB+ VRAM

#### Text Encoders (CLIP)
- **`models/text_encoders/t5xxl_fp8_e4m3fn_scaled.safetensors`** (Required)
  - T5XXL CLIP encoder in FP8 format
  - Recommended for RTX 3060 12GB
  - Source: [comfyanonymous/flux_text_encoders](https://huggingface.co/comfyanonymous/flux_text_encoders)
- **`models/text_encoders/t5xxl_fp16.safetensors`** (Optional)
  - T5XXL CLIP encoder in FP16 format
  - For GPUs with 16GB+ VRAM
- **`models/text_encoders/clip_l.safetensors`** (Required)
  - CLIP-L encoder
  - Source: [comfyanonymous/flux_text_encoders](https://huggingface.co/comfyanonymous/flux_text_encoders)

#### VAE
- **`models/vae/ae.safetensors`** (Required)
  - VAE decoder for Flux
  - Source: [Comfy-Org/Lumina_Image_2.0_Repackaged](https://huggingface.co/Comfy-Org/Lumina_Image_2.0_Repackaged)

### WAN 2.2 Models (Required for Video Generation)

**Location**: `ComfyUI/models/`

#### Diffusion Models (UNET)
- **`models/diffusion_models/wan2.2_i2v_high_noise_14B_fp8_scaled.safetensors`** (Required, ~14GB)
  - High noise UNet - Recommended (better quality, more details)
  - Main WAN 2.2 model for video generation
  - Source: [Comfy-Org/Wan_2.2_ComfyUI_Repackaged](https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged)
- **`models/diffusion_models/wan2.2_i2v_low_noise_14B_fp8_scaled.safetensors`** (Alternative, ~14GB)
  - Low noise UNet - Less noise, smoother results
  - Alternative to high_noise version

#### Text Encoders (CLIP)
- **`models/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors`** (Required, ~6.3GB)
  - UMT5-XXL CLIP loader for WAN 2.2
  - Source: [Comfy-Org/Wan_2.2_ComfyUI_Repackaged](https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged)

#### VAE
- **`models/vae/wan_2.1_vae.safetensors`** (Required)
  - WAN 2.1 VAE for video generation
  - Source: [Comfy-Org/Wan_2.1_ComfyUI_repackaged](https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged)

#### VFI (Frame Interpolation)
- **`models/vfi/film_net_fp32.pt`** (Required, ~132MB)
  - FILM VFI model for frame interpolation (increasing FPS)
  - Source: [nguu/film-pytorch](https://huggingface.co/nguu/film-pytorch) or [lucas-hug/film](https://huggingface.co/lucas-hug/film)

#### LoRAs (Optional but Recommended)
- **`models/loras/wan2.2_i2v_lightx2v_4steps_lora_v1_high_noise.safetensors`** (Optional)
  - LoRA for high noise model - improves video quality
- **`models/loras/wan2.2_i2v_lightx2v_4steps_lora_v1_low_noise.safetensors`** (Optional)
  - LoRA for low noise model - improves video quality
- Source: [Comfy-Org/Wan_2.2_ComfyUI_Repackaged](https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged)

### Custom Nodes (Required)

**Location**: `ComfyUI/custom_nodes/`

The following custom nodes are **required** for the workflow to function:

1. **ComfyUI-KJNodes** - Contains WanVideoNAG node
   - Repository: [kijai/ComfyUI-KJNodes](https://github.com/kijai/ComfyUI-KJNodes)
   
2. **ComfyUI-NegiTools** - Seed Generator
   - Repository: [natto-maki/ComfyUI-NegiTools](https://github.com/natto-maki/ComfyUI-NegiTools)
   
3. **ComfyUI-VideoHelperSuite (VHS)** - Video Combine and utilities
   - Repository: [Kosinkadink/ComfyUI-VideoHelperSuite](https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite)
   
4. **comfyui-frame-interpolation** - FILM VFI for frame interpolation
   - Repository: [Fannovel16/comfyui-frame-interpolation](https://github.com/Fannovel16/comfyui-frame-interpolation)
   
5. **rgthree-comfy** - Power Lora Loader
   - Repository: [rgthree/rgthree-comfy](https://github.com/rgthree/rgthree-comfy)

6. **ComfyUI-FLUX** - DualCLIPLoader for Flux models
   - Install via ComfyUI Manager or manually
   
7. **ComfyUI-Manager** - For easy node management
   - Repository: [ltdrdata/ComfyUI-Manager](https://github.com/ltdrdata/ComfyUI-Manager)

### Manual Download Scripts

This repository includes automated download scripts in the root directory:

- **`download-modelos-flux.sh`** - Downloads all Flux models
  - Downloads UNET, CLIP encoders, and VAE
  - Interactive prompts for optional models
  - Verifies disk space before downloading
  
- **`download-modelos-wan22.sh`** - Downloads all WAN 2.2 models and custom nodes
  - Downloads UNET, CLIP, VAE, FILM VFI, and optional LoRAs
  - Installs all required custom nodes automatically
  - Checks disk space (requires ~26GB minimum)

**Usage:**
```bash
# Make scripts executable
chmod +x download-modelos-flux.sh download-modelos-wan22.sh

# Download Flux models
./download-modelos-flux.sh /path/to/ComfyUI

# Download WAN 2.2 models (includes custom nodes installation)
./download-modelos-wan22.sh /path/to/ComfyUI
```

**Features:**
- ✅ Interactive prompts for optional downloads
- ✅ Disk space verification
- ✅ Automatic custom node installation via Git
- ✅ File integrity checks
- ✅ Progress indicators
- ✅ Skips already downloaded files (with confirmation)
- ✅ Creates necessary directory structure
- ✅ Color-coded output for better readability

## 🔧 Configuration

### Start ComfyUI

```bash
# Using the provided script
./scripts/start-comfyui.sh

# Or manually
cd ComfyUI
python3 main.py --listen 0.0.0.0 --port 8188
```

### Expose ComfyUI

#### Using vast.ai Built-in Tunnel (Recommended for vast.ai Instances)

**vast.ai automatically provides access when you create an instance:**

1. **Check your vast.ai dashboard** for the instance
2. **Find the "Connect" or "Access" section**
3. **Copy the provided URL** (includes token automatically)
4. **Use this URL** to access ComfyUI - it automatically routes to port 8188

**No additional setup needed!** vast.ai handles the tunneling automatically.

#### Using Cloudflare Tunnel (Alternative)

If you need an alternative tunnel (not using vast.ai or want additional tunnel):

```bash
# Install cloudflared
wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64
chmod +x cloudflared-linux-amd64
mv cloudflared-linux-amd64 /usr/local/bin/cloudflared

# Create tunnel
cloudflared tunnel --url http://localhost:8188
```

This will give you a public URL like `https://xxxxx.trycloudflare.com`

## 📊 Monitoring

### Check GPU Usage
```bash
watch -n 1 nvidia-smi
```

### Check Disk Space
```bash
df -h
```

### Check ComfyUI Logs
```bash
# If using systemd
journalctl -u comfyui -f

# If running directly
# Logs appear in terminal
```

## 🔗 Integration with n8n

After setting up ComfyUI, you'll need to connect it with n8n:

1. See the [n8n ComfyUI Integration Guide](https://github.com/enemy100/n8n-comfyui-integration) for detailed instructions
2. Configure network access (tunnel, ports, etc.)
3. Get your ComfyUI URL and API token
4. Use these credentials in the n8n workflow

## 💰 Cost Optimization

### Tips to Reduce Costs

1. **Stop instance when not in use**
   - vast.ai charges per hour
   - Stop instances during downtime

2. **Use spot instances**
   - Lower cost but may be interrupted
   - Good for development/testing

3. **Monitor usage**
   - Check vast.ai dashboard regularly
   - Set up billing alerts

4. **Optimize model loading**
   - Use FP8 models for lower VRAM usage
   - Unload models when not needed

## 🐛 Troubleshooting

### ComfyUI won't start
- Check if port 8188 is available: `netstat -tulpn | grep 8188`
- Check Python version: `python3 --version` (should be 3.8+)
- Check GPU: `nvidia-smi`

### Out of memory errors
- Use FP8 models instead of full precision
- Reduce batch size
- Close other applications

### Models not loading
- Check file paths
- Verify model files are complete
- Check disk space

### API not accessible
- Check firewall rules
- Verify `--listen 0.0.0.0` is set
- Check if port is exposed in vast.ai settings

## 📝 Maintenance

### Update ComfyUI
```bash
cd ComfyUI
git pull
pip install -r requirements.txt
```

### Update Custom Nodes
```bash
cd ComfyUI/custom_nodes
for dir in */; do
  cd "$dir"
  git pull
  cd ..
done
```

### Backup Models
```bash
# Create backup of models
tar -czf comfyui-models-backup.tar.gz ComfyUI/models/
```

## 🔗 Useful Links

### Infrastructure
- [vast.ai Dashboard (Referral Link)](https://cloud.vast.ai/?ref_id=350820)
- [ComfyUI GitHub](https://github.com/comfyanonymous/ComfyUI)
- [ComfyUI Documentation](https://github.com/comfyanonymous/ComfyUI/wiki)

### Model Repositories
- **Flux Models**:
  - [Comfy-Org/FLUX.1-Krea-dev_ComfyUI](https://huggingface.co/Comfy-Org/FLUX.1-Krea-dev_ComfyUI)
  - [comfyanonymous/flux_text_encoders](https://huggingface.co/comfyanonymous/flux_text_encoders)
  - [Comfy-Org/Lumina_Image_2.0_Repackaged](https://huggingface.co/Comfy-Org/Lumina_Image_2.0_Repackaged)
- **WAN 2.2 Models**:
  - [Comfy-Org/Wan_2.2_ComfyUI_Repackaged](https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged)
  - [Comfy-Org/Wan_2.1_ComfyUI_repackaged](https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged)
  - [wan-research/wan2.1](https://huggingface.co/wan-research/wan2.1)
- **FILM VFI**:
  - [nguu/film-pytorch](https://huggingface.co/nguu/film-pytorch)
  - [lucas-hug/film](https://huggingface.co/lucas-hug/film)

### Custom Nodes
- [ComfyUI-KJNodes](https://github.com/kijai/ComfyUI-KJNodes) - WanVideoNAG
- [ComfyUI-NegiTools](https://github.com/natto-maki/ComfyUI-NegiTools) - Seed Generator
- [ComfyUI-VideoHelperSuite](https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite) - VHS
- [comfyui-frame-interpolation](https://github.com/Fannovel16/comfyui-frame-interpolation) - FILM VFI
- [rgthree-comfy](https://github.com/rgthree/rgthree-comfy) - Power Lora Loader
- [ComfyUI-Manager](https://github.com/ltdrdata/ComfyUI-Manager) - Node Manager

## 📄 License

This infrastructure setup guide is provided as-is for educational purposes.

---

**Note**: Always follow vast.ai's terms of service and usage policies. This setup is optimized for video generation workloads.
