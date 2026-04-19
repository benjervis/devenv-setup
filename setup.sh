#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# Mac Dev Environment Setup
# Run this on a fresh Mac to get to a normal dev environment.
# =============================================================================

DOTFILES_REPO="https://github.com/benjervis/dotfiles.git"

# Colours
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info()    { echo -e "${BLUE}==>${NC} $*"; }
success() { echo -e "${GREEN}✓${NC} $*"; }
warn()    { echo -e "${YELLOW}!${NC} $*"; }
error()   { echo -e "${RED}✗${NC} $*" >&2; exit 1; }

# =============================================================================
# 1. Xcode Command Line Tools
# =============================================================================
install_xcode_tools() {
  info "Checking Xcode Command Line Tools..."
  if xcode-select -p &>/dev/null; then
    success "Xcode CLT already installed"
  else
    info "Installing Xcode Command Line Tools (follow the prompt)..."
    xcode-select --install
    # Wait for installation to complete
    until xcode-select -p &>/dev/null; do sleep 5; done
    success "Xcode CLT installed"
  fi
}

# =============================================================================
# 2. Homebrew
# =============================================================================
install_homebrew() {
  info "Checking Homebrew..."
  if command -v brew &>/dev/null; then
    success "Homebrew already installed"
  else
    info "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Add brew to PATH for the rest of this script
    if [[ -f /opt/homebrew/bin/brew ]]; then
      eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
    success "Homebrew installed"
  fi

  # Ensure brew is on PATH (Apple Silicon)
  [[ -f /opt/homebrew/bin/brew ]] && eval "$(/opt/homebrew/bin/brew shellenv)"
}

# =============================================================================
# 3. Shell init files
# These are NOT managed by the dotfiles repo (they live in $HOME, not ~/.config)
# =============================================================================
setup_shell_init() {
  info "Setting up shell init files..."

  # ~/.zprofile — Homebrew env (needed for zsh sessions and scripts)
  if ! grep -q 'brew shellenv' ~/.zprofile 2>/dev/null; then
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
    success "Added Homebrew to ~/.zprofile"
  else
    success "~/.zprofile already configured"
  fi

  # ~/.zshenv — Cargo env (loaded by all zsh sessions)
  if ! grep -q 'cargo/env' ~/.zshenv 2>/dev/null; then
    echo '. "$HOME/.cargo/env"' >> ~/.zshenv
    success "Added Cargo to ~/.zshenv"
  else
    success "~/.zshenv already configured"
  fi
}

# =============================================================================
# 4. Rust via rustup
# =============================================================================
install_rust() {
  info "Checking Rust..."
  if command -v rustup &>/dev/null || [[ -f ~/.cargo/bin/rustup ]]; then
    success "Rust already installed"
  else
    info "Installing Rust via rustup..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path
    success "Rust installed"
  fi

  # Source cargo env for the rest of this script
  # shellcheck source=/dev/null
  [[ -f ~/.cargo/env ]] && . ~/.cargo/env

  # Install rust-analyzer component
  info "Installing rust-analyzer..."
  rustup component add rust-analyzer
  success "rust-analyzer installed"
}

# =============================================================================
# 5. Cargo tools (Rust tools, preferred over Homebrew where available)
# =============================================================================
install_cargo_tools() {
  info "Installing Cargo tools..."

  local tools=(
    ripgrep   # rg — fast grep replacement
    git-delta # delta — better git diffs
    zoxide    # z — smarter cd
    fnm       # Node.js version manager
  )

  for tool in "${tools[@]}"; do
    local bin_name
    case "$tool" in
      ripgrep)   bin_name="rg" ;;
      git-delta) bin_name="delta" ;;
      *)         bin_name="$tool" ;;
    esac

    if command -v "$bin_name" &>/dev/null || [[ -f ~/.cargo/bin/$bin_name ]]; then
      success "$tool already installed"
    else
      info "Installing $tool..."
      ~/.cargo/bin/cargo install "$tool"
      success "$tool installed"
    fi
  done

  # bat — custom fork with nvim preview support
  if [[ -f ~/.cargo/bin/bat ]]; then
    success "bat already installed"
  else
    info "Installing bat (custom fork)..."
    ~/.cargo/bin/cargo install --git https://github.com/benjervis/bat --branch add-file-modified-time
    success "bat installed"
  fi
}

