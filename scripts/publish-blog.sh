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

# Step 3: Resolve missing referenced images from Obsidian vault
# Obsidian stores images in vault paths like 20-Knowledge/{topic}/assets/{post}/file.png
# but markdown references them as assets/{post}/file.png (relative to file location)
OBSIDIAN_VAULT="$(dirname "$(dirname "$SOURCE_DIR")")"

if [[ -d "$OBSIDIAN_VAULT" ]]; then
  echo "Resolving missing blog images..."
  while IFS= read -r -d '' md_file; do
    while IFS= read -r match; do
      img_rel=$(echo "$match" | sed 's/.*(\(.*\))/\1/')
      img_decoded=$(python3 -c "import urllib.parse; print(urllib.parse.unquote('$img_rel'))" 2>/dev/null || echo "$img_rel")
      # Skip external URLs
      [[ "$img_decoded" =~ ^https?:// ]] && continue
      md_dir=$(dirname "$md_file")
      expected_path="$md_dir/$img_decoded"
      [[ -f "$expected_path" ]] && continue
      # Search vault for the image by filename
      img_name=$(basename "$img_decoded")
      found=$(find "$OBSIDIAN_VAULT" -name "$img_name" -type f 2>/dev/null | head -1)
      if [[ -n "$found" ]]; then
        if [[ "$DRY_RUN" == true ]]; then
          echo "  [DRY RUN] Would copy image: $img_decoded"
        else
          mkdir -p "$(dirname "$expected_path")"
          cp "$found" "$expected_path"
          echo "  Copied image: $img_decoded"
        fi
      else
        echo "  WARNING: Could not find image in vault: $img_decoded"
      fi
    done < <(grep -Eo '!\[[^]]*\]\([^)]+\)' "$md_file" || true)
  done < <(find "$TARGET_DIR" -name '*.md' -type f -print0)
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
