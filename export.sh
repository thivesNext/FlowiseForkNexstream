#!/usr/bin/env bash
set -euo pipefail

# 1. Variables — adjust these
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"               # project root
REMOTE_REPO="git@github.com:thivesNext/FlowiseForkNexstream.git"
BRANCH="main"

# snapshot name with timestamp
TIMESTAMP="$(date +'%Y%m%d_%H%M%S')"
VOLUME_SNAPSHOT="flowise_data_${TIMESTAMP}.tar.gz"
VOLUME_SRC="${HOME}/.flowise"

# 2. Go to the project folder
cd "${REPO_DIR}"

# 3. Stage code & config changes
git add .

# 4. Commit code changes (no-op if nothing to commit)
git commit -m "Deploy update: ${TIMESTAMP}" || echo "No code changes to commit."

# 5. Push code to remote
if git push "${REMOTE_REPO}" "${BRANCH}"; then
  echo "Code pushed to ${REMOTE_REPO} ${BRANCH}"
else
  echo "Failed to push code. Aborting."
  exit 1
fi

# 6. Always create (or update) the data snapshot
echo "Creating snapshot of ${VOLUME_SRC}..."
# Ensure the snapshot goes into the repo directory
tar czf "${REPO_DIR}/${VOLUME_SNAPSHOT}" -C "${HOME}" ".flowise"

# 7. Stage and commit the new snapshot
cd "${REPO_DIR}"
git add "${VOLUME_SNAPSHOT}"
git commit -m "Add data snapshot: ${VOLUME_SNAPSHOT}" || echo "No changes in data snapshot."

# 8. Push the snapshot
if git push "${REMOTE_REPO}" "${BRANCH}"; then
  echo "Data snapshot pushed: ${VOLUME_SNAPSHOT}"
else
  echo "Failed to push data snapshot."
  exit 1
fi

echo "Export complete."
