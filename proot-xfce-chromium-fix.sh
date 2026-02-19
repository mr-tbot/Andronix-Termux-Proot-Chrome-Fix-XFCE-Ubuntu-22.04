#!/usr/bin/env bash
# proot-xfce-chromium-fix.sh
#
# Applies the Chromium+XFCE proot fixes that actually worked earlier:
#  1) Detects that XFCE/exo-open launches /usr/bin/chromium with only the URL.
#  2) Wraps /usr/bin/chromium so ANY caller gets the required proot-safe flags.
#  3) (Optional) patches /usr/share/applications/chromium.desktop to call the wrapper too.
#  4) (Optional) sets XDG defaults for http/https/text/html to chromium.desktop.
#  5) (Optional) installs at-spi2-core to reduce AT-SPI warnings (best-effort).
#
# Usage:
#   sudo bash proot-xfce-chromium-fix.sh
#   sudo bash proot-xfce-chromium-fix.sh --no-apt
#   sudo bash proot-xfce-chromium-fix.sh --no-xdg
#   sudo bash proot-xfce-chromium-fix.sh --patch-desktop
#   sudo bash proot-xfce-chromium-fix.sh --with-atspi
#
# Notes:
#  - Safe to re-run: creates backups once and will not double-wrap.
#  - Designed for proot where Chromium must run as root with --no-sandbox.
#  - Does NOT attempt to fix normal proot warnings (dbus/netlink/udev/inotify).
#
set -euo pipefail

NO_APT=0
NO_XDG=0
PATCH_DESKTOP=0
WITH_ATSPI=0

for arg in "$@"; do
  case "$arg" in
    --no-apt) NO_APT=1 ;;
    --no-xdg) NO_XDG=1 ;;
    --patch-desktop) PATCH_DESKTOP=1 ;;
    --with-atspi) WITH_ATSPI=1 ;;
    -h|--help)
      sed -n '1,120p' "$0"
      exit 0
      ;;
    *)
      echo "Unknown arg: $arg"
      exit 1
      ;;
  esac
done

need_root() {
  if [[ "$(id -u)" -ne 0 ]]; then
    echo "ERROR: run as root inside the proot environment."
    echo "Try: sudo bash $0"
    exit 1
  fi
}

msg() { printf '[*] %s\n' "$*"; }
warn() { printf '[!] %s\n' "$*" >&2; }

need_root

if [[ ! -e /usr/bin/chromium ]]; then
  echo "ERROR: /usr/bin/chromium does not exist."
  exit 1
fi

if [[ ! -x /usr/bin/chromium ]]; then
  warn "/usr/bin/chromium exists but is not executable. Attempting chmod +x..."
  chmod +x /usr/bin/chromium || true
fi

# --- 1) Wrap /usr/bin/chromium (the actual fix that solved exo-open/xfce4-mime-helper) ---
msg "Ensuring /usr/bin/chromium is a proot-safe wrapper (adds --no-sandbox etc)..."

already_wrapped=0
if head -n 5 /usr/bin/chromium 2>/dev/null | grep -q "chromium.real"; then
  already_wrapped=1
fi

if [[ "$already_wrapped" -eq 1 ]]; then
  msg "/usr/bin/chromium already wrapped (chromium.real detected)."
else
  if [[ ! -f /usr/bin/chromium.real ]]; then
    msg "Backing up /usr/bin/chromium -> /usr/bin/chromium.real"
    cp -v /usr/bin/chromium /usr/bin/chromium.real
  else
    msg "Backup /usr/bin/chromium.real already exists (not overwriting)."
  fi

  cat > /usr/bin/chromium <<'EOF'
#!/bin/sh
# proot chromium wrapper:
# XFCE/exo-open may launch /usr/bin/chromium with only the URL (no flags).
# Running as root requires --no-sandbox in proot environments.
exec /usr/bin/chromium.real \
  --no-sandbox \
  --disable-dev-shm-usage \
  --disable-gpu \
  --disable-software-rasterizer \
  --no-zygote \
  "$@"
EOF
  chmod +x /usr/bin/chromium
  msg "Wrapper installed at /usr/bin/chromium"
fi

# --- 2) Optional: patch chromium.desktop to call the wrapper as well ---
if [[ "$PATCH_DESKTOP" -eq 1 ]]; then
  if [[ -f /usr/share/applications/chromium.desktop ]]; then
    msg "Patching /usr/share/applications/chromium.desktop Exec= to call /usr/bin/chromium (wrapper)..."
    if [[ ! -f /usr/share/applications/chromium.desktop.bak.prootfix ]]; then
      cp -v /usr/share/applications/chromium.desktop /usr/share/applications/chromium.desktop.bak.prootfix || true
    fi
    # Use %U for desktop entry placeholder
    sed -i 's|^Exec=.*|Exec=/usr/bin/chromium %U|' /usr/share/applications/chromium.desktop || true
    grep -n '^Exec=' /usr/share/applications/chromium.desktop | head -n 1 || true
  else
    warn "/usr/share/applications/chromium.desktop not found; skipping desktop patch."
  fi
fi

# --- 3) Optional: set XDG defaults (best-effort) ---
if [[ "$NO_XDG" -eq 0 ]]; then
  msg "Setting XDG defaults to chromium.desktop (best-effort)..."
  set +e
  command -v xdg-settings >/dev/null 2>&1 && xdg-settings set default-web-browser chromium.desktop
  command -v xdg-mime >/dev/null 2>&1 && {
    xdg-mime default chromium.desktop x-scheme-handler/http
    xdg-mime default chromium.desktop x-scheme-handler/https
    xdg-mime default chromium.desktop text/html
  }
  set -e
else
  msg "Skipping XDG defaults (--no-xdg)"
fi

# --- 4) Optional: reduce AT-SPI warning spam (best-effort) ---
if [[ "$WITH_ATSPI" -eq 1 ]]; then
  if [[ "$NO_APT" -eq 1 ]]; then
    msg "Skipping apt installs (--no-apt)"
  else
    msg "Installing at-spi2-core (optional, best-effort)..."
    set +e
    apt-get update >/dev/null 2>&1
    apt-get install -y at-spi2-core >/dev/null 2>&1
    set -e
  fi
fi

# --- 5) Quick self-test hints ---
cat <<'EOT'

[*] Done.

Quick tests:
  exo-open --launch WebBrowser https://example.com
  exo-open https://example.com
  /usr/bin/chromium https://example.com

Notes:
  - In proot you will still see warnings about dbus/netlink/udev/inotify. Those are normal.
  - If Chromium opens but is unstable, consider adding --in-process-gpu to the wrapper.
EOT
