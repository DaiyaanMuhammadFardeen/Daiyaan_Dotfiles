#!/usr/bin/env bash
#===============================================================================
# Daiyaan's Dotfiles Installer
# https://github.com/DaiyaanMuhammad/Daiyaan_Dotfiles
#
# This script installs required packages and symlinks configuration files
# from this repository to their appropriate locations.
#
# Usage:
#   ./install.sh              # Interactive menu
#   ./install.sh --all        # Install everything non-interactively
#   ./install.sh --dry-run    # Show what would be done without doing it
#   ./install.sh --help       # Show this help
#
# Features:
#   - Cross-distro package detection (Arch, Debian/Ubuntu, Fedora, openSUSE)
#   - Interactive config selection menu
#   - Backup of existing configs before overwriting
#   - Symlink-based installation (no copies)
#   - Dry-run mode for preview
#   - Oh My Zsh installation (replaces Antigen)
#   - AstroNvim installation (replaces legacy nvim config)
#   - OpenCode configuration
#===============================================================================

set -euo pipefail

#===============================================================================
# CONSTANTS
#===============================================================================
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d_%H%M%S)"
DRY_RUN=false
INSTALL_ALL=false

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

#===============================================================================
# HELPER FUNCTIONS
#===============================================================================

log_info()    { echo -e "${BLUE}[INFO]${NC}  $*"; }
log_success() { echo -e "${GREEN}[OK]${NC}    $*"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC}  $*"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $*"; }
log_header()  { echo -e "\n${BOLD}${MAGENTA}━━━ $* ━━━${NC}\n"; }
log_step()    { echo -e "${CYAN}[STEP]${NC}  $*"; }

# Print usage/help
usage() {
    cat <<EOF
${BOLD}Daiyaan's Dotfiles Installer${NC}

Usage:
  $(basename "$0") [OPTIONS]

Options:
  --all         Install all configurations without interactive menu
  --dry-run     Show what would be done without making changes
  --help        Show this help message

Description:
  Installs dotfiles from ${DOTFILES_DIR} to your home directory.
  Creates backups of existing files before overwriting.
  Detects your Linux distribution and installs required packages.
EOF
    exit 0
}

# Run a command, respecting dry-run mode
run_cmd() {
    if [[ "$DRY_RUN" == true ]]; then
        echo -e "  ${YELLOW}DRY-RUN:${NC} $*"
        return 0
    fi
    "$@"
}

# Check if a command exists
cmd_exists() {
    command -v "$1" &>/dev/null
}

#===============================================================================
# DISTRO DETECTION
#===============================================================================

detect_distro() {
    # --- macOS ---
    if [[ "$(uname -s)" == "Darwin" ]]; then
        DISTRO_ID="macos"
        DISTRO_NAME="macOS"
        DISTRO_FAMILY="macos"
        PKG_MANAGER="brew"
        log_info "Detected: ${DISTRO_NAME}"
        log_info "Package manager: ${PKG_MANAGER}"
        log_info "Distribution family: ${DISTRO_FAMILY}"
        return
    fi

    log_step "Detecting Linux distribution..."

    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        DISTRO_ID="$ID"
        DISTRO_NAME="$NAME"
        DISTRO_ID_LIKE="${ID_LIKE:-}"
    elif [[ -f /etc/arch-release ]]; then
        DISTRO_ID="arch"
        DISTRO_NAME="Arch Linux"
    elif [[ -f /etc/debian_version ]]; then
        DISTRO_ID="debian"
        DISTRO_NAME="Debian"
    elif [[ -f /etc/fedora-release ]]; then
        DISTRO_ID="fedora"
        DISTRO_NAME="Fedora"
    else
        DISTRO_ID="unknown"
        DISTRO_NAME="Unknown Linux Distribution"
    fi

    DISTRO_ID="${DISTRO_ID,,}" # lowercase

    log_info "Detected: ${DISTRO_NAME} (${DISTRO_ID})"

    # Normalize variants
    case "$DISTRO_ID" in
        manjaro|endeavouros|arcolinux|garuda)
            PKG_MANAGER="pacman"
            DISTRO_FAMILY="arch"
            ;;
        ubuntu|debian|pop|linuxmint|elementary|zorin)
            PKG_MANAGER="apt"
            DISTRO_FAMILY="debian"
            ;;
        fedora)
            PKG_MANAGER="dnf"
            DISTRO_FAMILY="fedora"
            ;;
        # Atomic/immutable Fedora variants — use brew for CLI tools
        aurora|bluefin|silverblue|kinoite|sericea|onyx|vanilla|socra|fool)
            PKG_MANAGER="brew"
            DISTRO_FAMILY="immutable"
            ;;
        opensuse*|suse)
            PKG_MANAGER="zypper"
            DISTRO_FAMILY="opensuse"
            ;;
        *)
            # Try to detect package manager
            if   cmd_exists pacman; then PKG_MANAGER="pacman"; DISTRO_FAMILY="arch"
            elif cmd_exists apt;    then PKG_MANAGER="apt";    DISTRO_FAMILY="debian"
            elif cmd_exists dnf;    then PKG_MANAGER="dnf";    DISTRO_FAMILY="fedora"
            elif cmd_exists zypper; then PKG_MANAGER="zypper"; DISTRO_FAMILY="opensuse"
            elif cmd_exists brew;   then PKG_MANAGER="brew";   DISTRO_FAMILY="brew"
            else
                log_error "Could not detect package manager."
                log_error "Please install packages manually."
                PKG_MANAGER="unknown"
                DISTRO_FAMILY="unknown"
            fi
            ;;
    esac

    log_info "Package manager: ${PKG_MANAGER}"
    log_info "Distribution family: ${DISTRO_FAMILY}"
}

#===============================================================================
# PACKAGE INSTALLATION
#===============================================================================

install_packages() {
    log_header "Package Installation"

    if [[ "$PKG_MANAGER" == "unknown" ]]; then
        log_warn "No supported package manager detected. Skipping package installation."
        log_warn "Install the required packages manually (see the script for the list)."
        return
    fi

    # --- Homebrew (macOS, Aurora, Bluefin, or fallback) ---
    if [[ "$PKG_MANAGER" == "brew" ]]; then
        install_brew_packages
        return
    fi

    # Check if we have sudo/root access
    if ! cmd_exists sudo && [[ "$EUID" -ne 0 ]]; then
        log_warn "No sudo access. Skipping package installation."
        log_warn "Install the required packages manually or run as root."
        return
    fi

    # --- Define packages per distro ---

    # Core packages (universal names)
    local core_pkgs=()
    local shell_pkgs=()
    local wm_pkgs=()
    local term_pkgs=()
    local editor_pkgs=()
    local fm_pkgs=()
    local pdf_pkgs=()
    local music_pkgs=()
    local sys_pkgs=()
    local dev_pkgs=()

    case "$DISTRO_FAMILY" in
        arch)
            # Core
            core_pkgs=(zsh git curl wget neovim python python-pip)

            # Shell
            shell_pkgs=(zsh-completions zsh-autosuggestions zsh-syntax-highlighting fzf)
            # powerlevel10k available in AUR, starship in community
            # We'll install starship from the main repo, p10k from AUR later

            # Window Manager
            wm_pkgs=(i3-wm i3lock i3status rofi dunst picom polybar)

            # Terminal
            term_pkgs=(kitty alacritty)

            # Editor
            editor_pkgs=(neovim vim)

            # File Manager
            fm_pkgs=(ranger bat lsd)

            # PDF
            pdf_pkgs=(zathura zathura-pdf-mupdf)

            # Music
            music_pkgs=(cmus)

            # System
            sys_pkgs=(fastfetch htop tree)

            # Dev
            dev_pkgs=(nodejs npm gh go rust cargo)
            ;;

        debian)
            # Core
            core_pkgs=(zsh git curl wget neovim python3 python3-pip)

            # Shell
            shell_pkgs=(zsh-syntax-highlighting zsh-autosuggestions fzf)
            # zsh-completions comes with zsh-common on Debian

            # Window Manager
            wm_pkgs=(i3-wm i3lock i3status rofi dunst picom polybar)
            # Note: picom on Debian may be an older version
            # polybar may need to be built from source on older Debian

            # Terminal
            term_pkgs=(kitty alacritty)

            # Editor
            editor_pkgs=(neovim vim)

            # File Manager
            fm_pkgs=(ranger bat lsd)

            # PDF
            pdf_pkgs=(zathura zathura-pdf-mupdf)

            # Music
            music_pkgs=(cmus)

            # System
            sys_pkgs=(fastfetch htop tree)

            # Dev
            dev_pkgs=(nodejs npm gh golang cargo)
            ;;

        fedora)
            # Core
            core_pkgs=(zsh git curl wget neovim python3 python3-pip)

            # Shell
            shell_pkgs=(zsh-syntax-highlighting zsh-autosuggestions fzf)

            # Window Manager
            wm_pkgs=(i3 i3lock i3status rofi dunst picom polybar)

            # Terminal
            term_pkgs=(kitty alacritty)

            # Editor
            editor_pkgs=(neovim vim)

            # File Manager
            fm_pkgs=(ranger bat lsd)

            # PDF
            pdf_pkgs=(zathura zathura-pdf-mupdf)

            # Music
            music_pkgs=(cmus)

            # System
            sys_pkgs=(fastfetch htop tree)

            # Dev
            dev_pkgs=(nodejs npm gh golang cargo)
            ;;

        opensuse)
            # Core
            core_pkgs=(zsh git curl wget neovim python3 python3-pip)

            # Shell
            shell_pkgs=(zsh-syntax-highlighting zsh-autosuggestions fzf)

            # Window Manager
            wm_pkgs=(i3 i3lock i3status rofi dunst picom polybar)

            # Terminal
            term_pkgs=(kitty alacritty)

            # Editor
            editor_pkgs=(neovim vim)

            # File Manager
            fm_pkgs=(ranger bat lsd)

            # PDF
            pdf_pkgs=(zathura zathura-pdf-mupdf)

            # Music
            music_pkgs=(cmus)

            # System
            sys_pkgs=(fastfetch htop tree)

            # Dev
            dev_pkgs=(nodejs npm gh golang cargo)
            ;;
    esac

    # Combine all packages
    local all_pkgs=()
    all_pkgs+=("${core_pkgs[@]}")
    all_pkgs+=("${shell_pkgs[@]}")
    all_pkgs+=("${wm_pkgs[@]}")
    all_pkgs+=("${term_pkgs[@]}")
    all_pkgs+=("${editor_pkgs[@]}")
    all_pkgs+=("${fm_pkgs[@]}")
    all_pkgs+=("${pdf_pkgs[@]}")
    all_pkgs+=("${music_pkgs[@]}")
    all_pkgs+=("${sys_pkgs[@]}")
    all_pkgs+=("${dev_pkgs[@]}")

    # Remove duplicates
    local -A seen
    local unique_pkgs=()
    for pkg in "${all_pkgs[@]}"; do
        if [[ -z "${seen[$pkg]:-}" ]]; then
            unique_pkgs+=("$pkg")
            seen[$pkg]=1
        fi
    done

    log_info "Packages to install: ${unique_pkgs[*]}"

    # Install
    log_step "Installing packages with ${PKG_MANAGER}..."
    case "$PKG_MANAGER" in
        pacman)
            log_info "Running: sudo pacman -S --needed --noconfirm ${unique_pkgs[*]}"
            if [[ "$DRY_RUN" == false ]]; then
                sudo pacman -S --needed --noconfirm "${unique_pkgs[@]}" 2>&1 | tail -5 || log_warn "Some packages may not have installed correctly."
            fi
            ;;
        apt)
            log_info "Running: sudo apt update && sudo apt install -y ${unique_pkgs[*]}"
            if [[ "$DRY_RUN" == false ]]; then
                sudo apt update 2>&1 | tail -2
                sudo apt install -y "${unique_pkgs[@]}" 2>&1 | tail -5 || log_warn "Some packages may not have installed correctly."
            fi
            ;;
        dnf)
            log_info "Running: sudo dnf install -y ${unique_pkgs[*]}"
            if [[ "$DRY_RUN" == false ]]; then
                sudo dnf install -y "${unique_pkgs[@]}" 2>&1 | tail -5 || log_warn "Some packages may not have installed correctly."
            fi
            ;;
        zypper)
            log_info "Running: sudo zypper install -y ${unique_pkgs[*]}"
            if [[ "$DRY_RUN" == false ]]; then
                sudo zypper install -y "${unique_pkgs[@]}" 2>&1 | tail -5 || log_warn "Some packages may not have installed correctly."
            fi
            ;;
    esac
    log_success "Package installation complete."
}

