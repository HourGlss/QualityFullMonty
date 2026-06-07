#!/usr/bin/env python3
import json
import math
import os
import pathlib
import re
import shutil
import subprocess
import sys
import zipfile


REPO = pathlib.Path(__file__).resolve().parents[1]
MOD_DIR = REPO / "QualityFullMonty"
TEST_ROOT = REPO / ".factorio-test"
DEFAULT_FACTORIO_ROOT = REPO.parents[1] / "factorio_headless"
FACTORIO_ROOT = pathlib.Path(os.environ.get("FACTORIO_ROOT", DEFAULT_FACTORIO_ROOT))
FACTORIO = pathlib.Path(os.environ.get("FACTORIO_BIN", FACTORIO_ROOT / "bin/x64/factorio"))
DATA_DUMP = FACTORIO_ROOT / "script-output/data-raw-dump.json"


def run(command, cwd=REPO):
    print("+", " ".join(str(part) for part in command))
    subprocess.run(command, cwd=cwd, check=True)


def lua_files():
    return sorted(MOD_DIR.rglob("*.lua"))


def check_lua_syntax(files):
    luac = shutil.which("luac") or shutil.which("luac5.4")
    if not luac:
      raise RuntimeError("luac is required for Lua syntax checks")

    for path in files:
        run([luac, "-p", str(path)])


def strip_comments_and_strings(source):
    source = re.sub(r"--\[\[.*?\]\]", "", source, flags=re.S)
    source = re.sub(r"--.*", "", source)
    source = re.sub(r'"(?:\\\\.|[^"\\\\])*"', '""', source)
    return re.sub(r"'(?:\\\\.|[^'\\\\])*'", "''", source)


def function_bodies(source):
    pattern = re.compile(r"(^|\n)\s*(?:local\s+)?function\s+[\w.:]+\s*\([^)]*\)")
    matches = list(pattern.finditer(source))
    for index, match in enumerate(matches):
        start = match.start()
        end = matches[index + 1].start() if index + 1 < len(matches) else len(source)
        yield source[start:end]


def cyclomatic_complexity(body):
    cleaned = strip_comments_and_strings(body)
    keywords = re.findall(r"\b(if|elseif|for|while|repeat|and|or)\b", cleaned)
    return 1 + len(keywords)


def maintainability_score(source, complexities, bodies):
    cleaned = strip_comments_and_strings(source)
    loc = max(1, len([line for line in cleaned.splitlines() if line.strip()]))
    function_locs = [
        len([line for line in strip_comments_and_strings(body).splitlines() if line.strip()])
        for body in bodies
    ] or [loc]
    max_function_loc = max(function_locs)
    average_complexity = sum(complexities) / len(complexities)
    score = 100
    score -= max(0, loc - 100) * 0.15
    score -= max(0, max_function_loc - 24) * 1.25
    score -= max(0, max(complexities) - 5) * 8
    score -= max(0, average_complexity - 3) * 4
    return max(0, min(100, score))


def check_quality(files):
    failures = []
    for path in files:
        source = path.read_text()
        bodies = list(function_bodies(source))
        complexities = [cyclomatic_complexity(body) for body in bodies] or [1]
        max_complexity = max(complexities)
        mi = maintainability_score(source, complexities, bodies)
        print(f"{path.relative_to(REPO)}: max CC {max_complexity}, maintainability {mi:.1f}")
        if max_complexity > 5:
            failures.append(f"{path}: cyclomatic complexity {max_complexity} exceeds grade A threshold 5")
        if mi < 80:
            failures.append(f"{path}: maintainability index {mi:.1f} is below grade A threshold 80")

    if failures:
        raise AssertionError("\\n".join(failures))


def check_info_json():
    info = json.loads((MOD_DIR / "info.json").read_text())
    assert info["name"] == "QualityFullMonty"
    assert info["version"] == "0.1.3"
    assert info["factorio_version"] == "2.0"
    assert info["quality_required"] is True
    assert "quality >= 2.0.0" in info["dependencies"]


