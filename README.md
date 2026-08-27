# **THIS IS A WORK IN PROGRESS AND NOT READY FOR PRODUCTION USE YET!**

# Feather Core (Alpha)

> Welcome to Feather Core, the beating heart of the Feather Framework; An extraordinary open-source RedM framework designed to bring the ultimate RedM server vision to life.

## First time setup

Follow our easy [Guide](https://featherframework.net/guide)

## Features

- Interiors Fixes
- Population density control
- Easy Developer API's
  - Discord Webhook API
  - User Management
  - Character Management
  - Remote Procedure Callbacks (RPC)
  - PrettyPrint
  - Dataview
  - Game Events
  - Prompts
  - Pedestrians
  - Objects
  - Notifications
  - Text Rendering
  - Blips
  - Files
- Global per player locale
- Death handling
  - Death Camera
  - Death Timer
  - Hospital Spawner
- Position Syncing

# TODO
- Job API/Docs
- Logout functionality + character script. (currently logout does not take you to character select)
- Make the UI configurable
- Optimization pass
- Migrate user/character ID's to UUID

## API Documentation and usage
[https://featherframework.net/api](https://featherframework.net/)

## Contract 1 foundation

Contract 1 includes a provider-backed notification boundary. Server resources can
send a validated right-side notification without importing the legacy Core API:

```lua
local result = exports['feather-core']:SendNotification({
    source = playerId,
    style = 'right',
    message = 'Inventory updated.',
    duration = 3000
})
```

The result uses the standard Core envelope. Notification providers can be
registered through `RegisterNotificationProvider`; the built-in provider is the
default while notification rendering is extracted from Core.

Client resources can display the same validated style locally through the named
`ShowNotification` export.

Locale registration and translation are available in both runtimes through the
named `RegisterLocale` and `TranslateLocale` exports. Both return standard Core
result envelopes.

The clean-slate Core rebuild has begun. The existing `initiate()` export remains temporarily available while first-party resources are moved to the new contracts.

New server exports:

```lua
local capabilities = exports['feather-core']:GetCapabilities()
local health = exports['feather-core']:GetHealth()
local ready = exports['feather-core']:AwaitReady(10000)
```

All three exports return a standard result envelope. Successful results use `{ ok = true, value = ... }`; expected failures use `{ ok = false, code = ..., message = ... }`.

RPC transport is also available through named exports on the server and client:
`RegisterRPC`, `RegisterContractRPC`, `GetRPCRoutes`, `NotifyRPC`, `CallRPC`,
and `CallRPCAsync`. First-party resources should use these instead of obtaining
the RPC table through `initiate()`.

After starting or restarting `feather-core`, run this in the server console:

```text
CoreContractSmokeTest
```

The foundation is healthy when all four checks report `PASS`. See `docs/architecture-contract-1.md` for the frozen initial decisions and `MASTER_PLAN.md` for the full build plan.

Core now runs ordered, content-checksummed database migrations before reporting ready. To verify the migration ledger, minimal account tables, and safe reruns, run:

```text
CoreMigrationSmokeTest
```

The account identity service resolves one normalized Rockstar `license` identifier
(`license2` only when `license` is unavailable) to a UUID-backed Core account and
exposes immutable server-side contexts through `GetAccountContext(source)`. Steam,
Discord, Cfx, and other secondary identifiers never merge accounts.

Server consumers that require the normalized connection anchor can use
`GetPrimaryIdentifier(source)`. Connection-gate owners register through the named
`RegisterConnectionGate` export. `GetConnectionGates` returns safe runtime
diagnostics without exposing gate callbacks.

With a player connected, run:

```text
CoreAccountSmokeTest [serverId]
```

For clean-slate development only, `database/development_identity_reset.sql`
removes account/Character ownership and dependent runtime state while preserving
the Inventory item catalog and migration ledgers. Stop the server before running
it; the operation is destructive and is not a production migration.

After selecting and spawning a character, verify the UUID-backed session kernel with:

```text
CoreSessionSmokeTest [serverId]
```

Contract 1 RPC routes use versioned names, standard result envelopes, bounded plain-data payloads, authoritative account/session context, and explicit ownership metadata. Verify the route registry with:

```text
CoreRpcSmokeTest
```

Contract 1 server-local events are versioned and declared by one publisher. Payloads are validated and copied per listener, listener failures are isolated, and resource-owned declarations/subscriptions are removed automatically when that resource stops.

```text
CoreEventSmokeTest
```

Contract 1 providers publish their real contract and capabilities, have an explicit owning resource, support one named default per kind, expose health through result envelopes, and are removed when their owner stops.

```text
CoreProviderSmokeTest
```

The Contract 1 policy layer derives authoritative account/session actor context and asks one registered policy provider to evaluate named actions. Denials are successful decisions with `allowed = false`; missing, crashing, or malformed providers fail closed.

```text
CorePolicySmokeTest
```

No production policy provider is installed yet, so existing admin permission behavior remains unchanged until its coordinated cutover.

Contract 1 guards are synchronous, priority-ordered precondition checks for transaction-time and pre-mutation decisions. A callback returns `true` or `false, reason`; callback errors and malformed decisions fail closed.

```text
CoreGuardSmokeTest
```