#===============================================================================
# HOMEBREW PACKAGE INSTALLATION (macOS, Aurora, Bluefin)
#===============================================================================

install_brew_packages() {
    log_header "Homebrew Package Installation"

    # Ensure Homebrew is installed
    if ! cmd_exists brew; then
        log_step "Installing Homebrew..."
        if [[ "$DRY_RUN" == false ]]; then
            if cmd_exists curl; then
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" 2>&1 | tail -5
            elif cmd_exists wget; then
                /bin/bash -c "$(wget -qO- https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" 2>&1 | tail -5
            else
                log_error "Neither curl nor wget found. Cannot install Homebrew."
                return 1
            fi

            # Add brew to PATH for this session
            if [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
                eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
            elif [[ -x /opt/homebrew/bin/brew ]]; then
                eval "$(/opt/homebrew/bin/brew shellenv)"
            fi

            if cmd_exists brew; then
                log_success "Homebrew installed."
            else
                log_error "Homebrew installation failed."
                return 1
            fi
        else
            log_info "  DRY-RUN: Would install Homebrew"
        fi
    else
        log_success "Homebrew already installed."
    fi

    # --- Brew package lists ---
    # Note: brew package names differ from system packages
    local core_pkgs=(zsh git curl wget neovim python)
    local shell_pkgs=(fzf)
    local fm_pkgs=(ranger bat lsd)
    local sys_pkgs=(htop tree)
    local dev_pkgs=(node gh go rust)

    # Combine all packages
    local all_pkgs=()
    all_pkgs+=("${core_pkgs[@]}")
    all_pkgs+=("${shell_pkgs[@]}")
    all_pkgs+=("${fm_pkgs[@]}")
    all_pkgs+=("${sys_pkgs[@]}")
    all_pkgs+=("${dev_pkgs[@]}")

    # Remove duplicates
    local -A seen
    local unique_pkgs=()
    for pkg in "${all_pkgs[@]}"; do
        if [[ -z "${seen[$pkg]:-}" ]]; then
            unique_pkgs+=("$pkg")
            seen[$pkg]=1
        fi
    done

    log_info "Packages to install: ${unique_pkgs[*]}"

    log_step "Installing packages with brew..."
    if [[ "$DRY_RUN" == false ]]; then
        brew install "${unique_pkgs[@]}" 2>&1 | tail -10 || log_warn "Some packages may not have installed correctly."
    else
        log_info "  DRY-RUN: Would run: brew install ${unique_pkgs[*]}"
    fi

    # On immutable Linux (Aurora/Bluefin), also layer WM/terminal packages via rpm-ostree
    if [[ "$DISTRO_FAMILY" == "immutable" ]] && cmd_exists rpm-ostree; then
        log_header "System Packages (rpm-ostree layering)"
        log_info "Layering WM and terminal packages via rpm-ostree (requires reboot)..."

        local system_pkgs=(i3-wm i3lock i3status rofi dunst picom polybar kitty alacritty zathura zathura-pdf-mupdf cmus)

        if [[ "$DRY_RUN" == false ]]; then
            sudo rpm-ostree install --apply-live "${system_pkgs[@]}" 2>&1 | tail -10 || log_warn "Some system packages may not have installed correctly."
            log_info "A reboot may be required for all changes to take effect."
        else
            log_info "  DRY-RUN: Would run: sudo rpm-ostree install --apply-live ${system_pkgs[*]}"
        fi
    fi

    log_success "Package installation complete."
}

#===============================================================================
# MNEMORIA INSTALLATION
#===============================================================================

install_mnemoria() {
    log_header "Mnemoria Installation"

    if cmd_exists mnemoria; then
        log_success "Mnemoria already installed."
        return 0
    fi

    log_step "Installing mnemoria..."
    if [[ "$DRY_RUN" == false ]]; then
        local mnemoria_tmp
        mnemoria_tmp="$(mktemp)"
        if curl -fsSL https://raw.githubusercontent.com/one-bit/oc-mnemoria/main/install.sh -o "$mnemoria_tmp" 2>&1 | tail -1; then
            if sh "$mnemoria_tmp" 2>&1 | tail -5; then
                log_success "Mnemoria installed."
            else
                log_warn "Mnemoria install script encountered issues (may be partially installed)."
            fi
        else
            log_warn "Failed to download mnemoria install script."
            log_warn "Install manually from: https://github.com/one-bit/oc-mnemoria"
        fi
        rm -f "$mnemoria_tmp"
    else
        log_info "  DRY-RUN: Would run mnemoria install script"
    fi
}

#===============================================================================
# GITHUB CLI AUTHENTICATION
#===============================================================================

setup_gh_auth() {
    log_header "GitHub CLI Authentication"

    if ! cmd_exists gh; then
        log_warn "GitHub CLI (gh) is not installed. Skipping authentication."
        return 0
    fi

    # Check if already authenticated
    if gh auth status &>/dev/null; then
        log_success "GitHub CLI is already authenticated."
        local gh_user
        gh_user="$(gh api user -q '.login' 2>/dev/null)"
        if [[ -n "$gh_user" ]]; then
            log_info "Logged in as: $gh_user"
        fi
        return 0
    fi

    log_step "GitHub CLI is not authenticated."
    echo -e "${YELLOW}Would you like to authenticate with GitHub now?${NC} (y/N): "
    read -r auth_choice

    if [[ "${auth_choice,,}" == "y" ]]; then
        log_step "Starting GitHub CLI authentication..."
        log_info "This will open a browser for GitHub OAuth."
        log_info "If browser doesn't open, copy the URL printed below."
        echo ""

        if [[ "$DRY_RUN" == false ]]; then
            gh auth login --web --git-protocol https 2>&1 || {
                log_warn "Web authentication failed. Trying device flow..."
                gh auth login -p https -w 2>&1
            }

            # Verify authentication
            if gh auth status &>/dev/null; then
                log_success "GitHub CLI authenticated successfully!"
                local gh_user
                gh_user="$(gh api user -q '.login' 2>/dev/null)"
                if [[ -n "$gh_user" ]]; then
                    log_info "Logged in as: $gh_user"
                fi
            else
                log_warn "GitHub CLI authentication may have failed."
                log_info "You can run 'gh auth login' manually later."
            fi
        else
            log_info "  DRY-RUN: Would run 'gh auth login --web'"
        fi
    else
        log_info "Skipping GitHub CLI authentication."
        log_info "You can run 'gh auth login' later to authenticate."
    fi
}

#===============================================================================
# BACKUP FUNCTION
#===============================================================================

backup_existing() {
    local src="$1"
    if [[ -e "$src" ]] || [[ -L "$src" ]]; then
        local dest="${BACKUP_DIR}/$(echo "$src" | sed "s|^/||" | tr '/' '_')"
        log_info "Backing up: $src → $dest"
        if [[ "$DRY_RUN" == false ]]; then
            mkdir -p "$(dirname "$dest")"
            mv "$src" "$dest"
        fi
    fi
    return 0
}

#===============================================================================
# SYMLINK FUNCTION
#===============================================================================

create_symlink() {
    local target="$1"   # Path in the dotfiles repo
    local link_name="$2" # Where to create the symlink
    local description="${3:-}"

    # Ensure target exists in repo
    if [[ ! -e "$target" ]]; then
        log_warn "Source not found: $target (skipping)"
        return 1
    fi

    if [[ -n "$description" ]]; then
        log_step "Installing: $description"
    fi

    # Check if link_name already exists
    if [[ -L "$link_name" ]]; then
        local current_target
        current_target="$(readlink "$link_name")"
        if [[ "$current_target" == "$target" ]]; then
            log_info "  Already linked correctly: $link_name → $target"
            return 0
        fi
        log_info "  Removing existing symlink: $link_name"
        if [[ "$DRY_RUN" == false ]]; then
            rm -f "$link_name"
        fi
    elif [[ -e "$link_name" ]]; then
        backup_existing "$link_name"
    fi

    # Ensure parent directory exists
    if [[ "$DRY_RUN" == false ]]; then
        mkdir -p "$(dirname "$link_name")"
    fi

    log_info "  Symlink: $link_name → $target"
    if [[ "$DRY_RUN" == false ]]; then
        ln -sf "$target" "$link_name"
    fi
    return 0
}

#===============================================================================
# OH MY ZSH INSTALLATION
#===============================================================================

install_oh_my_zsh() {
    log_header "Oh My Zsh Installation"

    if [[ -d "$HOME/.oh-my-zsh" ]]; then
        log_info "Oh My Zsh is already installed at ~/.oh-my-zsh"
    else
        log_step "Installing Oh My Zsh..."
        if [[ "$DRY_RUN" == false ]]; then
            # Install Oh My Zsh unattended
            export RUNZSH=no
            export CHSH=no
            if cmd_exists curl; then
                sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended 2>&1 | tail -3
            elif cmd_exists wget; then
                sh -c "$(wget -qO- https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended 2>&1 | tail -3
            else
                log_error "Neither curl nor wget found. Cannot install Oh My Zsh."
                return 1
            fi
            log_success "Oh My Zsh installed."
        else
            log_info "  DRY-RUN: Would install Oh My Zsh"
        fi
    fi

    # Install powerlevel10k theme if using Oh My Zsh
    local p10k_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
    if [[ ! -d "$p10k_dir" ]]; then
        log_step "Installing Powerlevel10k theme..."
        if [[ "$DRY_RUN" == false ]]; then
            git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$p10k_dir" 2>&1 | tail -2
            log_success "Powerlevel10k installed."
        else
            log_info "  DRY-RUN: Would clone Powerlevel10k to $p10k_dir"
        fi
    else
        log_info "Powerlevel10k already installed."
    fi

    # Install custom plugins
    local custom_plugins_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins"

    # zsh-autosuggestions
    if [[ ! -d "${custom_plugins_dir}/zsh-autosuggestions" ]]; then
        log_step "Installing zsh-autosuggestions plugin..."
        if [[ "$DRY_RUN" == false ]]; then
            git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions.git "${custom_plugins_dir}/zsh-autosuggestions" 2>&1 | tail -1
        fi
    fi

    # zsh-completions
    if [[ ! -d "${custom_plugins_dir}/zsh-completions" ]]; then
        log_step "Installing zsh-completions plugin..."
        if [[ "$DRY_RUN" == false ]]; then
            git clone --depth=1 https://github.com/zsh-users/zsh-completions.git "${custom_plugins_dir}/zsh-completions" 2>&1 | tail -1
        fi
    fi

    # zsh-you-should-use
    if [[ ! -d "${custom_plugins_dir}/zsh-you-should-use" ]]; then
        log_step "Installing zsh-you-should-use plugin..."
        if [[ "$DRY_RUN" == false ]]; then
            git clone --depth=1 https://github.com/MichaelAquilina/zsh-you-should-use.git "${custom_plugins_dir}/zsh-you-should-use" 2>&1 | tail -1
        fi
    fi

    # fzf-tab
    if [[ ! -d "${custom_plugins_dir}/fzf-tab" ]]; then
        log_step "Installing fzf-tab plugin..."
        if [[ "$DRY_RUN" == false ]]; then
            git clone --depth=1 https://github.com/Aloxaf/fzf-tab.git "${custom_plugins_dir}/fzf-tab" 2>&1 | tail -1
        fi
    fi

    # Backup existing .zshrc
    if [[ -f "$HOME/.zshrc" ]]; then
        log_step "Backing up existing .zshrc..."
        backup_existing "$HOME/.zshrc"
    fi
    if [[ -f "$HOME/.zsh_history" ]]; then
        backup_existing "$HOME/.zsh_history"
    fi
    if [[ -f "$HOME/.zsh_logout" ]]; then
        backup_existing "$HOME/.zsh_logout"
    fi

    # Generate a new .zshrc that uses Oh My Zsh while preserving the user's settings
    log_step "Generating new .zshrc with Oh My Zsh..."
    if [[ "$DRY_RUN" == false ]]; then
        cat > "$HOME/.zshrc" << 'ZSHRC_EOF'
#===============================================================================
# Daiyaan's .zshrc — Managed by Daiyaan_Dotfiles
# Generated by install.sh — replaces Antigen with Oh My Zsh
#===============================================================================

# Enable Powerlevel10k instant prompt. Should stay close to the top.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
    source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Auto-start X on tty1
if [[ -z "$DISPLAY" ]] && [[ "$(tty)" = /dev/tty1 ]]; then
    exec startx
fi

#===============================================================================
# PATH & ENVIRONMENT VARIABLES
#===============================================================================

export EDITOR="nvim"
export VISUAL="nvim"

# Local bin
export PATH="$HOME/.local/bin:$PATH"
export PATH="$PATH:$HOME/.local/bin"

# Ruby gems
export PATH="$HOME/.local/share/gem/ruby/3.0.0/bin:$PATH"

# Pyenv
export PATH="$HOME/.pyenv/bin:$PATH"

# NPM global
export PATH="${HOME}/.npm-global/bin:${PATH}"

# Android SDK
export ANDROID_HOME="$HOME/Android/Sdk"
export ANDROID_SDK_ROOT="$ANDROID_HOME"
export PATH="$PATH:$ANDROID_HOME/platform-tools"
export PATH="$PATH:$ANDROID_HOME/emulator"
export PATH="$PATH:$ANDROID_HOME/cmdline-tools/latest/bin"

# JDK
export PATH="jdk/bin:$PATH"

# XKB
export XKB_DEFAULT_OPTIONS=caps:escape

# Qt platform theme
export QT_QPA_PLATFORMTHEME=qt5ct

# ROCm / GPU
export HSA_ENABLE_SDMA=0
export ROCM_FORCE_ENABLE_DP_FP16=1
export HSA_OVERRIDE_GFX_VERSION=10.3.0

# Ollama
export OLLAMA_FLASH_ATTENTION=1
export OLLAMA_KV_CACHE_TYPE=q8_0

# Python startup
export PYTHONSTARTUP="$HOME/Repositories/Daiyaan_Dotfiles/ipython.py"

# LS_COLORS
LS_COLORS='rs=0:di=01;34:ln=01;36:mh=00:pi=40;33:so=01;35:do=01;35:bd=40;33;01:cd=40;33;01:or=40;31;01:mi=00:su=37;41:sg=30;43:ca=30;41:tw=30;42:ow=34;42:st=37;44:ex=01;32:*.tar=01;31:*.tgz=01;31:*.arc=01;31:*.arj=01;31:*.taz=01;31:*.lha=01;31:*.lz4=01;31:*.lzh=01;31:*.lzma=01;31:*.tlz=01;31:*.txz=01;31:*.tzo=01;31:*.t7z=01;31:*.zip=01;31:*.z=01;31:*.dz=01;31:*.gz=01;31:*.lrz=01;31:*.lz=01;31:*.lzo=01;31:*.xz=01;31:*.zst=01;31:*.tzst=01;31:*.bz2=01;31:*.bz=01;31:*.tbz=01;31:*.tbz2=01;31:*.tz=01;31:*.deb=01;31:*.rpm=01;31:*.jar=01;31:*.war=01;31:*.ear=01;31:*.sar=01;31:*.rar=01;31:*.alz=01;31:*.ace=01;31:*.zoo=01;31:*.cpio=01;31:*.7z=01;31:*.rz=01;31:*.cab=01;31:*.wim=01;31:*.swm=01;31:*.dwm=01;31:*.esd=01;31:*.jpg=01;35:*.jpeg=01;35:*.mjpg=01;35:*.mjpeg=01;35:*.gif=01;35:*.bmp=01;35:*.pbm=01;35:*.pgm=01;35:*.ppm=01;35:*.tga=01;35:*.xbm=01;35:*.xpm=01;35:*.tif=01;35:*.tiff=01;35:*.png=01;35:*.svg=01;35:*.svgz=01;35:*.mng=01;35:*.pcx=01;35:*.mov=01;35:*.mpg=01;35:*.mpeg=01;35:*.m2v=01;35:*.mkv=01;35:*.webm=01;35:*.webp=01;35:*.ogm=01;35:*.mp4=01;35:*.m4v=01;35:*.mp4v=01;35:*.vob=01;35:*.qt=01;35:*.nuv=01;35:*.wmv=01;35:*.asf=01;35:*.rm=01;35:*.rmvb=01;35:*.flc=01;35:*.avi=01;35:*.fli=01;35:*.flv=01;35:*.gl=01;35:*.dl=01;35:*.xcf=01;35:*.xwd=01;35:*.yuv=01;35:*.cgm=01;35:*.emf=01;35:*.ogv=01;35:*.ogx=01;35:*.aac=00;36:*.au=00;36:*.flac=00;36:*.m4a=00;36:*.mid=00;36:*.midi=00;36:*.mka=00;36:*.mp3=00;36:*.mpc=00;36:*.ogg=00;36:*.ra=00;36:*.wav=00;36:*.oga=00;36:*.opus=00;36:*.spx=00;36:*.xspf=00;36:'
export LS_COLORS
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
export CLICOLOR=1

#===============================================================================
# OH MY ZSH
#===============================================================================

# Path to Oh My Zsh
export ZSH="$HOME/.oh-my-zsh"

# Theme: Powerlevel10k
ZSH_THEME="powerlevel10k/powerlevel10k"

# Oh My Zsh plugins
plugins=(
    git
    colored-man-pages
    zsh-autosuggestions
    zsh-completions
    zsh-you-should-use
    fzf-tab
    fzf
)

source "$ZSH/oh-my-zsh.sh"

#===============================================================================
# EXTERNAL PLUGIN SOURCES (from ~/Repositories/Zsh-plugins/)
#===============================================================================

# Git plugin (custom)
[[ -f ~/Repositories/Zsh-plugins/git/git.plugin.zsh ]] && source ~/Repositories/Zsh-plugins/git/git.plugin.zsh

# Bash completion fallback
[[ -f ~/Repositories/Zsh-plugins/zsh-bash-completions-fallback/zsh-bash-completions-fallback.plugin.zsh ]] && source ~/Repositories/Zsh-plugins/zsh-bash-completions-fallback/zsh-bash-completions-fallback.plugin.zsh

# History substring search
[[ -f ~/Repositories/Zsh-plugins/zsh-history-substring-search/zsh-history-substring-search.zsh ]] && source ~/Repositories/Zsh-plugins/zsh-history-substring-search/zsh-history-substring-search.zsh

# Fast syntax highlighting (must be last sourced)
[[ -f ~/Repositories/Zsh-plugins/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh ]] && source ~/Repositories/Zsh-plugins/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh

#===============================================================================
# HISTORY SETTINGS
#===============================================================================

HISTFILE="$HOME/.zsh_history"
HISTSIZE=5120
SAVEHIST=5120
setopt appendhistory sharehistory extended_history hist_ignore_dups hist_ignore_space

#===============================================================================
# GENERAL OPTIONS
#===============================================================================

setopt autocd beep extendedglob nomatch notify
setopt autopushd pushd_silent pushd_to_home pushd_ignore_dups pushd_minus
DIRSTACKSIZE=20

#===============================================================================
# COMPLETION SETTINGS
#===============================================================================

zstyle :compinstall filename "$HOME/.zshrc"
autoload -Uz compinit promptinit
compinit

zstyle ':completion:*' matcher-list \
    'm:{[:lower:][:upper:]}={[:upper:][:lower:]}' \
    'm:{[:lower:][:upper:]}={[:upper:][:lower:]} l:|=* r:|=*' \
    'm:{[:lower:][:upper:]}={[:upper:][:lower:]} l:|=* r:|=*' \
    'm:{[:lower:][:upper:]}={[:upper:][:lower:]} l:|=* r:|=*'

zstyle ':completion:*' menu select
zstyle ':completion:*' rehash true
zstyle ':completion::complete:*' gain-privileges 1
setopt complete_aliases

#===============================================================================
# VI MODE SETTINGS
#===============================================================================

bindkey -v
KEYTIMEOUT=5

# Cursor shape for different vi modes
function zle-keymap-select {
    if [[ ${KEYMAP} == vicmd ]] || [[ $1 = 'block' ]]; then
        echo -ne '\e[1 q'
    elif [[ ${KEYMAP} == main ]] || [[ ${KEYMAP} == viins ]] || [[ ${KEYMAP} = '' ]] || [[ $1 = 'beam' ]]; then
        echo -ne '\e[5 q'
    fi
}
zle -N zle-keymap-select

# Use beam cursor on startup
echo -ne '\e[5 q'

# Use beam cursor for each new prompt
preexec() { echo -ne '\e[5 q' }

#===============================================================================
# KEY BINDINGS
#===============================================================================

typeset -g -A key
key[Home]="${terminfo[khome]}"
key[End]="${terminfo[kend]}"
key[Insert]="${terminfo[kich1]}"
key[Backspace]="${terminfo[kbs]}"
key[Delete]="${terminfo[kdch1]}"
key[Up]="${terminfo[kcuu1]}"
key[Down]="${terminfo[kcud1]}"
key[Left]="${terminfo[kcub1]}"
key[Right]="${terminfo[kcuf1]}"
key[PageUp]="${terminfo[kpp]}"
key[PageDown]="${terminfo[knp]}"
key[Shift-Tab]="${terminfo[kcbt]}"

[[ -n "${key[Home]}"      ]] && bindkey -- "${key[Home]}"       beginning-of-line
[[ -n "${key[End]}"       ]] && bindkey -- "${key[End]}"        end-of-line
[[ -n "${key[Insert]}"    ]] && bindkey -- "${key[Insert]}"     overwrite-mode
[[ -n "${key[Backspace]}" ]] && bindkey -- "${key[Backspace]}"  backward-delete-char
[[ -n "${key[Delete]}"    ]] && bindkey -- "${key[Delete]}"     delete-char
[[ -n "${key[Up]}"        ]] && bindkey -- "${key[Up]}"         up-line-or-history
[[ -n "${key[Down]}"      ]] && bindkey -- "${key[Down]}"       down-line-or-history
[[ -n "${key[Left]}"      ]] && bindkey -- "${key[Left]}"       backward-char
[[ -n "${key[Right]}"     ]] && bindkey -- "${key[Right]}"      forward-char
[[ -n "${key[PageUp]}"    ]] && bindkey -- "${key[PageUp]}"     beginning-of-buffer-or-history
[[ -n "${key[PageDown]}"  ]] && bindkey -- "${key[PageDown]}"   end-of-buffer-or-history
[[ -n "${key[Shift-Tab]}" ]] && bindkey -- "${key[Shift-Tab]}"  reverse-menu-complete

# Terminal application mode
if (( ${+terminfo[smkx]} && ${+terminfo[rmkx]} )); then
    autoload -Uz add-zle-hook-widget
    function zle_application_mode_start { echoti smkx }
    function zle_application_mode_stop { echoti rmkx }
    add-zle-hook-widget -Uz zle-line-init zle_application_mode_start
    add-zle-hook-widget -Uz zle-line-finish zle_application_mode_stop
fi

# Up/Down search in history
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
[[ -n "${key[Up]}"   ]] && bindkey -- "${key[Up]}"   up-line-or-beginning-search
[[ -n "${key[Down]}" ]] && bindkey -- "${key[Down]}" down-line-or-beginning-search

key[Control-Left]="${terminfo[kLFT5]}"
key[Control-Right]="${terminfo[kRIT5]}"
[[ -n "${key[Control-Left]}"  ]] && bindkey -- "${key[Control-Left]}"  backward-word
[[ -n "${key[Control-Right]}" ]] && bindkey -- "${key[Control-Right]}" forward-word

#===============================================================================
# DIRECTORY STACK
#===============================================================================

autoload -Uz add-zsh-hook
DIRSTACKFILE="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/dirs"
if [[ -f "$DIRSTACKFILE" ]] && (( ${#dirstack} == 0 )); then
    dirstack=("${(@f)"$(< "$DIRSTACKFILE")"}")
    [[ -d "${dirstack[1]}" ]] && cd -- "${dirstack[1]}"
fi
chpwd_dirstack() {
    print -l -- "$PWD" "${(u)dirstack[@]}" > "$DIRSTACKFILE"
}
add-zsh-hook -Uz chpwd chpwd_dirstack

#===============================================================================
# CUSTOM KEYBINDINGS
#===============================================================================

# Ctrl+\ → ncmpcpp
ncmpcppShow() {
    BUFFER="ncmpcpp"
    zle accept-line
}
zle -N ncmpcppShow
bindkey '^[\' ncmpcppShow

# Alt+Up → cd parent
cdParentKey() {
    pushd ..
    zle reset-prompt
    print
    ls
    zle reset-prompt
}
zle -N cdParentKey
bindkey '^[[1;3A' cdParentKey

# Alt+Left → cd undo
cdUndoKey() {
    popd
    zle reset-prompt
    print
    ls
    zle reset-prompt
}
zle -N cdUndoKey
bindkey '^[[1;3D' cdUndoKey

# Edit command line in vim
autoload edit-command-line
zle -N edit-command-line
bindkey -M vicmd v edit-command-line

setopt EXTENDED_GLOB

#===============================================================================
# ALIASES
#===============================================================================

# Modern ls
alias ls='lsd -FAlX1 --group-dirs first --date relative --git --blocks permission --blocks size --blocks date --blocks name'
alias ll='lsd -FAl --total-size --group-dirs first --sort extension'
alias tree='lsd --tree'

# Shortcuts
alias c="clear"
alias o="opencode"
alias v="~/Repositories/Daiyaan_Dotfiles/OpenWithMetadata.sh"
alias freespace='df --sync -h /'
alias n="fastfetch"
alias ip='ip -c'
alias f='fzf'
alias polybar='bash ~/.config/polybar/launch.sh'
alias grep='grep --line-number -i --color=always'
alias p='~/.config/i3/screenshot.sh'
alias u='unipicker --copy'
alias d='dirs -v'
alias rm='rm -rfv'
alias make='make -s'
alias xclip='xclip -sel clip'
alias python='python -q'
alias bat='bat --theme=TwoDark'
alias dmenu_run="dmenu_run -fn JetBrainsMono:style=bold:size=12 -nb '#000000' -nf '#fffefe' -sb '#0a7aca' -sf '#fffefe'"

#===============================================================================
# POWERLEVEL10K & PYENV
#===============================================================================

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Pyenv
eval "$(pyenv init --path 2>/dev/null)"
eval "$(pyenv init - 2>/dev/null)"

# oh-my-opencode-slim background subagents
export OPENCODE_EXPERIMENTAL_BACKGROUND_SUBAGENTS=true
ZSHRC_EOF
        log_success "New .zshrc generated at $HOME/.zshrc"
    else
        log_info "  DRY-RUN: Would generate new .zshrc at $HOME/.zshrc"
    fi

    # Symlink .p10k.zsh from repo
    if [[ -f "$DOTFILES_DIR/.p10k.zsh" ]]; then
        create_symlink "$DOTFILES_DIR/.p10k.zsh" "$HOME/.p10k.zsh" "Powerlevel10k config"
    fi

    log_success "Oh My Zsh setup complete."
}

#===============================================================================
# ZSH PLUGINS CLONING
#===============================================================================

install_zsh_plugins() {
    log_header "Zsh Plugins (~/Repositories/Zsh-plugins/)"

    local plugins_dir="$HOME/Repositories/Zsh-plugins"

    if [[ "$DRY_RUN" == false ]]; then
        mkdir -p "$plugins_dir"
    fi

    # Define plugins: name → git URL
    declare -A zsh_plugins=(
        ["fast-syntax-highlighting"]="https://github.com/zdharma-continuum/fast-syntax-highlighting.git"
        ["git"]="https://github.com/davidde/git.git"
        ["zsh-bash-completions-fallback"]="https://github.com/3v1n0/zsh-bash-completions-fallback.git"
        ["zsh-history-substring-search"]="https://github.com/zsh-users/zsh-history-substring-search.git"
    )

    for name in "${!zsh_plugins[@]}"; do
        local url="${zsh_plugins[$name]}"
        local dest="$plugins_dir/$name"

        if [[ -d "$dest" ]]; then
            log_info "Already cloned: $name"
            continue
        fi

        log_step "Cloning $name..."
        if [[ "$DRY_RUN" == false ]]; then
            if git clone --depth=1 "$url" "$dest" 2>&1 | tail -2; then
                log_success "Cloned: $name"
            else
                log_warn "Failed to clone: $name ($url)"
            fi
        else
            log_info "  DRY-RUN: Would clone $url → $dest"
        fi
    done

    log_success "Zsh plugins setup complete."
}

#===============================================================================
# FONT INSTALLATION
#===============================================================================

install_fonts() {
    log_header "Font Installation"

    local font_dir="$HOME/.local/share/fonts"
    if [[ "$DRY_RUN" == false ]]; then
        mkdir -p "$font_dir"
    fi

    # --- Nerd Fonts ---
    local nerd_fonts=(
        "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/JetBrainsMono.zip"
        "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/FiraCode.zip"
    )

    for url in "${nerd_fonts[@]}"; do
        local filename
        filename="$(basename "$url")"
        local font_name="${filename%.zip}"

        # Check if already installed
        if ls "$font_dir"/"$font_name"* &>/dev/null 2>&1; then
            log_info "Nerd Font already installed: $font_name"
            continue
        fi

        log_step "Downloading: $filename"
        local tmp_dir
        tmp_dir="$(mktemp -d)"

        if [[ "$DRY_RUN" == false ]]; then
            if cmd_exists curl; then
                curl -fSL "$url" -o "$tmp_dir/$filename" 2>&1 | tail -1
            elif cmd_exists wget; then
                wget -q "$url" -O "$tmp_dir/$filename" 2>&1 | tail -1
            else
                log_error "Neither curl nor wget found. Cannot download fonts."
                rm -rf "$tmp_dir"
                return 1
            fi

            log_step "Installing: $font_name"
            unzip -qo "$tmp_dir/$filename" -d "$tmp_dir/$font_name" 2>/dev/null
            # Move only .ttf and .otf files
            find "$tmp_dir/$font_name" -maxdepth 1 \( -name "*.ttf" -o -name "*.otf" \) -exec cp -f {} "$font_dir/" \;
            rm -rf "$tmp_dir"
            log_success "Installed: $font_name"
        else
            log_info "  DRY-RUN: Would download and install $font_name"
        fi
    done

    # --- Bangla Fonts ---
    log_step "Installing Bangla fonts..."
    local lbfi_bin="$HOME/.local/bin/lbfi"

    if cmd_exists fc-list && fc-list :lang=bn | grep -q .; then
        log_info "Bangla fonts appear to already be installed."
    else
        if [[ "$DRY_RUN" == false ]]; then
            mkdir -p "$HOME/.local/bin"
            if cmd_exists curl; then
                curl -fSL --no-check-certificate \
                    "https://raw.githubusercontent.com/fahadahammed/linux-bangla-fonts/master/dist/lbfi" \
                    -o "$lbfi_bin" 2>&1 | tail -1
            elif cmd_exists wget; then
                wget --no-check-certificate -q \
                    "https://raw.githubusercontent.com/fahadahammed/linux-bangla-fonts/master/dist/lbfi" \
                    -O "$lbfi_bin" 2>&1 | tail -1
            fi
            chmod +x "$lbfi_bin"
            "$lbfi_bin" 2>&1 | tail -5 || log_warn "Bangla font install may have partially failed."
            log_success "Bangla fonts installed."
        else
            log_info "  DRY-RUN: Would download and run lbfi for Bangla fonts"
        fi
    fi

    # Refresh font cache
    if [[ "$DRY_RUN" == false ]] && cmd_exists fc-cache; then
        log_step "Refreshing font cache..."
        fc-cache -f "$font_dir" 2>/dev/null
        log_success "Font cache refreshed."
    fi

    log_success "Font installation complete."
}

#===============================================================================
# ASTRONVIM INSTALLATION
#===============================================================================

install_astronvim() {
    log_header "AstroNvim Installation"

    # Backup existing nvim configs
    log_step "Backing up existing Neovim configurations..."
    backup_existing "$HOME/.config/nvim"
    backup_existing "$HOME/.local/share/nvim"
    backup_existing "$HOME/.local/state/nvim"
    backup_existing "$HOME/.cache/nvim"

    log_step "Installing AstroNvim..."
    if [[ "$DRY_RUN" == false ]]; then
        if cmd_exists git; then
            git clone --depth 1 "https://github.com/AstroNvim/template" "$HOME/.config/nvim" 2>&1 | tail -3
            rm -rf "$HOME/.config/nvim/.git"
            log_success "AstroNvim installed to ~/.config/nvim"
        else
            log_error "git is required to install AstroNvim."
            return 1
        fi
    else
        log_info "  DRY-RUN: Would install AstroNvim to ~/.config/nvim"
    fi

    # Install vim-plug for .vimrc (legacy vim)
    if [[ ! -f "$HOME/.vim/autoload/plug.vim" ]]; then
        log_step "Installing vim-plug for legacy Vim..."
        if [[ "$DRY_RUN" == false ]]; then
            curl -fLo "$HOME/.vim/autoload/plug.vim" --create-dirs \
                "https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim" 2>&1 | tail -1 || log_warn "vim-plug installation failed."
        fi
    fi
}

#===============================================================================
# OPENCODE INSTALLATION
#===============================================================================

install_opencode() {
    log_header "OpenCode Installation"

    # Check if opencode is installed (check PATH and common install locations)
    local opencode_found=false
    if cmd_exists opencode; then
        opencode_found=true
    elif [[ -x "$HOME/.opencode/bin/opencode" ]]; then
        opencode_found=true
    elif [[ -x "$HOME/.local/bin/opencode" ]]; then
        opencode_found=true
    fi

    if [[ "$opencode_found" == true ]]; then
        local opencode_path
        opencode_path="$(command -v opencode 2>/dev/null || echo "$HOME/.opencode/bin/opencode")"
        log_success "OpenCode already installed at: $opencode_path"
    else
        log_step "Installing OpenCode..."
        if [[ "$DRY_RUN" == false ]]; then
            if cmd_exists curl; then
                curl -fsSL https://opencode.ai/install | bash 2>&1 | tail -5
            else
                log_error "curl is required to install OpenCode."
                return 1
            fi

            # Add opencode bin to PATH for this session
            if [[ -d "$HOME/.opencode/bin" ]]; then
                export PATH="$HOME/.opencode/bin:$PATH"
            fi

            # Verify installation
            if cmd_exists opencode || [[ -x "$HOME/.opencode/bin/opencode" ]]; then
                log_success "OpenCode installed successfully."
            else
                log_warn "OpenCode installation completed but binary not found in PATH."
                log_info "You may need to restart your shell or add OpenCode to your PATH."
            fi
        else
            log_info "  DRY-RUN: Would install OpenCode via curl -fsSL https://opencode.ai/install | bash"
        fi
    fi

    # Symlink opencode config
    if [[ -d "$DOTFILES_DIR/opencode" ]] && [[ -f "$DOTFILES_DIR/opencode/opencode.jsonc" ]]; then
        log_step "Setting up OpenCode configuration..."

        # Ensure ~/.config/opencode exists
        if [[ "$DRY_RUN" == false ]]; then
            mkdir -p "$HOME/.config/opencode"
        fi

        # Symlink each config file individually
        local opencode_files=(
            "opencode.jsonc"
            "tui.json"
            "oh-my-opencode-slim.json"
            "dcp.jsonc"
        )

        for f in "${opencode_files[@]}"; do
            if [[ -f "$DOTFILES_DIR/opencode/$f" ]]; then
                create_symlink "$DOTFILES_DIR/opencode/$f" "$HOME/.config/opencode/$f" "OpenCode config: $f"
            fi
        done

        # Symlink skills directory
        if [[ -d "$DOTFILES_DIR/opencode/skills" ]]; then
            # Remove existing skills dir if it's not from our repo
            if [[ -d "$HOME/.config/opencode/skills" ]] && [[ ! -L "$HOME/.config/opencode/skills" ]]; then
                backup_existing "$HOME/.config/opencode/skills"
            fi
            create_symlink "$DOTFILES_DIR/opencode/skills" "$HOME/.config/opencode/skills" "OpenCode skills"
        fi

        log_success "OpenCode configuration symlinked."
    else
        log_warn "OpenCode configuration directory not found in dotfiles repo."
    fi
}

#===============================================================================
# OPENCODE PLUGINS INSTALLATION
#===============================================================================

install_opencode_plugins() {
    log_header "OpenCode Plugins Installation"

    # Locate opencode config file
    local config_file=""
    if [[ -f "$HOME/.config/opencode/opencode.jsonc" ]]; then
        config_file="$HOME/.config/opencode/opencode.jsonc"
    elif [[ -f "$HOME/.config/opencode/opencode.json" ]]; then
        config_file="$HOME/.config/opencode/opencode.json"
    else
        log_warn "OpenCode config not found at \$HOME/.config/opencode/opencode.jsonc"
        log_warn "Run 'install_opencode' first or install opencode manually."
        return 1
    fi

    # python3 is required for JSONC manipulation
    if ! cmd_exists python3; then
        log_error "python3 is required for OpenCode plugins configuration."
        log_error "Install python3 and try again."
        return 1
    fi

    # Determine mode: install all without prompting?
    local install_all_plugins=false
    if [[ "$INSTALL_ALL" == true ]] || [[ "${1:-}" == "--all" ]]; then
        install_all_plugins=true
    fi

    #---------------------------------------------------------------------------
    # update_opencode_config()
    # Safely merge entries into the JSONC config using python3.
    # Supports: add-plugin, add-mcp, add-instruction, set-compaction
    # Idempotent — skips entries that already exist.
    #---------------------------------------------------------------------------
    update_opencode_config() {
        python3 -c "$(cat << 'PYEOF'
import json, sys, re

config_file = sys.argv[1]
args = sys.argv[2:]

def strip_comments(text):
    """Remove JSONC comments (// and /* */) while preserving strings."""
    result = []
    i = 0
    in_string = False
    string_char = None
    while i < len(text):
        ch = text[i]
        if in_string:
            result.append(ch)
            if ch == '\\':
                i += 1
                if i < len(text):
                    result.append(text[i])
            elif ch == string_char:
                in_string = False
        elif ch in ('"', "'"):
            in_string = True
            string_char = ch
            result.append(ch)
        elif ch == '/' and i + 1 < len(text):
            next_ch = text[i + 1]
            if next_ch == '/':
                # Line comment — skip to end of line
                i = text.find('\n', i)
                if i == -1:
                    break
                continue
            elif next_ch == '*':
                # Block comment — skip to */
                end = text.find('*/', i + 2)
                if end == -1:
                    break
                i = end + 1
                continue
            else:
                result.append(ch)
        else:
            result.append(ch)
        i += 1
    return ''.join(result)

with open(config_file, 'r') as f:
    content = f.read()

# Strip comments before parsing
content = strip_comments(content)
config = json.loads(content)

i = 0
while i < len(args):
    cmd = args[i]
    if cmd == 'add-mcp':
        name = args[i + 1]
        url = args[i + 2]
        if 'mcp' not in config:
            config['mcp'] = {}
        if name not in config['mcp']:
            config['mcp'][name] = {'type': 'remote', 'url': url, 'enabled': True}
        i += 3
    elif cmd == 'add-plugin':
        plugin = args[i + 1]
        if 'plugin' not in config:
            config['plugin'] = []
        if plugin not in config['plugin']:
            config['plugin'].append(plugin)
        i += 2
    elif cmd == 'add-instruction':
        instr = args[i + 1]
        if 'instructions' not in config:
            config['instructions'] = []
        if instr not in config['instructions']:
            config['instructions'].append(instr)
        i += 2
    elif cmd == 'set-compaction':
        auto_val = args[i + 1] == 'true'
        prune_val = args[i + 2] == 'true'
        config['compaction'] = {'auto': auto_val, 'prune': prune_val}
        i += 3
    else:
        i += 1

with open(config_file, 'w') as f:
    json.dump(config, f, indent=2)
    f.write('\n')
PYEOF
        )" "$config_file" "$@"
    }

    #---------------------------------------------------------------------------
    # 1. TypeUI MCP (remote)
    #---------------------------------------------------------------------------
    echo ""
    if $install_all_plugins; then
        log_step "1/7 — TypeUI MCP..."
        if [[ "$DRY_RUN" == false ]]; then
            update_opencode_config add-mcp typeui https://mcp.typeui.sh
            log_success "TypeUI MCP configured."
        else
            log_info "  DRY-RUN: Would add TypeUI MCP (typeui → https://mcp.typeui.sh)"
        fi
    else
        echo -e "  ${YELLOW}[y/N]${NC} Install TypeUI MCP (remote UI generation server)?"
        read -r resp
        if [[ "${resp,,}" == "y" ]]; then
            log_step "1/7 — TypeUI MCP..."
            if [[ "$DRY_RUN" == false ]]; then
                update_opencode_config add-mcp typeui https://mcp.typeui.sh
                log_success "TypeUI MCP configured."
            else
                log_info "  DRY-RUN: Would add TypeUI MCP"
            fi
        else
            log_step "1/7 — TypeUI MCP: skipped"
        fi
    fi

    #---------------------------------------------------------------------------
    # 2. opencode-shell-strategy (git clone + instruction)
    #---------------------------------------------------------------------------
    if $install_all_plugins; then
        log_step "2/7 — opencode-shell-strategy..."
        if [[ "$DRY_RUN" == false ]]; then
            local ss_dir="$HOME/.config/opencode/plugin/shell-strategy"
            if [[ ! -d "$ss_dir" ]]; then
                mkdir -p "$HOME/.config/opencode/plugin"
                if git clone --depth=1 https://github.com/JRedeker/opencode-shell-strategy.git "$ss_dir" 2>&1 | tail -2; then
                    log_success "shell-strategy cloned to $ss_dir"
                else
                    log_warn "Failed to clone shell-strategy repository."
                fi
            else
                log_info "shell-strategy already cloned at $ss_dir"
            fi
            update_opencode_config add-instruction "~/.config/opencode/plugin/shell-strategy/shell_strategy.md"
            log_success "shell-strategy instruction added."
        else
            log_info "  DRY-RUN: Would clone shell-strategy and add instruction"
        fi
    else
        echo -e "  ${YELLOW}[y/N]${NC} Install shell-strategy (agent workflow instructions via git clone)?"
        read -r resp
        if [[ "${resp,,}" == "y" ]]; then
            log_step "2/7 — opencode-shell-strategy..."
            if [[ "$DRY_RUN" == false ]]; then
                local ss_dir="$HOME/.config/opencode/plugin/shell-strategy"
                if [[ ! -d "$ss_dir" ]]; then
                    mkdir -p "$HOME/.config/opencode/plugin"
                    if git clone --depth=1 https://github.com/JRedeker/opencode-shell-strategy.git "$ss_dir" 2>&1 | tail -2; then
                        log_success "shell-strategy cloned to $ss_dir"
                    else
                        log_warn "Failed to clone shell-strategy repository."
                    fi
                else
                    log_info "shell-strategy already cloned at $ss_dir"
                fi
                update_opencode_config add-instruction "~/.config/opencode/plugin/shell-strategy/shell_strategy.md"
                log_success "shell-strategy instruction added."
            else
                log_info "  DRY-RUN: Would clone shell-strategy and add instruction"
            fi
        else
            log_step "2/7 — opencode-shell-strategy: skipped"
        fi
    fi

    #---------------------------------------------------------------------------
    # 3. opencode-research-papers
    #---------------------------------------------------------------------------
    if $install_all_plugins; then
        log_step "3/7 — opencode-research-papers..."
        if [[ "$DRY_RUN" == false ]]; then
            update_opencode_config add-plugin "opencode-research-papers"
            log_success "opencode-research-papers configured."
        else
            log_info "  DRY-RUN: Would add opencode-research-papers plugin"
        fi
    else
        echo -e "  ${YELLOW}[y/N]${NC} Install opencode-research-papers plugin?"
        read -r resp
        if [[ "${resp,,}" == "y" ]]; then
            log_step "3/7 — opencode-research-papers..."
            if [[ "$DRY_RUN" == false ]]; then
                update_opencode_config add-plugin "opencode-research-papers"
                log_success "opencode-research-papers configured."
            else
                log_info "  DRY-RUN: Would add opencode-research-papers plugin"
            fi
        else
            log_step "3/7 — opencode-research-papers: skipped"
        fi
    fi

    #---------------------------------------------------------------------------
    # 4. opencode-snip (binary + plugin)
    #---------------------------------------------------------------------------
    if $install_all_plugins; then
        log_step "4/7 — opencode-snip..."
        if [[ "$DRY_RUN" == false ]]; then
            if ! cmd_exists snip; then
                if cmd_exists go; then
                    log_step "Installing snip binary via 'go install'..."
                    if go install github.com/edouard-claude/snip/cmd/snip@latest 2>&1 | tail -3; then
                        log_success "snip binary installed via go."
                    else
                        log_warn "Failed to install snip via go."
                        log_warn "Download manually from: https://github.com/edouard-claude/snip/releases"
                    fi
                else
                    log_warn "Go is not installed. Cannot install snip binary automatically."
                    log_warn "Install Go or download the binary from:"
                    log_warn "  https://github.com/edouard-claude/snip/releases"
                fi
            else
                log_info "snip binary already installed."
            fi
            update_opencode_config add-plugin "opencode-snip@latest"
            log_success "opencode-snip configured."
        else
            log_info "  DRY-RUN: Would install snip binary and add plugin"
        fi
    else
        echo -e "  ${YELLOW}[y/N]${NC} Install opencode-snip (command snippet manager + plugin)?"
        read -r resp
        if [[ "${resp,,}" == "y" ]]; then
            log_step "4/7 — opencode-snip..."
            if [[ "$DRY_RUN" == false ]]; then
                if ! cmd_exists snip; then
                    if cmd_exists go; then
                        log_step "Installing snip binary via 'go install'..."
                        if go install github.com/edouard-claude/snip/cmd/snip@latest 2>&1 | tail -3; then
                            log_success "snip binary installed via go."
                        else
                            log_warn "Failed to install snip via go."
                            log_warn "Download manually from: https://github.com/edouard-claude/snip/releases"
                        fi
                    else
                        log_warn "Go is not installed. Cannot install snip binary automatically."
                        log_warn "Install Go or download the binary from:"
                        log_warn "  https://github.com/edouard-claude/snip/releases"
                    fi
                else
                    log_info "snip binary already installed."
                fi
                update_opencode_config add-plugin "opencode-snip@latest"
                log_success "opencode-snip configured."
            else
                log_info "  DRY-RUN: Would install snip binary and add plugin"
            fi
        else
            log_step "4/7 — opencode-snip: skipped"
        fi
    fi

    #---------------------------------------------------------------------------
    # 5. opencode-log-sanitizer
    #---------------------------------------------------------------------------
    if $install_all_plugins; then
        log_step "5/7 — opencode-log-sanitizer..."
        if [[ "$DRY_RUN" == false ]]; then
            update_opencode_config add-plugin "opencode-log-sanitizer"
            log_success "opencode-log-sanitizer configured."
        else
            log_info "  DRY-RUN: Would add opencode-log-sanitizer plugin"
        fi
    else
        echo -e "  ${YELLOW}[y/N]${NC} Install opencode-log-sanitizer plugin?"
        read -r resp
        if [[ "${resp,,}" == "y" ]]; then
            log_step "5/7 — opencode-log-sanitizer..."
            if [[ "$DRY_RUN" == false ]]; then
                update_opencode_config add-plugin "opencode-log-sanitizer"
                log_success "opencode-log-sanitizer configured."
            else
                log_info "  DRY-RUN: Would add opencode-log-sanitizer plugin"
            fi
        else
            log_step "5/7 — opencode-log-sanitizer: skipped"
        fi
    fi

    #---------------------------------------------------------------------------
    # 6. oc-mnemoria (install script handles everything)
    #---------------------------------------------------------------------------
    if $install_all_plugins; then
        log_step "6/7 — oc-mnemoria..."
        if [[ "$DRY_RUN" == false ]]; then
            if cmd_exists mnemoria; then
                log_info "oc-mnemoria CLI already installed."
            else
                log_step "Downloading and running oc-mnemoria install script..."
                local mnemoria_tmp
                mnemoria_tmp="$(mktemp)"
                if curl -fsSL https://raw.githubusercontent.com/one-bit/oc-mnemoria/main/install.sh -o "$mnemoria_tmp" 2>&1 | tail -1; then
                    if sh "$mnemoria_tmp" 2>&1 | tail -5; then
                        log_success "oc-mnemoria installed."
                    else
                        log_warn "oc-mnemoria install script encountered issues (may be partially installed)."
                    fi
                else
                    log_warn "Failed to download oc-mnemoria install script."
                    log_warn "Install manually from: https://github.com/one-bit/oc-mnemoria"
                fi
                rm -f "$mnemoria_tmp"
            fi
        else
            log_info "  DRY-RUN: Would run oc-mnemoria install script"
        fi
    else
        echo -e "  ${YELLOW}[y/N]${NC} Install oc-mnemoria (memory & session management)?"
        read -r resp
        if [[ "${resp,,}" == "y" ]]; then
            log_step "6/7 — oc-mnemoria..."
            if [[ "$DRY_RUN" == false ]]; then
                if cmd_exists mnemoria; then
                    log_info "oc-mnemoria CLI already installed."
                else
                    log_step "Downloading and running oc-mnemoria install script..."
                    local mnemoria_tmp
                    mnemoria_tmp="$(mktemp)"
                    if curl -fsSL https://raw.githubusercontent.com/one-bit/oc-mnemoria/main/install.sh -o "$mnemoria_tmp" 2>&1 | tail -1; then
                        if sh "$mnemoria_tmp" 2>&1 | tail -5; then
                            log_success "oc-mnemoria installed."
                        else
                            log_warn "oc-mnemoria install script encountered issues (may be partially installed)."
                        fi
                    else
                        log_warn "Failed to download oc-mnemoria install script."
                        log_warn "Install manually from: https://github.com/one-bit/oc-mnemoria"
                    fi
                    rm -f "$mnemoria_tmp"
                fi
            else
                log_info "  DRY-RUN: Would run oc-mnemoria install script"
            fi
        else
            log_step "6/7 — oc-mnemoria: skipped"
        fi
    fi

    #---------------------------------------------------------------------------
    # 7. magic-context (install script or manual fallback)
    #---------------------------------------------------------------------------
    if $install_all_plugins; then
        log_step "7/7 — magic-context..."
        if [[ "$DRY_RUN" == false ]]; then
            local mc_tmp
            mc_tmp="$(mktemp)"
            if curl -fsSL https://raw.githubusercontent.com/cortexkit/magic-context/master/scripts/install.sh -o "$mc_tmp" 2>&1 | tail -1; then
                if sh "$mc_tmp" 2>&1 | tail -5; then
                    log_success "magic-context installed via script."
                else
                    log_warn "magic-context install script failed — applying manual config..."
                    update_opencode_config add-plugin "@cortexkit/opencode-magic-context"
                    update_opencode_config set-compaction false false
                    log_success "magic-context manually configured."
                fi
            else
                log_warn "Failed to download magic-context install script — applying manual config..."
                update_opencode_config add-plugin "@cortexkit/opencode-magic-context"
                update_opencode_config set-compaction false false
                log_success "magic-context manually configured."
            fi
            rm -f "$mc_tmp"
        else
            log_info "  DRY-RUN: Would install magic-context via script or manual config"
        fi
    else
        echo -e "  ${YELLOW}[y/N]${NC} Install magic-context (context management plugin)?"
        read -r resp
        if [[ "${resp,,}" == "y" ]]; then
            log_step "7/7 — magic-context..."
            if [[ "$DRY_RUN" == false ]]; then
                local mc_tmp
                mc_tmp="$(mktemp)"
                if curl -fsSL https://raw.githubusercontent.com/cortexkit/magic-context/master/scripts/install.sh -o "$mc_tmp" 2>&1 | tail -1; then
                    if sh "$mc_tmp" 2>&1 | tail -5; then
                        log_success "magic-context installed via script."
                    else
                        log_warn "magic-context install script failed — applying manual config..."
                        update_opencode_config add-plugin "@cortexkit/opencode-magic-context"
                        update_opencode_config set-compaction false false
                        log_success "magic-context manually configured."
                    fi
                else
                    log_warn "Failed to download magic-context install script — applying manual config..."
                    update_opencode_config add-plugin "@cortexkit/opencode-magic-context"
                    update_opencode_config set-compaction false false
                    log_success "magic-context manually configured."
                fi
                rm -f "$mc_tmp"
            else
                log_info "  DRY-RUN: Would install magic-context"
            fi
        else
            log_step "7/7 — magic-context: skipped"
        fi
    fi

    log_success "OpenCode plugins installation complete."
}

#===============================================================================
# CONFIGURATION INSTALLATION FUNCTIONS
#===============================================================================

install_shell_configs() {
    log_header "Shell Configurations"
    create_symlink "$DOTFILES_DIR/.zshrc"   "$HOME/.zshrc"   "Zsh config"
    create_symlink "$DOTFILES_DIR/.bashrc"  "$HOME/.bashrc"  "Bash config"
    create_symlink "$DOTFILES_DIR/.p10k.zsh" "$HOME/.p10k.zsh" "Powerlevel10k config"
    create_symlink "$DOTFILES_DIR/.xinitrc" "$HOME/.xinitrc" "Xinitrc"
    create_symlink "$DOTFILES_DIR/.Xresources" "$HOME/.Xresources" "Xresources"
    create_symlink "$DOTFILES_DIR/base.ini" "$HOME/.config/fast-syntax-highlighting/base.ini" "Fast syntax highlighting theme"
}

install_wm_configs() {
    log_header "Window Manager Configurations"
    create_symlink "$DOTFILES_DIR/i3/config" "$HOME/.config/i3/config" "i3 config"
    create_symlink "$DOTFILES_DIR/i3/wallpaper.sh" "$HOME/.config/i3/wallpaper.sh" "i3 wallpaper script"
    create_symlink "$DOTFILES_DIR/i3/shutdown.sh" "$HOME/.config/i3/shutdown.sh" "i3 shutdown script"
    create_symlink "$DOTFILES_DIR/i3/edit_config.sh" "$HOME/.config/i3/edit_config.sh" "i3 edit config script"
    create_symlink "$DOTFILES_DIR/i3/pulseaudio-polybar.sh" "$HOME/.config/i3/pulseaudio-polybar.sh" "i3 pulseaudio script"
    create_symlink "$DOTFILES_DIR/polybar/config" "$HOME/.config/polybar/config" "Polybar config"
    create_symlink "$DOTFILES_DIR/polybar/launch.sh" "$HOME/.config/polybar/launch.sh" "Polybar launch script"
    create_symlink "$DOTFILES_DIR/dunst/dunstrc" "$HOME/.config/dunst/dunstrc" "Dunst notification config"
    create_symlink "$DOTFILES_DIR/picom/picom.conf" "$HOME/.config/picom/picom.conf" "Picom compositor config"

    # Awesome WM (optional, if user wants it)
    if [[ -f "$DOTFILES_DIR/awesome/rc.lua" ]]; then
        create_symlink "$DOTFILES_DIR/awesome/rc.lua" "$HOME/.config/awesome/rc.lua" "Awesome WM config (optional)"
    fi
}

install_terminal_configs() {
    log_header "Terminal Configurations"

    # Kitty: symlink dark theme as default kitty.conf (switch_theme.sh toggles between dark/light)
    create_symlink "$DOTFILES_DIR/kitty/dark.kitty.conf" "$HOME/.config/kitty/kitty.conf" "Kitty config (dark default)"
    create_symlink "$DOTFILES_DIR/kitty/dark.kitty.conf" "$HOME/.config/kitty/dark.kitty.conf" "Kitty dark theme"
    create_symlink "$DOTFILES_DIR/kitty/light.kitty.conf" "$HOME/.config/kitty/light.kitty.conf" "Kitty light theme"
    create_symlink "$DOTFILES_DIR/kitty/unipicker.sh" "$HOME/.config/kitty/unipicker.sh" "Kitty unipicker"
    create_symlink "$DOTFILES_DIR/alacritty/alacritty.yml" "$HOME/.config/alacritty/alacritty.yml" "Alacritty config"
    create_symlink "$DOTFILES_DIR/termite/config" "$HOME/.config/termite/config" "Termite config"
}

install_editor_configs() {
    log_header "Editor Configurations"

    # Install AstroNvim instead of symlinking legacy nvim
    install_astronvim

    # Legacy .vimrc
    create_symlink "$DOTFILES_DIR/.vimrc" "$HOME/.vimrc" "Vim config (legacy)"
}

install_file_manager_configs() {
    log_header "File Manager Configurations"
    create_symlink "$DOTFILES_DIR/ranger/rc.conf" "$HOME/.config/ranger/rc.conf" "Ranger config"
    create_symlink "$DOTFILES_DIR/ranger/commands.py" "$HOME/.config/ranger/commands.py" "Ranger commands"
    create_symlink "$DOTFILES_DIR/ranger/scope.sh" "$HOME/.config/ranger/scope.sh" "Ranger scope"
    create_symlink "$DOTFILES_DIR/ranger/rifle.conf" "$HOME/.config/ranger/rifle.conf" "Ranger rifle"
    # Ranger colorschemes
    if [[ -d "$DOTFILES_DIR/ranger/colorschemes" ]]; then
        create_symlink "$DOTFILES_DIR/ranger/colorschemes" "$HOME/.config/ranger/colorschemes" "Ranger colorschemes"
    fi
}

install_pdf_configs() {
    log_header "PDF Viewer Configuration"
    create_symlink "$DOTFILES_DIR/zathura/zathurarc" "$HOME/.config/zathura/zathurarc" "Zathura config"
}

install_music_configs() {
    log_header "Music Player Configuration"
    # cmus stores config in ~/.config/cmus/
    create_symlink "$DOTFILES_DIR/cmus/rc" "$HOME/.config/cmus/rc" "Cmus config"
    create_symlink "$DOTFILES_DIR/cmus/autosave" "$HOME/.config/cmus/autosave" "Cmus autosave"
    create_symlink "$DOTFILES_DIR/cmus/command-history" "$HOME/.config/cmus/command-history" "Cmus command history"
    create_symlink "$DOTFILES_DIR/cmus/search-history" "$HOME/.config/cmus/search-history" "Cmus search history"
    # Playlists
    if [[ -d "$DOTFILES_DIR/cmus/playlists" ]]; then
        create_symlink "$DOTFILES_DIR/cmus/playlists" "$HOME/.config/cmus/playlists" "Cmus playlists"
    fi
}

install_system_info_configs() {
    log_header "System Info Configuration"
    # fastfetch config (if exists in repo)
    if [[ -d "$DOTFILES_DIR/fastfetch" ]]; then
        create_symlink "$DOTFILES_DIR/fastfetch" "$HOME/.config/fastfetch" "Fastfetch config"
    elif [[ -f "$DOTFILES_DIR/fastfetch.jsonc" ]]; then
        mkdir -p "$HOME/.config/fastfetch"
        create_symlink "$DOTFILES_DIR/fastfetch.jsonc" "$HOME/.config/fastfetch/config.jsonc" "Fastfetch config"
    fi
}

install_ai_assistant_configs() {
    log_header "AI Assistant Configuration"
    install_opencode
    install_opencode_plugins

    # Symlink ipython.py
    if [[ -f "$DOTFILES_DIR/ipython.py" ]]; then
        create_symlink "$DOTFILES_DIR/ipython.py" "$HOME/.ipython/profile_default/startup/imports.py" "IPython startup script"
    fi
}

install_scripts() {
    log_header "Scripts Installation"

    # switch_theme.sh → ~/.local/bin/
    if [[ -f "$DOTFILES_DIR/switch_theme.sh" ]]; then
        create_symlink "$DOTFILES_DIR/switch_theme.sh" "$HOME/.local/bin/switch_theme.sh" "Theme switcher script"
    fi

    # OpenWithMetadata.sh → ~/.local/bin/
    if [[ -f "$DOTFILES_DIR/OpenWithMetadata.sh" ]]; then
        create_symlink "$DOTFILES_DIR/OpenWithMetadata.sh" "$HOME/.local/bin/OpenWithMetadata.sh" "Open with metadata script"
    fi

    # Xorg mouse configs
    create_symlink "$DOTFILES_DIR/50-mouse-acceleration.conf" "/etc/X11/xorg.conf.d/50-mouse-acceleration.conf" "Mouse acceleration config"
    create_symlink "$DOTFILES_DIR/50-mouse-deceleration.conf" "/etc/X11/xorg.conf.d/50-mouse-deceleration.conf" "Mouse deceleration config"
}

#===============================================================================
# INTERACTIVE MENU
#===============================================================================

show_menu() {
    clear
    echo ""
    echo -e "${BOLD}${MAGENTA}┌─────────────────────────────────────────┐${NC}"
    echo -e "${BOLD}${MAGENTA}│     Daiyaan's Dotfiles Installer          │${NC}"
    echo -e "${BOLD}${MAGENTA}├─────────────────────────────────────────┤${NC}"
    echo -e "${BOLD}${MAGENTA}│${NC} Select configurations to install:           ${BOLD}${MAGENTA}│${NC}"
    echo -e "${BOLD}${MAGENTA}│${NC} ${YELLOW}[1]${NC} Shell (.zshrc, .bashrc, .p10k.zsh)      ${BOLD}${MAGENTA}│${NC}"
    echo -e "${BOLD}${MAGENTA}│${NC} ${YELLOW}[2]${NC} Window Manager (i3, polybar, dunst)      ${BOLD}${MAGENTA}│${NC}"
    echo -e "${BOLD}${MAGENTA}│${NC} ${YELLOW}[3]${NC} Terminal (kitty, alacritty)              ${BOLD}${MAGENTA}│${NC}"
    echo -e "${BOLD}${MAGENTA}│${NC} ${YELLOW}[4]${NC} Editor (AstroNvim, vim)                  ${BOLD}${MAGENTA}│${NC}"
    echo -e "${BOLD}${MAGENTA}│${NC} ${YELLOW}[5]${NC} File Manager (ranger)                    ${BOLD}${MAGENTA}│${NC}"
    echo -e "${BOLD}${MAGENTA}│${NC} ${YELLOW}[6]${NC} PDF Viewer (zathura)                     ${BOLD}${MAGENTA}│${NC}"
    echo -e "${BOLD}${MAGENTA}│${NC} ${YELLOW}[7]${NC} Music Player (cmus)                      ${BOLD}${MAGENTA}│${NC}"
    echo -e "${BOLD}${MAGENTA}│${NC} ${YELLOW}[8]${NC} System Info (fastfetch)                  ${BOLD}${MAGENTA}│${NC}"
    echo -e "${BOLD}${MAGENTA}│${NC} ${YELLOW}[9]${NC} AI Assistant (opencode)                  ${BOLD}${MAGENTA}│${NC}"
    echo -e "${BOLD}${MAGENTA}│${NC} ${YELLOW}[C]${NC} OpenCode Plugins (7 plugins)              ${BOLD}${MAGENTA}│${NC}"
    echo -e "${BOLD}${MAGENTA}│${NC} ${YELLOW}[S]${NC} Scripts (switch_theme, OpenWith)         ${BOLD}${MAGENTA}│${NC}"
    echo -e "${BOLD}${MAGENTA}│${NC} ${YELLOW}[F]${NC} Fonts (JetBrainsMono, FiraCode, Bangla) ${BOLD}${MAGENTA}│${NC}"
    echo -e "${BOLD}${MAGENTA}│${NC} ${YELLOW}[P]${NC} Install Required Packages                 ${BOLD}${MAGENTA}│${NC}"
    echo -e "${BOLD}${MAGENTA}│${NC} ${YELLOW}[G]${NC} Setup GitHub CLI Auth (gh auth login)    ${BOLD}${MAGENTA}│${NC}"
    echo -e "${BOLD}${MAGENTA}│${NC} ${YELLOW}[O]${NC} Install Oh My Zsh (replaces Antigen)      ${BOLD}${MAGENTA}│${NC}"
    echo -e "${BOLD}${MAGENTA}│${NC} ${YELLOW}[Z]${NC} Clone Zsh Plugins (fast-syntax etc.)     ${BOLD}${MAGENTA}│${NC}"
    echo -e "${BOLD}${MAGENTA}│${NC} ${GREEN}[A]${NC} Install ALL                                ${BOLD}${MAGENTA}│${NC}"
    echo -e "${BOLD}${MAGENTA}│${NC} ${RED}[Q]${NC} Quit                                         ${BOLD}${MAGENTA}│${NC}"
    echo -e "${BOLD}${MAGENTA}└─────────────────────────────────────────┘${NC}"
    echo ""
    echo -e "${BOLD}Enter your choices (e.g., ${YELLOW}1 2 3${NC}, ${GREEN}A${NC}, or ${RED}Q${NC}):${NC} "
    read -r choices
    echo ""

    # Normalize: uppercase
    choices="${choices^^}"

    # Quit
    if [[ "$choices" == "Q" ]]; then
        echo -e "${YELLOW}Installation cancelled.${NC}"
        exit 0
    fi

    # Install ALL
    if [[ "$choices" == "A" ]]; then
        install_all=true
        INSTALL_ALL=true  # Propagate to child functions (e.g., install_opencode_plugins)
    else
        install_all=false
    fi

    # Process choices
    local has_choice=false
    for choice in $choices; do
        has_choice=true
        case "$choice" in
            1|SHELL)    install_shell_configs ;;
            2|WM)       install_wm_configs ;;
            3|TERM)     install_terminal_configs ;;
            4|EDITOR)   install_editor_configs ;;
            5|FM)       install_file_manager_configs ;;
            6|PDF)      install_pdf_configs ;;
            7|MUSIC)    install_music_configs ;;
            8|SYSINFO)  install_system_info_configs ;;
            9|AI)       install_ai_assistant_configs ;;
            C|PLUGINS)  install_opencode_plugins ;;
            S|SCRIPTS)  install_scripts ;;
            F|FONTS)    install_fonts ;;
            P|PKGS)     install_packages ;;
            G|GH)       setup_gh_auth ;;
            O|OMZ)      install_oh_my_zsh ;;
            Z|ZSHPLUGINS) install_zsh_plugins ;;
            A|ALL)      ;;  # handled above
            Q|QUIT)     ;;  # handled above
            *)          log_warn "Unknown option: $choice" ;;
        esac
    done

    # If A was chosen, install everything
    if [[ "$install_all" == true ]]; then
        install_shell_configs
        install_wm_configs
        install_terminal_configs
        install_editor_configs
        install_file_manager_configs
        install_pdf_configs
        install_music_configs
        install_system_info_configs
        install_ai_assistant_configs
        install_scripts
        install_fonts
        install_zsh_plugins
        install_mnemoria
    fi

    # Only ask about packages and Oh My Zsh if not already selected
    if [[ "$install_all" == false ]] && ! echo "$choices" | grep -q 'P' && ! echo "$choices" | grep -q 'O'; then
        echo ""
        echo -e "${BOLD}${YELLOW}Additional options:${NC}"
        echo -e "  ${YELLOW}[y]${NC} Install required packages? (detected: ${DISTRO_NAME})"
        read -r install_pkgs_choice
        if [[ "${install_pkgs_choice,,}" == "y" ]]; then
            install_packages
            setup_gh_auth
        fi

        echo ""
        echo -e "  ${YELLOW}[y]${NC} Install Oh My Zsh (replaces Antigen)?"
        read -r install_omz_choice
        if [[ "${install_omz_choice,,}" == "y" ]]; then
            install_oh_my_zsh
        fi

        echo ""
        echo -e "  ${YELLOW}[y]${NC} Clone Zsh plugins (fast-syntax-highlighting, git, etc.)?"
        read -r install_zshplugins_choice
        if [[ "${install_zshplugins_choice,,}" == "y" ]]; then
            install_zsh_plugins
        fi
    fi
}

