#!/bin/bash

# setup_env.sh - Script to set up a new development environment with custom dotfiles

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
DOTFILES_REPO="https://github.com/ajvadam/dotfiles.git"
DOTFILES_DIR="$HOME/dotfiles"
BACKUP_DIR="$HOME/dotfiles_backup_$(date +%Y%m%d_%H%M%S)"

# Check if running as root
if [ "$(id -u)" -eq 0 ]; then
    IS_ROOT=true
    SUDO_CMD=""  # Root doesn't need sudo
else
    IS_ROOT=false
    SUDO_CMD="sudo"  # Non-root needs sudo for system commands
fi

# Function to print colored output
print_status() {
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

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to run commands with appropriate privileges
run_privileged() {
    if [ "$IS_ROOT" = true ]; then
        "$@"
    else
        $SUDO_CMD "$@"
    fi
}

# Function to detect package manager
detect_package_manager() {
    if command_exists apt-get; then
        echo "apt"
    elif command_exists dnf; then
        echo "dnf"
    elif command_exists yum; then
        echo "yum"
    elif command_exists pacman; then
        echo "pacman"
    elif command_exists apk; then
        echo "apk"
    elif command_exists brew; then
        echo "brew"
    else
        echo "unknown"
    fi
}

# Function to install package based on OS
install_package() {
    local pkg=$1
    local pkg_manager=$(detect_package_manager)
    
    print_status "Installing $pkg using $pkg_manager..."
    
    case $pkg_manager in
        "apt")
            run_privileged apt-get update
            run_privileged apt-get install -y "$pkg"
            ;;
        "dnf")
            run_privileged dnf install -y "$pkg"
            ;;
        "yum")
            run_privileged yum install -y "$pkg"
            ;;
        "pacman")
            run_privileged pacman -S --noconfirm "$pkg"
            ;;
        "apk")
            run_privileged apk add --no-cache "$pkg"
            ;;
        "brew")
            brew install "$pkg"
            ;;
        *)
            print_error "Package manager not found. Please install $pkg manually."
            return 1
            ;;
    esac
}

# Function to backup existing dotfiles
backup_dotfiles() {
    local files=(
        "$HOME/.zshrc" "$HOME/.tmux.conf" "$HOME/.config/nvim"
        "$HOME/.bashrc" "$HOME/.bash_profile" "$HOME/.profile"
    )
    
    mkdir -p "$BACKUP_DIR"
    
    for file in "${files[@]}"; do
        if [[ -e "$file" ]]; then
            print_status "Backing up $file to $BACKUP_DIR"
            cp -r "$file" "$BACKUP_DIR/" 2>/dev/null || true
        fi
    done
}

# Function to clone dotfiles repository
clone_dotfiles() {
    print_status "Cloning dotfiles repository..."
    
    if [[ -d "$DOTFILES_DIR" ]]; then
        print_warning "Dotfiles directory already exists. Pulling latest changes..."
        cd "$DOTFILES_DIR" && git pull origin main
    else
        git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
    fi
}

