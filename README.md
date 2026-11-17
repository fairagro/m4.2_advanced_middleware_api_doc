# m4.2 Advanced Middleware — Documentation

Interactive architecture documentation (Archify) for
[`fairagro/m4.2_advanced_middleware_api`](https://github.com/fairagro/m4.2_advanced_middleware_api).

**License:** [MIT](LICENSE)

## Live site (GitHub Pages)

Published from [`docs/`](docs/) on every push/merge to `main` via
[`.github/workflows/pages.yml`](.github/workflows/pages.yml):

**https://fairagro.github.io/m4.2_advanced_middleware_doc/**

Detail diagrams (full Archify Viewer):

| Diagram | URL |
|---------|-----|
| Explainer | https://fairagro.github.io/m4.2_advanced_middleware_doc/ |
| System overview | https://fairagro.github.io/m4.2_advanced_middleware_doc/overview.html |
| Harvest ingest | https://fairagro.github.io/m4.2_advanced_middleware_doc/ingest-sequence.html |
| API process | https://fairagro.github.io/m4.2_advanced_middleware_doc/api-detail.html |
| Worker process | https://fairagro.github.io/m4.2_advanced_middleware_doc/worker-detail.html |

On the explainer, narrow layouts hide the inline preview — use **Open interactive view** or the links above.

Set the repository Pages source to **GitHub Actions** once (Settings → Pages).

## Canonical docs

There is **exactly one** documentation tree: [`docs/`](docs/).

| Path | Role |
|------|------|
| [`docs/index.html`](docs/index.html) | Documentation entry (GitHub Pages) |
| `docs/overview.html` / `api-detail.html` / `worker-detail.html` / `ingest-sequence.html` | Standalone interactive diagrams |
| `docs/*.architecture.json` / `*.sequence.json` | Archify sources |
| `docs/candidate.archify.md` | Explainer source |

Different snapshots belong on **git branches**, not timestamp folders.

## Rebuild sources

Sibling checkout of the middleware API: `../m4.2_advanced_middleware_api`

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

## Prerequisites (Dev Container)

- Docker, Cursor / VS Code with Dev Containers
- Sibling checkout: `../m4.2_advanced_middleware_api` (mounted into the container)
- In the container: Node.js 22 + Chromium for Archify `finalize`
