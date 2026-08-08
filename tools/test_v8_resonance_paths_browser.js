async (page) => {
  const consoleErrors = [];
  page.on('console', message => { if (message.type() === 'error') consoleErrors.push(message.text()); });
  page.on('pageerror', error => consoleErrors.push(String(error)));
  await page.goto('__TEST_URL__');
  await page.waitForFunction(() => window.__V68_TEST__?.game?.qingyaoModel?.status === 'ready', null, {timeout: 45000});
  return await page.evaluate((consoleErrors) => {
    const t = window.__V68_TEST__;
    const g = t.game;
    const failures = [];
    const check = (condition, message) => { if (!condition) failures.push(message); };
    const fixtures = [
      {id: 'sword', name: '剑道', members: ['glass', 'crown', 'swordheart', 'moon']},
      {id: 'thunder', name: '雷道', members: ['thunder', 'clock', 'skyeye', 'spiritplate']},
      {id: 'fire', name: '火道', members: ['starfire', 'phoenix', 'rage', 'alchemy']},
      {id: 'array', name: '阵道', members: ['bagua', 'qiankun', 'spiritplate', 'clock']},
      {id: 'spirit', name: '御灵', members: ['spiritgourd', 'blood', 'daoheart', 'soulbell']},
      {id: 'body', name: '炼体', members: ['turtle', 'dragonblood', 'goldenbody', 'lotus']}
    ];
    t.reset();
    check(Object.keys(g.resonance.tiers).length === fixtures.length, 'resonance path registry count is not six');
    const paths = [];
    for (const fixture of fixtures) {
      g.relics = [...fixture.members];
      g.recomputeResonances(false);
      const count = g.resonanceCount(fixture.id);
      const tier = g.resonanceTier(fixture.id);
      check(count === 4 && tier === 4, `${fixture.id} did not reach 4/4 resonance`);
      g.toggleTreasureBook(true);
      const chips = [...document.querySelectorAll('#resonanceBook .res-book-chip')];
      const chip = chips.find(element => element.textContent.includes(fixture.name));
      check(!!chip && /4\/4/.test(chip.textContent), `${fixture.id} book chip does not show 4/4`);
      const hud = [...document.querySelectorAll('#resonanceHud .res-chip')]
        .find(element => element.textContent.includes(fixture.name));
      check(!!hud && /4\/4/.test(hud.textContent), `${fixture.id} HUD chip does not show 4/4`);
      paths.push({id: fixture.id, name: fixture.name, count, tier, book: chip?.textContent.trim() || '', hud: hud?.textContent.trim() || ''});
      g.toggleTreasureBook(false);
      check(g.phase === 'PLAY', `${fixture.id} codex did not return to PLAY`);
    }
    g.relics = [];
    g.recomputeResonances(false);
    check(Object.values(g.resonance.tiers).every(value => value === 0), 'path reset retained resonance tiers');
    check(consoleErrors.length === 0, `browser console errors: ${consoleErrors.join(' | ')}`);
    return JSON.stringify({passed: failures.length === 0, failures, paths, consoleErrors});
  }, consoleErrors);
}
