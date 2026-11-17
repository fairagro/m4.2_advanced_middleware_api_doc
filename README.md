# m4.2 Advanced Middleware API — Dokumentation

Interaktive Architektur-Dokumentation (Archify) für
[`fairagro/m4.2_advanced_middleware_api`](https://github.com/fairagro/m4.2_advanced_middleware_api).

## Dokumentation

Es gibt **genau eine** kanonische Version unter [`docs/`](docs/):

| Datei | Rolle |
|-------|--------|
| [`docs/index.html`](docs/index.html) | Meeting-Explainer (GitHub Pages Einstieg) |
| `docs/*.architecture.json` / `*.sequence.json` | Archify-Quellen |
| `docs/candidate.archify.md` | Explainer-Quelle |

Unterschiedliche Stände gehören auf **Git-Branches**, nicht in Timestamp-Ordner.

### Lokal ansehen

```bash
python3 -m http.server 8765 --bind 0.0.0.0 --directory docs
```

Dann: http://localhost:8765/

### GitHub Pages

Nach dem ersten Push auf `main` deployt [`.github/workflows/pages.yml`](.github/workflows/pages.yml)
den Inhalt von `docs/` nach GitHub Pages.

Erwartete URL:
`https://fairagro.github.io/m4.2_advanced_middleware_api_doc/`

Einmalig in den Repo-Settings unter **Pages** die Quelle **GitHub Actions** wählen
(falls noch nicht gesetzt).

## Quellen neu bauen

Geschwister-Checkout der Middleware: `../m4.2_advanced_middleware_api`

```bash
export ARCHIFY_CHROME_NO_SANDBOX=1
BIN=.agents/skills/archify/bin/archify.mjs
REPO=/workspaces/m4.2_advanced_middleware_api

node "$BIN" finalize architecture docs/overview.architecture.json docs/overview.html \
  --repo-root "$REPO" --quality showcase
node "$BIN" finalize sequence docs/ingest.sequence.json docs/ingest-sequence.html \
  --repo-root "$REPO" --quality showcase
node "$BIN" finalize architecture docs/api-detail.architecture.json docs/api-detail.html \
  --repo-root "$REPO" --quality showcase
node "$BIN" finalize architecture docs/worker-detail.architecture.json docs/worker-detail.html \
  --repo-root "$REPO" --quality showcase
node "$BIN" finalize explainer docs/candidate.archify.md docs/index.html \
  --repo-root "$REPO" --quality showcase
```

## Voraussetzungen (Dev Container)

- Docker, Cursor / VS Code mit Dev Containers
- Geschwister-Checkout: `../m4.2_advanced_middleware_api` (wird gemountet)
- Im Container: Node.js 22 + Chromium für Archify `finalize`
