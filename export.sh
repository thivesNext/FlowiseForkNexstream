#!/usr/bin/env bash
set -euo pipefail

# 1. Variables — adjust these
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REMOTE_REPO="git@github.com:thivesNext/FlowiseForkNexstream.git"
BRANCH="main"

# 2. Ensure you’re in your project folder
cd "${REPO_DIR}"

# 3. Add any new or changed files (docker-compose, .env, flows, etc.)
git add .

# 4. Commit with a timestamped message
git commit -m "Deploy update: $(date +'%Y-%m-%d %H:%M:%S')"

# 5. Push to remote
git push "${REMOTE_REPO}" "${BRANCH}"
if [ $? -eq 0 ]; then
    echo "Changes pushed to ${REMOTE_REPO} on branch ${BRANCH}."
else
    echo "Failed to push changes. Please check your git configuration."
    exit 1
fi

# 6. Snapshot the Flowise data volume
VOLUME_SNAPSHOT="flowise_data_$(date +'%Y%m%d_%H%M%S').tar.gz"
VOLUME_SRC="$HOME/.flowise"

if [ -d "${VOLUME_SRC}" ]; then
  echo "Archiving Flowise data directory (${VOLUME_SRC}) to ${VOLUME_SNAPSHOT}..."
  tar czf "${VOLUME_SNAPSHOT}" -C "$(dirname "${VOLUME_SRC}")" "$(basename "${VOLUME_SRC}")"
  mv "${VOLUME_SNAPSHOT}" "${REPO_DIR}/"

  # 7. Commit the snapshot tarball
  cd "${REPO_DIR}"
  git add "${VOLUME_SNAPSHOT}"
  git commit -m "Add data snapshot: ${VOLUME_SNAPSHOT}"
  if git push "${REMOTE_REPO}" "${BRANCH}"; then
    echo "Volume snapshot pushed successfully."
  else
    echo "Failed to push volume snapshot. Please check your git configuration."
    exit 1
  fi
else
  echo "Warning: Flowise data directory ${VOLUME_SRC} not found; skipping snapshot."
fi

echo "Export complete."
#chmod +x export_to_git.sh

