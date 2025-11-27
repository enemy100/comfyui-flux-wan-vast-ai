#!/bin/bash

# Script para baixar modelos Wan 2.2 necessários para o workflow
# Uso: ./download-modelos-wan22.sh [CAMINHO_COMFYUI]
# Exemplo: ./download-modelos-wan22.sh /caminho/para/ComfyUI

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
            read -p "Deseja baixar novamente? (s/N): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Ss]$ ]]; then
                print_info "Pulando download de $filename"
                return 0
            fi
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
    
    # Extrair nome do repositório da URL (última parte antes de .git)
    local repo_name=$(basename "$repo_url" .git)
    # Se ainda tiver caminho, pegar apenas o nome final
    repo_name=$(basename "$repo_name")
    local node_dir="$custom_nodes_dir/$repo_name"
    
    # Criar diretório se não existir
    mkdir -p "$custom_nodes_dir"
    
    # Verificar se já está instalado
    if [ -d "$node_dir" ]; then
        print_warning "$node_name já está instalado em: $node_dir"
        read -p "Deseja reinstalar? (s/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Ss]$ ]]; then
            print_info "Pulando instalação de $node_name"
            return 0
        fi
        rm -rf "$node_dir"
    fi
    
    print_info "Instalando custom node: $node_name"
    print_info "Repositório: $repo_url"
    
    if ! command -v git &> /dev/null; then
        print_error "Git não encontrado. Instale git para continuar."
        return 1
    fi
    
    cd "$custom_nodes_dir" || return 1
    if git clone "$repo_url" 2>&1; then
        # Verificar se o diretório foi criado (pode ter nome diferente)
        if [ -d "$node_dir" ]; then
            print_success "Custom node instalado: $node_name"
            return 0
        else
            # Tentar encontrar o diretório criado
            local found_dir=$(find "$custom_nodes_dir" -maxdepth 1 -type d -name "*${repo_name}*" | head -1)
            if [ -n "$found_dir" ]; then
                print_success "Custom node instalado: $node_name (em: $found_dir)"
                return 0
            else
                print_warning "Custom node clonado, mas diretório não encontrado. Verifique manualmente."
                return 0  # Não é erro fatal, o clone funcionou
            fi
        fi
    else
        print_error "Erro ao clonar repositório: $node_name"
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

# Verificar espaço em disco disponível
print_info "Verificando espaço em disco..."
AVAILABLE_GB=$(df -BG "$COMFYUI_PATH" | tail -1 | awk '{print $4}' | sed 's/G//')
print_info "Espaço disponível: ${AVAILABLE_GB}GB"
print_warning "Espaço necessário aproximado: ~40GB (modelos: 2x UNET ~28GB + outros ~12GB) + ~1GB (custom nodes)"
if [ "$AVAILABLE_GB" -lt 41 ]; then
    print_error "ATENÇÃO: Espaço em disco pode ser insuficiente!"
    read -p "Continuar mesmo assim? (s/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Ss]$ ]]; then
        exit 1
    fi
fi
echo

# Definir caminhos das pastas
MODELS_DIR="$COMFYUI_PATH/models"
UNET_DIR="$MODELS_DIR/unet"
DIFFUSION_MODELS_DIR="$MODELS_DIR/diffusion_models"
TEXT_ENCODERS_DIR="$MODELS_DIR/text_encoders"
VAE_DIR="$MODELS_DIR/vae"
LORAS_DIR="$MODELS_DIR/loras/"
VFI_DIR="$MODELS_DIR/vfi"
CUSTOM_NODES_DIR="$COMFYUI_PATH/custom_nodes"

print_info "=== Iniciando instalação completa (Modelos + Custom Nodes) ==="
echo

# 1. UNET - Wan 2.2 14B fp8_scaled (OBRIGATÓRIO)
print_info "1. Baixando UNET: Wan 2.2 14B fp8_scaled"
print_warning "Este é o modelo principal do Wan 2.2 (~14GB cada). OBRIGATÓRIO!"
print_info "Baixando AMBOS os modelos (high_noise e low_noise) para máxima compatibilidade"
check_disk_space 30 || exit 1

# Baixar high_noise
UNET_HIGH_FILENAME="wan2.2_i2v_high_noise_14B_fp8_scaled.safetensors"
print_info "1.1. Baixando: $UNET_HIGH_FILENAME"
UNET_HIGH_DOWNLOADED=0

