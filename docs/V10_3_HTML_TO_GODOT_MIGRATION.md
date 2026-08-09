# V10.3 HTML → Godot Migration

## Authority and repeatability

- Gameplay authority remains `runtime-source/v6.7.html` during migration.
- `python tools/migrate_html_content.py` extracts versioned gameplay data into
  `godot/data/legacy/v67_content.json` and records the source SHA-256.
- Godot never executes the HTML or embeds a browser. The 3D runtime consumes native JSON,
  GDScript systems, Resources and signals.

## Converted catalog

| System | Count |
| --- | ---: |
| Realms | 6 |
| Realm rules | 15 |
| Weapons | 9 |
| Passives | 12 |
| Relics | 24 |
| Resonance paths | 6 |
| Regions | 5 |
| Encounter templates | 4 |
| Enemy definitions | 9 |
| Boss definitions | 6 |

## Native Godot runtime integration in this increment

- HTML boss schedule: 70 / 145 / 230 / 330 / 445 / 575 seconds.
- Six native Godot boss gates with migrated HP, speed, damage, radius and rewards.
- Realm route: 炼气 → 筑基 → 金丹 → 元婴 → 化神 → 炼虚.
- Boss defeat pauses the run and opens a native three-choice breakthrough modal.
- Selected realm rules persist for the run and are exposed in debug snapshots.
- Native adapters exist for sword-hit echoes, dash lightning, periodic sword/shadow casts,
  sword marks, movement nodes and dash fields. Rules depending on the later active-weapon,
  thunder-source and fatal-damage buses remain explicitly marked `reserved` in snapshots.
- The complete weapon/passive/relic/resonance/enemy catalogs are available to subsequent
  native runtime systems without reparsing the HTML.

## Verification

```powershell
python tools\migrate_html_content.py
& 'E:\tools\Godot-4.7.1\Godot_v4.7.1-stable_win64_console.exe' --headless --path .\godot --script res://tests/legacy_html_conversion_test.gd
```

The conversion gate kills the first migrated boss, verifies the three choices, selects
`剑骨道基`, and confirms the realm changes from 炼气 to 筑基.
