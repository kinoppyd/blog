# Agent Notes

## Ruby/Jekyll execution in Codex shell

Codex shell may not load `mise` automatically, and can fall back to system Ruby (`/usr/bin/ruby`).
Before running Jekyll/Bundler commands, initialize `mise` in the current shell:

```bash
eval "$(mise activate zsh)"
bundle exec jekyll build
```

Quick check:

```bash
which ruby && ruby -v
which bundle && bundle -v
```

Expected: `ruby 3.4.3` and `bundler 4.0.5` from `mise` paths (not `/usr/bin/*`).
