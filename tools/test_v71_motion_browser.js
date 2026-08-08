async (page) => {
  await page.goto('__TEST_URL__');
  await page.waitForFunction(() => window.__V68_TEST__ && window.__V68_TEST__.game && window.__V68_TEST__.game.qingyaoModel?.status === 'ready');
  return await page.evaluate(() => {
    const t = window.__V68_TEST__;
    const g = t.game;
    const failures = [];
    const check = (condition, message) => { if (!condition) failures.push(message); };
    const finiteTransform = sample => Object.values(sample.scale).every(Number.isFinite) && Object.values(sample.rotation).every(Number.isFinite);

    t.reset();
    check(g.qingyaoModel.status === 'ready', 'Qingyao model is not ready');
    check(g.player.visual.visible === false && g.player.externalModelRoot.visible === true, 'external model replacement visibility is wrong');

    const samples = {};
    for (const kind of ['IDLE', 'MOVE', 'CAST', 'HIT', 'DASH']) {
      samples[kind] = t.sampleMotion(kind);
      check(samples[kind].state === kind, `${kind} motion state did not resolve`);
      check(finiteTransform(samples[kind]), `${kind} transform contains a non-finite value`);
    }
    check(samples.MOVE.rotation.x !== samples.IDLE.rotation.x || samples.MOVE.rotation.z !== samples.IDLE.rotation.z, 'MOVE did not change external model pose');
    check(samples.CAST.scale.y < 1, 'CAST did not create a readable anticipation pose');
    check(samples.HIT.scale.y < 1, 'HIT did not create a readable reaction pose');
    check(samples.DASH.rotation.x < samples.MOVE.rotation.x, 'DASH did not lean the external model forward');

    t.reset();
    check(t.inspect().motionState === 'IDLE', 'restart did not reset motion state');
    return JSON.stringify({passed: failures.length === 0, failures, samples, final: t.inspect()});
  });
}
