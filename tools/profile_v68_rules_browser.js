async (page) => {
  await page.goto('__PROFILE_URL__');
  await page.waitForFunction(() => window.__V68_TEST__ && window.__V68_TEST__.game);
  return await page.evaluate(({frames}) => {
    const g = window.__V68_TEST__.game;
    const originalRandom = Math.random;
    let seed = 0x68c10;
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
    const activeRules = ['swordbone','swordcore','swordbaby','sworddomain','taixu'];
    activeRules.forEach(id => g.addRule(id));
    for (let i = 0; i < 96; i++) {
      const a = i * 6.283185307179586 / 96;
      const r = 3.2 + (i % 8) * .65;
      const e = g.createEnemy('wraith', i % 7 === 0, Math.sin(a) * r, Math.cos(a) * r);
      e.hp = e.maxHp = 999999;
    }
    for (let i = 0; i < 8; i++) g.spawnResonanceField(i % 2 ? 'array' : 'fire',
      Math.sin(i * .7853981633974483) * 4, Math.cos(i * .7853981633974483) * 4,
      2.8, 80, 9, 0x8cecff);
    const eventCounts = Object.fromEntries(['onHit','onKill','onDash','onDamageTaken','onWeaponCast','onBossKill','onSecond'].map(x => [x, 0]));
    const originalEmit = g.emitCombatEvent;
    g.emitCombatEvent = function(type, payload) { if (eventCounts[type] !== undefined) eventCounts[type]++; return originalEmit.call(this, type, payload); };
    const samples = [];
    const runFrame = () => { const start = performance.now(); g.update(1 / 60, 1 / 60); g.render(1 / 60); gsap.updateRoot(g.elapsed); return performance.now() - start; };
    for (let i = 0; i < 120; i++) runFrame();
    for (let i = 0; i < frames; i++) samples.push(runFrame());
    const sorted = [...samples].sort((a, b) => a - b);
    const percentile = p => sorted[Math.min(sorted.length - 1, Math.floor((sorted.length - 1) * p))];
    Math.random = originalRandom;
    return JSON.stringify({
      fixture: {seed: '0x68c10', enemies: 96, active_rules: activeRules.length, active_rule_ids: activeRules, weapon_setup: 'all level 5', resonance_fields: 8, samples: frames},
      whole_frame: {avg: samples.reduce((a, b) => a + b, 0) / samples.length, p50: percentile(.5), p95: percentile(.95), p99: percentile(.99), max: Math.max(...samples), samples: samples.length},
      hook_calls: eventCounts,
      hook_calls_per_frame: Object.fromEntries(Object.entries(eventCounts).map(([k, v]) => [k, v / frames])),
      active_rule_count: g.realmState.activeRealmRules.length,
      final_state: {enemies: g.enemies.length, scene_children: g.scene.children.length, geometries: g.renderer.info.memory.geometries}
    });
  }, {frames: __PROFILE_FRAMES__});
}
