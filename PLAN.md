# Quality Full Monty Implementation Plan

## Current State

- Directory: `/home/xyf/SeaBlockUpdates/repos/QualityFullMonty`
- The directory is empty and is not currently a git repository.
- Local Factorio headless install is available at `/home/xyf/SeaBlockUpdates/factorio_headless`.
- Local user data and mods directory are available at `/home/xyf/SeaBlockUpdates/factorio_user`.

## Product Goal

Factorio 2.0 mod for standard Factorio 2.0 games using the official Quality feature:

- Any placed entity with a module inventory that can accept quality modules is automatically filled with legendary `quality-module-3`.
- Players should not be able to keep/remove those modules through manual removal, robots, upgrade or downgrade planners, or inserter-style interactions.
- Beacons should be removed from practical gameplay and cleaned from existing saves.
- The mod should be packageable and publishable on the Factorio Mod Portal so it is discoverable in the in-game mod browser.

Out of scope:

- SeaBlock compatibility.
- Angel's Mods compatibility.
- Bob's Mods compatibility.
- General overhaul-mod compatibility work beyond the official Factorio 2.0 prototype set.

## Documentation Findings

- Factorio mods need an `info.json`; the game also recognizes `control.lua`, `data.lua`, `data-updates.lua`, `data-final-fixes.lua`, `locale`, `thumbnail.png`, `changelog.txt`, and `migrations`.
- A mod zip should be named `{mod-name}_{version}`; `info.json` defines the internal name and version.
- `factorio_version` should be `"2.0"` for Factorio 2.0 compatibility, not a full patch version.
- `quality_required = true` enables the quality feature flag that requires Space Age ownership.
- The in-game browser displays the short `info.json` description.
- Publishing uses the Mod Portal. API publishing requires an API key with `ModPortal: Publish Mods`, then `init_publish`, then uploading the zip to the returned upload URL.

References:

- https://lua-api.factorio.com/latest/auxiliary/mod-structure.html
- https://wiki.factorio.com/Mod_publish_API
- https://wiki.factorio.com/Mod_portal_API

## Key Technical Decisions

### Mod Identity

Use:

- Internal name: `QualityFullMonty`
- Display title: `Quality Full Monty`
- Initial version: `1.0.0`
- Factorio version: `2.0`
- Dependencies: `base`, `quality`
- Feature flag: `quality_required = true`
- Publisher: Fyx

Compatibility target:

- Official Factorio 2.0 only.
- Official `quality` mod only.
- No special handling for SeaBlock, Angel's Mods, Bob's Mods, or other overhaul prototype conventions.

Open question before publishing: confirm the Mod Portal name `QualityFullMonty` is available.

### Beacons

Data stage should make beacons unavailable without deleting prototypes outright:

- Iterate every prototype in `data.raw.beacon`.
- Hide beacon prototypes from normal browsing and Factoriopedia where supported.
- Find items with `place_result` pointing to a beacon and hide them.
- Find recipes producing beacon items/entities and hide/disable them.
- Remove beacon recipe unlock effects from technologies.

Runtime should clean saves and edge cases:

- On init/configuration change, scan all surfaces and destroy existing beacon entities.
- On build/revive/script-build events, immediately destroy any beacon entity that appears.

### Legendary Quality Module Enforcement

Use real module inventories first, then prove whether the lock is strong enough.

The runtime primitive is:

- `entity.get_module_inventory()` to detect module-capable entities.
- Try inserting or setting `{ name = "quality-module-3", quality = "legendary", count = 1 }`.
- If the module inventory accepts that stack, replace every slot with legendary quality modules.

The enforcement loop should be:

- Register every protected entity by `unit_number`.
- Fill on player build, robot build, script build, ghost revive, clone, and configuration migration.
- Reconcile protected entities periodically in small batches.
- Re-scan all surfaces on init/configuration change.
- Scrub or refill after player inventory/cursor changes if tests show manual extraction can leak free legendary modules.

Important risk:

- Factorio exposes module inventories, but there may not be a native "locked module slot" property. The implementation must test whether a player can briefly remove a module before reconciliation. If this leaks usable legendary modules, choose one of:
  - strict mode: remove legendary quality modules from player cursor/main inventory when they match the managed stack;
  - UI-lock mode: make protected entities non-operable where acceptable;
  - prototype-effect mode: stop using visible module slots and instead bake quality effects into machine prototypes, if exact locking proves impossible.

## Implementation Steps

