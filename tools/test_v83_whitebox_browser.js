async (page) => {
  const pageErrors = [];
  const consoleErrors = [];
  page.on('pageerror', error => pageErrors.push(String(error)));
  page.on('console', message => { if (message.type() === 'error') consoleErrors.push(message.text()); });
  await page.goto('__TEST_URL__');
  await page.waitForFunction(() => window.__V83_TEST__ && window.__V83_TEST__.game.qingyaoModel?.status === 'ready');
  return await page.evaluate(() => {
    const t = window.__V83_TEST__;
    const failures = [];
    const check = (condition, message) => { if (!condition) failures.push(message); };
    const map = t.inspectMap();
    const model = t.inspectModel();

    check(map.mode === 'WHITEBOX' && map.root === 'V83_WHITEBOX_MAP', 'whitebox scene root is missing');
    check(map.rooms.length === 5 && map.links.length === 4, 'room/link graph dimensions are wrong');
    check(map.blocks >= 50 && map.covers >= 20, 'whitebox has insufficient structural blocks');
    check(Object.values(map.legacyWorld).every(value => value === 0), 'legacy decorative world still builds in the active map');

    const adjacency = Object.fromEntries(map.rooms.map(room => [room.id, []]));
    for (const link of map.links) { adjacency[link.a].push(link.b); adjacency[link.b].push(link.a); }
    const visited = new Set(['ruins']);
    const queue = ['ruins'];
    while (queue.length) for (const next of adjacency[queue.shift()]) if (!visited.has(next)) { visited.add(next); queue.push(next); }
    check(visited.size === map.rooms.length, 'critical-path graph is disconnected');

    for (const room of map.rooms) check(t.canStand(room.x, room.z), `room center is not walkable: ${room.id}`);
    check(!t.canStand(43, 43), 'void corner is incorrectly walkable');
    check(!t.canStand(-7, -7), 'center cover has no collision footprint');
    const open = t.nearestOpen(-7, -7);
    check(t.canStand(open.x, open.z), 'nearest-open query did not resolve a valid point');
    check(t.place(28, 11) === true, 'valid arena placement failed');
    check(t.place(43, 43) === false, 'invalid void placement was accepted');

    check(model.status === 'ready', 'Qingyao GLB is not ready');
    check(model.meshes > 0 && model.vertices > 100000 && model.triangles > 200000, 'loaded Qingyao geometry metrics are implausible');
    check(model.legacyVisible === false && model.externalVisible === true, 'legacy character fallback is visible');
    check(model.path.endsWith('qingyao_v1.glb'), 'runtime model path changed');

    t.reset();
    const restarted = t.inspectModel();
    check(restarted.legacyVisible === false && restarted.externalVisible === true, 'restart reverted to legacy character');

    return JSON.stringify({
      passed: failures.length === 0,
      failures,
      map,
      model,
      restarted,
      reachableRooms: [...visited],
      nearestOpen: open,
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
