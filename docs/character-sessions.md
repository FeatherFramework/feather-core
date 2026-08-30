# Character session contract

## Purpose

Core owns the authoritative runtime binding between a connected source, account,
and active character. A session ID is regenerated on every activation and lets
long-running server work prove that the same character session is still current
before committing or returning success.

Character records, selection, appearance, spawn plans, position persistence,
logout presentation, and deletion belong to `feather-character`.

## Named server exports

```lua
local session = exports['feather-core']:GetSessionContext(source)
local required = exports['feather-core']:RequireSession(source)
local current = exports['feather-core']:IsSessionCurrent(
    source,
    session.value.sessionId,
    session.value.characterId
)
```

`GetSessionContext` and `RequireSession` return the standard result envelope and
only expose sessions in the `ready` state. `IsSessionCurrent` returns a boolean
for commit-time currency checks.

Activation ownership is explicit:

```lua
exports['feather-core']:ActivateSession(source, characterId)
exports['feather-core']:BeginSessionLeaving(source, 'logout')
exports['feather-core']:CompleteSessionLeaving(source, sessionId)
```

Only trusted server resources may call these exports. Character ownership must
be validated by `feather-character` before activation.

## Snapshot

A ready snapshot contains:

- `sessionId`
- `source`
- `accountId`
- `characterId`
- `generation`
- `state`
- `activatedAt`

Source IDs and session IDs are runtime addresses, not durable identity or bearer
credentials. Authorization, ownership, inventory, and proximity checks remain
mandatory.

## Lifecycle events

Core declares and publishes:

- `core.session.ready.v1`
- `core.session.leaving.v1`
- `core.session.left.v1`

Consumers should use `SubscribeEvent` for owned subscriptions. Core also emits
the same names as local server events for tightly scoped server integrations.

Character separately declares its domain events, including
`character.ready.v1`, `character.spawned.v1`, `character.leaving.v1`, and
`character.left.v1`.

```text
Character validates ownership
  -> ActivateSession
  -> core.session.ready.v1
  -> Character applies its spawn plan
  -> character.ready.v1 / character.spawned.v1

Logout
  -> character.leaving.v1
  -> BeginSessionLeaving
  -> core.session.leaving.v1
  -> Character persists domain state
  -> CompleteSessionLeaving
  -> core.session.left.v1
  -> character.left.v1

Disconnect
  -> Core idempotently transitions ready -> leaving -> left
  -> source and character indexes are released
```

Once leaving begins, the session is no longer current and character-required RPC
work fails closed. RPC responses also revalidate session currency so delayed work
cannot report success after logout or character switching.

## Verification

With a character active, run:

```text
CoreSessionSmokeTest <source>
```

Expected result: `4/4 passed`.
