async (page) => {
  const pageErrors = [];
  const consoleErrors = [];
  page.on('pageerror', error => pageErrors.push(String(error)));
  page.on('console', message => { if (message.type() === 'error') consoleErrors.push(message.text()); });
  await page.goto('__TEST_URL__');
  await page.waitForFunction(() => window.__V68_TEST__ && window.__V68_TEST__.game);
  return await page.evaluate(() => {
    const t = window.__V68_TEST__;
    const g = t.game;
    const failures = [];
    const check = (condition, message) => { if (!condition) failures.push(message); };

    t.reset();
    const baselineDamage = g.dmg(100, {level: 1});
    const baselineCooldown = g.cd(1, {level: 1});
    const spawned = t.spawnSpiritVeinForTest();
    let state = t.inspectEncounter();
    check(spawned && spawned.id === 1, 'spirit vein did not spawn');
    check(state.active && state.active.progress === 0, 'active capture state is missing');
    check(state.records.length === 1 && state.records[0].status === 'ACTIVE', 'active record was not created');
    check(g.transientVisuals.has(g.encounter.active.mesh), 'spirit vein visual is not lifecycle managed');

    g.player.x = spawned.x;
    g.player.z = spawned.z;
    g.player.group.position.set(spawned.x, 0, spawned.z);
    g.updateSpiritVein(.5, .5);
    state = t.inspectEncounter();
    check(state.active.inside === true, 'player did not enter the capture zone');
    check(state.active.progress > 0, 'capture progress did not advance in-zone');

    const captured = t.captureSpiritVeinForTest();
    state = t.inspectEncounter();
    const boostedDamage = g.dmg(100, {level: 1});
    const boostedCooldown = g.cd(1, {level: 1});
    check(captured.captures === 1 && captured.boonT > 0, 'capture did not grant spirit-vein boon');
    check(state.records[0].status === 'CAPTURED', 'capture record did not resolve');
    check(boostedDamage > baselineDamage * 1.2, 'damage boon is not active');
    check(boostedCooldown < baselineCooldown * .85, 'haste boon is not active');
    check(g.encounter.boonMesh && g.transientVisuals.has(g.encounter.boonMesh), 'boon aura is missing or unmanaged');

    for (let i = 0; i < 12; i++) g.registerComboKill(false);
    state = t.inspectEncounter();
    check(state.combo.value === 12 && state.combo.max === 12, 'combo chain did not accumulate');
    check(g.runRecord.maxCombo === 12, 'run record did not retain max combo');

    t.reset();
    state = t.inspectEncounter();
    check(!state.active && state.boonT === 0, 'restart did not clear encounter state');
    check(state.combo.value === 0 && state.records.length === 0, 'restart did not clear combo or records');
    const failed = t.failSpiritVeinForTest();
    state = t.inspectEncounter();
    check(failed.failures === 1 && state.records[0].status === 'FAILED', 'failure path did not resolve');
    check(!state.active, 'failed spirit vein remained active');

    return JSON.stringify({
      passed: failures.length === 0,
      failures,
      baselineDamage,
      boostedDamage,
      baselineCooldown,
      boostedCooldown,
      captured,
      failed,
      final: state,
    });
  }).then(raw => {
    const result = JSON.parse(raw);
    result.pageErrors = pageErrors;
    result.consoleErrors = consoleErrors;
    if (pageErrors.length || consoleErrors.length) {
      result.passed = false;
      result.failures.push(`browser errors: ${pageErrors.length} page / ${consoleErrors.length} console`);
    }
    return JSON.stringify(result);
  });
}
