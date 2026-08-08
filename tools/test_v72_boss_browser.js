async (page) => {
  await page.goto('__TEST_URL__');
  await page.waitForFunction(() => window.__V68_TEST__ && window.__V68_TEST__.game);
  return await page.evaluate(() => {
    const t = window.__V68_TEST__;
    const failures = [];
    const check = (condition, message) => { if (!condition) failures.push(message); };

    t.reset();
    const samples = [];
    for (let index = 0; index < 6; index++) {
      const boss = t.spawnBossForTest(index);
      const phase1 = t.sampleBossPhase(boss.id, .80);
      const phase2 = t.sampleBossPhase(boss.id, .50);
      const phase3 = t.sampleBossPhase(boss.id, .20);
      const phase3Repeat = t.sampleBossPhase(boss.id, .20);
      samples.push({index, boss, phase1, phase2, phase3, phase3Repeat});
      check(phase1?.phase === 1, `${boss.name} did not start in phase 1`);
      check(phase2?.phase === 2, `${boss.name} did not enter phase 2`);
      check(phase3?.phase === 3, `${boss.name} did not enter true-body phase`);
      check(JSON.stringify(phase3?.phaseTransitions) === JSON.stringify([2, 3]), `${boss.name} phase transitions are not [2,3]`);
      check(JSON.stringify(phase3Repeat?.phaseTransitions) === JSON.stringify([2, 3]), `${boss.name} repeated a phase transition`);
      check(Number.isFinite(phase3?.scale) && phase3.scale > 1, `${boss.name} true-body scale pulse is missing`);
    }

    const inspected = t.inspect();
    check(inspected.bosses.length === 6, 'six-boss phase sample did not retain all boss entities');
    check(inspected.bosses.every(b => b.phase === 3 && b.lastPhase === 3), 'inspect did not expose final boss phase state');

    t.reset();
    check(t.inspect().bosses.length === 0, 'restart did not clear boss entities');
    return JSON.stringify({passed: failures.length === 0, failures, samples, final: t.inspect()});
  });
}
