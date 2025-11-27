#!/bin/bash

# Script para baixar TODOS os modelos necessários (Flux + Wan 2.2)
# Uso: ./download-todos-modelos.sh [CAMINHO_COMFYUI]
# Exemplo: ./download-todos-modelos.sh /caminho/para/ComfyUI

# Não usar 'set -e' para permitir tentativas de links alternativos

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

# Função para verificar espaço em disco (em GB)
check_disk_space() {
    local required_gb=$1
    local available_gb=$(df -BG "$COMFYUI_PATH" | tail -1 | awk '{print $4}' | sed 's/G//')
    
    if [ "$available_gb" -lt "$required_gb" ]; then
        print_error "Espaço insuficiente! Necessário: ${required_gb}GB, Disponível: ${available_gb}GB"
        print_warning "Execute 'df -h' para verificar o uso de disco"
        return 1
    fi
    return 0
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
        local size_bytes=$(stat -f%z "$output_path" 2>/dev/null || stat -c%s "$output_path" 2>/dev/null || echo "0")
        if [ "$size_bytes" -gt 1000 ]; then
            print_warning "Arquivo já existe: $filename ($size)"
            print_info "Pulando download de $filename"
            return 0
        else
            print_warning "Arquivo existe mas está vazio/corrompido ($size). Removendo..."
            rm -f "$output_path"
        fi
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
        local size_bytes=$(stat -f%z "$output_path" 2>/dev/null || stat -c%s "$output_path" 2>/dev/null || echo "0")
        if [ "$size_bytes" -gt 1000 ]; then
            print_success "Download concluído: $filename ($size)"
            return 0
        else
            print_error "Arquivo baixado está vazio ou corrompido: $filename"
            rm -f "$output_path"
            return 1
        fi
    else
        print_error "Arquivo não foi baixado corretamente: $filename"
        return 1
    fi
}

# Função para instalar custom node via git
install_custom_node() {
    local repo_url=$1
    local node_name=$2
    local custom_nodes_dir="$COMFYUI_PATH/custom_nodes"
    
    # Extrair nome do repositório da URL
    local repo_name=$(basename "$repo_url" .git)
    repo_name=$(basename "$repo_name")
    local node_dir="$custom_nodes_dir/$repo_name"
    
    # Criar diretório se não existir
    mkdir -p "$custom_nodes_dir"
    
    # Verificar se já está instalado
    if [ -d "$node_dir" ]; then
        print_warning "$node_name já está instalado em: $node_dir"
        print_info "Pulando instalação de $node_name"
        return 0
    fi
    
    print_info "Instalando custom node: $node_name"
    print_info "Repositório: $repo_url"
    
    if ! command -v git &> /dev/null; then
        print_error "Git não encontrado. Instale git para continuar."
        return 1
    fi
    
    cd "$custom_nodes_dir" || return 1
    if git clone "$repo_url" 2>&1; then
        if [ -d "$node_dir" ]; then
            print_success "Custom node instalado: $node_name"
            return 0
        else
            local found_dir=$(find "$custom_nodes_dir" -maxdepth 1 -type d -name "*${repo_name}*" | head -1)
            if [ -n "$found_dir" ]; then
                print_success "Custom node instalado: $node_name (em: $found_dir)"
                return 0
            else
                print_warning "Custom node clonado, mas diretório não encontrado. Verifique manualmente."
                return 0
            fi
        fi
    else
        print_error "Erro ao clonar repositório: $node_name"
        return 1
    fi
}

# Obter caminho do ComfyUI
if [ -z "$1" ]; then
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

# Verificar espaço em disco disponível
print_info "Verificando espaço em disco..."
AVAILABLE_GB=$(df -BG "$COMFYUI_PATH" | tail -1 | awk '{print $4}' | sed 's/G//')
print_info "Espaço disponível: ${AVAILABLE_GB}GB"
print_warning "Espaço necessário aproximado: ~70GB (Flux ~30GB + Wan 2.2 ~40GB)"
if [ "$AVAILABLE_GB" -lt 71 ]; then
    print_error "ATENÇÃO: Espaço em disco pode ser insuficiente!"
    print_warning "Continuando mesmo assim..."