# =============================================================================
# 6. Homebrew packages (tools not available via Cargo)
# =============================================================================
install_brew_packages() {
  info "Installing Homebrew packages..."

  local formulae=(
    bash        # modern bash (macOS ships bash 3.2 which lacks associative arrays)
    fish        # default shell
    neovim      # editor
    tmux        # terminal multiplexer
    lazygit     # TUI git client
    fzf         # fuzzy finder
    lua         # (required by neovim plugins)
    luajit
    git-lfs     # large file storage
  )

  for pkg in "${formulae[@]}"; do
    if brew list --formula "$pkg" &>/dev/null; then
      success "$pkg already installed"
    else
      info "Installing $pkg..."
      brew install "$pkg"
      success "$pkg installed"
    fi
  done

  # Fonts (casks)
  local casks=(
    font-symbols-only-nerd-font  # Nerd Font icons + Legacy Computing symbols for Neovim/tmux (use as Non-ASCII font in iTerm2)
  )

  for cask in "${casks[@]}"; do
    if brew list --cask "$cask" &>/dev/null; then
      success "$cask already installed"
    else
      info "Installing $cask..."
      brew install --cask "$cask"
      success "$cask installed"
    fi
  done
}

# =============================================================================
# 6b. Node.js via fnm
# =============================================================================
install_node() {
  info "Installing Node.js via fnm..."

  # fnm must be on PATH — it's installed via Homebrew above
  local fnm_bin
  fnm_bin="$(command -v fnm || echo /opt/homebrew/bin/fnm)"

  if ! "$fnm_bin" list 2>/dev/null | grep -q 'lts'; then
    info "Installing latest LTS Node.js..."
    "$fnm_bin" install --lts
    "$fnm_bin" default lts-latest
    success "Node.js LTS installed and set as default"
  else
    success "Node.js LTS already installed via fnm"
  fi
}

# =============================================================================
# 7. Dotfiles
# The dotfiles repo is cloned directly into ~/.config
# =============================================================================
install_dotfiles() {
  info "Setting up dotfiles..."

  if [[ -d ~/.config/.git ]]; then
    success "Dotfiles repo already present at ~/.config"
    info "Pulling latest..."
    git -C ~/.config pull --ff-only || warn "Could not fast-forward dotfiles — check for local changes"
  else
    if [[ -d ~/.config ]]; then
      warn "~/.config exists but is not a git repo. Moving to ~/.config.bak..."
      mv ~/.config ~/.config.bak
    fi
    info "Cloning dotfiles to ~/.config..."
    git clone "$DOTFILES_REPO" ~/.config
    success "Dotfiles cloned"
  fi

  # Wire up tracked git hooks
  git -C ~/.config config core.hooksPath .githooks
  success "Dotfiles git hooks configured"
}

# =============================================================================
# 8. Set Fish as default shell
# =============================================================================
set_fish_shell() {
  info "Setting Fish as default shell..."

  local fish_path
  fish_path="$(command -v fish || echo /opt/homebrew/bin/fish)"

  if [[ "$SHELL" == "$fish_path" ]]; then
    success "Fish is already the default shell"
    return
  fi

  # Add fish to /etc/shells if not already there
  if ! grep -qF "$fish_path" /etc/shells; then
    info "Adding $fish_path to /etc/shells..."
    echo "$fish_path" | sudo tee -a /etc/shells
  fi

  chsh -s "$fish_path"
  success "Default shell set to Fish (takes effect in new sessions)"
}

