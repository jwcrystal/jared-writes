# Jared Writes

Personal blog built with [Astro](https://astro.build). Deployed on GitHub Pages.

Tech notes, reading reflections, and ideas.

## Commands

| Command | Action |
|---|---|
| `npm run dev` | Start dev server at `localhost:4321` |
| `npm run build` | Build to `./dist/` |
| `npm run preview` | Preview production build locally |
| `npm run publish:blog` | Sync ready Obsidian posts, build, commit, and push |
| `npm run publish:blog:archive` | Publish and move source posts from `Ready/` to `Published/` after push |
| `npm run publish:blog:dry` | Preview which posts would sync without changing files |

## Workflow

1. Write publish-ready `.md` or `.mdx` files in Obsidian:
   `~/Library/Mobile Documents/iCloud~md~obsidian/Documents/Obsidian Vault/30-Publish/Ready/`
2. Run `npm run publish:blog:dry` to preview incremental sync changes.
3. Run `npm run publish:blog` to sync, build, commit, and push.
   - Use `npm run publish:blog:archive` to also move successfully published source posts from `Ready/` to `Published/`.
4. `git push` triggers GitHub Actions to deploy automatically.

Required frontmatter for each post:

```yaml
---
title: Post title
description: Short description
pubDate: 2026-06-10
tags: [writing, notes]
---
```

The publish script uses `rsync` incremental copy. It syncs new and changed Markdown files, but intentionally does not delete target files when a source file is removed. Archive mode only runs after a successful commit and push.

## Structure

```
src/
├── content/blog/   ← your posts go here
├── layouts/        ← page templates
├── components/     ← reusable UI
└── pages/          ← routes (index, about, etc.)
```
