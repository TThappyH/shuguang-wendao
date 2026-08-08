async (page) => {
  await page.goto('__TEST_URL__');
  await page.waitForFunction(() => window.__V68_TEST__ && window.__V68_TEST__.game);
  return await page.evaluate(() => {
    const t = window.__V68_TEST__;
    const g = t.game;
    const failures = [];
    const check = (condition, message) => { if (!condition) failures.push(message); };
    const state = () => t.inspect();
    const chooseFirst = () => {
      const card = document.querySelector('#breakthroughCards .breakthrough-choice');
      check(!!card, 'breakthrough choice card is missing');
      card?.click();
    };

    t.reset();
    let s = state();
    check(s.phase === 'PLAY', 'reset does not enter PLAY');
    check(s.realmState.currentRealm === 'qi' && s.realmState.currentIndex === 0, 'reset realm is not qi');
    check(s.realmState.activeRealmRules.length === 0, 'reset retained active rules');

    t.triggerBreakthrough(1);
    s = state();
    check(s.phase === 'BREAKTHROUGH' && s.modal.active?.type === 'BREAKTHROUGH', 'breakthrough modal did not pause combat');
    t.queueLevel(); t.queueChest();
    g.togglePause(); g.toggleTreasureBook();
    s = state();
    check(s.phase === 'BREAKTHROUGH', 'pause/codex escaped breakthrough phase');
    check(s.modal.queue.map(x => x.type).join(',') === 'CHEST,LEVEL', 'modal queue priority order is wrong');
    chooseFirst();
    s = state();
    check(s.phase === 'CHEST' && s.modal.active?.type === 'CHEST', 'queued chest did not drain first');
    g.closeModal('CHEST');
    s = state();
    check(s.phase === 'LEVEL' && s.modal.active?.type === 'LEVEL', 'queued level did not drain after chest');
    document.querySelector('#cards .card')?.click();
    s = state();
    check(s.phase === 'PLAY' && s.realmState.currentRealm === 'foundation', 'first breakthrough did not commit');

    for (let index = 2; index < 6; index++) {
      t.triggerBreakthrough(index);
      check(state().phase === 'BREAKTHROUGH', `realm ${index} did not open breakthrough`);
      chooseFirst();
      s = state();
      check(s.phase === 'PLAY' && s.realmState.currentIndex === index, `realm ${index} did not commit`);
    }
    s = state();
    check(s.realmState.breakthroughCount === 5, 'full chain breakthrough count is not five');
    check(new Set(s.realmState.selectedFoundations).size === 5, 'foundation choices are not unique');
    check(s.realmState.activeRealmRules.length === 5, 'active rule count is not five');
    check(Object.values(s.hookCounts).some(count => count > 0), 'active hooks were not rebuilt');

    t.reset();
    for (let bossIndex = 0; bossIndex < 5; bossIndex++) {
      t.simulateBossKill(bossIndex, true);
      check(state().phase === 'BREAKTHROUGH', `boss ${bossIndex} did not gate breakthrough`);
      chooseFirst();
      s = state();
      check(s.realmState.currentIndex === bossIndex + 1, `boss ${bossIndex} advanced wrong realm`);
      check(s.phase === 'CHEST' && s.modal.active?.type === 'BOSS_REWARD', `boss ${bossIndex} reward did not queue after breakthrough`);
      g.closeModal('BOSS_REWARD');
      check(state().phase === 'PLAY', `boss ${bossIndex} reward did not return to PLAY`);
    }

    t.reset();
    const baseline = {scene: g.scene.children.length, geometries: g.renderer.info.memory.geometries};
    for (let i = 0; i < 5; i++) t.reset();
    const afterRestarts = {scene: g.scene.children.length, geometries: g.renderer.info.memory.geometries};
    check(afterRestarts.scene <= baseline.scene + 2, 'restart scene children grew');
    check(afterRestarts.geometries <= baseline.geometries + 2, 'restart geometries grew');

    return JSON.stringify({
      passed: failures.length === 0,
      failures,
      final: state(),
      restart: {baseline, afterRestarts},
      rules: {registry: 15, selected: 5, active: state().realmState.activeRealmRules.length}
    });
  });
}
