#!/usr/bin/env node

/**
 * Convert Obsidian frontmatter to Astro content schema and validate.
 *
 * Obsidian → Astro mapping:
 *   created    → pubDate  (required)
 *   modified   → updatedDate (optional)
 *
 * Required fields (manual, will block publish if missing):
 *   - description
 *   - pubDate (or created as alias)
 *
 * Usage: node scripts/convert-frontmatter.mjs [--dry-run] [--fix-duplicate-h1]
 */

import { readFileSync, writeFileSync } from 'node:fs';
import { readdirSync } from 'node:fs';
import { join, extname } from 'node:path';
import matter from 'gray-matter';

const TARGET_DIR = process.env.BLOG_TARGET_DIR
  || new URL('../src/content/blog', import.meta.url).pathname;
const DRY_RUN = process.argv.includes('--dry-run');
const FIX_DUPLICATE_H1 = process.argv.includes('--fix-duplicate-h1');

/** Obsidian field → Astro field mapping */
const FIELD_MAP = {
  created: 'pubDate',
  modified: 'updatedDate',
};

/** Fields that must exist after transformation */
const REQUIRED_FIELDS = ['pubDate', 'description'];

function normalizeTitle(value) {
  return String(value)
    .trim()
    .replace(/^#+\s*/, '')
    .replace(/\s+/g, ' ')
    .toLowerCase();
}

function findDuplicateLeadingH1(title, content) {
  if (typeof title !== 'string' || title.trim() === '') return null;

  const lines = content.split('\n');
  const lineIndex = lines.findIndex((line) => line.trim() !== '');
  if (lineIndex === -1) return null;

  const match = lines[lineIndex].match(/^#\s+(.+?)\s*#*\s*$/);
  if (!match) return null;

  const headingTitle = normalizeTitle(match[1]);
  const frontmatterTitle = normalizeTitle(title);

  return headingTitle === frontmatterTitle ? { lineIndex, lines } : null;
}

function removeDuplicateLeadingH1(title, content) {
  const duplicate = findDuplicateLeadingH1(title, content);
  if (!duplicate) return { content, removed: false };

  const lines = [...duplicate.lines];
  lines.splice(duplicate.lineIndex, 1);

  if (lines[duplicate.lineIndex]?.trim() === '') {
    lines.splice(duplicate.lineIndex, 1);
  }

  return { content: lines.join('\n'), removed: true };
}

function processFile(filePath, errors, warnings) {
  const raw = readFileSync(filePath, 'utf-8');
  const parsed = matter(raw);

  if (parsed.isEmpty || !parsed.data) return;

  const fileName = filePath.split('/').pop();

  // Check if created/pubDate exists (before transformation for better error message)
  const hasPubDate = 'pubDate' in parsed.data || 'created' in parsed.data;

  // Transform: created → pubDate, modified → updatedDate
  let needsRewrite = false;
  for (const [obsidianField, astroField] of Object.entries(FIELD_MAP)) {
    if (obsidianField in parsed.data && !(astroField in parsed.data)) {
      parsed.data[astroField] = parsed.data[obsidianField];
      delete parsed.data[obsidianField];
      needsRewrite = true;
    }
  }

  // Check required fields after transformation
  const missing = REQUIRED_FIELDS.filter((f) => !(f in parsed.data));

  if (missing.length > 0) {
    errors.push(`${fileName}: missing required field(s): ${missing.join(', ')}`);
    return;
  }

  if (findDuplicateLeadingH1(parsed.data.title, parsed.content)) {
    warnings.push(`${fileName}: body starts with duplicate H1 matching frontmatter title`);

    if (FIX_DUPLICATE_H1) {
      const result = removeDuplicateLeadingH1(parsed.data.title, parsed.content);
      parsed.content = result.content;
      needsRewrite = needsRewrite || result.removed;
    }
  }

  if (needsRewrite) {
    const output = matter.stringify(parsed.content, parsed.data);

    if (DRY_RUN) {
      console.log(`[DRY RUN] Would update: ${fileName}`);
    } else {
      writeFileSync(filePath, output, 'utf-8');
      console.log(`Updated: ${fileName}`);
    }
  }
}

function main() {
  const files = readdirSync(TARGET_DIR).filter((f) => extname(f).toLowerCase() === '.md');

  if (files.length === 0) {
    console.log('No markdown files found.');
    process.exit(1);
  }

  const errors = [];
  const warnings = [];

  for (const file of files) {
    processFile(join(TARGET_DIR, file), errors, warnings);
  }

  if (errors.length > 0) {
    console.error('\n❌ Frontmatter validation failed:');
    for (const err of errors) {
      console.error(`   ${err}`);
    }
    process.exit(1);
  }

  if (warnings.length > 0) {
    console.warn('\n⚠️  Content warnings:');
    for (const warning of warnings) {
      console.warn(`   ${warning}`);
    }
  }

  if (DRY_RUN) {
    console.log('\nDry run complete. No files were modified.');
  }

  console.log('\n✓ All files have valid frontmatter.');
}

main();