# Tentativa 1: Comfy-Org (link que funcionou)
print_info "Tentativa 1: Comfy-Org repositório..."
download_file \
    "https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/diffusion_models/$UNET_HIGH_FILENAME" \
    "$DIFFUSION_MODELS_DIR/$UNET_HIGH_FILENAME" && UNET_HIGH_DOWNLOADED=1

# Criar link simbólico em unet/ para compatibilidade
if [ $UNET_HIGH_DOWNLOADED -eq 1 ]; then
    mkdir -p "$UNET_DIR"
    if [ ! -e "$UNET_DIR/$UNET_HIGH_FILENAME" ]; then
        ln -s "../diffusion_models/$UNET_HIGH_FILENAME" \
            "$UNET_DIR/$UNET_HIGH_FILENAME"
        print_success "Link simbólico criado em unet/ para high_noise"
    fi
else
    print_error "Link do UNET high_noise falhou. Baixe manualmente de:"
    print_info "  - https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged"
    print_info "  - Arquivo: $UNET_HIGH_FILENAME"
fi
echo

# Baixar low_noise
UNET_LOW_FILENAME="wan2.2_i2v_low_noise_14B_fp8_scaled.safetensors"
print_info "1.2. Baixando: $UNET_LOW_FILENAME"
UNET_LOW_DOWNLOADED=0

# Tentativa 1: Comfy-Org (link que funcionou)
print_info "Tentativa 1: Comfy-Org repositório..."
download_file \
    "https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/diffusion_models/$UNET_LOW_FILENAME" \
    "$DIFFUSION_MODELS_DIR/$UNET_LOW_FILENAME" && UNET_LOW_DOWNLOADED=1

# Criar link simbólico em unet/ para compatibilidade
if [ $UNET_LOW_DOWNLOADED -eq 1 ]; then
    mkdir -p "$UNET_DIR"
    if [ ! -e "$UNET_DIR/$UNET_LOW_FILENAME" ]; then
        ln -s "../diffusion_models/$UNET_LOW_FILENAME" \
            "$UNET_DIR/$UNET_LOW_FILENAME"
        print_success "Link simbólico criado em unet/ para low_noise"
    fi
else
    print_error "Link do UNET low_noise falhou. Baixe manualmente de:"
    print_info "  - https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged"
    print_info "  - Arquivo: $UNET_LOW_FILENAME"
fi
echo

# 2. CLIP - UMT5-XXL fp8 (OBRIGATÓRIO)
print_info "2. Baixando CLIP: umt5_xxl_fp8_e4m3fn_scaled.safetensors"
print_warning "Tamanho: ~6.3GB. OBRIGATÓRIO!"
check_disk_space 7 || exit 1

CLIP_DOWNLOADED=0

# Tentativa 1: Comfy-Org (link que funcionou)
print_info "Tentativa 1: Comfy-Org repositório..."
download_file \
    "https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors" \
    "$TEXT_ENCODERS_DIR/umt5_xxl_fp8_e4m3fn_scaled.safetensors" && CLIP_DOWNLOADED=1

if [ $CLIP_DOWNLOADED -eq 0 ]; then
    print_error "Link do CLIP falhou. Baixe manualmente de:"
    print_info "  - https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged"
fi
echo

# 3. VAE - Wan 2.1 VAE (OBRIGATÓRIO)
print_info "3. Baixando VAE: wan_2.1_vae.safetensors"
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

# 4. FILM VFI - Interpolação de frames (OBRIGATÓRIO)
print_info "4. Baixando FILM VFI: film_net_fp32.pt"
print_info "Este modelo é usado para interpolação de frames (aumentar FPS)"
print_warning "Tamanho: ~132MB. OBRIGATÓRIO!"

FILM_DOWNLOADED=0

# Tentativa 1: Comfy-Org (mais provável de funcionar)
print_info "Tentativa 1: Comfy-Org repositório..."
download_file \
    "https://huggingface.co/nguu/film-pytorch/resolve/887b2c42bebcb323baf6c3b6d59304135699b575/film_net_fp32.pt" \
    "$VFI_DIR/film_net_fp32.pt" && FILM_DOWNLOADED=1

# Tentativa 2: lucas-hug/film (pode requerer autenticação)
if [ $FILM_DOWNLOADED -eq 0 ]; then
    print_info "Tentativa 2: lucas-hug/film repositório..."
    download_file \
        "https://huggingface.co/lucas-hug/film/resolve/main/film_net_fp32.pt" \
        "$VFI_DIR/film_net_fp32.pt" && FILM_DOWNLOADED=1
