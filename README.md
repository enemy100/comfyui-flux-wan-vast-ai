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
- **Storage**: 200GB+ disk space
- **RAM**: 32GB+

> **Cost Comparison**: Renting an RTX 4090 24GB on [vast.ai](https://cloud.vast.ai/?ref_id=350820) is significantly cheaper than using services like VEO 3.1, Runway Gen-3, Sora 2, etc., while providing full control over the infrastructure.
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
- Download Flux and WAN 2.2 models (FP8 versions)
- Configure all necessary folders
- Generate API token

### 4. Manual Setup (Alternative)

If you prefer manual setup, see the [Manual Installation Guide](MANUAL_SETUP.md).

## 📦 Installed Models

The setup script installs the following FP8 models:

### Flux Models
- `flux1-krea-dev_fp8_scaled.safetensors` - Main Flux model for image generation
- `clip_l.safetensors` - CLIP encoder
- `t5xxl_fp8_e4m3fn_scaled.safetensors` - T5XXL CLIP encoder (FP8)
- `ae.safetensors` - VAE decoder

### WAN 2.2 Models
- `wan2.2_i2v_high_noise_14B_fp8_scaled.safetensors` - High noise UNet
- `wan2.2_i2v_low_noise_14B_fp8_scaled.safetensors` - Low noise UNet
- `umt5_xxl_fp8_e4m3fn_scaled.safetensors` - UMT5 CLIP loader
- `wan_2.1_vae.safetensors` - WAN VAE

## 🔧 Configuration

### Start ComfyUI

```bash
# Using the provided script
./scripts/start-comfyui.sh

# Or manually
cd ComfyUI
python3 main.py --listen 0.0.0.0 --port 8188
```

### Expose ComfyUI (Optional)

#### Using Cloudflare Tunnel
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

- [vast.ai Dashboard (Referral Link)](https://cloud.vast.ai/?ref_id=350820)
- [ComfyUI GitHub](https://github.com/comfyanonymous/ComfyUI)
- [ComfyUI Documentation](https://github.com/comfyanonymous/ComfyUI/wiki)
- [WAN 2.2 Repository](https://github.com/tencent-ailab/IP-Adapter)
- [Flux Model Repository](https://huggingface.co/black-forest-labs)

## 📄 License

This infrastructure setup guide is provided as-is for educational purposes.

---

**Note**: Always follow vast.ai's terms of service and usage policies. This setup is optimized for video generation workloads.
