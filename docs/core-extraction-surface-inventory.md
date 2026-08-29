# Core Extraction Surface Inventory

Status: Complete — all seven phases and final Core-independence acceptance passed  
Applies to: `feather-core` 0.2.0  
Authority: `CORE-EXTRACTION-MASTER-PLAN.md`

## Purpose

This document freezes the public and operational surface of Core before extraction begins. It is the removal ledger for the extraction program: a surface may move or disappear only when its listed consumers have migrated and its acceptance gate passes.

During the freeze:

- no new gameplay, presentation, world, routing, updater, or generic utility API may be added to Core;
- new Core APIs must belong to the retained kernel and use named, versioned contracts;
- extracted resources must not import Core internals or recreate the legacy `initiate()` table;
- a moved surface is deleted from Core in the same phase after its consumers pass their tests;
- undocumented compatibility aliases are not permitted.

## Disposition legend

| Disposition | Meaning |
| --- | --- |
| Retain | Remains part of the Core kernel. |
| Extract | Moves to the named focused resource. |
| Delete | Removed after the stated consumer/removal gate. |
| Review | Retained only if a concrete multi-resource requirement is demonstrated. |

## Public export surface

### Retained kernel exports

| Export | Side | Owner after extraction | Known first-party consumers | Gate |
| --- | --- | --- | --- | --- |
| `GetCapabilities` | server | Core foundation | Character, Inventory, Weapons, Admin | Keep; capability output must describe only retained features after each phase. |
| `GetHealth` | server | Core foundation | Diagnostics and smoke tests | Keep. |
| `AwaitReady` | server | Core foundation | First-party startup adapters | Keep. |
| `GetPrimaryIdentifier` | server | Core identity | Admin/connection integration | Keep until the account contract exposes the required immutable snapshot; do not expose non-anchor identifiers as account authority. |
| `GetAccountContext` | server | Core identity | Admin | Keep. |
| `GetAccountSettings` | server | Core account settings | Core settings/locale paths | Keep until Phase 5 decides whether settings persistence moves with `feather-settings`. |
| `GetSessionContext`, `RequireSession`, `IsSessionCurrent` | server | Core session kernel | Character, Inventory, Weapons, Admin | Keep. |
| `ActivateSession`, `BeginSessionLeaving`, `CompleteSessionLeaving` | server | Core session kernel | Character | Keep as the Character/Core lifecycle boundary. |
| `RegisterRPC`, `RegisterContractRPC`, `RegisterRpc` | shared/server | Core transport | First-party resources | Consolidate naming during hardening; retain one documented registration export. |
| `GetRPCRoutes`, `GetRpcRoutes` | shared/server | Core transport diagnostics | Smoke tests | Consolidate duplicate casing/name during hardening. |
| `NotifyRPC`, `CallRPC`, `CallRPCAsync` | shared | Core transport | First-party resources | Keep; legacy callback semantics must not survive final hardening. |
| `DeclareEvent`, `SubscribeEvent`, `UnsubscribeEvent`, `PublishEvent`, `GetEvents` | server | Core event broker | Framework services and tests | Keep. |
| `RegisterProvider`, `UnregisterProvider`, `GetProvider`, `GetProviderHealth`, `GetProviders` | server | Core provider registry | Character, Admin and future domain providers | Keep. |
| `RegisterPolicyProvider`, `Authorize` | server | Core policy boundary | Admin, Inventory | Keep. |
| `RegisterGuard`, `UnregisterGuard`, `EvaluateGuards`, `GetGuards` | server | Core guard registry | Inventory/Weapons and tests | Keep. |
| `RegisterNotificationProvider`, `SendNotification` | server | Core provider boundary | Inventory, Weapons, Admin | Keep the registry contract; the default presentation provider moves in Phase 2. |
| `RegisterConnectionGate`, `GetConnectionGates` | server | Core connection lifecycle | Admin moderation | Keep. |
| `RegisterLocale`, `TranslateLocale` | shared | Core locale primitive | Character, Inventory, Admin | Keep registration/translation primitives; delete translation synchronization transport. |

### Extracted or deleted exports

