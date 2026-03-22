# Startup Performance

## Warp defaults

Interactive startup now takes a lighter path inside Warp by default.

- `ZSH_STATUS_BANNER_MODE=auto` suppresses the probe-heavy status banner in Warp.
- `ZSH_AUTO_RECOVER_MODE=auto` skips automatic service recovery in Warp.

Outside Warp, both settings still behave normally unless overridden.

## Overrides

Use these when you explicitly want the heavier interactive checks:

```zsh
export ZSH_STATUS_BANNER_MODE=full
export ZSH_AUTO_RECOVER_MODE=on
```

Use these when you want the lightest possible startup everywhere:

```zsh
export ZSH_STATUS_BANNER_MODE=off
export ZSH_AUTO_RECOVER_MODE=off
```
