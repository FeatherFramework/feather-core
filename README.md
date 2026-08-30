# Feather Core

Feather Core is the required foundation for the Feather Framework. It manages
player accounts, active character sessions, database migrations, framework
communication, and the shared services used by other Feather resources.

Core does not provide gameplay by itself. Character creation, inventory,
weapons, administration, notifications, HUD, world behavior, and player
settings are supplied by their respective Feather resources.

## Requirements

- A current RedM/FXServer artifact
- [`oxmysql`](https://github.com/overextended/oxmysql)
- A MySQL or MariaDB database configured for `oxmysql`

For the easiest setup, install Feather with the official recipe. If you install
or update resources manually, download each required resource from its official
Feather release and follow any compatibility instructions in its release notes.

## Installation

1. Download the `feather-core` release for the version
   you intend to run.
2. Place the complete `feather-core` folder in your server's resources folder.
   When updating, replace the complete old folder instead of copying individual
   files over it.
3. Configure and start `oxmysql` before Feather Core.
4. Start Core before every Feather resource that depends on it.

A typical startup order is:

```cfg
ensure oxmysql
ensure feather-menu
ensure feather-core
ensure feather-routing
ensure feather-notify
ensure feather-world
ensure feather-pvp
ensure feather-toolkit
ensure feather-hud
ensure feather-character
ensure feather-inventory
ensure feather-weapons
ensure feather-admin
ensure feather-settings
ensure feather-versioner
```

The official Feather recipe manages this order automatically. See the
[installation guide](https://featherframework.net/guide) for the complete server
setup.

## Configuration

Settings are documented directly in [`config.lua`](config.lua). Most server
owners only need to review:

- `Config.DevMode` — keep `false` on a production server.
- `Config.DefaultLang` — fallback language code used for account settings. The
  selected language must be registered by an installed Feather resource.
- `Config.Logging.level` — minimum Core log level: `debug`, `info`, `warn`, or
  `error`.

The remaining values are framework safety and capacity limits. Leave them at
their defaults unless a resource developer identifies a specific need to change
them.

## Database setup

Core creates and updates its own tables automatically during startup. There is
no SQL file to import manually.

Migrations are ordered and checksummed. Never edit an applied migration, remove
migration-ledger records, or manually recreate Core tables. New releases add a
new migration when the schema needs to change.

Before an upgrade, back up the complete database, server configuration, and all
coordinated Feather resource folders.

## Verifying an installation (Optional)

With the default `warn` logging level, a successful `ready` transition is not
printed. Confirm there are no manifest, Lua, SQL, or Core error messages, then
run:

```text
CoreContractSmokeTest
CoreMigrationSmokeTest
CoreRpcSmokeTest
```

All checks should report `PASS`.

With a player connected, run:

```text
CoreAccountSmokeTest [serverId]
```

After that player selects and spawns a character, run:

```text
CoreSessionSmokeTest [serverId]
```

These verification commands can be run only from the server console.

## Updating

Use a controlled full server restart for Core updates. Core holds live account
sessions and registrations in memory, so restarting only Core can temporarily
disconnect dependent resources from their providers and contracts.

To update safely:

1. Stop new connections and shut down the server cleanly.
2. Back up the database and deployed resource folders.
3. Replace complete resource folders with one coordinated release set.
4. Start the server and confirm there are no Core startup errors.
5. Run `CoreContractSmokeTest` to verify readiness, then test character login
   and logout.

## Support

When requesting help, include the Core version, FXServer artifact version,
database version, startup order, the first relevant console error, and the exact
smoke-test output.
