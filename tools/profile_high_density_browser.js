async (page) => {
  await page.goto('__PROFILE_URL__');
  await page.waitForFunction(() => window.__V67_GAME__);
  await page.setViewportSize({width: 1440, height: 900});
  return await page.evaluate(({frames}) => {
    const g = window.__V67_GAME__;
    const originalRandom = Math.random;
    let seed = 0x67c10;
    Math.random = () => {
      seed = (Math.imul(seed ^ seed >>> 15, 1 | seed) + 0x6D2B79F5) >>> 0;
      let x = Math.imul(seed ^ seed >>> 15, 1 | seed);
      x ^= x + Math.imul(x ^ x >>> 7, 61 | x);
      return ((x ^ x >>> 14) >>> 0) / 4294967296;
    };

    g.start();
    g.phase = 'PAUSE';
    g.player.weapons = {
      bolt: {level: 5, cd: 0}, blades: {level: 5, cd: 0}, storm: {level: 5, cd: 0},
      nova: {level: 5, cd: 0}, aura: {level: 5, cd: 0}, raven: {level: 5, cd: 0},
      void: {level: 5, cd: 0}, meteor: {level: 5, cd: 0}, spear: {level: 5, cd: 0}
    };
    for (let i = 0; i < 96; i++) {
      const a = i * 6.283185307179586 / 96;
      const r = 3.2 + (i % 8) * .65;
      const e = g.createEnemy('wraith', i % 7 === 0, Math.sin(a) * r, Math.cos(a) * r);
      e.hp = e.maxHp = 999999;
    }
    for (let i = 0; i < 8; i++) {
      g.spawnResonanceField(i % 2 ? 'array' : 'fire', Math.sin(i * .7853981633974483) * 4,
        Math.cos(i * .7853981633974483) * 4, 2.8, 80, 9, 0x8cecff);
    }

    const names = ['updatePlayer', 'spawnDirector', 'updateWeapons', 'updateEnemies',
      'updateProjectiles', 'updateEnemyProjectiles', 'updatePickups', 'updateHazards',
      'updateResonances', 'updateSparkPool', 'updateEffects', 'checkEvents', 'render', 'update'];
    const samples = Object.fromEntries(names.map(name => [name, []]));
    const originals = {};
    for (const name of names) {
      originals[name] = g[name];
      g[name] = function (...args) {
        const start = performance.now();
        const result = originals[name].apply(this, args);
        samples[name].push(performance.now() - start);
        return result;
      };
    }
    const originalRendererRender = g.renderer.render.bind(g.renderer);
    const rendererSamples = [];
    g.renderer.render = function (...args) {
      const start = performance.now();
      const result = originalRendererRender(...args);
      rendererSamples.push(performance.now() - start);
      return result;
    };

    const frameSamples = [];
    const gsapSamples = [];
    const slowFrameTrace = [];
    let previousKills = g.kills;
    let previousPickups = g.pickups.length;
    const stat = values => {
      const sorted = [...values].sort((a, b) => a - b);
      const percentile = p => sorted[Math.min(sorted.length - 1, Math.floor((sorted.length - 1) * p))];
      return {avg: values.reduce((a, b) => a + b, 0) / values.length, p50: percentile(.5),
        p95: percentile(.95), p99: percentile(.99), max: Math.max(...values), samples: values.length};
    };
    const resourceState = () => ({
      enemies: g.enemies.length, projectiles: g.projectiles.length,
      enemy_projectiles: g.enemyProjectiles.length, effects: g.effects.length,
      hazards: g.hazards.length, resonance_fields: g.resonance.fields.length,
      spark_active: g.sparkPool?.items.filter(item => item.life > 0).length ?? 0,
      trail_active: g.trailPool?.items.filter(item => item.life > 0).length ?? 0,
      scene_children: g.scene.children.length, geometries: g.renderer.info.memory.geometries
    });
    const uniqueMaterials = () => {
      const materials = new Set();
      g.scene.traverse(object => {
        const list = Array.isArray(object.material) ? object.material : [object.material];
        for (const material of list) if (material) materials.add(material);
      });
      return materials.size;
    };
    const runFrame = () => {
      const start = performance.now();
      g.update(1 / 60, 1 / 60);
      g.render(1 / 60);
      const gsapStart = performance.now();
      gsap.updateRoot(g.elapsed);
      const gsapMs = performance.now() - gsapStart;
      gsapSamples.push(gsapMs);
      return performance.now() - start;
    };
    for (let i = 0; i < 120; i++) runFrame();
    frameSamples.length = 0;
    for (const values of Object.values(samples)) values.length = 0;
    rendererSamples.length = 0;
    gsapSamples.length = 0;
    previousKills = g.kills;
    previousPickups = g.pickups.length;
    for (let i = 0; i < frames; i++) {
      const floaterBefore = g.floaterPool?.next ?? 0;
      const frameMs = runFrame();
      const damageNumbersThisFrame = (g.floaterPool?.next ?? 0) - floaterBefore;
      frameSamples.push(frameMs);
      if (frameMs > 16.667) {
        slowFrameTrace.push({
          frame: i + 1, frame_ms: frameMs, update_ms: samples.update.at(-1),
          render_ms: samples.render.at(-1), updateEffects_ms: samples.updateEffects.at(-1),
          updateEnemies_ms: samples.updateEnemies.at(-1), updateWeapons_ms: samples.updateWeapons.at(-1),
          updateResonances_ms: samples.updateResonances.at(-1), projectiles_ms: samples.updateProjectiles.at(-1),
          spark_trail_ms: (samples.updateSparkPool.at(-1) || 0) + (samples.render.at(-1) || 0),
          renderer_render_ms: rendererSamples.at(-1),
          enemies: g.enemies.length, projectiles: g.projectiles.length,
          enemy_projectiles: g.enemyProjectiles.length, effects: g.effects.length,
          hazards: g.hazards.length, scene_children: g.scene.children.length,
          geometries: g.renderer.info.memory.geometries, materials: uniqueMaterials(),
          kills_this_frame: g.kills - previousKills,
          damage_numbers_this_frame: damageNumbersThisFrame,
          pickups_this_frame: g.pickups.length - previousPickups
        });
      }
      previousKills = g.kills;
      previousPickups = g.pickups.length;
    }
    Math.random = originalRandom;
    const result = {
      fixture: {seed: '0x67c10', enemies: 96, weapon_setup: 'all level 5', resonance_fields: 8,
        viewport: '1440x900', fixed_dt: 1 / 60, warmup: 120, samples: frames},
      whole_frame: stat(frameSamples),
      update: stat(samples.update), render: stat(samples.render),
      updateEffects: stat(samples.updateEffects), updateEnemies: stat(samples.updateEnemies),
      updateWeapons: stat(samples.updateWeapons), updateResonances: stat(samples.updateResonances),
      updateProjectiles: stat(samples.updateProjectiles), updateSparkPool: stat(samples.updateSparkPool),
      renderer_render: stat(rendererSamples), gsap_update_root: stat(gsapSamples),
      spike_count: slowFrameTrace.length, slow_frame_trace: slowFrameTrace,
      final_state: {...resourceState(), materials: uniqueMaterials(), floaters: g.floaterPool?.items.length ?? 0}
    };
    return JSON.stringify(result);
  }, {frames: __PROFILE_FRAMES__});
}
