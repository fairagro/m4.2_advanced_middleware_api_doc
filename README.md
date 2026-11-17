# m4.2 Advanced Middleware — Documentation

Interactive architecture documentation (Archify) for
[`fairagro/m4.2_advanced_middleware_api`][api-repo].

**License:** [MIT](LICENSE)

[api-repo]: https://github.com/fairagro/m4.2_advanced_middleware_api

## Live site (GitHub Pages)

Published from [`docs/`](docs/) on every push/merge to `main` via
[`.github/workflows/pages.yml`](.github/workflows/pages.yml):

**<https://fairagro.github.io/m4.2_advanced_middleware_doc/>**

Detail diagrams (full Archify Viewer):

| Diagram | URL |
| --- | --- |
| Explainer | <https://fairagro.github.io/m4.2_advanced_middleware_doc/> |
| System overview | <https://fairagro.github.io/m4.2_advanced_middleware_doc/overview.html> |
| Harvest ingest | <https://fairagro.github.io/m4.2_advanced_middleware_doc/ingest-sequence.html> |
| API process | <https://fairagro.github.io/m4.2_advanced_middleware_doc/api-detail.html> |
| Worker process | <https://fairagro.github.io/m4.2_advanced_middleware_doc/worker-detail.html> |

On the explainer, narrow layouts hide the inline preview — use
**Open interactive view** or the links above.

Set the repository Pages source to **GitHub Actions** once
(Settings → Pages).

## Preview locally

No deploy needed — serve the same `docs/` tree GitHub Pages uses:

```bash
./scripts/serve-docs.sh
# optional: PORT=8765 ./scripts/serve-docs.sh
```

Then open <http://127.0.0.1:8080/> (Simple Browser or your host browser;
port is forwarded from the Dev Container).

Edit `docs/candidate.archify.md` (or diagram JSON), run the rebuild
commands below, refresh the browser.

## Canonical docs

There is **exactly one** documentation tree: [`docs/`](docs/).

| Path | Role |
| --- | --- |
| [`docs/index.html`](docs/index.html) | Documentation entry (GitHub Pages) |
| `docs/overview.html` / `api-detail.html` / `worker-detail.html` / `ingest-sequence.html` | Standalone interactive diagrams |
| `docs/*.architecture.json` / `*.sequence.json` | Archify sources |
| `docs/candidate.archify.md` | Explainer source |

Different snapshots belong on **git branches**, not timestamp folders.

## Rebuild sources

Sibling checkouts (mounted into the Dev Container):

| Host path | Container path | Used for |
| --- | --- | --- |
| `../m4.2_advanced_middleware_api` | `/workspaces/m4.2_advanced_middleware_api` | Middleware API diagrams + explainer |
| `../m4.2_middleware_harvester` | `/workspaces/m4.2_middleware_harvester` | Harvester diagrams |

```bash
export ARCHIFY_CHROME_NO_SANDBOX=1
BIN=.agents/skills/archify/bin/archify.mjs
API=/workspaces/m4.2_advanced_middleware_api
HARVESTER=/workspaces/m4.2_middleware_harvester

node "$BIN" finalize architecture docs/overview.architecture.json docs/overview.html \
  --repo-root "$API" --quality showcase
node "$BIN" finalize sequence docs/ingest.sequence.json docs/ingest-sequence.html \
  --repo-root "$API" --quality showcase
node "$BIN" finalize architecture docs/api-detail.architecture.json docs/api-detail.html \
  --repo-root "$API" --quality showcase
node "$BIN" finalize architecture docs/worker-detail.architecture.json docs/worker-detail.html \
  --repo-root "$API" --quality showcase
node "$BIN" finalize explainer docs/candidate.archify.md docs/index.html \
  --repo-root "$API" --quality showcase
node "$BIN" finalize architecture docs/harvester-overview.architecture.json docs/harvester-overview.html \
  --repo-root "$HARVESTER" --quality showcase
node "$BIN" finalize dataflow docs/harvester-pipeline.dataflow.json docs/harvester-pipeline.html \
  --repo-root "$HARVESTER" --quality showcase
```

## Prerequisites (Dev Container)

- Docker, Cursor / VS Code with Dev Containers
- Sibling checkouts next to this repo (same parent folder):
  - `../m4.2_advanced_middleware_api`
  - `../m4.2_middleware_harvester`
  (both mounted into the container; see `.devcontainer/devcontainer.json`)
- In the container: Node.js 22 + Chromium for Archify `finalize`