fi
echo

# Definir caminhos das pastas
MODELS_DIR="$COMFYUI_PATH/models"
UNET_DIR="$MODELS_DIR/unet"
DIFFUSION_MODELS_DIR="$MODELS_DIR/diffusion_models"
TEXT_ENCODERS_DIR="$MODELS_DIR/text_encoders"
VAE_DIR="$MODELS_DIR/vae"
LORAS_DIR="$MODELS_DIR/loras"
VFI_DIR="$MODELS_DIR/vfi"
CUSTOM_NODES_DIR="$COMFYUI_PATH/custom_nodes"

print_info "=== Iniciando download de TODOS os modelos (Flux + Wan 2.2) ==="
echo

# ============================================
# PARTE 1: MODELOS FLUX
# ============================================
print_success "=== PARTE 1: MODELOS FLUX ==="
echo

# 1. UNET - Flux Krea Dev
print_info "1. Baixando UNET Flux: flux1-krea-dev_fp8_scaled.safetensors"
download_file \
    "https://huggingface.co/Comfy-Org/FLUX.1-Krea-dev_ComfyUI/resolve/main/split_files/diffusion_models/flux1-krea-dev_fp8_scaled.safetensors" \
    "$DIFFUSION_MODELS_DIR/flux1-krea-dev_fp8_scaled.safetensors"
echo

# 2. CLIP - T5-XXL fp8
print_info "2. Baixando CLIP Flux: t5xxl_fp8_e4m3fn_scaled.safetensors"
download_file \
    "https://huggingface.co/comfyanonymous/flux_text_encoders/resolve/main/t5xxl_fp8_e4m3fn_scaled.safetensors" \
    "$TEXT_ENCODERS_DIR/t5xxl_fp8_e4m3fn_scaled.safetensors"
echo

# 3. CLIP - T5-XXL fp16
print_info "3. Baixando CLIP Flux: t5xxl_fp16.safetensors"
download_file \
    "https://huggingface.co/comfyanonymous/flux_text_encoders/resolve/main/t5xxl_fp16.safetensors" \
    "$TEXT_ENCODERS_DIR/t5xxl_fp16.safetensors"
echo

# 4. CLIP - CLIP-L
print_info "4. Baixando CLIP Flux: clip_l.safetensors"
download_file \
    "https://huggingface.co/comfyanonymous/flux_text_encoders/resolve/main/clip_l.safetensors" \
    "$TEXT_ENCODERS_DIR/clip_l.safetensors"
echo

# 5. VAE - ae.safetensors
print_info "5. Baixando VAE Flux: ae.safetensors"
download_file \
    "https://huggingface.co/Comfy-Org/Lumina_Image_2.0_Repackaged/resolve/main/split_files/vae/ae.safetensors" \
    "$VAE_DIR/ae.safetensors"
echo

# ============================================
# PARTE 2: MODELOS WAN 2.2
# ============================================
print_success "=== PARTE 2: MODELOS WAN 2.2 ==="
echo

# 6. UNET - Wan 2.2 14B fp8_scaled (high_noise)
print_info "6. Baixando UNET Wan 2.2: wan2.2_i2v_high_noise_14B_fp8_scaled.safetensors"
check_disk_space 15 || exit 1

UNET_HIGH_FILENAME="wan2.2_i2v_high_noise_14B_fp8_scaled.safetensors"
download_file \
    "https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/diffusion_models/$UNET_HIGH_FILENAME" \
    "$DIFFUSION_MODELS_DIR/$UNET_HIGH_FILENAME"

# Criar link simbólico em unet/ para compatibilidade
if [ -f "$DIFFUSION_MODELS_DIR/$UNET_HIGH_FILENAME" ]; then
    mkdir -p "$UNET_DIR"
    if [ ! -e "$UNET_DIR/$UNET_HIGH_FILENAME" ]; then
        ln -s "../diffusion_models/$UNET_HIGH_FILENAME" \
            "$UNET_DIR/$UNET_HIGH_FILENAME"
        print_success "Link simbólico criado em unet/ para high_noise"
    fi
