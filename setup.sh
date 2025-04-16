#!/bin/bash
set -e # Exit on error

echo "🔍 Checking system compatibility..."
if ! grep -q "Ubuntu 24.04.2 LTS" /etc/os-release || ! grep -q "WSL2" /proc/version; then
    echo "⚠️ Warning: This script is tested only on WSL2 with Ubuntu 24.04.2 LTS. Your system may not be fully compatible."
fi

echo "🐍 Setting up Python virtual environment..."
if [ ! -d "venv" ]; then
    python3 -m venv venv
    echo "✅ Virtual environment created."
else
    echo "✅ Virtual environment already exists."
fi

# Activate the virtual environment
source venv/bin/activate
echo "✅ Virtual environment activated."

check_and_install() {
    local name="$1"
    local check_command="$2"
    local install_command="$3"
    local version_command="$4"

    echo "🔍 Checking for $name installation..."
    if ! eval "$check_command" &>/dev/null; then
        echo "❌ $name not found. Installing $name..."
        sudo apt update
        eval "$install_command"
        if [ -n "$version_command" ]; then
            local version_output
            version_output=$(eval "$version_command")
            echo "✅ Installed $name. Version: $version_output"
            versions["$name"]="$version_output"
        else
            echo "✅ Installed $name."
            versions["$name"]="N/A"
        fi
        else
        echo "✅ $name is already installed."
        if [ -n "$version_command" ]; then
            local version_output
            version_output=$(eval "$version_command")
            echo "🔍 $name Version: $version_output"
            versions["$name"]="$version_output"
        else
            versions["$name"]="N/A"
        fi
        fi
    }

declare -A versions

check_and_install "CUDA" "command -v nvcc" "sudo apt install -y nvidia-cuda-toolkit" "nvcc --version | grep release"
check_and_install "HDF5" "dpkg -l | grep -q libhdf5-dev" "sudo apt install -y libhdf5-dev hdf5-tools" "h5cc -showconfig | grep 'HDF5 Version'"
check_and_install "Ninja build system" "command -v ninja" "sudo apt install -y ninja-build" "ninja --version"
check_and_install "build-essential" "dpkg -l | grep -q build-essential" "sudo apt install -y build-essential" "g++ --version | head -1"

echo "📜 Installed components and their versions:"
for component in "${!versions[@]}"; do
    echo "🔹 $component: ${versions[$component]}"
done
echo "🔍 Checking for PyTorch installation..."
if python -c "import torch; print(torch.__version__)" &>/dev/null; then
    echo "✅ PyTorch is already installed."
    if python -c "import torch; print(torch.cuda.is_available())" | grep -q "True"; then
        echo "✅ PyTorch supports CUDA."
    else
        echo "❌ PyTorch does not support CUDA. Reinstalling with CUDA support..."
        pip install --force-reinstall torch torchvision --index-url https://download.pytorch.org/whl/cu124
    fi
else
    echo "❌ PyTorch not found. Installing PyTorch with CUDA support..."
    pip install torch torchvision --index-url https://download.pytorch.org/whl/cu124
fi

echo "🔍 Verifying PyTorch installation..."
if python -c "import torch; print(torch.__version__)" &>/dev/null; then
    echo "✅ PyTorch installation verified. Version: $(python -c 'import torch; print(torch.__version__)')"
    if python -c "import torch; print(torch.cuda.is_available())" | grep -q "True"; then
        echo "✅ PyTorch CUDA support verified."
    else
        echo "❌ PyTorch does not support CUDA after installation."
    fi
else
    echo "❌ PyTorch installation verification failed."
fi

echo "📦 Installing remaining pip requirements..."
pip install -r requirements.txt
