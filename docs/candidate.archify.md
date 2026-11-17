# Middleware stores sync in CouchDB and publishes async to Datahub {#middleware}

The Advanced Middleware accepts RO-Crate ARCs, writes them **immediately to CouchDB**, and publishes **asynchronously** to Datahub. The overview shows the store ports [ArcStore](node:overview-arch.arc-store) and [ConsolidatedArcStore](node:overview-arch.consol-store) — without concrete Git implementations.

- Sync path via Harvest API: `POST /v3/harvests` and `POST /v3/harvests/{id}/arcs` → CouchDB → HTTP response.[](source:submit-arc)
- Async path: Celery syncs via ArcStore and finalizes the catalog via ConsolidatedArcStore after Harvest COMPLETED.[](source:worker-sync)[](source:bl-harvest)
- SearchHUB is context only: no code reference in this repository.

@answer scope="main @ d7756ceb · Middleware-API only · sql_to_arc/Harvester out of scope · SearchHUB external · overview shows ports only"
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

## How does the system fit together? {#overview}

@diagram architecture id=overview-arch source=overview.architecture.json title="System overview"

@steps id=overview-steps
| s-client | RDI client | Delivers RO-Crate to the API over mTLS. | overview-arch | rdi-client |
| s-api | Middleware API | AuthZ and sync store; enqueues tasks. | overview-arch | api |
| s-couch | CouchDB | Durable ARC and harvest documents. | overview-arch | couchdb |
| s-worker | Celery worker | Calls the store ports. | overview-arch | worker |
| s-arc | ArcStore | Port for per-ARC persistence.[](source:arc-port) | overview-arch | arc-store |
| s-consol | ConsolidatedArcStore | Port for catalog finalize.[](source:consol-port) | overview-arch | consol-store |
| s-hub | SearchHUB | External consumer context; not wired here. | overview-arch | searchhub |

@callout id=viewer-tip level=note title="More detail in the diagram"
| Click a node to open the Semantic Passport (sources, neighbors, deep link). |
| Views: Ingest / Store ports / Consumption context. Question mark opens the guide. |

## What happens during harvest ingest? {#ingest-seq}

@diagram sequence id=ingest-flow source=ingest.sequence.json title="Harvest API: BusinessLogic in API vs worker process"

@steps id=ingest-steps
| i-create | POST /v3/harvests | Client starts a harvest run.[](source:harvest-routes) | ingest-flow | client |
| i-bl-api | BusinessLogic | Library code in the API process.[](source:submit-arc) | ingest-flow | bl-api |
| i-store | DocumentStore | Shared CouchDB — persistence for both processes.[](source:couch-store) | ingest-flow | store |
| i-enq | enqueue | API BL enqueues; the worker is a different process.[](source:worker-sync) | ingest-flow | broker |
| i-bl-w | BusinessLogic | Library code in the worker process: publish + events. | ingest-flow | bl-worker |


## What is inside the Middleware API process? {#api-detail}

@diagram architecture id=api-detail-arch source=api-detail.architecture.json title="API process internals"

@steps id=api-detail-steps
| a-http | FastAPI / Routes | Accepts harvest/ARC requests.[](source:harvest-routes) | api-detail-arch | fastapi |
| a-auth | AuthZ | mTLS and RDI authorization.[](source:authz) | api-detail-arch | authz |
| a-bl | BusinessLogic | mode=api: stores ARC/metadata, enqueues sync.[](source:fastapi-app) | api-detail-arch | bl |
| a-store | DocumentStore | Reads existing doc; writes ARC + last_seen ….[](source:couch-store) | api-detail-arch | docstore |
| a-disp | TaskDispatcher | Enqueue to RabbitMQ.[](source:worker-sync) | api-detail-arch | dispatcher |

## What is inside the Celery worker process? {#worker-detail}

@diagram architecture id=worker-detail-arch source=worker-detail.architecture.json title="Worker process internals"

@steps id=worker-detail-steps
| w-task | Celery tasks | Entry: `sync_arc_to_gitlab` with full ARC JSON-LD, `finalize_catalog` with RDI.[](source:sync-payload) | worker-detail-arch | tasks |
| w-mgr | BL manager | Holds and provides the one BusinessLogic instance per process.[](source:bl-manager) | worker-detail-arch | bl-mgr |
| w-bl | BusinessLogic | Drives sync and finalize; does not read ARCs from CouchDB itself.[](source:worker-sync) | worker-detail-arch | bl |
| w-arctrl | ARCtrl | Core of the worker: builds the ARC object from JSON-LD.[](source:arctrl-sync) | worker-detail-arch | arctrl |
| w-arc | ArcStore | Writes the ARC object as a Git repo to Datahub.[](source:arc-port) | worker-detail-arch | arcstore |
| w-consol | ConsolidatedArcStore | Reads an RDI’s ARCs directly from CouchDB, not via BL.[](source:consol-read) | worker-detail-arch | consol |
| w-doc | DocumentStore | Sync writes events only; finalize reads ARC content.[](source:sync-events) | worker-detail-arch | docstore |

## Configuration checklist {#checklist}

- [ ] Is `consolidated_store` configured (ConsolidatedArcStore active)?
- [ ] Downstream consumers: `{rdi}.json` catalog, per-ARC repos, or both?
- [ ] Which RDI IDs and certificate ODIs are the AuthZ source of truth?[](source:authz)
- [ ] Which failure modes (Git down, catalog unchanged, empty harvest) are acceptable?
