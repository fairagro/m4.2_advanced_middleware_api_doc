# Die Middleware speichert sync in CouchDB und publisht async nach Datahub {#middleware-meeting}

Die Advanced Middleware nimmt RO-Crate-ARCs entgegen, schreibt sie **sofort nach CouchDB** und publisht **asynchron** nach Datahub. Der Überblick zeigt die Store-Ports [ArcStore](node:overview-arch.arc-store) und [ConsolidatedArcStore](node:overview-arch.consol-store) — ohne konkrete Git-Implementierungen.

- Sync-Pfad über Harvest-API: `POST /v3/harvests` und `POST /v3/harvests/{id}/arcs` → CouchDB → HTTP-Antwort.[](source:submit-arc)
- Async-Pfad: Celery synct über ArcStore und finalisiert den Katalog über ConsolidatedArcStore nach Harvest COMPLETED.[](source:worker-sync)[](source:bl-harvest)
- SearchHUB ist hier nur Kontext: kein Code-Bezug in diesem Repository.

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
@source consol-read title="ConsolidatedArcStore liest ARC JSON-LD" path=middleware/api/src/middleware/api/arc_store/consolidated_git/store.py lines=183:225
@source sync-payload title="ArcSyncTask mit ARC-JSON-LD" path=middleware/api/src/middleware/api/business_logic/arc_manager.py lines=167:180
@source sync-events title="Git-Sync-Events in CouchDB" path=middleware/api/src/middleware/api/business_logic/arc_manager.py lines=374:399

## Wie hängt das System zusammen? {#overview}

@diagram architecture id=overview-arch source=overview.architecture.json title="Systemüberblick"

@steps id=overview-steps
| s-client | RDI-Client | Liefert RO-Crate per mTLS an die API. | overview-arch | rdi-client |
| s-api | Middleware API | AuthZ und speichert sync; enqueued Tasks. | overview-arch | api |
| s-couch | CouchDB | Haltbare ARC- und Harvest-Dokumente. | overview-arch | couchdb |
| s-worker | Celery Worker | Ruft die Store-Ports auf. | overview-arch | worker |
| s-arc | ArcStore | Port für per-ARC Persistenz.[](source:arc-port) | overview-arch | arc-store |
| s-consol | ConsolidatedArcStore | Port für Katalog-Finalize.[](source:consol-port) | overview-arch | consol-store |
| s-hub | SearchHUB | Nur Diskussionsrahmen, nicht verdrahtet. | overview-arch | searchhub |

@callout id=viewer-tip level=note title="Mehr Detail im Diagramm"
| Knoten anklicken öffnet den Semantic Passport (Quellen, Nachbarn, Deep Link). |
| Views: Ingest / Store-Ports / Konsum-Kontext. Fragezeichen öffnet die Guide. |

## Was passiert im Harvest-Ingest? {#ingest-seq}

@diagram sequence id=ingest-flow source=ingest.sequence.json title="Harvest-API: BusinessLogic in API- bzw. Worker-Prozess"

@steps id=ingest-steps
| i-create | POST /v3/harvests | Client startet einen Harvest-Lauf.[](source:harvest-routes) | ingest-flow | client |
| i-bl-api | BusinessLogic | Bibliothekscode im API-Prozess.[](source:submit-arc) | ingest-flow | bl-api |
| i-store | DocumentStore | Geteilte CouchDB — Persistenz für beide Prozesse.[](source:couch-store) | ingest-flow | store |
| i-enq | enqueue | API-BL enqueued; Worker ist ein anderer Prozess.[](source:worker-sync) | ingest-flow | broker |
| i-bl-w | BusinessLogic | Bibliothekscode im Worker-Prozess: Publish + Events. | ingest-flow | bl-worker |


## Was steckt im Middleware-API-Prozess? {#api-detail}

@diagram architecture id=api-detail-arch source=api-detail.architecture.json title="API-Prozess Innenleben"

@steps id=api-detail-steps
| a-http | FastAPI / Routes | Nimmt Harvest/ARC-Requests entgegen.[](source:harvest-routes) | api-detail-arch | fastapi |
| a-auth | AuthZ | mTLS und RDI-Freigabe.[](source:authz) | api-detail-arch | authz |
| a-bl | BusinessLogic | mode=api: speichert ARC/Metadaten, enqueued Sync.[](source:fastapi-app) | api-detail-arch | bl |
| a-store | DocumentStore | Liest bestehendes Doc; schreibt ARC + last_seen ….[](source:couch-store) | api-detail-arch | docstore |
| a-disp | TaskDispatcher | Enqueue nach RabbitMQ.[](source:worker-sync) | api-detail-arch | dispatcher |

## Was steckt im Celery-Worker-Prozess? {#worker-detail}

@diagram architecture id=worker-detail-arch source=worker-detail.architecture.json title="Worker-Prozess Innenleben"

@steps id=worker-detail-steps
| w-task | Celery Tasks | Einstieg: `sync_arc_to_gitlab` mit komplettem ARC-JSON-LD, `finalize_catalog` mit RDI.[](source:sync-payload) | worker-detail-arch | tasks |
| w-mgr | BL-Manager | Hält und stellt die eine BusinessLogic-Instanz pro Prozess bereit.[](source:bl-manager) | worker-detail-arch | bl-mgr |
| w-bl | BusinessLogic | Steuert Sync und Finalize; liest selbst keine ARCs aus CouchDB.[](source:worker-sync) | worker-detail-arch | bl |
| w-arctrl | ARCtrl | Kern des Workers: baut aus dem JSON-LD das ARC-Objekt.[](source:arctrl-sync) | worker-detail-arch | arctrl |
| w-arc | ArcStore | Schreibt das ARC-Objekt als Git-Repo nach Datahub.[](source:arc-port) | worker-detail-arch | arcstore |
| w-consol | ConsolidatedArcStore | Liest die ARCs einer RDI direkt aus CouchDB, nicht über die BL.[](source:consol-read) | worker-detail-arch | consol |
| w-doc | DocumentStore | Sync schreibt nur Events; Finalize liest ARC-Inhalte.[](source:sync-events) | worker-detail-arch | docstore |

## Was solltet ihr im Meeting klären? {#checklist}

- [ ] Ist `consolidated_store` konfiguriert (ConsolidatedArcStore aktiv)?
- [ ] Reicht SearchHUB der Katalog `{rdi}.json`, die per-ARC-Repos, oder beides?
- [ ] Welche RDI-IDs und Zertifikat-ODIs sind die AuthZ-Wahrheit?[](source:authz)
- [ ] Welche Fehlerfälle (Git down, Katalog unverändert, Harvest leer) sind akzeptabel?
