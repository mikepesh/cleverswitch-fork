#!/usr/bin/env bash
# CleverSwitch — macOS setup script (Unifying receiver)
# Run: chmod +x setup_macos.sh && ./setup_macos.sh

set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info()  { echo -e "${GREEN}[✓]${NC} $1"; }
warn()  { echo -e "${YELLOW}[!]${NC} $1"; }
error() { echo -e "${RED}[✗]${NC} $1"; }

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_DIR="$HOME/.config/cleverswitch"
CONFIG_FILE="$CONFIG_DIR/config.yaml"

echo ""
echo "╔══════════════════════════════════════╗"
echo "║   CleverSwitch — macOS Setup         ║"
echo "╚══════════════════════════════════════╝"
echo ""

# ── 1. Check Python ──────────────────────────────────────────────────────────
# Find the best available Python 3.10+
PYTHON=""
for candidate in python3.14 python3.13 python3.12 python3.11 python3.10 python3; do
    if command -v "$candidate" &>/dev/null; then
        PY_VERSION=$("$candidate" -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')
        PY_MAJOR=$(echo "$PY_VERSION" | cut -d. -f1)
        PY_MINOR=$(echo "$PY_VERSION" | cut -d. -f2)
        if [ "$PY_MAJOR" -ge 3 ] && [ "$PY_MINOR" -ge 10 ]; then
            PYTHON="$candidate"
            break
        fi
    fi
done

if [ -z "$PYTHON" ]; then
    error "Python 3.10+ required. Install it via: brew install python@3.12"
    error "Then re-run this script."
    exit 1
fi
info "Python $PY_VERSION found ($(command -v "$PYTHON"))"

# ── 2. Check/install Homebrew ────────────────────────────────────────────────
if ! command -v brew &>/dev/null; then
    error "Homebrew not found. Install it from https://brew.sh"
    exit 1
fi
info "Homebrew found"

# ── 3. Install libhidapi ────────────────────────────────────────────────────
if brew list hidapi &>/dev/null; then
    info "hidapi already installed"
else
    warn "Installing hidapi via Homebrew..."
    brew install hidapi
    info "hidapi installed"
fi

# ── 4. Create virtual environment ────────────────────────────────────────────
VENV_DIR="$PROJECT_DIR/.venv"
if [ -d "$VENV_DIR" ]; then
    info "Virtual environment already exists at .venv"
else
    warn "Creating virtual environment..."
    "$PYTHON" -m venv "$VENV_DIR"
    info "Virtual environment created at .venv"
fi

# ── 5. Install CleverSwitch in editable mode ─────────────────────────────────
warn "Installing CleverSwitch (editable + dev dependencies)..."
"$VENV_DIR/bin/pip" install --upgrade pip -q
"$VENV_DIR/bin/pip" install -e "$PROJECT_DIR[dev]" -q
info "CleverSwitch installed"

# ── 6. Create config file ───────────────────────────────────────────────────
if [ -f "$CONFIG_FILE" ]; then
    warn "Config already exists at $CONFIG_FILE — not overwriting"
else
    mkdir -p "$CONFIG_DIR"
    cat > "$CONFIG_FILE" << 'YAML'
# CleverSwitch configuration — macOS / Unifying receiver

receiver:
  vendor_id: 0x046D
  # Unifying receiver — try 0xC52B first; if not detected, switch to 0xC532
  product_id: 0xC52B

hooks:
  on_switch: []
  on_connect: []
  on_disconnect: []

settings:
  read_timeout_ms: 1000
  retry_interval_s: 5
  max_retries: 0
  log_level: "INFO"
YAML
    info "Config created at $CONFIG_FILE"
fi

# ── 7. Run tests to verify ──────────────────────────────────────────────────
warn "Running tests..."
if "$VENV_DIR/bin/pytest" -q 2>&1; then
    info "All tests passed"
else
    warn "Some tests failed — check output above"
fi

# ── Done ─────────────────────────────────────────────────────────────────────
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
info "Setup complete! To run CleverSwitch:"
echo ""
echo "    # Activate the virtual environment"
echo "    source $VENV_DIR/bin/activate"
echo ""
echo "    # Dry-run (check that your receiver is detected)"
echo "    cleverswitch --dry-run"
echo ""
echo "    # Start the daemon"
echo "    cleverswitch"
echo ""
echo "    # Start with debug logging"
echo "    cleverswitch -v"
echo ""
warn "Note: On macOS you may need to grant Input Monitoring"
warn "permission to Terminal (or iTerm) in:"
warn "  System Settings → Privacy & Security → Input Monitoring"
echo ""
