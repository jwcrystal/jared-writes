import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { spawnSync } from 'node:child_process';

const scriptPath = new URL('./publish-blog.sh', import.meta.url).pathname;

test('help documents --fix-duplicate-h1', () => {
  const result = spawnSync('bash', [scriptPath, '--help'], { encoding: 'utf-8' });

  assert.equal(result.status, 0);
  assert.match(result.stdout, /--fix-duplicate-h1/);
});

test('publish script forwards --fix-duplicate-h1 to convert-frontmatter', () => {
  const script = readFileSync(scriptPath, 'utf-8');

  assert.match(script, /CONVERT_ARGS=\(/);
  assert.match(script, /FIX_DUPLICATE_H1/);
  assert.match(script, /--fix-duplicate-h1/);
  assert.match(script, /node scripts\/convert-frontmatter\.mjs "\$\{CONVERT_ARGS\[@\]\}"/);
});
