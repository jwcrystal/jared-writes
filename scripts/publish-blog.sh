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

usage() {
  cat <<'EOF'
Usage: scripts/publish-blog.sh [options]

Incrementally publish Markdown posts from Obsidian to the Astro blog.

Options:
  --dry-run        Show what would be copied, without writing files or pushing
  --no-push        Commit changes locally but do not push to GitHub
  --archive        Move published source posts from Ready to Published after push
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

if [[ "$ARCHIVE" == true && "$PUSH" == false ]]; then
  echo "--archive requires push to complete; remove --no-push or omit --archive." >&2
  exit 1
fi

if [[ ! -d "$SOURCE_DIR" ]]; then
  echo "Source folder does not exist: $SOURCE_DIR" >&2
  exit 1
fi

if [[ ! -d "$TARGET_DIR" ]]; then
  echo "Target folder does not exist: $TARGET_DIR" >&2
  exit 1
fi

echo "Source: $SOURCE_DIR"
echo "Target: $TARGET_DIR"
if [[ "$ARCHIVE" == true ]]; then
  echo "Archive: $ARCHIVE_DIR"
fi

RSYNC_FLAGS=(-av --itemize-changes)
if [[ "$DRY_RUN" == true ]]; then
  RSYNC_FLAGS+=(-n)
fi

rsync "${RSYNC_FLAGS[@]}" \
  --include='*/' \
  --include='*.md' \
  --include='*.mdx' \
  --exclude='*' \
  "$SOURCE_DIR/" \
  "$TARGET_DIR/"

if [[ "$DRY_RUN" == true ]]; then
  echo "Dry run complete. No files changed."
  exit 0
fi

cd "$REPO_ROOT"

echo "Converting Obsidian frontmatter to Astro schema..."
node scripts/convert-frontmatter.mjs

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

if [[ "$ARCHIVE" == true ]]; then
  echo "Archiving published source posts..."
  mkdir -p "$ARCHIVE_DIR"

  find "$SOURCE_DIR" -type f \( -name '*.md' -o -name '*.mdx' \) -print0 |
    while IFS= read -r -d '' source_file; do
      relative_path="${source_file#"$SOURCE_DIR/"}"
      archive_file="$ARCHIVE_DIR/$relative_path"
      mkdir -p "$(dirname "$archive_file")"
      mv -f "$source_file" "$archive_file"
      echo "Archived: $relative_path"
    done

  # NOTE: intentionally keeping empty subdirectories in SOURCE_DIR
fi

# Recreate SOURCE_DIR if iCloud pruned the empty directory after archiving
if [[ ! -d "$SOURCE_DIR" ]]; then
  mkdir -p "$SOURCE_DIR"
  echo "Recreated empty source folder: $SOURCE_DIR"
fi
