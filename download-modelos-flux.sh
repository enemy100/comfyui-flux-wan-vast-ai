#!/bin/bash

# Script para baixar modelos Flux necessários para o workflow
# Uso: ./download-modelos-flux.sh [CAMINHO_COMFYUI]
# Exemplo: ./download-modelos-flux.sh /caminho/para/ComfyUI

set -e  # Parar em caso de erro

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para imprimir mensagens coloridas
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Função para baixar arquivo com verificação
download_file() {
    local url=$1
    local output_path=$2
    local filename=$(basename "$output_path")
    local dir=$(dirname "$output_path")
    
    # Criar diretório se não existir
    mkdir -p "$dir"
    
    # Verificar se arquivo já existe
    if [ -f "$output_path" ]; then
        local size=$(du -h "$output_path" | cut -f1)
        print_warning "Arquivo já existe: $filename ($size)"
        read -p "Deseja baixar novamente? (s/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Ss]$ ]]; then
            print_info "Pulando download de $filename"
            return 0
        fi
        rm -f "$output_path"
    fi
    
    print_info "Baixando $filename..."
    print_info "URL: $url"
    print_info "Destino: $output_path"
    
    # Baixar com wget ou curl
    if command -v wget &> /dev/null; then
        wget --progress=bar:force:noscroll --show-progress -O "$output_path" "$url" || {
            print_error "Erro ao baixar $filename"
            return 1
        }
    elif command -v curl &> /dev/null; then
        curl -L --progress-bar -o "$output_path" "$url" || {
            print_error "Erro ao baixar $filename"
            return 1
        }
    else
        print_error "wget ou curl não encontrado. Instale um deles para continuar."
        exit 1
    fi
    
    if [ -f "$output_path" ]; then
        local size=$(du -h "$output_path" | cut -f1)
        print_success "Download concluído: $filename ($size)"
        return 0
    else
        print_error "Arquivo não foi baixado corretamente: $filename"
        return 1
    fi
}

# Obter caminho do ComfyUI
if [ -z "$1" ]; then
    # Tentar encontrar ComfyUI no diretório atual ou comum
    if [ -d "./ComfyUI" ]; then
        COMFYUI_PATH="./ComfyUI"
    elif [ -d "../ComfyUI" ]; then
        COMFYUI_PATH="../ComfyUI"
    else
        print_error "Caminho do ComfyUI não fornecido e não encontrado automaticamente."
        echo "Uso: $0 [CAMINHO_COMFYUI]"
        echo "Exemplo: $0 /home/user/ComfyUI"
        exit 1
    fi
else
    COMFYUI_PATH="$1"
fi

# Verificar se o caminho existe
if [ ! -d "$COMFYUI_PATH" ]; then
    print_error "Diretório não encontrado: $COMFYUI_PATH"
    exit 1
fi

print_info "Usando ComfyUI em: $COMFYUI_PATH"

# Definir caminhos das pastas
MODELS_DIR="$COMFYUI_PATH/models"
UNET_DIR="$MODELS_DIR/unet"
DIFFUSION_MODELS_DIR="$MODELS_DIR/diffusion_models"
TEXT_ENCODERS_DIR="$MODELS_DIR/text_encoders"
VAE_DIR="$MODELS_DIR/vae"
LORAS_DIR="$MODELS_DIR/loras/Flux"

print_info "=== Iniciando download dos modelos Flux ==="
echo

# 1. UNET - Flux Krea Dev (RECOMENDADO para pessoas/retratos)
print_info "1. Baixando UNET: flux1-krea-dev_fp8_scaled.safetensors"
download_file \
    "https://huggingface.co/Comfy-Org/FLUX.1-Krea-dev_ComfyUI/resolve/main/split_files/diffusion_models/flux1-krea-dev_fp8_scaled.safetensors" \
    "$DIFFUSION_MODELS_DIR/flux1-krea-dev_fp8_scaled.safetensors"
echo