| Export | Current owner | Known first-party consumers | Disposition | Phase and removal gate |
| --- | --- | --- | --- | --- |
| client `initiate()` | Core legacy API | No active first-party consumer found | Delete | Phase 7; remove after an all-repository search and clean-start suite confirm zero consumers. |
| server `initiate()` | Core legacy API | No active first-party consumer found | Deleted | Removed during Phase 1 after the clean consumer search; its user/cache startup path depended on retired tables. |
| `ShowNotification` | Core client presentation | Character, Inventory, Weapons, Admin | Extracted to `feather-notify` | Phase 2 complete; contract, all-style visual, consumer, and restart recovery tests passed. |
| `TeleportToCoords` | Core client helper | Character; Admin owns a separate local implementation | Moved to Character | Phase 4 audit found no shared semantics: Character owns its streamed placement controller and Admin retains its admin-specific controller. |

## RPC route surface

| Route | Contract state | Known consumer | Disposition | Removal gate |
| --- | --- | --- | --- | --- |
| `core.health.v1` | named Contract 1 | Core smoke tests/diagnostics | Retain | None. |
| `core.account.settings.get.v1` | named Contract 1 | settings/locale flow | Retain pending Phase 5 ownership decision | Settings extraction must preserve account authority and locale validation. |
| `core.account.settings.update.v1` | named Contract 1 | settings/locale flow | Retain pending Phase 5 ownership decision | Same as above. |
| `core.instance.enter.v1` | named Contract 1 | Character selection | Extract to `feather-routing` | Phase 1; Character uses the routing capability and routing restart/cleanup tests pass. |
| `core.instance.leave.v1` | named Contract 1 | Character activation/selection exit | Extract to `feather-routing` | Same as above. |
| `CreateInstance` | legacy | No active first-party consumer found | Delete | Phase 1 after repository search and routing tests. |
| `LeaveInstance` | legacy | No active first-party consumer found | Delete | Phase 1 after repository search and routing tests. |
| `GetInstancedCharacters` | legacy | No active first-party consumer found | Delete | Phase 1 after repository search and routing tests. |
| `SyncTranslations` | legacy | No active first-party consumer found | Delete | Phase 7 after locale registration/translation tests pass without it. |
| `popdensity:sync` | legacy gameplay route | Core population client | Extract to `feather-world` | Phase 3 after world-density synchronization tests pass. |

The transport events `Feather:Call` and `Feather:Response` remain Core-owned implementation details of the RPC contract. They are not public domain events and consumers must use the named RPC exports.

## Framework event surface

| Event | Producer | Disposition | Notes/gate |
| --- | --- | --- | --- |
| `core.account.connected.v1` | Core identity | Retain | Immutable account snapshot. |
| `core.account.disconnected.v1` | Core identity | Retain | Cleanup lifecycle. |
| `core.connection.rejected.v1` | Core connection lifecycle | Retain internal lifecycle contract | Used to release pending account ownership. |
| `core.session.ready.v1` | Core sessions | Retain | Authoritative active-session lifecycle. |
| `core.session.leaving.v1` | Core sessions | Retain | Authoritative cleanup lifecycle. |
| `core.session.left.v1` | Core sessions | Retain | Authoritative cleanup lifecycle. |
| `Feather:Instance:Created` | Core instances | Extract/rename with `feather-routing` | Do not preserve as an undocumented compatibility alias. |
| `Feather:Instance:Leave` | Core instances | Extract/rename with `feather-routing` | Same gate as Phase 1 routing cutover. |
| `Feather:Notify` | Core notifications | Removed | Replaced by the `feather-notify:show.v1` presentation event owned by Notify. |

## Persistent data ownership

| Table | Current owner | Final owner/disposition | Gate |
| --- | --- | --- | --- |
| `core_schema_migrations` | Core | Retain | Core migrations only. |
| `core_accounts` | Core | Retain | Minimal durable account identity. |
| `core_account_identifiers` | Core | Retain | Normalized account anchor identifiers. |
| `core_account_settings` | Core | Decide in Phase 5 | Locale/account preferences may remain minimal Core state; gameplay/UI settings move. |

`database/development_identity_reset.sql` is development tooling, not a Core-owned production schema contract. It references tables owned by Character, Inventory, and Admin and must be moved to recipe/development tooling or deleted before final hardening.

## Configuration disposition