# Function to install Neovim (universal method)
install_neovim() {
    if command_exists nvim; then
        print_status "Neovim is already installed"
        return 0
    fi

    print_status "Installing Neovim..."
    
    # Try package manager first
    if install_package neovim; then
        return 0
    fi
    
    # Fallback: manual installation
    print_warning "Falling back to manual Neovim installation..."
    
    local temp_dir=$(mktemp -d)
    cd "$temp_dir"
    
    # Download appropriate version based on architecture
    if [ "$(uname -m)" = "x86_64" ]; then
        curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux64.tar.gz
        tar xzf nvim-linux64.tar.gz
        run_privileged cp -r nvim-linux64/* /usr/local/
    elif [ "$(uname -m)" = "aarch64" ]; then
        curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-arm64.tar.gz
        tar xzf nvim-linux-arm64.tar.gz
        run_privileged cp -r nvim-linux-arm64/* /usr/local/
    else
        # Build from source as last resort
        print_warning "Building Neovim from source..."
        run_privileged apt-get install -y ninja-build gettext cmake unzip curl
        git clone https://github.com/neovim/neovim
        cd neovim && make CMAKE_BUILD_TYPE=RelWithDebInfo
        run_privileged make install
    fi
    
    cd && rm -rf "$temp_dir"
}

# Function to install Tmux
install_tmux() {
    if command_exists tmux; then
        print_status "Tmux is already installed"
        return 0
    fi
    
    install_package tmux
}

# Function to install Zsh
install_zsh() {
    if command_exists zsh; then
        print_status "Zsh is already installed"
    else
        install_package zsh
    fi

    # Install Oh-My-Zsh if not present (only for non-root users)
    if [[ ! -d "$HOME/.oh-my-zsh" ]] && [ "$IS_ROOT" = false ]; then
        print_status "Installing Oh-My-Zsh..."
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    fi

    # Set Zsh as default shell (only if not root for safety)
    if [ "$IS_ROOT" = false ] && [ "$SHELL" != "$(command -v zsh)" ]; then
        print_status "Setting Zsh as default shell..."
        chsh -s "$(command -v zsh)"
    elif [ "$IS_ROOT" = true ]; then
        print_warning "Running as root: Skipping default shell change for safety"
    fi
}

# Function to install additional tools
install_additional_tools() {
    local tools=("git" "curl" "wget" "fzf" "ripgrep" "fd-find" "bat" "exa")
    
    for tool in "${tools[@]}"; do
        if ! command_exists "$tool"; then
            install_package "$tool"
        fi
    done
}

# Function to set up symlinks
setup_symlinks() {
    print_status "Setting up symlinks..."
    
    # Create config directory if it doesn't exist
    mkdir -p "$HOME/.config"
    
    # Symlink Neovim config
    if [[ -d "$DOTFILES_DIR/nvim" ]]; then
        ln -sfn "$DOTFILES_DIR/nvim" "$HOME/.config/nvim"
    fi
    
    # Symlink other dotfiles
    local dotfiles=(
        ".zshrc" ".tmux.conf" ".bashrc" ".bash_profile" ".profile"
    )
    
    for dotfile in "${dotfiles[@]}"; do
        if [[ -f "$DOTFILES_DIR/$dotfile" ]]; then
            ln -sfn "$DOTFILES_DIR/$dotfile" "$HOME/$dotfile"
        fi
    done
}

# Main execution
main() {
    print_status "Starting environment setup..."
    print_status "Running as: $(whoami)"
    print_status "Detected package manager: $(detect_package_manager)"
    
    # Update package lists
    case $(detect_package_manager) in
        "apt") run_privileged apt-get update ;;
        "dnf") run_privileged dnf check-update ;;
        "yum") run_privileged yum check-update ;;
        "pacman") run_privileged pacman -Sy ;;
        "apk") run_privileged apk update ;;
    esac
    
    # Install essential build tools
    install_package build-essential 2>/dev/null || install_package build-base 2>/dev/null || true
    
    # Backup existing dotfiles
    backup_dotfiles
    
    # Clone dotfiles
    clone_dotfiles
    
    # Install required programs
    install_neovim
    install_tmux
    install_zsh
    install_additional_tools
    
    # Set up symlinks
    setup_symlinks
    
    print_success "Environment setup completed successfully!"
    print_success "Backup of old dotfiles created at: $BACKUP_DIR"
    
    if [ "$IS_ROOT" = false ]; then
        print_success "Please restart your terminal or run: exec zsh"
    fi
    
    # Show installed versions
    echo -e "\n${GREEN}Installed versions:${NC}"
    command_exists nvim && echo "Neovim: $(nvim --version | head -n1 | cut -d' ' -f2-)"
    command_exists tmux && echo "Tmux: $(tmux -V)"
    command_exists zsh && echo "Zsh: $(zsh --version)"
}

# Run main function
main "$@"
