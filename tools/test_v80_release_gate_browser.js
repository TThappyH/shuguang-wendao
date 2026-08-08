async (page) => {
  const consoleErrors = [];
  page.on('console', message => { if (message.type() === 'error') consoleErrors.push(message.text()); });
  page.on('pageerror', error => consoleErrors.push(String(error)));
  await page.goto('__TEST_URL__');
  await page.waitForFunction(() => window.__V68_TEST__?.game?.qingyaoModel?.status === 'ready', null, {timeout: 45000});
  return await page.evaluate(async (consoleErrors) => {
    const t = window.__V68_TEST__;
    const g = t.game;
    const failures = [];
    const check = (condition, message) => { if (!condition) failures.push(message); };
    const chooseFirstBreakthrough = () => {
      const card = document.querySelector('#breakthroughCards .breakthrough-choice');
      check(!!card, 'breakthrough choice card is missing');
      card?.click();
    };
    const wait = ms => new Promise(resolve => setTimeout(resolve, ms));

    t.reset();
    check(g.phase === 'PLAY', 'reset did not enter PLAY');
    check(g.qingyaoModel.status === 'ready', 'Qingyao GLB is not ready');
    check(g.player.visual.visible === false && g.player.externalModelRoot.visible === true, 'old Qingyao GLB is not the active visual');
    check(Object.keys(g.resonance.tiers).length === 6, 'six resonance paths are not registered');
    check(typeof g.exportRunRecord === 'function', 'run record export is not available');

    const beforeMove = {x: g.player.x, z: g.player.z};
    g.keys.add('w');
    await wait(220);
    g.keys.delete('w');
    check(Math.hypot(g.player.x - beforeMove.x, g.player.z - beforeMove.z) > .15, 'player movement did not change position');

    g.emitWeaponCast('bolt');
    check(g.player.attackT > 0, 'weapon cast did not enter attack state');
    g.togglePause();
    check(g.phase === 'PAUSE', 'pause did not stop the run');
    g.togglePause();
    check(g.phase === 'PLAY', 'resume did not restore the run');
    g.toggleTreasureBook();
    check(g.phase === 'CODEX', 'treasure book did not open');
    check(document.querySelectorAll('#resonanceBook .res-book-chip').length === 6, 'treasure book does not show six paths');
    g.toggleTreasureBook(false);
    check(g.phase === 'PLAY', 'treasure book did not close');

    g.player.xp = g.player.xpNeed - 1;
    g.addXP(1);
    check(g.phase === 'LEVEL', 'real XP threshold did not open level-up modal');
    check(g.runRecord.levelUps === 1, 'level-up was not recorded');
    g.takeChoice({kind: 'passive', id: 'might'}, 1);
    check(g.phase === 'PLAY' && g.runRecord.levelChoices.length > 0, 'level choice did not return to play or record');
    g.hurt(8);
    check(g.runRecord.damageTaken > 0, 'damage taken was not recorded');

    const realmSnapshots = [];
    for (let bossIndex = 0; bossIndex < 5; bossIndex++) {
      g.elapsed = (bossIndex + 1) * 60;
      const spawned = t.spawnBossForTest(bossIndex);
      const enemy = g.enemies.find(e => e.id === spawned.id);
      g.hitEnemy(enemy, 10, 0xffffff, 'gate');
      g.kill(enemy, true, 'gate');
      check(g.phase === 'BREAKTHROUGH', `boss ${bossIndex} did not open breakthrough`);
      chooseFirstBreakthrough();
      check(g.phase === 'CHEST' && g.modalState.active?.type === 'BOSS_REWARD', `boss ${bossIndex} reward modal missing`);
      g.closeModal('BOSS_REWARD');
      check(g.phase === 'PLAY', `boss ${bossIndex} reward did not return to play`);
      realmSnapshots.push({bossIndex, realm: g.realmState.currentRealm, rules: g.realmState.activeRealmRules.length});
      g.updateEnemies(.016);
    }

    g.elapsed = 360;
    const finalBoss = t.spawnBossForTest(5);
    const finalEnemy = g.enemies.find(e => e.id === finalBoss.id);
    g.hitEnemy(finalEnemy, 10, 0xffffff, 'gate');
    g.kill(finalEnemy, true, 'gate');
    check(g.phase === 'CHEST' && g.modalState.active?.type === 'BOSS_REWARD', 'final boss reward modal missing');
    g.closeModal('BOSS_REWARD');
    check(g.phase === 'RUN_COMPLETE', 'final boss reward did not open complete-run settlement');
    check(document.querySelector('#runComplete')?.classList.contains('show'), 'complete-run settlement overlay is hidden');
    check(g.runRecord.status === 'BOSS_CLEARED', 'run record is not BOSS_CLEARED');
    check(g.runRecord.bosses.length === 6, 'run record does not contain six bosses');
    check(g.runRecord.bosses.every(b => b.defeatedAt !== null), 'not all six bosses have defeat timestamps');
    check(g.realmState.breakthroughCount === 5, 'full run did not complete five realm breakthroughs');
    check(g.realmState.activeRealmRules.length === 5, 'full run did not retain five realm choices');
    check(g.runRecord.damageDealt > 0 && g.runRecord.damageTaken > 0, 'full run damage ledger is incomplete');

    g.closeModal('RUN_COMPLETE');
    check(g.phase === 'MENU', 'closing settlement did not return to menu');
    check(consoleErrors.length === 0, `browser console errors: ${consoleErrors.join(' | ')}`);
    return JSON.stringify({
      passed: failures.length === 0,
      failures,
      consoleErrors,
      realmSnapshots,
      runRecord: g.runRecord,
      final: {phase: g.phase, realm: g.realmState.currentRealm, rules: g.realmState.activeRealmRules.length}
    });
  }, consoleErrors);
}