1. Scaffold mod files:
   - `QualityFullMonty/info.json`
   - `QualityFullMonty/control.lua`
   - `QualityFullMonty/data-final-fixes.lua`
   - `QualityFullMonty/locale/en/QualityFullMonty.cfg`
   - `QualityFullMonty/changelog.txt`
   - `QualityFullMonty/thumbnail.png`
   - `scripts/package.sh`
   - `README.md`

2. Add data-final-fixes beacon removal:
   - hide beacon prototypes/items/recipes;
   - remove technology unlock effects;
   - keep prototype removal conservative to avoid corrupting old saves.

3. Add runtime module manager:
   - helper `is_quality_module_machine(entity)`;
   - helper `fill_modules(entity)`;
   - storage table for protected entity unit numbers;
   - event registration for player/robot/script builds and ghost revival;
   - chunked periodic reconciliation.

4. Add runtime beacon cleanup:
   - `remove_beacon(entity)` helper;
   - surface scan on init/configuration;
   - build-event guard.

5. Add migration/configuration handling:
   - scan existing saves when the mod is added or updated;
   - refill existing module-capable entities;
   - remove existing beacons.

6. Package for local testing:
   - symlink or copy `QualityFullMonty` into `factorio_user/mods`;
   - enable `quality` and `QualityFullMonty` in `mod-list.json`;
   - build zip as `QualityFullMonty_0.1.0.zip`.

## Test Plan

### Static/Packaging Tests

- Validate `info.json` with `python3 -m json.tool`.
- Confirm zip name and folder layout match Factorio's expected mod structure.
- Run Factorio with the unpacked mod folder.
- Run Factorio with the packaged zip.

### Data Tests

Use `factorio --dump-data` and inspect `data-raw-dump.json`:

- `quality-module-3` exists.
- quality `legendary` exists.
- all beacon recipes are hidden/disabled.
- beacon item prototypes are hidden and not placeable through normal crafting.
- technologies no longer unlock beacon recipes.

### Runtime Smoke Tests

Use a local-only companion test mod or scenario, not included in the published zip. The runtime matrix should stay focused on official Factorio 2.0 entities:

- Create an assembling machine with module slots.
- Verify every module slot contains legendary `quality-module-3`.
- Create a lab, miner, furnace, recycler, or any entity with quality-module-compatible slots and verify filling.
- Create an entity with module slots that cannot accept quality modules and verify it is ignored.
- Try clearing the module inventory through script, wait for reconciliation, verify it refills.
- Try inserting a different module through script, wait for reconciliation, verify it is replaced.
- Build a beacon and verify it is destroyed.
- Load a save containing existing beacons and module-capable entities, verify migration cleanup.
- Do not add SeaBlock, Angel's Mods, Bob's Mods, or other overhaul mods to the required test matrix.

### Manual In-Game Tests

- Start a freeplay save with the mod enabled.
- Place assembler, miner, lab, recycler, and rocket silo.
- Attempt to remove modules manually.
- Attempt to paste settings with different modules.
- Attempt upgrade/downgrade planner actions involving modules.
- Attempt robot placement from blueprints with modules.
- Confirm no removable free legendary modules remain in player inventories.
- Confirm beacons are unavailable in crafting, tech unlocks, Factoriopedia, and placement.

## Publishing Plan

1. Create Factorio account API key:
   - Go to `https://factorio.com/profile`.
   - Create an API key with `ModPortal: Publish Mods`.

2. Prepare release artifacts:
   - `QualityFullMonty_0.1.0.zip`
   - `thumbnail.png`, ideally 144x144.
   - `changelog.txt` in Factorio changelog format.
   - Markdown long description for Mod Portal.
   - License choice.
   - Source URL if hosted publicly.

3. Publish either manually or via API:
   - Manual: upload release zip through `mods.factorio.com`.
   - API: POST `mod=QualityFullMonty` to `/api/v2/mods/init_publish`, then POST the zip to the returned `upload_url`.

4. Verify discoverability:
   - Search `Quality Full Monty` and `QualityFullMonty` on `mods.factorio.com`.
   - Open Factorio's in-game Mods > Install tab and search for the mod.
   - Confirm title, thumbnail, short description, long description, changelog, and dependencies display correctly.

## Definition Of Done

- Mod loads in Factorio 2.0 with Quality enabled.
- Fresh saves and existing saves are handled.
- Module-capable quality machines are filled automatically.
- Removal attempts cannot produce usable free legendary quality modules.
- Beacons are effectively removed from gameplay.
- Local package passes folder and zip smoke tests.
- Release zip is accepted by the Factorio Mod Portal and appears in the in-game mod browser.
