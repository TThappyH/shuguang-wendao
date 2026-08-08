async (page) => {
  const output = 'E:/shuguang-wendao-v68/output';
  await page.goto('http://127.0.0.1:8000/index.html?test=v82-visual');
  await page.waitForFunction(() => window.__V82_TEST__ && window.__V82_TEST__.game);
  await page.evaluate(() => window.__V82_TEST__.reset());
  const views = [
    ['01-ruins', 0, 0],
    ['02-bamboo', 25, 0],
    ['03-marsh', -25, 0],
    ['04-sword', 0, -25],
    ['05-ember', 0, 25],
  ];
  const captured = [];
  for (const [name, x, z] of views) {
    await page.evaluate(([px, pz]) => window.__V82_TEST__.setPosition(px, pz), [x, z]);
    await page.waitForTimeout(550);
    const path = `${output}/v82-${name}.png`;
    await page.screenshot({path});
    captured.push(path);
  }
  return JSON.stringify({passed: true, captured});
}
