#!/usr/bin/env bash
#
# Keyino one-click setup — point your AI tools at Keyino in ~10 seconds.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/<org>/<repo>/main/setup-keyino.sh | bash -s -- sk-your-key-here
#
# What it does:
#   1. Verifies the key against the Keyino API
#   2. Configures Claude Code (~/.claude/settings.json)
#   3. Adds exports to your shell profile (bash / zsh / fish) — idempotent
#   4. Optional: also sets OPENAI_BASE_URL for OpenAI-compatible tools (--openai)
#
# Flags:
#   --key KEY        API key (or pass sk-... as first arg, or type it when prompted)
#   --base-url URL   API base URL (default: https://api.keyino.cc)
#   --openai         also configure OPENAI_BASE_URL / OPENAI_API_KEY
#   --uninstall      remove all Keyino config added by this script
#   -h, --help       show help
#
set -euo pipefail

KEYINO_BASE_URL="${KEYINO_BASE_URL:-https://api.keyino.cc}"
KEY=""
WITH_OPENAI=0
UNINSTALL=0

usage() {
  sed -n '2,20p' "$0"
  exit "${1:-0}"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --key)      KEY="${2:?--key needs a value}"; shift 2 ;;
    --base-url) KEYINO_BASE_URL="${2:?--base-url needs a value}"; shift 2 ;;
    --openai)   WITH_OPENAI=1; shift ;;
    --uninstall) UNINSTALL=1; shift ;;
    -h|--help)  usage 0 ;;
    sk-*)       KEY="$1"; shift ;;
    *) echo "Unknown argument: $1" >&2; usage 1 ;;
  esac
done

BLOCK_BEGIN="# >>> keyino >>>"
BLOCK_END="# <<< keyino <<<"

backup() { # $1 = file
  if [[ -f "$1" ]]; then
    local b="$1.bak.$(date +%Y%m%d%H%M%S)"
    cp "$1" "$b" && echo "  backup -> $b"
  fi
}

strip_block() { # $1 = file — remove previous keyino block (idempotent)
  local f="$1"
  [[ -f "$f" ]] || return 0
  awk -v b="$BLOCK_BEGIN" -v e="$BLOCK_END" '
    $0 == b { skip=1; next }
    $0 == e { skip=0; next }
    !skip { print }
  ' "$f" > "$f.tmp" && mv "$f.tmp" "$f"
}

# ---------------------------------------------------------------- uninstall
if [[ "$UNINSTALL" -eq 1 ]]; then
  echo "==> Removing Keyino config ..."
  for f in "$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.config/fish/config.fish"; do
    if [[ -f "$f" ]] && grep -qF "$BLOCK_BEGIN" "$f" 2>/dev/null; then
      backup "$f"; strip_block "$f"; echo "  cleaned $f"
    fi
  done
  if [[ -f "$HOME/.claude/settings.json" ]] && command -v python3 >/dev/null 2>&1; then
    backup "$HOME/.claude/settings.json"
    python3 - <<'PYEOF'
import json, os
p = os.path.expanduser("~/.claude/settings.json")
try:
    with open(p) as f: cfg = json.load(f)
except Exception:
    cfg = {}
env = cfg.get("env", {})
env.pop("ANTHROPIC_BASE_URL", None)
env.pop("ANTHROPIC_AUTH_TOKEN", None)
if env: cfg["env"] = env
else: cfg.pop("env", None)
with open(p, "w") as f: json.dump(cfg, f, indent=2)
print("  cleaned ~/.claude/settings.json")
PYEOF
  fi
  echo "Done. Restart your terminal / Claude Code."
  exit 0
fi

# ---------------------------------------------------------------- key input
if [[ -z "$KEY" ]]; then
  if [[ -t 0 ]]; then
    read -rp "Paste your Keyino API key (sk-...): " KEY
  elif [[ -r /dev/tty ]]; then
    read -rp "Paste your Keyino API key (sk-...): " KEY </dev/tty
  else
    echo "ERROR: no API key. Get one at https://keyino.cc (free \$1 on sign-up)," >&2
    echo "then re-run: curl -fsSL <script-url> | bash -s -- sk-your-key" >&2
    exit 1
  fi
fi
if [[ "$KEY" != sk-* ]]; then
  echo "WARNING: key does not start with 'sk-' — continuing anyway." >&2
fi