def check_dumped_data():
    data = json.loads(DATA_DUMP.read_text())
    module = data["module"]["qfm-locked-quality-module-3"]
    assert module["localised_name"] == ["item-name.qfm-locked-quality-module-3"]
    assert module["auto_recycle"] is False
    assert module["effect"] == {"quality": 0.25}
    assert "qfm-locked-quality-module-3-recycling" not in data.get("recipe", {})


def check_package():
    result = subprocess.run(["scripts/package.sh"], cwd=REPO, check=True, text=True, capture_output=True)
    archive = REPO / result.stdout.strip()
    assert archive.exists(), archive
    with zipfile.ZipFile(archive) as zip_file:
        names = set(zip_file.namelist())
        assert "QualityFullMonty/info.json" in names
        assert "QualityFullMonty/control.lua" in names
        assert "QualityFullMonty/data-final-fixes.lua" in names
        assert not any(name.startswith("local-tests/") for name in names)


def write_mod_list(mods_dir):
    mod_list = {
        "mods": [
            {"name": "base", "enabled": True},
            {"name": "quality", "enabled": True},
            {"name": "QualityFullMonty", "enabled": True},
            {"name": "QualityFullMontyLocalTest", "enabled": True},
        ]
    }
    (mods_dir / "mod-list.json").write_text(json.dumps(mod_list, indent=2))


