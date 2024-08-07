#!/bin/bash
 
# This file will be sourced in init.sh
 
# https://raw.githubusercontent.com/ai-dock/comfyui/main/config/provisioning/default.sh
 
# Packages are installed after nodes so we can fix them...
 
PYTHON_PACKAGES=(
    "opencv-python==4.7.0.72"
	"onnx==1.16.1"
    "onnxruntime==1.18.0"
    "onnxruntime-gpu==1.18.0"
    "numba==0.59.1"
	"insightface"
)
 
NODES=(
    "https://github.com/ltdrdata/ComfyUI-Manager"
 	"https://github.com/cubiq/ComfyUI_InstantID"
	"https://github.com/cubiq/ComfyUI_IPAdapter_plus"
	"https://github.com/cubiq/ComfyUI_InstantID"
	"https://github.com/cubiq/ComfyUI_essentials"
	"https://github.com/cubiq/ComfyUI_FaceAnalysis"
)
 
CHECKPOINT_MODELS=(
    "https://civitai.com/api/download/models/361593"
	"https://civitai.com/api/download/models/354657"
)
 
LORA_MODELS=(
    #"https://civitai.com/api/download/models/16576"
)
 
VAE_MODELS=(
    "https://huggingface.co/stabilityai/sd-vae-ft-ema-original/resolve/main/vae-ft-ema-560000-ema-pruned.safetensors"
    "https://huggingface.co/stabilityai/sd-vae-ft-mse-original/resolve/main/vae-ft-mse-840000-ema-pruned.safetensors"
    "https://huggingface.co/stabilityai/sdxl-vae/resolve/main/sdxl_vae.safetensors"
)
 
ESRGAN_MODELS=(
    "https://huggingface.co/ai-forever/Real-ESRGAN/resolve/main/RealESRGAN_x4.pth"
    "https://huggingface.co/FacehugmanIII/4x_foolhardy_Remacri/resolve/main/4x_foolhardy_Remacri.pth"
    "https://huggingface.co/Akumetsu971/SD_Anime_Futuristic_Armor/resolve/main/4x_NMKD-Siax_200k.pth"
)
 
CONTROLNET_MODELS=(
    "https://huggingface.co/InstantX/InstantID/resolve/main/ControlNetModel/diffusion_pytorch_model.safetensors"
)

CLIP_VISION_MODELS=(
	"https://huggingface.co/h94/IP-Adapter/resolve/main/models/image_encoder/model.safetensors"
	"CLIP-ViT-H-14-laion2B-s32B-b79K.safetensors"
	"https://huggingface.co/h94/IP-Adapter/resolve/main/sdxl_models/image_encoder/model.safetensors"
	"CLIP-ViT-bigG-14-laion2B-39B-b160k.safetensors"
)

IPADAPTER_MODELS=(
    "https://huggingface.co/h94/IP-Adapter-FaceID/resolve/main/ip-adapter-faceid-plusv2_sdxl.bin"
    "https://huggingface.co/h94/IP-Adapter/resolve/main/sdxl_models/ip-adapter-plus-face_sdxl_vit-h.safetensors"
    "https://huggingface.co/h94/IP-Adapter/resolve/main/sdxl_models/ip-adapter-plus_sdxl_vit-h.safetensors"
)

INSTANTID_MODELS=(
    "https://huggingface.co/InstantX/InstantID/resolve/main/ip-adapter.bin?download=true"
    "ip-adapter.bin"
)

INSIGHTFACE_MODELS=(
    "https://huggingface.co/MonsterMMORPG/tools/resolve/main/antelopev2.zip"
    "antelopev2.zip"
)
 
### DO NOT EDIT BELOW HERE UNLESS YOU KNOW WHAT YOU ARE DOING ###
 
function provisioning_start() {
    DISK_GB_AVAILABLE=$(($(df --output=avail -m "${WORKSPACE}" | tail -n1) / 1000))
    DISK_GB_USED=$(($(df --output=used -m "${WORKSPACE}" | tail -n1) / 1000))
    DISK_GB_ALLOCATED=$(($DISK_GB_AVAILABLE + $DISK_GB_USED))
    provisioning_print_header
    provisioning_get_nodes
    provisioning_install_python_packages
    provisioning_get_models \
        "${WORKSPACE}/storage/stable_diffusion/models/ckpt" \
        "${CHECKPOINT_MODELS[@]}"
    provisioning_get_models \
        "${WORKSPACE}/storage/stable_diffusion/models/lora" \
        "${LORA_MODELS[@]}"
    provisioning_get_models \
        "${WORKSPACE}/storage/stable_diffusion/models/controlnet" \
        "${CONTROLNET_MODELS[@]}"
    provisioning_get_models \
        "${WORKSPACE}/storage/stable_diffusion/models/vae" \
        "${VAE_MODELS[@]}"
    provisioning_get_models \
        "${WORKSPACE}/storage/stable_diffusion/models/esrgan" \
        "${ESRGAN_MODELS[@]}"
	provisioning_get_models_with_names \
        "${WORKSPACE}/storage/stable_diffusion/models/clip_vision" \
        "${CLIP_VISION_MODELS[@]}"
    provisioning_get_models \
        "${WORKSPACE}/storage/stable_diffusion/models/ipadapter" \
        "${IPADAPTER_MODELS[@]}"
    provisioning_get_models_with_names \
        "${WORKSPACE}/storage/stable_diffusion/models/instantid" \
        "${INSTANTID_MODELS[@]}"
    provisioning_get_models_with_names \
        "${WORKSPACE}/storage/stable_diffusion/models/insightface/models" \
        "${INSIGHTFACE_MODELS[@]}"
    provisioning_print_end
}
 
