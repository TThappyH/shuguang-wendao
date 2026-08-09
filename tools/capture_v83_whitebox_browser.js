async (page) => {
  const output = 'E:/shuguang-wendao-v68/output';
  await page.goto('http://127.0.0.1:8000/index.html?test=v83-visual');
  await page.waitForFunction(() => window.__V83_TEST__ && window.__V83_TEST__.game.qingyaoModel?.status === 'ready');
  await page.evaluate(() => window.__V83_TEST__.reset());
  const views = [
    ['center', 0, 2],
    ['bamboo-blockout', 28, 11],
    ['marsh-blockout', -28, 10],
    ['sword-blockout', 0, -25],
    ['ember-blockout', 0, 24],
  ];
  const captured = [];
  for (const [name, x, z] of views) {
    await page.evaluate(([px, pz]) => window.__V83_TEST__.place(px, pz), [x, z]);
    await page.waitForTimeout(450);
    const path = `${output}/v83-${name}.png`;
    await page.screenshot({path});
    captured.push(path);
  }
  return JSON.stringify({passed: true, captured});
}
