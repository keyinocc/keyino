# Keyino — one-click setup

Point your AI tools at Keyino in ~10 seconds. One API key for Claude, GPT, Gemini & Grok at ~half the market price.

## Install

1. Get your free API key at https://keyino.cc ($1 free credit on sign-up, no card required).
2. Run:

```
curl -fsSL https://raw.githubusercontent.com/keyinocc/keyino/main/setup-keyino.sh | bash -s -- sk-your-key-here
```

## What it does

- Verifies your key against the Keyino API
- Configures Claude Code (~/.claude/settings.json)
- Adds exports to your shell profile (bash / zsh / fish) — safe to re-run
- Optional flags: --openai (also set OPENAI_BASE_URL), --uninstall (remove everything)

## Manual setup

```
export ANTHROPIC_BASE_URL="https://api.keyino.cc"
export ANTHROPIC_AUTH_TOKEN="sk-your-key-here"
```

Docs: https://docs.keyino.cc · Support: https://t.me/keyino_cc
