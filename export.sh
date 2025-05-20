#!/usr/bin/env bash
set -euo pipefail

# 1. Variables — adjust these
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"               # project root
REMOTE_REPO="git@github.com:thivesNext/FlowiseForkNexstream.git"
BRANCH="main"

# snapshot name with timestamp
TIMESTAMP="$(date +'%Y%m%d_%H%M%S')"

# Fixed snapshot file names
VOLUME_SNAPSHOT="flowise_data_latest.tar.gz"
PGVOLUME_SNAPSHOT="pgdata_latest.tar.gz"
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


# 6. Always create (or update) the data snapshot (Flowise config)
echo "Creating snapshot of ${VOLUME_SRC}..."
tar czf "${REPO_DIR}/${VOLUME_SNAPSHOT}" -C "${HOME}" ".flowise"

# 6b. Create a snapshot of the Postgres Docker volume (overwrite each time)
echo "Creating snapshot of Postgres Docker volume (pgdata)..."
docker run --rm -v pgdata:/volume -v "${REPO_DIR}":/backup alpine \
  sh -c "rm -f /backup/${PGVOLUME_SNAPSHOT} && tar czf /backup/${PGVOLUME_SNAPSHOT} -C /volume ."


# 7. Stage and commit the new snapshots
cd "${REPO_DIR}"
git add "${VOLUME_SNAPSHOT}" "${PGVOLUME_SNAPSHOT}"
git commit -m "Add latest data and pgdata snapshots" || echo "No changes in snapshots."

# 8. Push the snapshot
if git push "${REMOTE_REPO}" "${BRANCH}"; then
  echo "Data snapshot pushed: ${VOLUME_SNAPSHOT}"
else
  echo "Failed to push data snapshot."
  exit 1
fi

echo "Export complete."
