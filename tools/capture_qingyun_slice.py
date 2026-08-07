#!/usr/bin/env python3
"""Capture deterministic Golden Scene A screenshots for the disposable V0 prototype."""
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
VIEWPORTS = {"1440": (1440, 900), "1920": (1920, 1080), "mobile": (390, 844)}


def free_port() -> int:
    with socket.socket() as sock:
        sock.bind(("127.0.0.1", 0))
        return int(sock.getsockname()[1])


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--label", required=True, choices=("before", "after"))
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    args.output.mkdir(parents=True, exist_ok=True)
    port = free_port()
    server = subprocess.Popen([sys.executable, "-m", "http.server", str(port), "--bind", "127.0.0.1"],
                              cwd=ROOT, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    session = f"qingyun_{os.getpid()}"
    base = ["npx.cmd", "--yes", "--package", "@playwright/cli", "playwright-cli", "--session", session]
    url = f"http://127.0.0.1:{port}/index.html?visual-slice={args.label}"
    targets = {key: str((args.output / f"{args.label}_A_{key}.png").resolve()) for key in VIEWPORTS}
    script = f'''async (page) => {{
  await page.goto({json.dumps(url)});
  await page.waitForFunction(() => window.__V67_GAME__);
  await page.click('#startBtn');
  await page.waitForTimeout(700);
  await page.evaluate(() => {{
    const g = window.__V67_GAME__;
    g.clearRuntime();
    g.phase = 'PAUSE';
    g.render(0);
  }});
  const result = {{}};
  for (const [name, size] of Object.entries({json.dumps(VIEWPORTS)})) {{
    await page.setViewportSize({{width: size[0], height: size[1]}});
    await page.waitForTimeout(120);
    await page.screenshot({{path: {json.dumps(targets)}[name], fullPage: false}});
    result[name] = {{width: size[0], height: size[1], path: {json.dumps(targets)}[name], metrics: await page.evaluate(() => {{
      const g = window.__V67_GAME__; const materials = new Set();
      g.scene.traverse(object => {{ const list = Array.isArray(object.material) ? object.material : [object.material]; for (const material of list) if (material) materials.add(material); }});
      return {{calls: g.renderer.info.render.calls, triangles: g.renderer.info.render.triangles,
        geometries: g.renderer.info.memory.geometries, textures: g.renderer.info.memory.textures,
        materials: materials.size, scene_children: g.scene.children.length}};
    }})}};
  }}
  return JSON.stringify({{label: {json.dumps(args.label)}, screenshots: result,
    console_errors: await page.evaluate(() => window.__visualConsoleErrors || [])}});
}}'''
    script_path = None
    try:
        time.sleep(.25)
        opened = subprocess.run(base + ["open", url], cwd=ROOT, capture_output=True, text=True,
                                encoding="utf-8", errors="replace", timeout=120)
        if opened.returncode:
            raise RuntimeError(opened.stdout + opened.stderr)
        with tempfile.NamedTemporaryFile("w", suffix=".js", encoding="utf-8", delete=False) as handle:
            handle.write(script)
            script_path = Path(handle.name)
        run = subprocess.run(base + ["run-code", "--filename", str(script_path), "--raw"], cwd=ROOT,
                             capture_output=True, text=True, encoding="utf-8", errors="replace", timeout=120)
        if run.returncode:
            raise RuntimeError(run.stdout + run.stderr)
        print(run.stdout.strip().splitlines()[-1])
        return 0
    finally:
        subprocess.run(base + ["close"], cwd=ROOT, capture_output=True, text=True,
                       encoding="utf-8", errors="replace", timeout=20)
        server.terminate()
        try:
            server.wait(timeout=5)
        except subprocess.TimeoutExpired:
            server.kill()
        if script_path:
            script_path.unlink(missing_ok=True)


if __name__ == "__main__":
    raise SystemExit(main())
