async (page) => {
  await page.goto('__TEST_URL__');
  await page.waitForFunction(() => window.__V68_TEST__ && window.__V68_TEST__.game);
  return await page.evaluate(() => {
    const t = window.__V68_TEST__;
    const g = t.game;
    const failures = [];
    const check = (condition, message) => { if (!condition) failures.push(message); };

    t.reset();
    let s = t.inspect();
    check(s.phase === 'PLAY', 'reset does not enter PLAY');
    check(s.signatureWeapon === null, 'reset retained signature weapon');
    check(s.weapons.bolt.level === 1 && !s.weapons.bolt.evolved, 'reset bolt state is not Lv1');

    t.forceWeaponEvolution('bolt');
    s = t.inspect();
    check(s.weapons.bolt.level === 5 && s.weapons.bolt.evolved, 'bolt did not reach evolved state');
    check(s.signatureWeapon === 'bolt' && s.weapons.bolt.signature, 'first evolution did not claim signature slot');
    check(document.querySelector('#signatureBadge')?.textContent.includes('万星归弦'), 'signature badge did not update');
    check(document.querySelector('[aria-label*="本命法宝"]'), 'weapon bar did not expose signature label');

    const normalDamage = g.dmg(10, {level:5, evolved:false});
    const evolvedDamage = g.dmg(10, {level:5, evolved:true});
    check(evolvedDamage > normalDamage, 'evolved weapon has no active damage behavior');

    t.forceWeaponEvolution('spear');
    s = t.inspect();
    check(s.weapons.spear.level === 5 && s.weapons.spear.evolved, 'second weapon did not evolve');
    check(s.signatureWeapon === 'bolt', 'signature slot was replaced by second evolution');
    check(s.weapons.spear.signature === false, 'second weapon incorrectly claimed signature slot');

    t.reset();
    s = t.inspect();
    check(s.signatureWeapon === null && s.weapons.bolt.level === 1 && !s.weapons.bolt.evolved, 'restart did not clear evolution state');
    check(document.querySelector('#signatureBadge')?.textContent.includes('未定'), 'restart did not clear signature badge');

    return JSON.stringify({
      passed: failures.length === 0,
      failures,
      firstEvolution: {weapon: 'bolt', name: '万星归弦'},
      secondEvolution: {weapon: 'spear', name: '万竹诛仙阵'},
      final: t.inspect()
    });
  });
}
