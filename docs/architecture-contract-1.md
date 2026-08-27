# Feather Core Contract 1 Architecture Decisions

Status: accepted for the foundation slice

This document freezes the decisions needed to begin the clean-slate Core rebuild. Later decisions remain tracked in `MASTER_PLAN.md`.

## Ownership

- Core owns account identity, connection context, active character-session bindings, transport, capability discovery, provider lifecycle, and operational health.
- `feather-character` owns character records, selection, creation, appearance, spawn presentation, and character-domain persistence.
- Domain resources own their schemas, transactions, policy rules, and audit facts.
- Core does not expose general SQL, mutable caches, or gameplay helper APIs in Contract 1.

## Results

Public operations use exactly one result envelope:

```lua
{ ok = true, value = value, meta = optionalMeta }
{ ok = false, code = 'stable_code', message = 'Safe summary', details = optionalDetails }
```

Expected rejection is represented by `ok = false`. Exceptions are reserved for programming and startup faults. Public boundaries catch those faults, log their correlation ID, and return `internal_error` where a result can still be returned safely.

## Capabilities

Capabilities report the provider's actual contract and runtime state. A consumer requirement is never echoed back as a provider capability.

Contract 1 capability documents contain:

- `resource`
- `contract`
- `version`
- `state`
- `features`, with an integer contract per feature

Required capability mismatch fails closed.

## Lifecycle

Core uses these states:

```text
stopped -> booting -> migrating -> starting -> ready
                                  \-> degraded
                                  \-> failed
ready -> stopping -> stopped
```

The foundation slice implements `booting`, `starting`, `ready`, `failed`, `stopping`, and `stopped`. `migrating` becomes active when the new Core persistence layer is introduced. `degraded` is reserved for explicitly optional providers.

## Compatibility during construction

The final architecture has no backward-compatibility requirement. During construction, the existing `initiate()` export remains available only to keep first-party resources operational while Contract 1 is built and tested. It is not part of Contract 1 and will be deleted during the coordinated consumer-cutover phase.

## IDs and sessions

- Durable public account and character IDs will be UUIDs.
- Session IDs are server-generated UUIDs and unique for every activation.
- A source is a temporary transport address, never durable identity.

## Account settings

- Player locale is an account preference, not character-domain state.
- `core.account.settings.get.v1` returns the authenticated account's settings.
- `core.account.settings.update.v1` accepts only registered locale codes and
  derives the account identity from the connection context.
- Settings persist in `core_account_settings`; clients never submit an
  account ID and cannot update another account.
- Delayed character work must carry a session ID and verify it again before commit or success.
- Simultaneous activation of the same character is rejected by default.
- Feather-owned SQL schemas store UUID values as `CHAR(36)` for compatibility
  with MariaDB versions that predate the native `UUID` datatype.
- UUIDs are generated explicitly by server persistence code. Schemas do not
  rely on `DEFAULT UUID()` expression support.
- Server consumers may resolve only the normalized primary license anchor through
  `GetPrimaryIdentifier`; the complete identifier collection remains private to Core.

## Transport

- Route names are globally unique and include an explicit version suffix, such as `inventory.move.v1`.
- Registration metadata also declares its contract for diagnostics.
- Identity and session fields are created by the server request context and cannot be supplied by clients.
- Every route declares payload limits, timeout, rate limits, and whether a character session is required.

## Policy

- Authorization is action-based.
- Core provides authoritative actor context but does not hardcode role levels.
- The policy provider evaluates actions and returns an envelope.
- Provider failure and indeterminate decisions fail closed.
- Synchronous guards retain `true` or `false, reason` callback results because transaction-time guard evaluation cannot yield through an asynchronous envelope protocol.

## Notifications

- Core exposes provider-based notification dispatch rather than requiring consumers to import its legacy API table.
- Server dispatch supports the `right` style. Local client dispatch supports
  `right` and `top_banner`, with validated text and duration.
- Providers return result envelopes and provider failures never report successful delivery.
- Additional styles may be added as explicit capabilities without changing the request envelope.

## Localization

- Locale registration and translation are available through named exports and return result envelopes.
- Consumers unwrap translated strings at their own UI boundary and do not import Core's monolithic API table for localization.

## Persistence

- Core owns only its minimal account/identifier/migration schema.
- Core repositories are the only writers to Core tables.
- Migrations are ordered and checksum verified; services never perform ad hoc `ALTER TABLE` statements.
- Development may use a clean rebuild. A production upgrade path must exist before Contract 1 is released.

## Restart behavior

- A domain-resource restart removes that resource's routes, providers, guards, subscriptions, and pending calls.
- A Core restart invalidates all runtime sessions and registrations.
- Automatic live reconstruction after a Core restart is not assumed for Contract 1. The server owner receives a clear health failure until dependent resources and player sessions are re-established through the documented recovery path.

## First implementation slice

The first slice provides:

- result helpers;
- structured resource loggers;
- configuration validation;
- truthful lifecycle state;
- `GetCapabilities`, `GetHealth`, and `AwaitReady` named exports;
- verification of success and failure behavior.

It deliberately does not replace identity, sessions, RPC, events, or persistence yet.
