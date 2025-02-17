#!/bin/bash

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

if ! command_exists brew; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
    echo "Homebrew is already installed."
fi

brew update

if ! command_exists docker; then
    echo "Installing Docker..."
    brew install --cask docker
    echo "Please open Docker and complete any setup required."
else
    echo "Docker is already installed."
fi

if ! command_exists kubectl; then
    echo "Installing kubectl..."
    brew install kubectl
else
    echo "kubectl is already installed."
fi

if ! command_exists helm; then
    echo "Installing Helm..."
    brew install helm
else
    echo "Helm is already installed."
fi

if ! command_exists k3d; then
    echo "Installing k3d..."
    brew install k3d
else
    echo "k3d is already installed."
fi

echo "Verifying installations..."
kubectl version --client
helm version
docker --version
k3d version

echo "Installation script completed!"