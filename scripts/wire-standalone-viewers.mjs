#!/usr/bin/env node
/**
 * After `archify finalize explainer`, rewire Open interactive view /
 * diagram-node clicks to sibling standalone Viewer HTML pages.
 *
 * The in-page srcdoc modal works locally on wide viewports but is a poor
 * fit for GitHub Pages; standalone pages are the reliable interactive path.
 */
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const target = path.join(root, 'docs', 'index.html');
let html = fs.readFileSync(target, 'utf8');

const marker = 'location.assign(standalone';
if (!html.includes(marker)) {
  const old = '  function openViewer(id,hash,opener) {\n    const diagram = diagrams[id];';
  const neu = `  function openViewer(id,hash,opener) {
    // Prefer sibling standalone viewers (same experience as opening overview.html locally).
    const standalone = ({'overview-arch':'overview.html','ingest-flow':'ingest-sequence.html','api-detail-arch':'api-detail.html','worker-detail-arch':'worker-detail.html'})[id];
    if (standalone) { location.assign(standalone + (hash ? '#' + hash : '')); return; }
    const diagram = diagrams[id];`;
  if (!html.includes(old)) {
    console.error('wire-standalone-viewers: openViewer hook not found in docs/index.html');
    process.exit(1);
  }
  html = html.replace(old, neu);
}

const abs = 'https://fairagro.github.io/m4.2_advanced_middleware_doc/';
for (const page of ['overview.html', 'ingest-sequence.html', 'api-detail.html', 'worker-detail.html']) {
  html = html.split(abs + page).join(page);
}

fs.writeFileSync(target, html);
console.log('wire-standalone-viewers: docs/index.html → standalone Viewer navigation');