#===============================================================================
# MAIN
#===============================================================================

main() {
    echo ""
    echo -e "${BOLD}${MAGENTA}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${MAGENTA}║         Daiyaan's Dotfiles Installer           ║${NC}"
    echo -e "${BOLD}${MAGENTA}║     Repository: Daiyaan_Dotfiles               ║${NC}"
    echo -e "${BOLD}${MAGENTA}╚═══════════════════════════════════════════════╝${NC}"
    echo ""

    # Show dotfiles directory
    log_info "Dotfiles directory: $DOTFILES_DIR"

    # Create backup directory
    if [[ "$DRY_RUN" == false ]]; then
        mkdir -p "$BACKUP_DIR"
        log_info "Backup directory: $BACKUP_DIR"
    else
        log_info "${YELLOW}DRY RUN MODE${NC} — No changes will be made."
    fi
    echo ""

    # Detect distro
    detect_distro
    echo ""

    # Interactive menu or --all
    if [[ "$INSTALL_ALL" == true ]]; then
        log_info "Installing ALL configurations..."
        echo ""

        # Ask about packages
        echo -e "${BOLD}${YELLOW}Install required packages?${NC} (y/N): "
        read -r install_pkgs_choice
        if [[ "${install_pkgs_choice,,}" == "y" ]]; then
            install_packages
            setup_gh_auth
        fi

        # Ask about Oh My Zsh
        echo ""
        echo -e "${BOLD}${YELLOW}Install Oh My Zsh (replaces Antigen)?${NC} (y/N): "
        read -r install_omz_choice
        if [[ "${install_omz_choice,,}" == "y" ]]; then
            install_oh_my_zsh
        fi

        # Clone Zsh plugins
        install_zsh_plugins

        # Install all configs
        install_shell_configs
        install_wm_configs
        install_terminal_configs
        install_editor_configs
        install_file_manager_configs
        install_pdf_configs
        install_music_configs
        install_system_info_configs
        install_ai_assistant_configs
        install_scripts
        install_fonts
        install_mnemoria

        # Ask about Xorg configs (requires sudo)
        echo ""
        echo -e "${BOLD}${YELLOW}Install Xorg mouse configs (requires sudo)?${NC} (y/N): "
        read -r install_xorg_choice
        if [[ "${install_xorg_choice,,}" == "y" ]]; then
            log_header "Xorg Configurations"
            if [[ "$DRY_RUN" == false ]]; then
                sudo mkdir -p /etc/X11/xorg.conf.d/
                sudo ln -sf "$DOTFILES_DIR/50-mouse-acceleration.conf" /etc/X11/xorg.conf.d/50-mouse-acceleration.conf
                sudo ln -sf "$DOTFILES_DIR/50-mouse-deceleration.conf" /etc/X11/xorg.conf.d/50-mouse-deceleration.conf
                log_success "Xorg mouse configs installed."
            else
                log_info "  DRY-RUN: Would install Xorg mouse configs to /etc/X11/xorg.conf.d/"
            fi
        fi

    else
        # Show interactive menu
        show_menu

        # Ask about Xorg configs
        echo ""
        echo -e "${BOLD}${YELLOW}Install Xorg mouse configs (requires sudo)?${NC} (y/N): "
        read -r install_xorg_choice
        if [[ "${install_xorg_choice,,}" == "y" ]]; then
            log_header "Xorg Configurations"
            if [[ "$DRY_RUN" == false ]]; then
                sudo mkdir -p /etc/X11/xorg.conf.d/ 2>/dev/null || true
                sudo ln -sf "$DOTFILES_DIR/50-mouse-acceleration.conf" /etc/X11/xorg.conf.d/50-mouse-acceleration.conf 2>/dev/null || log_warn "Could not install Xorg mouse config (run with sudo)"
                sudo ln -sf "$DOTFILES_DIR/50-mouse-deceleration.conf" /etc/X11/xorg.conf.d/50-mouse-deceleration.conf 2>/dev/null || log_warn "Could not install Xorg mouse config (run with sudo)"
            fi
        fi
    fi

    # Wallpapers
    if [[ -d "$DOTFILES_DIR/Wallpapers" ]]; then
        if [[ "$INSTALL_ALL" == true ]]; then
            create_symlink "$DOTFILES_DIR/Wallpapers" "$HOME/Pictures/Dotfiles-Wallpapers" "Wallpapers collection"
        else
            echo ""
            echo -e "${BOLD}${YELLOW}Symlink Wallpapers to ~/Pictures/Dotfiles-Wallpapers?${NC} (y/N): "
            read -r install_wallpapers
            if [[ "${install_wallpapers,,}" == "y" ]]; then
                create_symlink "$DOTFILES_DIR/Wallpapers" "$HOME/Pictures/Dotfiles-Wallpapers" "Wallpapers collection"
            fi
        fi
    fi

    #===========================================================================
    # SUMMARY
    #===========================================================================
    echo ""
    echo -e "${BOLD}${GREEN}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${GREEN}║           Installation Complete!               ║${NC}"
    echo -e "${BOLD}${GREEN}╚═══════════════════════════════════════════════╝${NC}"
    echo ""

    if [[ "$DRY_RUN" == false ]]; then
        echo -e "  ${GREEN}✓${NC} Configs installed to their target locations"
        echo -e "  ${GREEN}✓${NC} Backups saved to: ${YELLOW}$BACKUP_DIR${NC}"
        echo ""
        echo -e "  ${BOLD}Post-installation notes:${NC}"
        echo -e "  ${YELLOW}→${NC} Log out and back in (or 'source ~/.zshrc') to apply shell changes"
        echo -e "  ${YELLOW}→${NC} For AstroNvim: run 'nvim' and wait for plugins to install"
        echo -e "  ${YELLOW}→${NC} For i3: run 'i3-msg reload' or restart i3"
        echo -e "  ${YELLOW}→${NC} For polybar: run '~/.config/polybar/launch.sh'"
        echo -e "  ${YELLOW}→${NC} For powerlevel10k: run 'p10k configure' to customize prompt"
        echo -e "  ${YELLOW}→${NC} For fonts: log out and back in (or reboot) for font changes to take effect"
        echo ""
        echo -e "  ${BOLD}If anything broke:${NC}"
        echo -e "  ${YELLOW}→${NC} Restore from backup: ${YELLOW}cp -r $BACKUP_DIR/* ~/${NC}"
        echo ""
    else
        echo -e "  ${YELLOW}⚠${NC} Dry run completed — no changes were made."
        echo -e "  ${YELLOW}⚠${NC} Run without --dry-run to actually install."
    fi
}

#===============================================================================
# ARGUMENT PARSING
#===============================================================================

for arg in "$@"; do
    case "$arg" in
        --all|--full)
            INSTALL_ALL=true
            ;;
        --dry-run|--dryrun)
            DRY_RUN=true
            ;;
        --help|-h)
            usage
            ;;
        *)
            log_warn "Unknown argument: $arg"
            usage
            ;;
    esac
done

#===============================================================================
# RUN
#===============================================================================
main
