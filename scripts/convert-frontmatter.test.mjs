import test from 'node:test';
import assert from 'node:assert/strict';
import { mkdtempSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { spawnSync } from 'node:child_process';

const scriptPath = new URL('./convert-frontmatter.mjs', import.meta.url).pathname;

function createBlogDir() {
  const dir = mkdtempSync(join(tmpdir(), 'convert-frontmatter-'));
  const blogDir = join(dir, 'blog');
  mkdirSync(blogDir);
  return blogDir;
}

function runScript(blogDir, args = []) {
  return spawnSync(process.execPath, [scriptPath, ...args], {
    env: { ...process.env, BLOG_TARGET_DIR: blogDir },
    encoding: 'utf-8',
  });
}

test('warns when the body starts with an H1 matching the frontmatter title', () => {
  const blogDir = createBlogDir();
  writeFileSync(join(blogDir, 'post.md'), [
    '---',
    'title: Search as Code',
    'pubDate: 2026-06-11',
    'description: Test description',
    '---',
    '',
    '# Search as Code',
    '',
    'Body text.',
    '',
  ].join('\n'));

  const result = runScript(blogDir, ['--dry-run']);

  assert.equal(result.status, 0);
  assert.match(result.stderr, /⚠️  Content warnings:/);
  assert.match(result.stderr, /post\.md: body starts with duplicate H1 matching frontmatter title/);
});

test('removes duplicate leading H1 when --fix-duplicate-h1 is passed', () => {
  const blogDir = createBlogDir();
  const filePath = join(blogDir, 'post.md');
  writeFileSync(filePath, [
    '---',
    'title: Search as Code',
    'pubDate: 2026-06-11',
    'description: Test description',
    '---',
    '',
    '# Search as Code',
    '',
    'Body text.',
    '',
  ].join('\n'));

  const result = runScript(blogDir, ['--fix-duplicate-h1']);

  assert.equal(result.status, 0);
  const updated = readFileSync(filePath, 'utf-8');
  assert.doesNotMatch(updated, /^# Search as Code$/m);
  assert.match(updated, /Body text\./);
});
