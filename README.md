# Jared Writes

Personal blog built with [Astro](https://astro.build). Deployed on GitHub Pages.

Tech notes, reading reflections, and ideas.

## Commands

| Command | Action |
|---|---|
| `npm run dev` | Start dev server at `localhost:4321` |
| `npm run build` | Build to `./dist/` |
| `npm run preview` | Preview production build locally |

## Workflow

1. Write `.md` files in `src/content/blog/`
2. `git push` → GitHub Actions builds and deploys automatically

## Structure

```
src/
├── content/blog/   ← your posts go here
├── layouts/        ← page templates
├── components/     ← reusable UI
└── pages/          ← routes (index, about, etc.)
```
