#!/usr/bin/env bash
set -euo pipefail

REPO_URL="git@github.com:elichall/toolbox.git"
REPO_DIR="$HOME/.toolbox"

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
      elif grep -qi '^ID=nixos' /etc/os-release 2>/dev/null; then
        echo "linux"
      elif grep -qi '^ID=ubuntu' /etc/os-release 2>/dev/null; then
        echo "ubuntu"
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

# ── Identity: Linux + Windows usernames ──────────────────────────────────────

IDENTITY_FILE="$HOME/.config/toolbox/identity"

load_identity() {
  # shellcheck disable=SC1090
  [ -f "$IDENTITY_FILE" ] && . "$IDENTITY_FILE"
  linux_user="${linux_user:-$USER}"
  win_user="${win_user:-}"
}

save_identity() {
  mkdir -p "$(dirname "$IDENTITY_FILE")"
  printf 'linux_user=%q\nwin_user=%q\n' "$linux_user" "$win_user" > "$IDENTITY_FILE"
}

prompt_identity() {
  local host="$1"
  local input=""

  load_identity

  info "Identify yourself so the toolbox integrates with this system."
  printf "Linux username [%s]: " "${linux_user:-$USER}"
  read -r input
  linux_user="${input:-${linux_user:-$USER}}"

  if [ "$host" = "wsl" ]; then
    printf "Windows username (for /mnt/c/Users/... paths) [%s]: " "${win_user:-$linux_user}"
    read -r input
    win_user="${input:-${win_user:-$linux_user}}"

    if [ -n "$win_user" ]; then
      if [ -d "/mnt/c/Users/$win_user" ]; then
        ok "Windows profile confirmed: /mnt/c/Users/$win_user"
      else
        warn "No /mnt/c/Users/$win_user directory found on this machine."
        printf "Try again [%s] (or blank to skip Windows font install): " "$win_user"
        read -r input
        if [ -n "$input" ]; then
          win_user="$input"
          [ -d "/mnt/c/Users/$win_user" ] || warn "Still not found — Windows integration may not work"
        else
          win_user=""
          warn "Skipping Windows integration (fonts will not be installed to Windows)"
        fi
      fi
    fi
  fi

  save_identity
  info "Using Linux username: $linux_user"
  if [ -n "$win_user" ]; then
    info "Using Windows username: $win_user"
  fi
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

# ── Step 3: Install unzip ───────────────────────────────────────────────────

ensure_unzip() {
  if command -v unzip &>/dev/null; then
    ok "unzip already installed"
    return
  fi

  info "Installing unzip..."
  if command -v apt &>/dev/null; then
    sudo apt-get update -qq && sudo apt-get install -y -qq unzip
  elif command -v brew &>/dev/null; then
    brew install unzip
  else
    warn "Cannot install unzip automatically. Install it manually."
    exit 1
  fi
  ok "unzip installed"
}

# ── Step 4b: Install fonts for Windows Terminal (WSL only) ─────────────────

# Resolve the Windows user profile directory. WSL has no env var exposing the
# Windows username (WSL username != Windows username), so query it through the
# Windows interop layer: %USERPROFILE% -> wslpath -> /mnt/c/Users/<winuser>.
# Falls back to the prompted Windows username if interop is unavailable.
# Returns non-zero if no valid Windows profile can be found.
resolve_win_home() {
  local profile=""
  if command -v cmd.exe &>/dev/null && command -v wslpath &>/dev/null; then
    profile="$(cmd.exe /c 'echo %USERPROFILE%' 2>/dev/null | tr -d '\r' || true)"
    profile="$(wslpath "$profile" 2>/dev/null || true)"
  fi
  if [ -n "$profile" ] && [ -d "$profile" ]; then
    printf '%s' "$profile"
    return 0
  fi
  if [ -n "$win_user" ] && [ -d "/mnt/c/Users/$win_user" ]; then
    printf '%s' "/mnt/c/Users/$win_user"
    return 0
  fi
  return 1
}

install_windows_fonts() {
  info "Installing fonts for Windows Terminal..."

  local font_dir="$HOME/.nix-profile/share/fonts"
  local win_home
  if ! win_home="$(resolve_win_home)"; then
    warn "Could not resolve the Windows user profile — skipping font install"
    return
  fi
  info "Windows user profile: $win_home"
  local win_font_dir="$win_home/AppData/Local/Microsoft/Windows/Fonts"

  if [ ! -d "$font_dir" ]; then
    warn "No fonts found in $font_dir — skipping"
    return
  fi

  mkdir -p "$win_font_dir"

  local count=0
  while IFS= read -r -d '' font; do
    local name
    name="$(basename "$font")"
    if [ ! -f "$win_font_dir/$name" ]; then
      cp "$font" "$win_font_dir/$name"
      count=$((count + 1))
    fi
  done < <(find "$font_dir" -type f \( -name '*.ttf' -o -name '*.otf' \) -print0 2>/dev/null)

  if [ "$count" -gt 0 ]; then
    ok "Copied $count font(s) to Windows"
  else
    ok "Windows fonts already up to date"
  fi
}

# ── Step 4c: Install win32yank (WSL only) ────────────────────────────────────

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

# ── Step 5: Clone or update repo ────────────────────────────────────────────

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

# ── Step 6: Build and activate ──────────────────────────────────────────────

backup_existing_files() {
  local files=(
    "$HOME/.profile"
    "$HOME/.bashrc"
    "$HOME/.bash_profile"
    "$HOME/.zshenv"
  )

  for f in "${files[@]}"; do
    if [ -f "$f" ] && ! [ -L "$f" ]; then
      info "Backing up existing $f → ${f}.backup"
      mv "$f" "${f}.backup"
    fi
  done
}

build_and_activate() {
  local host="$1"
  local target="homeConfigurations.${linux_user}@${host}.activationPackage"

  backup_existing_files

  export TOOLBOX_USER="$linux_user"

  info "Building $target..."
  local result
  result="$(nix build --impure ".#${target}" --no-link --print-out-paths)"

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

  prompt_identity "$host"

  install_nix
  enable_flakes

  ensure_unzip

  if [ "$host" = "wsl" ]; then
    install_win32yank
  fi

  sync_repo
  cd "$REPO_DIR"

  build_and_activate "$host"

  if [ "$host" = "wsl" ]; then
    install_windows_fonts
  fi

  echo
  ok "Done. Restart your shell or run: source ~/.bashrc"
}

# Only run when executed directly (allows sourcing for tests).
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  main "$@"
fi