fi
echo

# 7. UNET - Wan 2.2 14B fp8_scaled (low_noise)
print_info "7. Baixando UNET Wan 2.2: wan2.2_i2v_low_noise_14B_fp8_scaled.safetensors"
check_disk_space 15 || exit 1

UNET_LOW_FILENAME="wan2.2_i2v_low_noise_14B_fp8_scaled.safetensors"
download_file \
    "https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/diffusion_models/$UNET_LOW_FILENAME" \
    "$DIFFUSION_MODELS_DIR/$UNET_LOW_FILENAME"

# Criar link simbólico em unet/ para compatibilidade
if [ -f "$DIFFUSION_MODELS_DIR/$UNET_LOW_FILENAME" ]; then
    mkdir -p "$UNET_DIR"
    if [ ! -e "$UNET_DIR/$UNET_LOW_FILENAME" ]; then
        ln -s "../diffusion_models/$UNET_LOW_FILENAME" \
            "$UNET_DIR/$UNET_LOW_FILENAME"
        print_success "Link simbólico criado em unet/ para low_noise"
    fi
fi
echo

# 8. CLIP - UMT5-XXL fp8
print_info "8. Baixando CLIP Wan 2.2: umt5_xxl_fp8_e4m3fn_scaled.safetensors"
check_disk_space 7 || exit 1

download_file \
    "https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors" \
    "$TEXT_ENCODERS_DIR/umt5_xxl_fp8_e4m3fn_scaled.safetensors"
echo

# 9. VAE - Wan 2.1 VAE
print_info "9. Baixando VAE Wan 2.2: wan_2.1_vae.safetensors"
download_file \
    "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/vae/wan_2.1_vae.safetensors" \
    "$VAE_DIR/wan_2.1_vae.safetensors" || {
    print_error "Link do VAE falhou. Tentando link alternativo..."
    download_file \
        "https://huggingface.co/wan-research/wan2.1/resolve/main/wan_2.1_vae.safetensors" \
        "$VAE_DIR/wan_2.1_vae.safetensors" || {
        print_error "Ambos os links falharam. Baixe manualmente do Hugging Face."
    }
}
echo

# 10. FILM VFI - Interpolação de frames
print_info "10. Baixando FILM VFI: film_net_fp32.pt"
download_file \
    "https://huggingface.co/nguu/film-pytorch/resolve/887b2c42bebcb323baf6c3b6d59304135699b575/film_net_fp32.pt" \
    "$VFI_DIR/film_net_fp32.pt" || {
    print_error "Link do FILM VFI falhou. Tentando link alternativo..."
    download_file \
        "https://huggingface.co/lucas-hug/film/resolve/main/film_net_fp32.pt" \
        "$VFI_DIR/film_net_fp32.pt" || {
        print_error "Ambos os links falharam. Baixe manualmente do Hugging Face."
    }
}
echo

# 11. LoRAs Wan 2.2 (opcionais mas recomendados)
print_info "11. Baixando LoRAs Wan 2.2 (opcionais)"
print_info "11.1. Baixando LoRA: wan2.2_i2v_lightx2v_4steps_lora_v1_low_noise.safetensors"
download_file \
    "https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/loras/wan2.2_i2v_lightx2v_4steps_lora_v1_low_noise.safetensors" \
    "$LORAS_DIR/wan2.2_i2v_lightx2v_4steps_lora_v1_low_noise.safetensors" || {
    print_warning "LoRA low_noise não encontrado. Pode não ser necessário."
}
echo

print_info "11.2. Baixando LoRA: wan2.2_i2v_lightx2v_4steps_lora_v1_high_noise.safetensors"
download_file \
    "https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/loras/wan2.2_i2v_lightx2v_4steps_lora_v1_high_noise.safetensors" \
    "$LORAS_DIR/wan2.2_i2v_lightx2v_4steps_lora_v1_high_noise.safetensors" || {
    print_warning "LoRA high_noise não encontrado. Pode não ser necessário."
}
echo

# ============================================
# PARTE 3: CUSTOM NODES
# ============================================
print_success "=== PARTE 3: INSTALANDO CUSTOM NODES ==="
echo

