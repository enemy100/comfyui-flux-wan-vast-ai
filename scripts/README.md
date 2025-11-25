# Setup Scripts

Scripts to automate ComfyUI installation and management on vast.ai instances.

## Available Scripts

### `setup-comfyui.sh`
Complete automated setup of ComfyUI with all dependencies and custom nodes.

**Usage:**
```bash
chmod +x setup-comfyui.sh
./setup-comfyui.sh
```

### `start-comfyui.sh`
Start ComfyUI with proper configuration.

**Usage:**
```bash
chmod +x start-comfyui.sh
./start-comfyui.sh

# Or with API token
./start-comfyui.sh --token YOUR_TOKEN
```

## Notes

- Make scripts executable: `chmod +x script.sh`
- Run as root or with sudo if needed
- Check logs if something fails

