async (page) => {
  const pageErrors = [];
  const consoleErrors = [];
  page.on('pageerror', error => pageErrors.push(String(error)));
  page.on('console', message => { if (message.type() === 'error') consoleErrors.push(message.text()); });
  await page.goto('__TEST_URL__');
  await page.waitForFunction(() => window.__V82_TEST__ && window.__V82_TEST__.game);
  return await page.evaluate(() => {
    const t = window.__V82_TEST__;
    const g = t.game;
    const failures = [];
    const check = (condition, message) => { if (!condition) failures.push(message); };

    t.reset();
    const route = [
      ['ruins', 0, 0],
      ['bamboo', 25, 0],
      ['marsh', -25, 0],
      ['sword', 0, -25],
      ['ember', 0, 25],
    ];
    const visited = route.map(([id, x, z]) => ({expected: id, actual: t.setPosition(x, z)}));
    let state = t.inspectExpedition();
    check(visited.every(item => item.expected === item.actual), 'position-to-region mapping is incorrect');
    check(state.region.discovered.length === 5, 'all five regions were not discovered');
    check(state.records.regions.length >= 5, 'region transitions were not written to the run record');
    check(document.getElementById('regionName').textContent === '丹霞裂谷', 'region HUD did not update');

    t.setPosition(0, -25);
    const record = t.forceEncounter('crossfire');
    check(record && record.template === 'crossfire', 'forced encounter did not start');
    state = t.tickDirector(5, .1);
    check(state.director.phase === 'ACTIVE', 'director did not reach ACTIVE state');
    check(state.director.totalSpawned >= 5, 'director did not stagger a full squad into play');
    check(state.director.queue <= 2, 'director queue did not drain at the configured stagger rate');
    check(state.director.active.enemyIds.length === state.director.totalSpawned, 'encounter enemy ownership is incomplete');
    check(state.enemyStates.every(enemy => enemy.encounterId === record.id || enemy.encounterId === 0), 'enemy encounter ownership is corrupt');

    for (let i = 0; i < 8; i++) g.updateEnemies(.1);
    state = t.inspectExpedition();
    check(state.enemyStates.some(enemy => enemy.aiState !== 'SPAWN'), 'enemy tactical states did not advance');

    state = t.clearEncounter();
    check(state.director.phase === 'REST' && state.director.completed === 1, 'encounter did not close into REST');
    check(state.records.encounters[0].status === 'CLEARED', 'encounter record was not finalized');
    check(state.director.pressure >= .18 && state.director.pressure <= .92, 'director pressure escaped its clamp');

    t.reset();
    state = t.inspectExpedition();
    check(state.region.current === 'ruins' && state.region.discovered.length === 1, 'restart did not reset region discovery');
    check(state.director.phase === 'REST' && !state.director.active && state.director.totalSpawned === 0, 'restart did not reset the director');
    check(state.records.encounters.length === 0, 'restart retained encounter records');

    return JSON.stringify({
      passed: failures.length === 0,
      failures,
      visited,
      encounter: record,
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
