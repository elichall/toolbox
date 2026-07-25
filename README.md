# Toolbox

Standalone Home Manager flake for cross-platform development environments.
Drop-in configuration for Wayland Linux, WSL, and macOS.

## Hosts

| Host | Output | System |
|------|--------|--------|
| Linux (Wayland) | `elichall@linux` | `x86_64-linux` |
| WSL | `elichall@wsl` | `x86_64-linux` |
| macOS | `elichall@macos` | `aarch64-darwin` |

## Prerequisites

### All platforms

Install [Nix](https://nixos.org/download/) and enable flakes:

```bash
# Install Nix (single-user)
sh <(curl -L https://nixos.org/nix/install) --no-daemon

# Enable flakes
mkdir -p ~/.config/nix
echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf

# Restart shell
source ~/.bashrc
```

### WSL extras

For Windows clipboard integration (yazi, tmux paste), install `win32yank` manually — it's not available in nixpkgs:

```bash
curl -sLo /tmp/win32yank.zip https://github.com/equalsraf/win32yank/releases/download/v0.0.4/win32yank-x64.zip
unzip -p /tmp/win32yank.zip win32yank.exe | sudo tee /usr/local/bin/win32yank > /dev/null
sudo chmod +x /usr/local/bin/win32yank
```

## Quick start

```bash
# Clone
git clone git@github.com:elichall/toolbox.git ~/toolbox
cd ~/toolbox

# Build and activate (pick your host)
nix build .#homeConfigurations.elichall@wsl.activationPackage
./result/activate
```

## Build commands

```bash
cd ~/toolbox

# Linux (Wayland)
nix build .#homeConfigurations.elichall@linux.activationPackage
./result/activate

# WSL
nix build .#homeConfigurations.elichall@wsl.activationPackage
./result/activate

# macOS
nix build .#homeConfigurations.elichall@macos.activationPackage
./result/activate
```

## Updating

```bash
cd ~/toolbox

# Update all pinned inputs to latest
nix flake update

# Rebuild and activate
nix build .#homeConfigurations.elichall@wsl.activationPackage
./result/activate
```

## What's included

- **Shell**: bash or zsh with [starship](https://starship.rs/) prompt, [blesh](https://github.com/scop/bash-it) integration
- **File manager**: [yazi](https://yazi-rs.github.io/) with cross-platform clipboard plugin
- **Terminal multiplexer**: [tmux](https://github.com/tmux/tmux) with vi mode, plugins (resurrect, continuum, extrakto, tmux-fzf)
- **Editor**: [Neovim](https://neovim.io/) with out-of-tree Lua config (`nvim/` directory)
- **Dev tools**: [direnv](https://direnv.net/), [zoxide](https://github.com/ajeetdsouza/zoxide), [fzf](https://github.com/junegunn/fzf), [git](https://git-scm.com/)
- **Global LSPs**: nil (Nix), lua-language-server, marksman (Markdown), texlab (LaTeX), bash-language-server
- **Fonts**: JetBrains Mono Nerd Font, Noto Sans
- **Clipboard**: platform-aware — `wl-clipboard` (Wayland), `win32yank` (WSL), `pbcopy`/`pbpaste` (macOS)

## Architecture

```
flake.nix                          # Entry point
modules/
  toolbox.nix                      # Central data (per-host settings)
  home.nix                         # Global env, packages, fonts
  cmdLine.nix                      # Shell selection, starship prompt
  programs/
    tmux.nix                       # Tmux config + plugins
    yazi.nix                       # Yazi config + clipboard plugin
    nvim.nix                       # Neovim wrapper
  host/
    linux.nix                      # homeConfigurations for Wayland Linux
    wsl.nix                        # homeConfigurations for WSL
    macos.nix                      # homeConfigurations for macOS
```

Each host file reads from `self.toolbox.{name}` and produces its own
`flake.homeConfigurations` output. Adding a new host requires:
1. A new entry in `modules/toolbox.nix` under `flake.toolbox`
2. A new file in `modules/host/`
