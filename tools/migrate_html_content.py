"""Extract the authoritative V6.7/V8 gameplay catalog from the legacy HTML.

The HTML remains the source of truth during the Godot migration. This tool evaluates only
the constant-data prelude before ``class Game`` and serializes data/functions as metadata;
it does not launch a browser or execute the game runtime.
"""

from __future__ import annotations

import hashlib
import json
import re
import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "runtime-source" / "v6.7.html"
OUTPUT = ROOT / "godot" / "data" / "legacy" / "v67_content.json"


def main() -> int:
    source = SOURCE.read_text(encoding="utf-8")
    start = source.index("const DIFF=")
    end = source.index("class Game{", start)
    prelude = source[start:end]
    projection = r"""
const ruleMetadata=Object.fromEntries(Object.entries(RUN_RULES).map(([id,r])=>[id,{
  id,name:r.name,tags:r.tags,description:r.description,lore:r.lore,
  hooks:Object.keys(r).filter(k=>typeof r[k]==='function')
}]));
return {
  difficulty:DIFF,game_phases:GamePhase,modal_priority:MODAL_PRIORITY,
  realms:REALMS,rules:ruleMetadata,weapon_tags:WEAPON_TAGS,weapons:WEAPONS,
  passives:PASSIVES,tiers:TIER_INFO,relics:RELICS,resonance_paths:RESONANCE_PATHS,
  spirit_vein:SPIRIT_VEIN,regions:REGIONS,encounter_templates:ENCOUNTER_TEMPLATES,
  level_metrics:LEVEL_METRICS,map_rooms:MAP_ROOMS,map_links:MAP_LINKS,
  map_blockers:MAP_BLOCKERS,enemies:ENEMIES,bosses:BOSSES
};
"""
    javascript = (
        "const fs=require('fs');\n"
        + "const data=(new Function("
        + json.dumps(prelude + projection, ensure_ascii=False)
        + "))();\nprocess.stdout.write(JSON.stringify(data));"
    )
    completed = subprocess.run(
        ["node", "-e", javascript],
        check=True,
        capture_output=True,
        text=True,
        encoding="utf-8",
    )
    catalog = json.loads(completed.stdout)
    schedule_match = re.search(r"const bossTimes=\[([^\]]+)\]", source)
    if schedule_match is None:
        raise SystemExit("Legacy boss schedule not found")
    catalog["boss_schedule_seconds"] = [int(value) for value in schedule_match.group(1).split(",")]
    payload = {
        "schema_version": 1,
        "source": "runtime-source/v6.7.html",
        "source_sha256": hashlib.sha256(SOURCE.read_bytes()).hexdigest(),
        "content": catalog,
    }
    expected = {
        "realms": 6,
        "rules": 15,
        "weapons": 9,
        "passives": 12,
        "relics": 24,
        "resonance_paths": 6,
        "regions": 5,
        "encounter_templates": 4,
        "enemies": 9,
        "bosses": 6,
    }
    counts = {key: len(catalog[key]) for key in expected}
    if counts != expected:
        raise SystemExit(f"Legacy catalog count mismatch: {counts} != {expected}")
    payload["counts"] = counts
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT.write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")
    print("HTML_CONTENT_MIGRATION_PASS=" + json.dumps(counts, separators=(",", ":")))
    return 0


if __name__ == "__main__":
    sys.exit(main())
