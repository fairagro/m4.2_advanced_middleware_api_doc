# Advanced Middleware docs: API, Harvester, and SQL-to-ARC {#middleware}

This page is the docs hub for the FAIRagro Advanced Middleware family: **API**, **Harvester**, and **SQL-to-ARC**.

- Middleware API: harvest ingest writes CouchDB immediately and publishes asynchronously via Celery.[](source:submit-arc)[](source:worker-sync)
- Harvester: catalog plugins discover, parse, and map into `HarvestedArc`, then upload RO-Crate JSON.
- SQL-to-ARC: ISA-shaped SQL views carry the domain mapping; the converter assembles and uploads.
- Standalone Archify viewers for every diagram are linked from the catalog below.

@answer scope="docs hub · API @ d7756ceb · Harvester @ 0af067d7 · SQL-to-ARC @ 6ba87ef6 · SearchHUB external context only"
@meta locale=en quality_profile=showcase repo_url=git@github.com:fairagro/m4.2_advanced_middleware_api.git repo_revision=d7756ceb54060d999567ebfaa924c523bc0dfa3a
@source arc-manager title="ArcManager.create_or_update_arc" path=middleware/api/src/middleware/api/business_logic/arc_manager.py lines=115:210
@source couch-store title="CouchDB.store_arc" path=middleware/api/src/middleware/api/document_store/couchdb.py lines=293:367
@source worker-sync title="Celery sync_arc_to_gitlab" path=middleware/api/src/middleware/api/worker/worker.py lines=111:155
@source worker-final title="Celery finalize_catalog" path=middleware/api/src/middleware/api/worker/worker.py lines=158:191
@source bl-harvest title="transition_harvest enqueue finalize" path=middleware/api/src/middleware/api/business_logic/business_logic.py lines=200:235
@source factory title="create_arc_stores dual slot" path=middleware/api/src/middleware/api/arc_store/factory.py lines=16:25
@source arc-port title="ArcStore port" path=middleware/api/src/middleware/api/arc_store/__init__.py lines=95:132
@source consol-port title="ConsolidatedArcStore port" path=middleware/api/src/middleware/api/arc_store/__init__.py lines=277:300
@source authz title="validate_rdi_authorized" path=middleware/api/src/middleware/api/api/common/dependencies.py lines=140:151
@source harvest-routes title="v3 harvests routes" path=middleware/api_v3/src/middleware/api_v3/routers/harvests.py lines=16:68
@source submit-arc title="submit_arc_in_harvest" path=middleware/api/src/middleware/api/api/v3/lifecycle_port.py lines=129:164
@source fastapi-app title="FastAPI app wiring" path=middleware/api/src/middleware/api/api/fastapi_app.py lines=136:140
@source bl-manager title="BusinessLogicManager" path=middleware/api/src/middleware/api/worker/worker.py lines=35:79
@source arctrl-sync title="ARCtrl ARC.from_rocrate_json_string" path=middleware/api/src/middleware/api/business_logic/arc_manager.py lines=461:463
@source consol-read title="ConsolidatedArcStore reads ARC JSON-LD" path=middleware/api/src/middleware/api/arc_store/consolidated_git/store.py lines=183:225
@source sync-payload title="ArcSyncTask with ARC JSON-LD" path=middleware/api/src/middleware/api/business_logic/arc_manager.py lines=167:180
@source sync-events title="Git sync events in CouchDB" path=middleware/api/src/middleware/api/business_logic/arc_manager.py lines=374:399

## Which diagrams are available? {#catalog}