| Configuration | Disposition | Target |
| --- | --- | --- |
| `DevMode`, `Logging` | Retain | Core operations. |
| `EventBroker`, `ProviderRegistry`, `GuardRegistry`, `RPCRateLimit` | Retain | Core contracts and limits. |
| `NotificationRegistry` | Retain | Core notification provider boundary; presentation config belongs to `feather-notify`. |
| `DefaultLang` | Retain | Core locale primitive/account preference. |
| `PublicInstanceIds` | Extract | `feather-routing`. |
| `DisableRandomLootPrompts`, `DensityMultipliers` | Extract | `feather-world`. |
| `PVP`, `UseDeadEye`, `UseEagleEye`, `UseFogOfWar` | Extract | `feather-pvp` and/or `feather-world` according to the master plan. |
| `PlayerSettings` | Extract | `feather-settings`. |
| `XP` | Delete from Core | Domain progression owner must define it if still needed. |
| executable `Commands` callbacks | Delete from Core | Commands are owned by the resource implementing the behavior; config remains declarative. |
| GitHub updater/checker manifest metadata | Extract/delete | `feather-versioner` or recipe/release tooling. |

## File and side-effect disposition

### Retain in Core

- foundation/readiness, result envelopes, validation, logging and migrations;
- account identity, connection gates, account settings pending Phase 5, and sessions;
- hardened RPC transport and event broker;
- provider, policy, guard, and notification registries;
- locale registration/translation primitives.

### Phase 1: `feather-routing`

- `server/services/instances.lua`;
- routing bucket allocation, membership, cleanup, and public/shared bucket policy;
- Character selection routing integration.

### Phase 2: `feather-notify`

- Core client and server notification presentation files removed;
- Core default presentation provider removed from `notification_registry.lua`;
- all fourteen native presentation styles moved to `feather-notify`;
- Character, Inventory, Weapons, and Admin client adapters moved to Notify;
- `Feather:Notify` replaced by the Notify-owned versioned presentation event.

Core retains only provider registration and validated dispatch. Contract, all-style visual, consumer, and restart recovery tests passed; Phase 2 is closed.

### Phase 3: `feather-world`

- population density runtime and configuration moved;
- interior/map compatibility and wagon-cleanup loops moved;
- random-loot prompt suppression and related configuration moved;
- legacy `popdensity:sync` route removed in favor of World-owned configuration;
- Core map exposure removed from the legacy client API.

Implementation is ready for live density, interiors, wagon, prompt-suppression, Core-independence, and resource-stop testing.

All contract, client-loop, manual world-behavior, Core-independence, and restart tests passed; Phase 3 is closed.

### Phase 4: `feather-toolkit` or domain ownership

- `blips.lua`, `clip.lua`, `horses.lua`, `keys.lua`, `objects.lua`, `peds.lua`, `prompts.lua`, `render.lua`, `teleport.lua`, `wagons.lua`;
- shared `dataview.lua`, `math.lua`, and `prettyprint.lua` only where concrete reuse justifies a maintained library.

Each helper requires a stable, owner-isolated contract before entering `feather-toolkit`. Domain lifecycle behavior remains with its owning resource.

Audit result: no generic toolkit is justified by current first-party use. Character now owns teleport; Inventory and Admin already own their narrower object, prompt, render, clipboard, key, ped, and teleport helpers. Core's dormant client API and unused blip, clipboard, horse, object, ped, prompt, render, and wagon copies were removed. The final Core key poller moved out with the Phase 5 settings UI.

The audit also found HUD's final dependency on Core's removed client API. XP-per-level display configuration now belongs to HUD, its legacy Core import was removed, and HUD no longer declares Core as a dependency.

Character ownership, Core absence, activation, HUD, Admin teleport, and manual death/placement tests passed; Phase 4 is closed without creating a generic toolkit.

After extraction acceptance, a standalone `feather-toolkit` Contract 1 was created for future resources. It provides bounded model loading and owner-scoped objects, peds, blips, key listeners, and prompts, plus stateless drawing and clipboard helpers. It does not restore Core compatibility APIs or absorb teleport, horse, or wagon lifecycle behavior.

### Phase 5: focused settings/PVP resources

- client PVP enforcement and configuration moved to `feather-pvp`;
- player settings presentation and PGUP polling moved to `feather-settings`;
- Core's Feather Menu dependency, settings UI, generic key poller, and PVP loop removed;
- locale persistence and translation remain minimal Core account primitives;
- a named client-locale update export replaces direct access to Core locale internals.

Implementation is ready for PVP state, settings menu, locale persistence, Core-independence, and restart testing.

Reconnect testing exposed a pre-existing session-kernel gap: explicit logout finalized sessions, but network disconnect did not. Core now finalizes ready or already-leaving sessions idempotently on `playerDropped`, releasing both source and character indexes before reconnect.

- `player_settings.lua`, `pvp.lua`, and their configuration/UI ownership;
- `ui/index.html` clipboard relay and the Core `ui_page` declaration after all consumers migrate.

