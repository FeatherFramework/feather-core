# Character session contract

## Purpose

A character session identifies one authoritative source-to-character binding. Session IDs are runtime-only and change whenever a character is loaded again. Long-running server operations can use the session ID to prevent a request made by an old character from committing after logout, disconnect, or character switching.

## Server API

```lua
local Feather = exports['feather-core'].initiate()

local session = Feather.Character.GetSession(source)
local resolved = Feather.Character.ResolveSession(source)
local current = Feather.Character.IsSessionCurrent(source, sessionId, characterId)
local capabilities = Feather.Character.GetCapabilities()
```

`GetSession` returns only sessions in the `ready` state. `ResolveSession` additionally verifies the current character cache and returns the authoritative character snapshot.

## Server lifecycle events

### `Feather:Server:Character:Ready`

Fires after ownership validation, character cache creation, and session creation. Arguments are the session snapshot followed by the character snapshot.

### `Feather:Server:Character:Leaving`

Fires synchronously before persistence and cache removal. The session immediately stops being current, so new character-required operations are rejected. Consumers should stop runtime activity and stage final domain persistence here.

### `Feather:Server:Character:Left`

Fires after cache persistence and removal. The session state is `left`. Consumers should release remaining runtime-only state.

The existing `Feather:Server:Character:Spawned` and `Feather:Character:Logout` events remain available for existing consumers.

## Character-required RPC routes

```lua
Feather.RPC.Register('example:secured', function(params, respond, source, context)
    -- context.characterId, context.sessionId, context.character, and
    -- context.correlationId were created by core.
    respond({ ok = true })
end, {
    requireCharacter = true,
    windowMs = 1000,
    maxCalls = 4,
    maxPayloadBytes = 1024
})
```

Core rejects the call when no current character session exists. The response function also revalidates the session, so an asynchronous handler cannot reply successfully after that session starts leaving.

## Ordering

```text
InitiateCharacter
  -> session created
  -> Feather:Server:Character:Spawned (legacy)
  -> Feather:Server:Character:Ready

Logout/disconnect
  -> session state becomes leaving
  -> Feather:Server:Character:Leaving
  -> cache persisted and removed
  -> Feather:Character:Logout (legacy)
  -> Feather:Server:Character:Left
```

Session snapshots are immutable identifiers. A session ID is not a bearer credential and never replaces server-side permission, ownership, proximity, or inventory validation.