# 2. UNET - Flux Dev fp8 (alternativa - mais versátil)
print_info "2. Baixando UNET (opcional): flux1-dev-fp8.safetensors"
print_warning "Este arquivo é grande (~23GB). Deseja baixar? (s/N): "
read -p "" -n 1 -r
echo
if [[ $REPLY =~ ^[Ss]$ ]]; then
    download_file \
        "https://huggingface.co/Comfy-Org/flux1-dev/resolve/main/flux1-dev-fp8.safetensors" \
        "$UNET_DIR/flux1-dev-fp8.safetensors"
fi
echo

# 3. CLIP - T5-XXL fp8 (RECOMENDADO para RTX 3060 12GB)
print_info "3. Baixando CLIP: t5xxl_fp8_e4m3fn_scaled.safetensors"
download_file \
    "https://huggingface.co/comfyanonymous/flux_text_encoders/resolve/main/t5xxl_fp8_e4m3fn_scaled.safetensors" \
    "$TEXT_ENCODERS_DIR/t5xxl_fp8_e4m3fn_scaled.safetensors"
echo

# 4. CLIP - T5-XXL fp16 (OPCIONAL - para placas mais potentes)
print_info "4. Baixando CLIP (opcional): t5xxl_fp16.safetensors"
print_warning "Este arquivo é para placas com 16GB+ VRAM. Deseja baixar? (s/N): "
read -p "" -n 1 -r
echo
if [[ $REPLY =~ ^[Ss]$ ]]; then
    download_file \
        "https://huggingface.co/comfyanonymous/flux_text_encoders/resolve/main/t5xxl_fp16.safetensors" \
        "$TEXT_ENCODERS_DIR/t5xxl_fp16.safetensors"
fi
echo

# 5. CLIP - CLIP-L
print_info "5. Baixando CLIP: clip_l.safetensors"
download_file \
    "https://huggingface.co/comfyanonymous/flux_text_encoders/resolve/main/clip_l.safetensors" \
    "$TEXT_ENCODERS_DIR/clip_l.safetensors"
echo

# 6. VAE - ae.safetensors
print_info "6. Baixando VAE: ae.safetensors"
download_file \
    "https://huggingface.co/Comfy-Org/Lumina_Image_2.0_Repackaged/resolve/main/split_files/vae/ae.safetensors" \
    "$VAE_DIR/ae.safetensors"
echo

# 7. LoRA (OPCIONAL)
print_info "7. LoRA (opcional)"
print_warning "LoRAs são opcionais. O workflow funciona sem eles."
print_warning "Deseja baixar algum LoRA? (s/N): "
read -p "" -n 1 -r
echo
if [[ $REPLY =~ ^[Ss]$ ]]; then
    print_info "LoRAs devem ser baixados manualmente de:"
    print_info "  - Civitai: https://civitai.com"
    print_info "  - Hugging Face: https://huggingface.co"
    print_info "Coloque os LoRAs em: $LORAS_DIR"
fi
echo

# Resumo final
print_success "=== Download concluído! ==="
echo
print_info "Resumo dos arquivos baixados:"
echo
echo "UNET (Diffusion Models):"
ls -lh "$DIFFUSION_MODELS_DIR"/flux1-krea-dev* 2>/dev/null || echo "  (nenhum)"
ls -lh "$UNET_DIR"/flux1-dev-fp8* 2>/dev/null || echo "  (nenhum)"
echo
echo "CLIP (Text Encoders):"
ls -lh "$TEXT_ENCODERS_DIR"/t5xxl* 2>/dev/null || echo "  (nenhum)"
ls -lh "$TEXT_ENCODERS_DIR"/clip_l* 2>/dev/null || echo "  (nenhum)"
echo
echo "VAE:"
ls -lh "$VAE_DIR"/ae* 2>/dev/null || echo "  (nenhum)"
echo
print_success "Todos os modelos necessários foram baixados!"
print_info "Próximos passos:"
print_info "1. Instale os custom nodes via ComfyUI Manager:"
print_info "   - ComfyUI-FLUX (para DualCLIPLoader)"
print_info "   - ComfyUI-Manager (se ainda não tiver)"
print_info "2. Reinicie o ComfyUI"
print_info "3. Teste o workflow no n8n"