# ---------------------------------------------------------------- 1. verify
echo "==> [1/3] Verifying key against $KEYINO_BASE_URL ..."
http_code=$(curl -s -m 12 -o /dev/null -w "%{http_code}" \
  -H "Authorization: Bearer $KEY" "$KEYINO_BASE_URL/v1/models" || true)
if [[ "$http_code" == "200" ]]; then
  echo "  key OK (API reachable)"
elif [[ "$http_code" == "401" ]]; then
  echo "  WARNING: API rejected the key (401). Check the key and re-run; continuing anyway."
else
  echo "  WARNING: unexpected HTTP $http_code from API. Continuing anyway."
fi

# ---------------------------------------------------------------- 2. Claude Code
echo "==> [2/3] Configuring Claude Code (~/.claude/settings.json) ..."
if command -v python3 >/dev/null 2>&1; then
  mkdir -p "$HOME/.claude"
  [[ -f "$HOME/.claude/settings.json" ]] || echo '{}' > "$HOME/.claude/settings.json"
  backup "$HOME/.claude/settings.json"
  KEYINO_KEY="$KEY" KEYINO_BASE="$KEYINO_BASE_URL" python3 - <<'PYEOF'
import json, os
p = os.path.expanduser("~/.claude/settings.json")
try:
    with open(p) as f: cfg = json.load(f)
except Exception: cfg = {}
if not isinstance(cfg, dict): cfg = {}
env = cfg.setdefault("env", {})
env["ANTHROPIC_BASE_URL"] = os.environ["KEYINO_BASE"]
env["ANTHROPIC_AUTH_TOKEN"] = os.environ["KEYINO_KEY"]
with open(p, "w") as f: json.dump(cfg, f, indent=2)
print("  settings.json updated")
PYEOF
else
  echo "  SKIP: python3 not found (needed for JSON merge)"
fi

# ---------------------------------------------------------------- 3. shell
echo "==> [3/3] Adding shell exports ..."
detected_shell="$(basename "${SHELL:-bash}")"
declare -a targets=()
case "$detected_shell" in
  fish) targets=("$HOME/.config/fish/config.fish:fish") ;;
  zsh)  targets=("$HOME/.zshrc:sh") ;;
  *)    targets=("$HOME/.bashrc:sh") ;;
esac
# also cover the other common rc file if it exists
[[ "$detected_shell" != "zsh" && -f "$HOME/.zshrc" ]] && targets+=("$HOME/.zshrc:sh")
[[ "$detected_shell" != "bash" && -f "$HOME/.bashrc" ]] && targets+=("$HOME/.bashrc:sh")

for t in "${targets[@]}"; do
  f="${t%%:*}"; kind="${t##*:}"
  mkdir -p "$(dirname "$f")"; touch "$f"
  backup "$f"; strip_block "$f"
  {
    echo "$BLOCK_BEGIN"
    if [[ "$kind" == "fish" ]]; then
      echo "set -gx ANTHROPIC_BASE_URL \"$KEYINO_BASE_URL\""
      echo "set -gx ANTHROPIC_AUTH_TOKEN \"$KEY\""
      [[ "$WITH_OPENAI" -eq 1 ]] && {
        echo "set -gx OPENAI_BASE_URL \"$KEYINO_BASE_URL/v1\""
        echo "set -gx OPENAI_API_KEY \"$KEY\""
      }
    else
      echo "export ANTHROPIC_BASE_URL=\"$KEYINO_BASE_URL\""
      echo "export ANTHROPIC_AUTH_TOKEN=\"$KEY\""
      [[ "$WITH_OPENAI" -eq 1 ]] && {
        echo "export OPENAI_BASE_URL=\"$KEYINO_BASE_URL/v1\""
        echo "export OPENAI_API_KEY=\"$KEY\""
      }
    fi
    echo "$BLOCK_END"
  } >> "$f"
  echo "  updated $f"
done

# ---------------------------------------------------------------- done
echo
echo "Done! Next steps:"
echo "  1. Restart your terminal (or run: source ~/.${detected_shell}rc)"
echo "  2. Restart Claude Code, then just run: claude"
echo "  3. Test manually: curl -s $KEYINO_BASE_URL/v1/models -H \"Authorization: Bearer \$KEY\" | head -c 200"
echo
echo "Docs: https://docs.keyino.cc  |  Support: https://t.me/keyino_cc"