### Phase 6: version tooling

- centralized GitHub release/UI checking removed from Core;
- Core's checker service and updater-specific manifest metadata removed;
- release/version validation now belongs to recipe and release tooling rather than the runtime kernel.

After extraction, the optional server-only `feather-versioner` resource was
created for operator-authorized GitHub release reporting. It cannot update,
restart, or mutate resources, and it is not a runtime compatibility authority.

### Phase 7: delete/absorb

- legacy client/server `initiate()` tables removed;
- unused generic database, file, Discord webhook, UI, and command wrappers removed;
- mutable legacy cache and user surfaces removed;
- legacy translation synchronization removed; locales register independently in each runtime;
- orphaned Core loadscreen callback removed because Core has no NUI page and the recipe has no `bcc-loadscreen` integration.

The final native client safeguard loop and its native event queue moved to `feather-world`. Core now has no client-only scripts, gameplay loops, native-event buffers, key tables, or presentation data.

The unused `weathersync` dependency was also removed; Core's only manifest dependency is its persistence adapter, `oxmysql`.

## Known first-party consumer map

| Consumer | Current Core dependencies relevant to extraction |
| --- | --- |
| `feather-character` | session/account contracts, RPC, locale, notifications, and teleport helper. Its baseline Core instance dependency has moved to server-authorized `feather-routing` intent routes. |
| `feather-inventory` | sessions, RPC, policy, guards, locale, notifications; client gameplay helpers are already locally owned. |
| `feather-weapons` | sessions, RPC, notifications; native weapon work is intentionally outside this extraction program. |
| `feather-admin` | accounts, sessions, RPC, policy, connection gates, locale, notifications; admin teleport is locally owned. |

No active first-party use of Core's client or server `initiate()` export was found at this baseline. That finding is not permission to remove it without the Phase 7 repository search and acceptance gate.

## Baseline acceptance suite

Run these before extraction and after every phase affecting the listed contract:

- `CoreContractSmokeTest`
- `CoreMigrationSmokeTest`
- `CoreAccountSmokeTest <source>`
- `CoreSessionSmokeTest <source>`
- `CoreRpcSmokeTest`
- `CoreEventSmokeTest`
- `CoreProviderSmokeTest`
- `CorePolicySmokeTest`
- `CoreGuardSmokeTest`
- `CoreNotificationSmokeTest <source>`
- `CoreAccountSettingsSmokeTest <source>`
- `CoreLegacyCharacterRemovalSmokeTest <source>`
- `CharacterCoreCutoverSmokeTest`
- `CharacterActivationContractSmokeTest`
- `InvServerCoreCutoverSmokeTest <owner> <player>`
- `AdminPolicySmokeTest <owner> <player>`

Every extracted resource adds its own clean-start, restart, ownership-cleanup, malformed-request, and manual gameplay tests before the old Core implementation is removed.

## Phase 0 exit checklist

- [x] Core responsibility boundary recorded.
- [x] Current exports classified.
- [x] Current RPC routes classified.
- [x] Current framework events classified.
- [x] Core-owned database tables classified.
- [x] Configuration and UI ownership classified.
- [x] Known first-party consumers recorded from repository search.
- [x] Removal gates and baseline acceptance suite recorded.
- [ ] Maintainers approve the inventory and freeze.
- [x] `feather-routing` contract, capability schema, configuration, and tests are frozen before implementation.

## Phase 1 implementation status

- [x] Dedicated `feather-routing` resource created with Contract 1 capabilities.
- [x] Opaque route handles and collision-safe internal bucket allocation implemented.
- [x] Invoking-resource ownership enforced for route mutation and inspection.
- [x] Character selection uses Character-owned intent routes and server-only Routing calls.
- [x] Core routing routes, capability, configuration, and implementation removed.
- [x] Retired server `initiate()`, `users`, and mutable user-cache paths removed after clean consumer search.
- [x] Character validates Routing as a required runtime capability and recovers active selection membership after Routing restart without a CFX stop cascade.
- [x] Routing contract smoke test passes live (`6/6`).
- [x] Routing live membership smoke test passes (`6/6`).
- [x] Character/Core cutover smoke test passes (`5/5`).
- [x] Routing restart recreates the Character-owned selection route and preserves a working selector without export-host errors.
- [x] Character selection, creation, activation, logout, and reconnect pass after the cutover.
- [x] Player disconnect cleanup and Character owner-stop cleanup pass live.

**Phase 1 status:** complete. All Routing release gates passed live.
