#!/usr/bin/env python3
"""Capture Golden Scene B/C evidence without shipping screenshots in Git."""
from __future__ import annotations

import argparse
import json
import os
import socket
import subprocess
import sys
import tempfile
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def free_port() -> int:
    with socket.socket() as sock:
        sock.bind(("127.0.0.1", 0))
        return int(sock.getsockname()[1])


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    args.output.mkdir(parents=True, exist_ok=True)
    port = free_port()
    server = subprocess.Popen([sys.executable, "-m", "http.server", str(port), "--bind", "127.0.0.1"],
                              cwd=ROOT, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    session = f"qingyun_scenes_{os.getpid()}"
    base = ["npx.cmd", "--yes", "--package", "@playwright/cli", "playwright-cli", "--session", session]
    url = f"http://127.0.0.1:{port}/index.html?golden-scenes=BC"
    targets = {"B": str((args.output / "after_B_COMBAT_1440.png").resolve()),
               "C": str((args.output / "after_C_HIGH_DENSITY_1440.png").resolve())}
    script = f'''async (page) => {{
  await page.goto({json.dumps(url)}); await page.waitForFunction(() => window.__V67_GAME__);
  await page.setViewportSize({{width: 1440, height: 900}}); await page.click('#startBtn'); await page.waitForTimeout(450);
  const makeScene = async (name, enemyCount, weaponNames, fieldCount) => {{
    await page.evaluate(({{enemyCount, weaponNames, fieldCount}}) => {{
      const g=window.__V67_GAME__; g.phase='PAUSE'; g.player.weapons={{}};
      for(const name of weaponNames)g.player.weapons[name]={{level:5,cd:0}};
      for(let i=0;i<enemyCount;i++){{const a=i*6.283185307179586/enemyCount,r=4.3+(i%5)*.72;const e=g.createEnemy('wraith',i%9===0,Math.sin(a)*r,Math.cos(a)*r);e.hp=e.maxHp=999999;}}
      for(let i=0;i<fieldCount;i++)g.spawnResonanceField(i%2?'array':'fire',Math.sin(i*.7853981633974483)*4,Math.cos(i*.7853981633974483)*4,2.8,80,9,0x8cecff);
      g.render(0);
    }}, {{enemyCount,weaponNames,fieldCount}});
    await page.waitForTimeout(150); await page.screenshot({{path: targets[name],fullPage:false}});
    return await page.evaluate(() => {{const g=window.__V67_GAME__;return {{calls:g.renderer.info.render.calls,triangles:g.renderer.info.render.triangles,geometries:g.renderer.info.memory.geometries,scene_children:g.scene.children.length,enemies:g.enemies.length,projectiles:g.projectiles.length,effects:g.effects.length}};}});
  }};
  const result={{B:await makeScene('B',42,['bolt','blades','storm'],2)}};
  await page.reload(); await page.waitForFunction(() => window.__V67_GAME__); await page.setViewportSize({{width:1440,height:900}}); await page.click('#startBtn'); await page.waitForTimeout(450);
  result.C=await makeScene('C',96,['bolt','blades','storm','nova','aura','raven','void','meteor','spear'],8);
  return JSON.stringify({{result,console_errors:await page.evaluate(() => window.__visualConsoleErrors||[])}});
}}'''.replace("targets[name]", json.dumps(targets)+"[name]")
    script_path = None
    try:
        time.sleep(.25)
        opened = subprocess.run(base + ["open", url], cwd=ROOT, capture_output=True, text=True,
                                encoding="utf-8", errors="replace", timeout=120)
        if opened.returncode:
            raise RuntimeError(opened.stdout + opened.stderr)
        with tempfile.NamedTemporaryFile("w", suffix=".js", encoding="utf-8", delete=False) as handle:
            handle.write(script); script_path=Path(handle.name)
        run = subprocess.run(base + ["run-code", "--filename", str(script_path), "--raw"], cwd=ROOT,
                             capture_output=True, text=True, encoding="utf-8", errors="replace", timeout=180)
        if run.returncode:
            raise RuntimeError(run.stdout + run.stderr)
        print(run.stdout.strip().splitlines()[-1]); return 0
    finally:
        subprocess.run(base + ["close"], cwd=ROOT, capture_output=True, text=True,
                       encoding="utf-8", errors="replace", timeout=20)
        server.terminate()
        try: server.wait(timeout=5)
        except subprocess.TimeoutExpired: server.kill()
        if script_path: script_path.unlink(missing_ok=True)


if __name__ == "__main__": raise SystemExit(main())
