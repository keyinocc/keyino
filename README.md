<p align="center">
  <img src="logo.png" width="120" alt="Keyino logo">
</p>

<h1 align="center">Keyino — one-click setup</h1>

<p align="center">
  One API key for Claude, GPT, Gemini &amp; Grok at ~half the market price.<br>
  Point your AI tools at Keyino in ~10 seconds.
</p>

<p align="center">
  <a href="https://keyino.cc">Website</a> ·
  <a href="https://docs.keyino.cc">Docs</a> ·
  <a href="https://keyino.cc/price/">Pricing</a> ·
  <a href="https://t.me/keyino_cc">Telegram</a>
</p>

## Install

1. Get your free API key at https://keyino.cc — $1 free credit on sign-up, no card required.
2. Run:

```bash
curl -fsSL https://raw.githubusercontent.com/keyinocc/keyino/main/setup-keyino.sh | bash -s -- sk-your-key-here
```

## What it does

- Verifies your key against the Keyino API
- Configures Claude Code (`~/.claude/settings.json`)
- Adds exports to your shell profile (bash / zsh / fish) — safe to re-run
- Optional flags: `--openai` (also set `OPENAI_BASE_URL`), `--uninstall` (remove everything)

## Manual setup

```bash
export ANTHROPIC_BASE_URL="https://api.keyino.cc"
export ANTHROPIC_AUTH_TOKEN="sk-your-key-here"
```

---

Pay as you go · credit never expires · failed requests are free