# 12. ComfyUI-FLUX (para DualCLIPLoader)
print_info "12. Instalando ComfyUI-FLUX (para DualCLIPLoader)"
install_custom_node \
    "https://github.com/Comfy-Org/ComfyUI-FLUX.git" \
    "ComfyUI-FLUX"
echo

# 13. WanVideoNAG (dentro do ComfyUI-KJNodes)
print_info "13. Instalando ComfyUI-KJNodes (contém WanVideoNAG)"
install_custom_node \
    "https://github.com/kijai/ComfyUI-KJNodes.git" \
    "ComfyUI-KJNodes"
echo

# 14. ComfyUI-NegiTools (Seed Generator)
print_info "14. Instalando ComfyUI-NegiTools (Seed Generator)"
install_custom_node \
    "https://github.com/natto-maki/ComfyUI-NegiTools.git" \
    "ComfyUI-NegiTools"
echo

# 15. ComfyUI-VideoHelperSuite (Video Combine)
print_info "15. Instalando ComfyUI-VideoHelperSuite (VHS)"
install_custom_node \
    "https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git" \
    "ComfyUI-VideoHelperSuite"
echo

# 16. ComfyUI-FILM (FILM VFI)
print_info "16. Instalando comfyui-frame-interpolation (FILM VFI)"
install_custom_node \
    "https://github.com/Fannovel16/comfyui-frame-interpolation.git" \
    "comfyui-frame-interpolation"
echo

# 17. Power Lora Loader (rgthree)
print_info "17. Instalando rgthree-comfy (Power Lora Loader)"
install_custom_node \
    "https://github.com/rgthree/rgthree-comfy.git" \
    "rgthree-comfy"
echo

# ============================================
# RESUMO FINAL
# ============================================
print_success "=== DOWNLOAD E INSTALAÇÃO CONCLUÍDOS! ==="
echo
print_info "Resumo dos arquivos baixados:"
echo

echo "=== MODELOS FLUX ==="
echo "UNET (Diffusion Models):"
ls -lh "$DIFFUSION_MODELS_DIR"/flux1-krea-dev* 2>/dev/null || echo "  (nenhum)"
echo
echo "CLIP (Text Encoders):"
ls -lh "$TEXT_ENCODERS_DIR"/t5xxl* 2>/dev/null || echo "  (nenhum)"
ls -lh "$TEXT_ENCODERS_DIR"/clip_l* 2>/dev/null || echo "  (nenhum)"
echo
echo "VAE:"
ls -lh "$VAE_DIR"/ae* 2>/dev/null || echo "  (nenhum)"
echo

echo "=== MODELOS WAN 2.2 ==="
echo "UNET:"
ls -lh "$UNET_DIR"/wan2.2* 2>/dev/null || ls -lh "$DIFFUSION_MODELS_DIR"/wan2.2* 2>/dev/null || echo "  (nenhum)"
echo
echo "CLIP (Text Encoders):"
ls -lh "$TEXT_ENCODERS_DIR"/umt5* 2>/dev/null || echo "  (nenhum)"
echo
echo "VAE:"
ls -lh "$VAE_DIR"/wan_2.1* 2>/dev/null || echo "  (nenhum)"
echo
echo "VFI (Frame Interpolation):"
ls -lh "$VFI_DIR"/film_net* 2>/dev/null || echo "  (nenhum)"
echo
echo "LoRAs:"
ls -lh "$LORAS_DIR"/wan2.2* 2>/dev/null || echo "  (nenhum - opcional)"
echo

echo "=== CUSTOM NODES ==="
ls -d "$CUSTOM_NODES_DIR"/*/ 2>/dev/null | while read dir; do
    echo "  - $(basename "$dir")"
done || echo "  (nenhum)"
echo

print_success "Todos os modelos e custom nodes foram baixados/instalados!"
echo
print_info "Próximos passos:"
print_info "1. Reinicie o ComfyUI para carregar os custom nodes"
print_info "2. Verifique nos logs se os custom nodes foram carregados"
print_info "3. Teste o workflow no n8n"
echo

