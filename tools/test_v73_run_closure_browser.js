async (page) => {
  await page.goto('__TEST_URL__');
  await page.waitForFunction(() => window.__V68_TEST__ && window.__V68_TEST__.game);
  return await page.evaluate(() => {
    const t = window.__V68_TEST__;
    const g = t.game;
    const failures = [];
    const check = (condition, message) => { if (!condition) failures.push(message); };

    t.reset();
    check(g.runRecord.status === 'RUNNING', 'run record did not enter RUNNING');
    t.triggerBreakthrough(1);
    check(g.phase === 'BREAKTHROUGH', 'breakthrough modal did not open');
    check(t.selectChoice('swordbone') === true, 'realm choice was not accepted');
    g.takeChoice({kind: 'passive', id: 'might'}, 1);
    check(g.runRecord.realmChoices.length === 1, 'realm choice was not recorded');
    check(g.runRecord.levelChoices.some(choice => choice.id === 'might'), 'level choice was not recorded');

    const boss = t.spawnBossForTest(5);
    const enemy = g.enemies.find(e => e.id === boss.id);
    g.hitEnemy(enemy, 10, 0xffffff, 'test');
    g.hurt(10);
    g.kill(enemy, true, 'test');
    check(g.runRecord.bosses.length === 1, 'boss spawn was not recorded');
    check(g.runRecord.bosses[0].defeatedAt !== null, 'boss defeat time was not recorded');
    check(g.runRecord.damageDealt > 0, 'damage dealt was not recorded');
    check(g.runRecord.damageTaken > 0, 'damage taken was not recorded');
    check(g.runRecord.status === 'BOSS_CLEARED', 'final boss did not close the run record');
    check(g.modalState.active?.type === 'BOSS_REWARD', 'final boss reward modal did not open');

    g.closeModal('BOSS_REWARD');
    check(g.phase === 'RUN_COMPLETE', 'run completion modal did not open after reward');
    check(document.querySelector('#runComplete')?.classList.contains('show'), 'run completion overlay is hidden');
    check(document.querySelector('#runSummary')?.textContent.includes('完整通关'), 'run summary did not render');

    g.closeModal('RUN_COMPLETE');
    check(g.phase === 'MENU', 'closing run summary did not return to menu');
    return JSON.stringify({passed: failures.length === 0, failures, runRecord: g.runRecord, final: t.inspect()});
  });
}
