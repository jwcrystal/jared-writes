#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

DEFAULT_SOURCE="$HOME/Library/Mobile Documents/iCloud~md~obsidian/Documents/Obsidian Vault/30-Publish/Ready"
DEFAULT_ARCHIVE="$HOME/Library/Mobile Documents/iCloud~md~obsidian/Documents/Obsidian Vault/30-Publish/Published"
SOURCE_DIR="${OBSIDIAN_PUBLISH_DIR:-$DEFAULT_SOURCE}"
ARCHIVE_DIR="${OBSIDIAN_ARCHIVE_DIR:-$DEFAULT_ARCHIVE}"
TARGET_DIR="$REPO_ROOT/src/content/blog"
COMMIT_MESSAGE="publish: update blog posts"
DRY_RUN=false
PUSH=true
ARCHIVE=false
FIX_DUPLICATE_H1=false

usage() {
  cat <<'EOF'
Usage: scripts/publish-blog.sh [options]

Incrementally publish Markdown posts from Obsidian to the Astro blog.

Options:
  --dry-run        Show what would be copied, without writing files or pushing
  --no-push        Commit changes locally but do not push to GitHub
  --archive        Move published source posts from Ready to Published before sync
  --fix-duplicate-h1
                   Remove a leading H1 when it duplicates frontmatter title
  -m, --message    Commit message (default: "publish: update blog posts")
  -h, --help       Show this help

Environment:
  OBSIDIAN_PUBLISH_DIR  Override the source folder
  OBSIDIAN_ARCHIVE_DIR  Override the archive folder
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --no-push)
      PUSH=false
      shift
      ;;
    --archive)
      ARCHIVE=true
      shift
      ;;
    --fix-duplicate-h1)
      FIX_DUPLICATE_H1=true
      shift
      ;;
    -m|--message)
      if [[ $# -lt 2 ]]; then
        echo "Missing value for $1" >&2
        exit 1
      fi
      COMMIT_MESSAGE="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage
      exit 1
      ;;
  esac
done

# Archive now happens before sync, so it's independent of --no-push

if [[ ! -d "$SOURCE_DIR" ]]; then
  mkdir -p "$SOURCE_DIR"
  echo "Created empty source folder: $SOURCE_DIR"
fi

if [[ ! -d "$TARGET_DIR" ]]; then
  echo "Target folder does not exist: $TARGET_DIR" >&2
  exit 1
fi

RSYNC_FLAGS=(-av --itemize-changes)
[[ "$DRY_RUN" == true ]] && RSYNC_FLAGS+=(-n)

# Step 1: Consolidate Ready → Published (single source for blog sync)
if [[ "$ARCHIVE" == true ]]; then
  echo "Archiving source posts..."
  mkdir -p "$ARCHIVE_DIR"
  if [[ "$DRY_RUN" != true ]]; then
    find "$SOURCE_DIR" -type f \( -name '*.md' -o -name '*.mdx' \) -print0 |
      while IFS= read -r -d '' source_file; do
        relative_path="${source_file#"$SOURCE_DIR/"}"
        archive_file="$ARCHIVE_DIR/$relative_path"
        mkdir -p "$(dirname "$archive_file")"
        mv -f "$source_file" "$archive_file"
        echo "  Archived: $relative_path"
      done
  else
    echo "  [DRY RUN] Would move files from Ready to Published"
  fi
else
  echo "Copying Ready → Published..."
  rsync "${RSYNC_FLAGS[@]}" \
    --include='*/' \
    --include='*.md' --include='*.mdx' \
    --include='*.png' --include='*.jpg' --include='*.jpeg' \
    --include='*.gif' --include='*.svg' --include='*.webp' --include='*.avif' \
    --exclude='*' \
    "$SOURCE_DIR/" "$ARCHIVE_DIR/"
fi

# Step 2: Sync from Published → blog (single source of truth)
echo "Syncing Published → blog..."
rsync "${RSYNC_FLAGS[@]}" \
  --include='*/' \
  --include='*.md' --include='*.mdx' \
  --include='*.png' --include='*.jpg' --include='*.jpeg' \
  --include='*.gif' --include='*.svg' --include='*.webp' --include='*.avif' \
  --exclude='*' \
  "$ARCHIVE_DIR/" "$TARGET_DIR/"

# Step 3: Normalize all blog images to src/content/blog/assets/{post-name}/{filename}
# regardless of the relative path in the original Markdown.
# Also rewrites Markdown references to use the canonical path.
OBSIDIAN_VAULT="$(dirname "$(dirname "$SOURCE_DIR")")"

if [[ -d "$OBSIDIAN_VAULT" ]]; then
  echo "Resolving blog images..."
  export TARGET_DIR OBSIDIAN_VAULT DRY_RUN
  python3 -c "
import os, re, urllib.parse, shutil

target_dir = os.environ['TARGET_DIR']
vault = os.environ['OBSIDIAN_VAULT']
dry_run = os.environ.get('DRY_RUN', 'false') == 'true'

for md_file in (f.path for f in os.scandir(target_dir) if f.name.endswith('.md')):
    post_name = os.path.splitext(os.path.basename(md_file))[0]
    assets_dir = os.path.join(target_dir, 'assets', post_name)

    with open(md_file, 'r') as f:
        content = f.read()

    changed = False
    for m in re.finditer(r'!\[([^\]]*)\]\(([^)]+)\)', content):
        img_rel = m.group(2)
        if img_rel.startswith(('http://', 'https://')):
            continue

        img_decoded = urllib.parse.unquote(img_rel)
        img_name = os.path.basename(img_decoded)
        canonical = os.path.join(assets_dir, img_name)
        new_rel = './assets/' + urllib.parse.quote(f'{post_name}/{img_name}')

        # Already uses canonical path — nothing to do
        if img_rel == new_rel:
            continue

        # Check if image file is already at canonical location
        if not os.path.exists(canonical):
            # Search Obsidian vault
            found = None
            for root, dirs, files in os.walk(vault):
                if img_name in files:
                    found = os.path.join(root, img_name)
                    break
            if not found:
                print(f'  WARNING: Could not find image in vault: {img_decoded}')
                continue
            if not dry_run:
                os.makedirs(assets_dir, exist_ok=True)
                shutil.copy2(found, canonical)
            print(f'  Copied: {img_name} → assets/{post_name}/')

        # Rewrite markdown reference to canonical path
        if not dry_run:
            content = content.replace(f'({img_rel})', f'({new_rel})')
            changed = True
        print(f'  Rewrote: {img_rel} → {new_rel}')

    if changed:
        with open(md_file, 'w') as f:
            f.write(content)
"
else
  echo "  Skipped (Obsidian vault not found at $OBSIDIAN_VAULT)"
fi

if [[ "$DRY_RUN" == true ]]; then
  echo "Dry run complete. No files changed."
  exit 0
fi

cd "$REPO_ROOT"

CONVERT_ARGS=()
[[ "$FIX_DUPLICATE_H1" == true ]] && CONVERT_ARGS+=(--fix-duplicate-h1)

echo "Converting Obsidian frontmatter to Astro schema..."
node scripts/convert-frontmatter.mjs "${CONVERT_ARGS[@]}"

echo "Running Astro build check..."
npm run build

if [[ -z "$(git status --short -- src/content/blog)" ]]; then
  echo "No blog post changes to publish."
  exit 0
fi

git add src/content/blog
git commit -m "$COMMIT_MESSAGE"

if [[ "$PUSH" == true ]]; then
  git push
else
  echo "Committed locally. Skipped push because --no-push was set."
fi

# Ensure Ready/ exists for next use (iCloud may prune empty directories)
if [[ ! -d "$SOURCE_DIR" ]]; then
  mkdir -p "$SOURCE_DIR"
  echo "Created empty source folder: $SOURCE_DIR"
fi
