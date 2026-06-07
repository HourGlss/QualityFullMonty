# Quality Full Monty

Quality Full Monty is a standard Factorio 2.0 mod for games using the official Quality feature.

It automatically fills every quality-capable module inventory with locked legendary quality modules. Beacons are hidden from normal gameplay and removed from saves as they appear.

## Scope

- Supports standard Factorio 2.0 plus the official `quality` mod.
- Does not target SeaBlock, Angel's Mods, Bob's Mods, or overhaul compatibility.
- Local tests live outside the mod folder and are intentionally ignored by git.

## Packaging

Run:

```sh
scripts/package.sh
```

The release zip is written to `dist/QualityFullMonty_0.1.1.zip`.

## Local Validation

The local validation harness is intentionally ignored by git. It checks every mod Lua file for syntax, cyclomatic complexity, and maintainability, then loads the mod in Factorio headless with a local-only companion test mod.

The current quality gate requires:

- max cyclomatic complexity of 5 or lower per Lua function;
- maintainability score of 80 or higher per Lua file;
- successful Factorio headless create, benchmark load, and data dump.

## Factorio Mod Portal

To make the mod findable in-game, publish the release zip to the official Factorio Mod Portal. The in-game Mods > Install tab searches that portal.

First-time publishing needs a Factorio account API key from `https://factorio.com/profile` with `ModPortal: Publish Mods` permission. The first upload uses the Mod Publish API `init_publish` endpoint, then uploads `dist/QualityFullMonty_0.1.1.zip` to the returned upload URL.

Subsequent releases use the Mod Upload API release upload endpoint for the existing mod.
