#!/bin/bash
# apply-and-repack.sh
# Re-apply the local UI patches after `hermes update` resets the checkout,
# run the sidebar tests, and repack the desktop app.
#
# Usage: scripts/apply-and-repack.sh
# Override the repo location with: HERMES_REPO=/path/to/hermes-agent scripts/apply-and-repack.sh
set -e

REPO="${HERMES_REPO:-$HOME/.hermes/hermes-agent}"
DESKTOP="$REPO/apps/desktop"
PATCH_DIR="$(cd "$(dirname "$0")/.." && pwd)/patches"

cd "$REPO"

for patch in "$PATCH_DIR"/*.patch; do
  subject=$(grep -m1 '^Subject:' "$patch" | sed 's/^Subject: \[PATCH[^]]*\] //')
  # Reverse-apply check: succeeds only when the patch content is already in the tree.
  if git apply --reverse --check "$patch" 2>/dev/null; then
    echo "✓ already applied, skipping: $subject"
  else
    echo "→ applying: $subject"
    git am --3way "$patch" || {
      git am --abort 2>/dev/null || true
      echo ""
      echo "❌ Patch conflict — upstream changed the same lines. Resolve manually, do not force it."
      exit 1
    }
  fi
done

echo "→ running sidebar tests..."
if [ -x "$REPO/node_modules/.bin/vitest" ]; then
  (cd "$DESKTOP" && "$REPO/node_modules/.bin/vitest" run --project ui src/app/chat/sidebar/ | tail -4)
else
  echo "  (node_modules missing — skipping tests; run npm install in the repo first)"
fi

echo "→ packing the desktop app (~2 min, the app may stay open)..."
(cd "$DESKTOP" && npm run pack > /dev/null 2>&1)

echo ""
echo "✅ Done. Quit Hermes (⌘Q) and relaunch — changes load on restart."