fi

if [ $FILM_DOWNLOADED -eq 0 ]; then
    print_error "Links do FILM VFI falharam. Baixe manualmente de:"
    print_info "  - https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged"
    print_info "  - https://huggingface.co/lucas-hug/film"
    print_warning "NOTA: Se requerer autenticação, use 'huggingface-cli download'"
fi
echo

# 5. LoRAs (OPCIONAIS mas recomendados)
print_info "5. LoRAs (opcionais mas recomendados)"
print_warning "Os LoRAs melhoram a qualidade do vídeo. Deseja baixar? (s/N): "
read -p "" -n 1 -r
echo
if [[ $REPLY =~ ^[Ss]$ ]]; then
    check_disk_space 1 || {
        print_warning "Espaço insuficiente para LoRAs. Pulando..."
        REPLY="n"
    }
fi
if [[ $REPLY =~ ^[Ss]$ ]]; then
    print_info "5.1. Baixando LoRA: wan2.2_i2v_lightx2v_4steps_lora_v1_low_noise.safetensors"
    
    LORA1_DOWNLOADED=0
    # Tentativa 1: Comfy-Org (link que funcionou)
    download_file \
        "https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/loras/wan2.2_i2v_lightx2v_4steps_lora_v1_low_noise.safetensors" \
        "$LORAS_DIR/wan2.2_i2v_lightx2v_4steps_lora_v1_low_noise.safetensors" && LORA1_DOWNLOADED=1
    
    if [ $LORA1_DOWNLOADED -eq 0 ]; then
        print_warning "LoRA low_noise não encontrado. Pode não ser necessário."
    fi
    echo
    
    print_info "5.2. Baixando LoRA: wan2.2_i2v_lightx2v_4steps_lora_v1_high_noise.safetensors"
    
    LORA2_DOWNLOADED=0
    # Tentativa 1: Comfy-Org (link que funcionou)
    download_file \
        "https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/loras/wan2.2_i2v_lightx2v_4steps_lora_v1_high_noise.safetensors" \
        "$LORAS_DIR/wan2.2_i2v_lightx2v_4steps_lora_v1_high_noise.safetensors" && LORA2_DOWNLOADED=1
    
    if [ $LORA2_DOWNLOADED -eq 0 ]; then
        print_warning "LoRA high_noise não encontrado. Pode não ser necessário."
    fi
    echo
else
    print_info "Pulando download dos LoRAs (opcional)"
fi
echo

# Resumo final
print_success "=== Download concluído! ==="
echo
print_info "Resumo dos arquivos baixados:"
echo
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
echo
print_info "=== Instalando Custom Nodes ==="
echo

# 6. Custom Nodes (OBRIGATÓRIOS)
print_info "6. Instalando Custom Nodes via Git"
print_warning "Estes custom nodes são OBRIGATÓRIOS para o workflow funcionar."

# WanVideoNAG (dentro do ComfyUI-KJNodes)
install_custom_node \
    "https://github.com/kijai/ComfyUI-KJNodes.git" \
    "ComfyUI-KJNodes (contém WanVideoNAG)"

# ComfyUI-NegiTools (Seed Generator)
install_custom_node \
    "https://github.com/natto-maki/ComfyUI-NegiTools.git" \
    "ComfyUI-NegiTools (Seed Generator)"

# ComfyUI-VHS (Video Combine)
install_custom_node \
    "https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git" \
    "ComfyUI-VideoHelperSuite (VHS)"

# ComfyUI-FILM (FILM VFI)
install_custom_node \
    "https://github.com/Fannovel16/comfyui-frame-interpolation.git" \
    "comfyui-frame-interpolation (FILM VFI)"

# Power Lora Loader (rgthree)
install_custom_node \
    "https://github.com/rgthree/rgthree-comfy.git" \
    "rgthree-comfy (Power Lora Loader)"

echo
print_success "=== Instalação completa! ==="
echo
print_info "Resumo:"
echo "  ✅ Modelos Wan 2.2 baixados"
echo "  ✅ Custom nodes instalados"
echo
print_info "Próximos passos:"
print_info "1. Reinicie o ComfyUI para carregar os custom nodes"
print_info "2. Verifique nos logs se os custom nodes foram carregados"
print_info "3. Teste o workflow no n8n"