def write_test_mod(mods_dir):
    test_mod = mods_dir / "QualityFullMontyLocalTest"
    test_mod.mkdir(parents=True, exist_ok=True)
    (test_mod / "info.json").write_text(json.dumps({
        "name": "QualityFullMontyLocalTest",
        "version": "0.1.0",
        "title": "Quality Full Monty Local Test",
        "author": "HourGlss",
        "factorio_version": "2.0",
        "dependencies": ["base >= 2.0.0", "quality >= 2.0.0", "QualityFullMonty"],
        "quality_required": True,
        "description": "Local-only smoke tests for Quality Full Monty."
    }, indent=2))
    (test_mod / "control.lua").write_text(r'''
local qfm_entities = require("__QualityFullMonty__.scripts.entities")
local locked_module_name = "qfm-locked-quality-module-3"
local locked_module_stack = {name = locked_module_name, count = 2, quality = "legendary"}

local function assert_locked_modules(entity)
  local inventory = entity.get_module_inventory()
  if not inventory or not inventory.valid or #inventory == 0 then
    error(entity.name .. " has no module inventory")
  end

  for index = 1, #inventory do
    local stack = inventory[index]
    if not stack.valid_for_read then
      error(entity.name .. " slot " .. index .. " is empty")
    end
    if stack.name ~= locked_module_name then
      error(entity.name .. " slot " .. index .. " has " .. stack.name)
    end
    if stack.quality.name ~= "legendary" then
      error(entity.name .. " slot " .. index .. " is not legendary")
    end
  end
end

local function insert_locked_into(entity, inventory_id)
  local inventory = entity.get_inventory(inventory_id)
  if not inventory or not inventory.valid then
    error(entity.name .. " does not have expected storage inventory")
  end

  if inventory.insert(locked_module_stack) ~= locked_module_stack.count then
    error("could not insert locked module into " .. entity.name)
  end

  table.insert(storage.storage_checks, {entity = entity, inventory_id = inventory_id})
end

local function assert_storage_destroyed()
  for _, check in pairs(storage.storage_checks or {}) do
    local inventory = check.entity.get_inventory(check.inventory_id)
    if inventory.get_item_count(locked_module_name) ~= 0 then
      error("locked module survived in " .. check.entity.name)
    end
  end
end

local function create_module_request_proxy(entity)
  return entity.surface.create_entity{
    name = "item-request-proxy",
    position = entity.position,
    target = entity,
    force = entity.force,
    modules = {
      {
        id = {name = "quality-module-3", quality = "legendary"},
        items = {
          in_inventory = {
            {
              inventory = defines.inventory.assembling_machine_modules,
              stack = 0
            }
          }
        }
      }
    }
  }
end

local function assert_request_proxy_cleared(entity)
  local proxy = create_module_request_proxy(entity)
  if not proxy or not proxy.valid or entity.item_request_proxy ~= proxy then
    error("could not create module request proxy")
  end

  qfm_entities.fill_modules(entity)
  if proxy.valid or entity.item_request_proxy then
    error("module request proxy was not cleared")
  end
end

script.on_init(function()
  local surface = game.surfaces.nauvis
  local force = game.forces.player
  force.research_all_technologies()
  storage.storage_checks = {}

  local assembler = surface.create_entity{
    name = "assembling-machine-3",
    position = {0, 0},
    force = force,
    raise_built = true
  }
  assert_locked_modules(assembler)
  assert_request_proxy_cleared(assembler)

  local furnace = surface.create_entity{
    name = "electric-furnace",
    position = {4, 0},
    force = force,
    raise_built = true
  }
  assert_locked_modules(furnace)

  local beacon = surface.create_entity{
    name = "beacon",
    position = {8, 0},
    force = force,
    raise_built = true
  }
  if beacon and beacon.valid then
    error("beacon was not destroyed")
  end

  storage.assembler = assembler
  assembler.get_module_inventory().clear()

  local miner_test = surface.create_entity{
    name = "assembling-machine-3",
    position = {12, 0},
    force = force,
    raise_built = true
  }
  assert_locked_modules(miner_test)

  qfm_entities.clear_modules(miner_test)
  local miner_inventory = miner_test.get_module_inventory()
  for index = 1, #miner_inventory do
    if miner_inventory[index].valid_for_read then
      error("pre-mining did not clear locked module slot " .. index)
    end
  end
  miner_test.destroy({raise_destroy = true})

  local chest = surface.create_entity{
    name = "steel-chest",
    position = {16, 0},
    force = force
  }
  insert_locked_into(chest, defines.inventory.chest)

  local car = surface.create_entity{
    name = "car",
    position = {20, 0},
    force = force
  }
  insert_locked_into(car, defines.inventory.car_trunk)

  for x = 28, 36, 2 do
    surface.create_entity{
      name = "straight-rail",
      position = {x, -1},
      direction = defines.direction.east,
      force = force
    }
  end

  local wagon = surface.create_entity{
    name = "cargo-wagon",
    position = {32, 1},
    force = force,
    orientation = 0.25
  }
  insert_locked_into(wagon, defines.inventory.cargo_wagon)

  game.print("Quality Full Monty local tests passed")
end)

script.on_event(defines.events.on_tick, function(event)
  if event.tick ~= 65 then
    return
  end

  assert_locked_modules(storage.assembler)
  assert_storage_destroyed()
end)
''')


def check_factorio_loads():
    if TEST_ROOT.exists():
        shutil.rmtree(TEST_ROOT)
    mods_dir = TEST_ROOT / "mods"
    script_output = TEST_ROOT / "script-output"
    saves = TEST_ROOT / "saves"
    mods_dir.mkdir(parents=True)
    script_output.mkdir(parents=True)
    saves.mkdir(parents=True)

    os.symlink(MOD_DIR, mods_dir / "QualityFullMonty", target_is_directory=True)
    write_test_mod(mods_dir)
    write_mod_list(mods_dir)

    save = saves / "qfm-local-test.zip"
    run([str(FACTORIO), "--mod-directory", str(mods_dir), "--create", str(save)])
    run([str(FACTORIO), "--mod-directory", str(mods_dir), "--benchmark", str(save), "--benchmark-ticks", "70", "--benchmark-sanitize"])
    run([str(FACTORIO), "--mod-directory", str(mods_dir), "--dump-data"])
    check_dumped_data()


def main():
    files = lua_files()
    if not files:
        raise RuntimeError("No mod Lua files found")
    check_lua_syntax(files)
    check_quality(files)
    check_info_json()
    check_package()
    check_factorio_loads()
    print("All local checks passed")


if __name__ == "__main__":
    main()
