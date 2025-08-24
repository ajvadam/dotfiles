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

# Function to install package based on OS
install_package() {
    local pkg=$1
    print_status "Installing $pkg..."
    
    if command_exists apt-get; then
        # Debian/Ubuntu
        sudo apt-get update
        sudo apt-get install -y "$pkg"
    elif command_exists dnf; then
        # Fedora
        sudo dnf install -y "$pkg"
    elif command_exists yum; then
        # CentOS/RHEL
        sudo yum install -y "$pkg"
    elif command_exists pacman; then
        # Arch Linux
        sudo pacman -S --noconfirm "$pkg"
    elif command_exists brew; then
        # macOS
        brew install "$pkg"
    else
        print_error "Package manager not found. Please install $pkg manually."
        return 1
    fi
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

# Function to install Neovim
install_neovim() {
    if command_exists nvim; then
        print_status "Neovim is already installed"
        return 0
    fi

    print_status "Installing Neovim..."
    
    if command_exists apt-get; then
        sudo add-apt-repository ppa:neovim-ppa/stable -y
        sudo apt-get update
        sudo apt-get install -y neovim
    elif command_exists brew; then
        brew install neovim
    else
        # Install from source or use other package managers
        install_package neovim || {
            print_warning "Falling back to manual Neovim installation..."
            curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim.appimage
            chmod u+x nvim.appimage
            sudo mv nvim.appimage /usr/local/bin/nvim
        }
    fi
}

# Function to install Tmux
install_tmux() {
    if command_exists tmux; then
        print_status "Tmux is already installed"
        return 0
    fi
    
    install_package tmux
}

# Function to install Zsh and Oh-My-Zsh
install_zsh() {
    if command_exists zsh; then
        print_status "Zsh is already installed"
    else
        install_package zsh
    fi

    # Install Oh-My-Zsh if not present
    if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
        print_status "Installing Oh-My-Zsh..."
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    fi

    # Set Zsh as default shell
    if [[ "$SHELL" != "$(which zsh)" ]]; then
        print_status "Setting Zsh as default shell..."
        chsh -s "$(which zsh)"
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

# Function to install Neovim plugins
install_neovim_plugins() {
    print_status "Installing Neovim plugins..."
    
    if command_exists nvim; then
        nvim --headless -c 'autocmd User PackerComplete quitall' -c 'PackerSync' 2>/dev/null || true
        nvim --headless -c 'autocmd User PackerComplete quitall' -c 'PackerInstall' 2>/dev/null || true
    fi
}

# Function to set up Tmux plugins
setup_tmux_plugins() {
    print_status "Setting up Tmux plugins..."
    
    if [[ -d "$HOME/.tmux/plugins/tpm" ]]; then
        # Install Tmux plugins
        bash "$HOME/.tmux/plugins/tpm/scripts/install_plugins.sh" 2>/dev/null || true
    fi
}

# Main execution
main() {
    print_status "Starting environment setup..."
    
    # Update package lists
    if command_exists apt-get; then
        sudo apt-get update
    fi
    
    # Install essential build tools
    install_package build-essential
    
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
    
    # Install plugins
    install_neovim_plugins
    setup_tmux_plugins
    
    print_success "Environment setup completed successfully!"
    print_success "Backup of old dotfiles created at: $BACKUP_DIR"
    print_success "Please restart your terminal or run: exec zsh"
    
    # Show installed versions
    echo -e "\n${GREEN}Installed versions:${NC}"
    command_exists nvim && echo "Neovim: $(nvim --version | head -n1)"
    command_exists tmux && echo "Tmux: $(tmux -V)"
    command_exists zsh && echo "Zsh: $(zsh --version)"
}

# Run main function
main "$@"