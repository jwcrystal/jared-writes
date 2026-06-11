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
 * Usage: node scripts/convert-frontmatter.mjs [--dry-run]
 */

import { readFileSync, writeFileSync } from 'node:fs';
import { readdirSync } from 'node:fs';
import { join, extname } from 'node:path';
import matter from 'gray-matter';

const TARGET_DIR = new URL('../src/content/blog', import.meta.url).pathname;
const DRY_RUN = process.argv.includes('--dry-run');

/** Obsidian field → Astro field mapping */
const FIELD_MAP = {
  created: 'pubDate',
  modified: 'updatedDate',
};

/** Fields that must exist after transformation */
const REQUIRED_FIELDS = ['pubDate', 'description'];

function processFile(filePath, errors) {
  const raw = readFileSync(filePath, 'utf-8');
  const parsed = matter(raw);

  if (parsed.isEmpty || !parsed.data) return;

  const fileName = filePath.split('/').pop();

  // Check if created/pubDate exists (before transformation for better error message)
  const hasPubDate = 'pubDate' in parsed.data || 'created' in parsed.data;

  // Transform: created → pubDate, modified → updatedDate
  for (const [obsidianField, astroField] of Object.entries(FIELD_MAP)) {
    if (obsidianField in parsed.data && !(astroField in parsed.data)) {
      parsed.data[astroField] = parsed.data[obsidianField];
      delete parsed.data[obsidianField];
    }
  }

  // Check required fields after transformation
  const missing = REQUIRED_FIELDS.filter((f) => !(f in parsed.data));

  if (missing.length > 0) {
    errors.push(`${fileName}: missing required field(s): ${missing.join(', ')}`);
    return;
  }

  // If pubDate came from created or any field was transformed, write back
  const hasTransformedFields = Object.keys(FIELD_MAP).some(
    (f) => !(f in parsed.data) && (f === 'created' || 'pubDate' in parsed.data),
  );
  // Simpler check: did we delete any Obsidian field?
  const needsRewrite = Object.keys(FIELD_MAP).some(
    (obsidianField) => !(obsidianField in parsed.data) && raw.includes(obsidianField + ':'),
  );

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

  for (const file of files) {
    processFile(join(TARGET_DIR, file), errors);
  }

  if (errors.length > 0) {
    console.error('\n❌ Frontmatter validation failed:');
    for (const err of errors) {
      console.error(`   ${err}`);
    }
    process.exit(1);
  }

  if (DRY_RUN) {
    console.log('\nDry run complete. No files were modified.');
  }

  console.log('\n✓ All files have valid frontmatter.');
}

main();