| Diagram | Component | Full page |
| --- | --- | --- |
| System overview | Middleware API | [Open system overview](https://fairagro.github.io/m4.2_advanced_middleware_doc/overview.html) |
| Harvest ingest sequence | Middleware API | [Open harvest ingest](https://fairagro.github.io/m4.2_advanced_middleware_doc/ingest-sequence.html) |
| API process internals | Middleware API | [Open API process](https://fairagro.github.io/m4.2_advanced_middleware_doc/api-detail.html) |
| Worker process internals | Middleware API | [Open worker process](https://fairagro.github.io/m4.2_advanced_middleware_doc/worker-detail.html) |
| Harvester overview | Harvester | [Open Harvester overview](https://fairagro.github.io/m4.2_advanced_middleware_doc/harvester-overview.html) |
| Harvester pipeline | Harvester | [Open Harvester pipeline](https://fairagro.github.io/m4.2_advanced_middleware_doc/harvester-pipeline.html) |
| SQL-to-ARC overview | SQL-to-ARC | [Open SQL-to-ARC overview](https://fairagro.github.io/m4.2_advanced_middleware_doc/sql-to-arc-overview.html) |
| SQL-to-ARC data flow | SQL-to-ARC | [Open SQL-to-ARC data flow](https://fairagro.github.io/m4.2_advanced_middleware_doc/sql-to-arc-pipeline.html) |

This explainer embeds the four Middleware API diagrams below (Archify limit: four inline). Harvester and SQL-to-ARC open as standalone viewers from the table. Locally, the same files are under `docs/` via `./scripts/serve-docs.sh`.

## How does the Middleware API fit together? {#overview}

Full page: [System overview](https://fairagro.github.io/m4.2_advanced_middleware_doc/overview.html)

@diagram architecture id=overview-arch source=overview.architecture.json title="System overview"

@steps id=overview-steps
| s-client | RDI client | Delivers RO-Crate to the API over mTLS. | overview-arch | rdi-client |
| s-api | Middleware API | AuthZ and sync store; enqueues tasks. | overview-arch | api |
| s-couch | CouchDB | Durable ARC and harvest documents. | overview-arch | couchdb |
| s-rabbit | RabbitMQ | Celery broker between API enqueue and the worker. | overview-arch | rabbitmq |
| s-worker | Celery worker | Calls the store ports. | overview-arch | worker |
| s-stores | Store ports | ArcStore and ConsolidatedArcStore are two ports on the worker, wired side by side: per-ARC publish vs catalog. At runtime, finalize runs after ARC sync.[](source:arc-port)[](source:consol-port) | overview-arch | arc-store,consol-store |
| s-datahub | Datahub | Git hosting for ARC repos and the catalog. | overview-arch | datahub |
| s-hub | SearchHUB | External consumer context; not wired here. | overview-arch | searchhub |

## What happens during harvest ingest? {#ingest-seq}

Full page: [Harvest ingest sequence](https://fairagro.github.io/m4.2_advanced_middleware_doc/ingest-sequence.html)

@diagram sequence id=ingest-flow source=ingest.sequence.json title="Harvest API: BusinessLogic in API vs worker process"

## What is inside the Middleware API process? {#api-detail}

Full page: [API process internals](https://fairagro.github.io/m4.2_advanced_middleware_doc/api-detail.html)

@diagram architecture id=api-detail-arch source=api-detail.architecture.json title="API process internals"

@steps id=api-detail-steps
| a-client | RDI client | Calls the API over mTLS with RO-Crate ARCs. | api-detail-arch | client |
| a-http | FastAPI / Routes | Accepts harvest/ARC requests.[](source:harvest-routes) | api-detail-arch | fastapi |
| a-bl | BusinessLogic | mode=api: stores ARC/metadata, enqueues sync.[](source:fastapi-app) | api-detail-arch | bl |
| a-store | DocumentStore | Reads existing doc; writes ARC + last_seen ….[](source:couch-store) | api-detail-arch | docstore |
| a-disp | TaskDispatcher | Enqueue to RabbitMQ.[](source:worker-sync) | api-detail-arch | dispatcher |
| a-rabbit | RabbitMQ | Broker sink of the API process: sync tasks leave here. | api-detail-arch | rabbitmq |

## What is inside the Celery worker process? {#worker-detail}

Full page: [Worker process internals](https://fairagro.github.io/m4.2_advanced_middleware_doc/worker-detail.html)

@diagram architecture id=worker-detail-arch source=worker-detail.architecture.json title="Worker process internals"

@steps id=worker-detail-steps
| w-rabbit | RabbitMQ | Source of worker work: delivers sync and finalize tasks. | worker-detail-arch | rabbitmq |
| w-task | Celery tasks | Entry: `sync_arc_to_gitlab` with full ARC JSON-LD, `finalize_catalog` with RDI.[](source:sync-payload) | worker-detail-arch | tasks |
| w-bl | BusinessLogic | Drives sync and finalize; does not read ARCs from CouchDB itself.[](source:worker-sync) | worker-detail-arch | bl |
| w-doc | DocumentStore | Sync: BL writes events only; finalize: ConsolidatedArcStore reads ARC content.[](source:sync-events)[](source:consol-read) | worker-detail-arch | docstore |
| w-stores | Store ports | ArcStore writes each ARC repo; ConsolidatedArcStore reads ARCs from CouchDB and writes the catalog. Parallel ports; finalize follows sync.[](source:arc-port)[](source:consol-read) | worker-detail-arch | arcstore,consol |
| w-datahub | Datahub | Sink: ARC repos and catalog land in Git hosting. | worker-detail-arch | datahub |

## How does the Harvester produce ARCs? {#harvester}

Full pages: [Harvester overview](https://fairagro.github.io/m4.2_advanced_middleware_doc/harvester-overview.html) · [Discover / Parse / Map](https://fairagro.github.io/m4.2_advanced_middleware_doc/harvester-pipeline.html)

- Plugins (INSPIRE, generic Protocol, OAI-PMH) discover catalog records and map them to `HarvestedArc`.
- Shared `PayloadParser` / `DataMapper` registries sit in the middle; INSPIRE bypasses the shared parser.
- The orchestrator unwraps `HarvestedArc.arc_json` (RO-Crate JSON) and uploads via `ApiClient.harvest_arcs`.

## How does SQL-to-ARC produce ARCs? {#sql-to-arc}

Full pages: [SQL-to-ARC overview](https://fairagro.github.io/m4.2_advanced_middleware_doc/sql-to-arc-overview.html) · [SQL → ARC data flow](https://fairagro.github.io/m4.2_advanced_middleware_doc/sql-to-arc-pipeline.html)

- Domain mapping to ISA/ARC shape lives in the RDI SQL views, not in the converter code.
- The converter validates and streams those views, mechanically assembles ARCtrl objects, and uploads RO-Crate JSON.
- Same Middleware API sink as the Harvester (`harvest_arcs` under mTLS).