# =============================================================================
# 9. Fisher + Fish plugins
# =============================================================================
install_fish_plugins() {
  info "Installing Fisher and Fish plugins..."

  local fish_path
  fish_path="$(command -v fish || echo /opt/homebrew/bin/fish)"

  # Install Fisher if not present
  if ! "$fish_path" -c "type -q fisher" &>/dev/null; then
    info "Installing Fisher..."
    "$fish_path" -c "curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher"
  else
    success "Fisher already installed"
  fi

  # Install plugins from fish_plugins file (dotfiles must be cloned first)
  if [[ -f ~/.config/fish/fish_plugins ]]; then
    info "Installing Fish plugins from fish_plugins..."
    "$fish_path" -c "fisher update"
    success "Fish plugins installed"
  fi
}

# =============================================================================
# 10. Tmux Plugin Manager (TPM)
# =============================================================================
install_tpm() {
  info "Setting up Tmux Plugin Manager..."

  local tpm_dir=~/.config/tmux/plugins/tpm

  if [[ -d "$tpm_dir" ]]; then
    success "TPM already installed"
  else
    info "Installing TPM..."
    git clone https://github.com/tmux-plugins/tpm "$tpm_dir"
    success "TPM installed"
  fi

  info "Installing tmux plugins via TPM..."
  if command -v tmux &>/dev/null; then
    # Run TPM install headlessly
    bash ~/.config/tmux/plugins/tpm/scripts/install_plugins.sh
    success "Tmux plugins installed"
  else
    warn "tmux not found — skipping plugin install"
  fi
}

# =============================================================================
# 11. iTerm2 preferences
# Points iTerm2 at ~/.config/iterm2 so settings are loaded from dotfiles.
# The plist itself is committed to the dotfiles repo.
# Note: the custom folder setting still needs to be enabled manually in iTerm2
# on first launch (Settings → General → Preferences).
# =============================================================================
configure_iterm2() {
  info "Configuring iTerm2 preferences path..."
  defaults write com.googlecode.iterm2 PrefsCustomFolder -string "~/.config/iterm2"
  defaults write com.googlecode.iterm2 LoadPrefsFromCustomFolder -bool true
  success "iTerm2 pointed at ~/.config/iterm2"

  # Ensure the plist is XML (human-readable) rather than binary
  local plist=~/.config/iterm2/com.googlecode.iterm2.plist
  if [[ -f "$plist" ]]; then
    local format
    format="$(file "$plist")"
    if [[ "$format" == *"binary"* ]]; then
      info "Converting iTerm2 plist to XML format..."
      plutil -convert xml1 "$plist"
      success "Plist converted to XML"
    fi
  fi

  warn "Open iTerm2 → Settings → General → Preferences and enable 'Load preferences from a custom folder' on first launch"
}

# =============================================================================
# Main
# =============================================================================
main() {
  echo ""
  echo "  Mac Dev Environment Setup"
  echo "  ========================="
  echo ""

  install_xcode_tools
  install_homebrew
  setup_shell_init
  install_rust
  install_cargo_tools
  install_brew_packages
  install_node
  install_dotfiles
  set_fish_shell
  install_fish_plugins
  install_tpm
  configure_iterm2

  echo ""
  echo -e "${GREEN}All done!${NC}"
  echo ""
  echo "Next steps:"
  echo "  1. Open iTerm2 → Settings → General → Preferences"
  echo "     → Enable 'Load preferences from a custom folder'"
  echo "     → Set path to: ~/.config/iterm2"
  echo "  2. Install MonoLisa, then set fonts in iTerm2 (see README)"
  echo "  3. Open a new terminal — Fish shell will be active"
  echo "  4. Open tmux and press <prefix>+I to verify plugins loaded"
  echo "  5. Open nvim — Lazy.nvim will auto-install plugins on first launch"
  echo "  6. Set up SSH keys and re-authenticate GitHub if needed"
  echo ""
}

main "$@"