function provisioning_get_nodes() {
    for repo in "${NODES[@]}"; do
        dir="${repo##*/}"
        path="/opt/ComfyUI/custom_nodes/${dir}"
        requirements="${path}/requirements.txt"
        if [[ -d $path ]]; then
            if [[ ${AUTO_UPDATE,,} != "false" ]]; then
                printf "Updating node: %s...\n" "${repo}"
                ( cd "$path" && git pull )
                if [[ -e $requirements ]]; then
                    micromamba -n comfyui run ${PIP_INSTALL} -r "$requirements"
                fi
            fi
        else
            printf "Downloading node: %s...\n" "${repo}"
            git clone "${repo}" "${path}" --recursive
            if [[ -e $requirements ]]; then
                micromamba -n comfyui run ${PIP_INSTALL} -r "${requirements}"
            fi
        fi
    done
}
 
function provisioning_install_python_packages() {
    if [ ${#PYTHON_PACKAGES[@]} -gt 0 ]; then
        micromamba -n comfyui run ${PIP_INSTALL} ${PYTHON_PACKAGES[*]}
    fi
}
 
function provisioning_get_models() {
    if [[ -z $2 ]]; then return 1; fi
    dir="$1"
    mkdir -p "$dir"
    shift
    if [[ $DISK_GB_ALLOCATED -ge $DISK_GB_REQUIRED ]]; then
        arr=("$@")
    else
        printf "WARNING: Low disk space allocation - Only the first model will be downloaded!\n"
        arr=("$1")
    fi
 
    printf "Downloading %s model(s) to %s...\n" "${#arr[@]}" "$dir"
    for url in "${arr[@]}"; do
        printf "Downloading: %s\n" "${url}"
        provisioning_download "${url}" "${dir}"
        printf "\n"
    done
}

function provisioning_get_models_with_names() {
    if [[ -z $3 ]]; then return 1; fi
    dir="$1"
    mkdir -p "$dir"
    shift

    if [[ $(( $# % 2 )) -ne 0 ]]; then
        echo "Error: URLs and filenames must be provided in pairs."
        return 1
    fi

    if [[ $DISK_GB_ALLOCATED -ge $DISK_GB_REQUIRED ]]; then
        arr=("$@")
    else
        printf "WARNING: Low disk space allocation - Only the first model will be downloaded!\n"
        arr=("${@:1:2}")
    fi
    
    printf "Downloading %s model(s) to %s...\n" "$(( ${#arr[@]} / 2 ))" "$dir"
    for ((i = 0; i < ${#arr[@]}; i+=2)); do
        url="${arr[i]}"
        filename="${arr[i+1]}"
        filepath="${dir}/${filename}"
        printf "Downloading: %s as %s\n" "${url}" "${filename}"
        provisioning_download "${url}" "${filepath}"
        printf "\n"
        
        # Check if the file is a ZIP file and unzip it
        if [[ "${filename}" == *.zip ]]; then
            printf "Unzipping: %s\n" "${filepath}"
            unzip -o "${filepath}" -d "${dir}"
            printf "Unzipped: %s\n" "${filepath}"
        fi
    done
}
 
function provisioning_print_header() {
    printf "\n##############################################\n#                                            #\n#          Provisioning container            #\n#                                            #\n#         This will take some time           #\n#                                            #\n# Your container will be ready on completion #\n#                                            #\n##############################################\n\n"
    if [[ $DISK_GB_ALLOCATED -lt $DISK_GB_REQUIRED ]]; then
        printf "WARNING: Your allocated disk size (%sGB) is below the recommended %sGB - Some models will not be downloaded\n" "$DISK_GB_ALLOCATED" "$DISK_GB_REQUIRED"
    fi
}
 
function provisioning_print_end() {
    printf "\nProvisioning complete:  Web UI will start now\n\n"
}
 
# Download from $1 URL to $2 file path


function initialize_instantid() {
    # Navigate to the directory
    cd /workspace/ComfyUI/models/
    
    # Create a directory called instantid
    mkdir -p instantid
    
    # Change into the instantid directory
    cd instantid
    
    # Download the file using wget
    wget "https://huggingface.co/InstantX/InstantID/resolve/main/ip-adapter.bin?download=true"

    mv ip-adapter.bin?download=true ip-adapter.bin
}

function initialize_insightface() {
    # Navigate to the directory
    cd /workspace/ComfyUI/models/ || exit
    
    # Create a directory called insightface
    mkdir -p insightface
    
    # Change into the insightface directory
    cd insightface || exit

    # Create models directory
    mkdir -p models

    cd models || exit
    
    # Download the file using wget
    if wget "https://huggingface.co/MonsterMMORPG/tools/resolve/main/antelopev2.zip?download=true"; then
        # Unzip the file if download is successful
        unzip antelopev2.zip?download=true
    else
        echo "Download failed!"
        exit 1
    fi
}
 
provisioning_start
initialize_instantid
initialize_insightface