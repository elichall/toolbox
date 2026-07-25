#!/usr/bin/env bash
set -euo pipefail

REPO_URL="git@github.com:elichall/toolbox.git"
REPO_DIR="$HOME/toolbox"

# ── Helpers ──────────────────────────────────────────────────────────────────

info()  { printf "\033[1;34m==>\033[0m %s\n" "$*"; }
warn()  { printf "\033[1;33mwarn:\033[0m %s\n" "$*"; }
ok()    { printf "\033[1;32m  ok\033[0m %s\n" "$*"; }

detect_host() {
  local system
  system="$(uname -s)"

  case "$system" in
    Linux)
      if grep -qi microsoft /proc/version 2>/dev/null; then
        echo "wsl"
      else
        echo "linux"
      fi
      ;;
    Darwin)
      echo "macos"
      ;;
    *)
      echo "unknown"
      ;;
  esac
}

# ── Step 1: Install Nix ─────────────────────────────────────────────────────

install_nix() {
  if command -v nix &>/dev/null; then
    ok "Nix already installed"
    return
  fi

  info "Installing Nix..."
  sh <(curl -L https://nixos.org/nix/install) --no-daemon

  # Source nix into current shell
  # shellcheck disable=SC1091
  . "$HOME/.nix-profile/etc/profile.d/nix.sh"
  ok "Nix installed"
}

# ── Step 2: Enable flakes ───────────────────────────────────────────────────

enable_flakes() {
  local nix_conf="$HOME/.config/nix/nix.conf"

  if grep -q "experimental-features.*nix-command flakes" "$nix_conf" 2>/dev/null; then
    ok "Flakes already enabled"
    return
  fi

  info "Enabling flakes..."
  mkdir -p "$HOME/.config/nix"
  echo "experimental-features = nix-command flakes" >> "$nix_conf"
  ok "Flakes enabled"
}

# ── Step 3: Install win32yank (WSL only) ────────────────────────────────────

install_win32yank() {
  if command -v win32yank &>/dev/null; then
    ok "win32yank already installed"
    return
  fi

  info "Installing win32yank..."
  local tmp_dir
  tmp_dir=$(mktemp -d)
  curl -sLo "$tmp_dir/win32yank.zip" \
    https://github.com/equalsraf/win32yank/releases/download/v0.0.4/win32yank-x64.zip
  unzip -p "$tmp_dir/win32yank.zip" win32yank.exe | sudo tee /usr/local/bin/win32yank > /dev/null
  sudo chmod +x /usr/local/bin/win32yank
  rm -rf "$tmp_dir"
  ok "win32yank installed"
}

# ── Step 4: Clone or update repo ────────────────────────────────────────────

sync_repo() {
  if [ -d "$REPO_DIR/.git" ]; then
    info "Updating existing repo..."
    git -C "$REPO_DIR" pull --ff-only || warn "Pull failed, using existing repo"
    ok "Repo up to date"
  else
    info "Cloning repo..."
    git clone "$REPO_URL" "$REPO_DIR"
    ok "Repo cloned to $REPO_DIR"
  fi
}

# ── Step 5: Build and activate ──────────────────────────────────────────────

build_and_activate() {
  local host="$1"
  local target="homeConfigurations.elichall@${host}.activationPackage"

  info "Building $target..."
  nix build ".#${target}" --no-link --print-out-paths

  local result
  result="$(nix build ".#${target}" --no-link --print-out-paths)"

  info "Activating..."
  "$result/activate"

  ok "Toolbox active for $host"
}

# ── Main ────────────────────────────────────────────────────────────────────

main() {
  local host
  host="$(detect_host)"

  if [ "$host" = "unknown" ]; then
    warn "Unsupported platform: $(uname -s)"
    exit 1
  fi

  info "Detected host: $host"
  echo

  install_nix
  enable_flakes

  if [ "$host" = "wsl" ]; then
    install_win32yank
  fi

  sync_repo
  cd "$REPO_DIR"

  build_and_activate "$host"

  echo
  ok "Done. Restart your shell or run: source ~/.bashrc"
}

main "$@"
