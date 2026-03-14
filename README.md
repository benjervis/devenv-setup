# Dev Environment Setup

Scripts and documentation for setting up a fresh Mac to my normal dev environment.

## Quick Start

```sh
# On a brand new Mac, open Terminal and run:
curl -fsSL https://raw.githubusercontent.com/benjervis/devenv-setup/main/setup.sh | bash
```

Or clone this repo and run locally:

```sh
git clone https://github.com/benjervis/devenv-setup.git ~/dev/devenv-setup
bash ~/dev/devenv-setup/setup.sh
```

## What Gets Installed

### Package Managers

| Tool         | How                                              |
| ------------ | ------------------------------------------------ |
| Homebrew     | Installed via official install script            |
| Rust / Cargo | Installed via `rustup`                           |
| Node.js      | Installed via `fnm` (latest LTS, set as default) |

### CLI Tools

| Tool                | Installed via       | Purpose                                                                           |
| ------------------- | ------------------- | --------------------------------------------------------------------------------- |
| `rust-analyzer`     | rustup component    | Rust LSP server for editor integration                                            |
| `rg` (ripgrep)      | Cargo               | Fast grep replacement                                                             |
| `bat`               | Cargo (custom fork) | `cat` with syntax highlighting — built from github.com/benjervis/bat              |
| `delta`             | Cargo               | Better git diffs                                                                  |
| `zoxide`            | Cargo               | Smarter `cd` (aliased to `z`)                                                     |
| `bash`              | Homebrew            | Modern bash (macOS ships 3.2 which lacks associative arrays — breaks tmux themes) |
| `fish`              | Homebrew            | Default shell                                                                     |
| `nvim`              | Homebrew            | Editor                                                                            |
| `tmux`              | Homebrew            | Terminal multiplexer                                                              |
| `lazygit`           | Homebrew            | TUI git client                                                                    |
| `fzf`               | Homebrew            | Fuzzy finder                                                                      |
| `fnm`               | Cargo               | Node.js version manager                                                           |
| `git-lfs`           | Homebrew            | Large file storage                                                                |
| Fira Code Nerd Font | Homebrew cask       | Nerd Font icons + Legacy Computing Unicode block for Neovim/tmux in iTerm2        |

### Shell

Default shell is set to **Fish** (via `chsh`). Fish is configured via the dotfiles repo.

**Fish plugins** (managed by [Fisher](https://github.com/jorgebucaran/fisher)):

- `edc/bass` — run bash scripts/exports from Fish

### Terminal Multiplexer

**tmux** with [TPM](https://github.com/tmux-plugins/tpm) plugins:

- `tmux-plugins/tmux-sensible`
- `alexwforsythe/tmux-which-key`
- `janoamaral/tokyo-night-tmux`

After first launch, press `<prefix>+I` inside tmux to install plugins.

### Editor

**Neovim** with [LazyVim](https://www.lazyvim.org/). Plugins are auto-installed on first launch.

## Dotfiles

Configuration is stored in a separate repo cloned directly to `~/.config`:

```
https://github.com/benjervis/dotfiles.git
```

This covers: Fish config, Neovim (LazyVim), tmux, git, lazygit, bat, iTerm2 preferences.

## Shell Init Files

These files live in `$HOME` (not in the dotfiles repo) and are written by the setup script:

| File          | Purpose                                              |
| ------------- | ---------------------------------------------------- |
| `~/.zprofile` | Adds Homebrew to PATH (needed for zsh and scripts)   |
| `~/.zshenv`   | Sources `~/.cargo/env` (makes Cargo tools available) |

## Post-Install Checklist

- [ ] Install MonoLisa font from [monolisa.dev](https://www.monolisa.dev)
- [ ] Configure iTerm2 fonts: MonoLisa as primary, SymbolsNerdFontMono-Regular as Non-ASCII font (see below)
- [ ] Open a new terminal — Fish should be the active shell
- [ ] Open tmux, press `<prefix>+I` to install plugins
- [ ] Open `nvim` — Lazy.nvim will bootstrap and install plugins automatically
- [ ] Set up SSH keys (`ssh-keygen -t ed25519 -C "ben@jervis.net.au"`)
- [ ] Add SSH key to GitHub
- [ ] Set git user if needed: `git config --global user.name "Ben Jervis"` / `user.email`
- [ ] Authenticate 1Password CLI if used

## Manual Steps

Some things can't easily be scripted:

- **SSH keys** — generate and add to GitHub/other services
- **1Password** — install from the App Store or [1password.com](https://1password.com)
- **Mac System Preferences** — keyboard repeat rate, trackpad speed, Dock settings, etc.
- **iTerm2 preferences** — enable loading from custom folder (see below)
- **iTerm2 fonts** — set up the two-font configuration for MonoLisa + Nerd Font icons (see below)

### iTerm2 Preferences

`setup.sh` writes the correct path to iTerm2's preferences via `defaults write`, but iTerm2 still needs the setting toggled on manually once:

1. Open iTerm2 → **Settings** → **General** → **Preferences**
2. Check **"Load preferences from a custom folder or URL"**
3. The path should already be set to `~/.config/iterm2` — if not, set it manually

After this, iTerm2 will read from and write back to `~/.config/iterm2/com.googlecode.iterm2.plist`, which is tracked in your dotfiles repo.

### iTerm2 Font Setup

iTerm2 supports a primary font and a separate "Non-ASCII Font", which lets you use MonoLisa for all text while Fira Code Nerd Font provides the icons used by Neovim and tmux.

1. Open iTerm2 → **Settings** → **Profiles** → **Text**
2. Under **Font**, set your main font to **MonoLisa** (install separately from [monolisa.dev](https://www.monolisa.dev))
3. Check **"Use a different font for non-ASCII text"**
4. Set the **Non-ASCII Font** to **FiraCodeNerdFontMono-Regular** (installed by `setup.sh`)
