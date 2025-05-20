#!/usr/bin/env bash
set -euo pipefail

# 1. Variables — adjust these
WORKDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"   # the directory this script lives in
REMOTE_REPO="git@github.com:thivesNext/FlowiseForkNexstream.git"
BRANCH="main"

# 2. Clone or update the repository
if [ -d "${WORKDIR}/.git" ]; then
  cd "${WORKDIR}"
  git fetch origin "${BRANCH}"
  git reset --hard "origin/${BRANCH}"
else
  git clone -b "${BRANCH}" "${REMOTE_REPO}" "${WORKDIR}"
  cd "${WORKDIR}"
fi

# 3. Restore Flowise data snapshot (if present)
SNAPSHOT_FILE=$(ls -1t flowise_data_*.tar.gz 2>/dev/null | head -n1 || true)
if [ -n "${SNAPSHOT_FILE}" ]; then
  echo "Found data snapshot: ${SNAPSHOT_FILE}"
  echo "Purging old ~/.flowise directory..."
  rm -rf ~/.flowise
  echo "Extracting ${SNAPSHOT_FILE} to ~/.flowise..."
  tar xzf "${SNAPSHOT_FILE}" -C "$HOME"
  echo "Data restored."
else
  echo "No snapshot file found (pattern flowise_data_*.tar.gz); skipping data restore."
fi

# 4. Recreate containers with any updated compose or code
echo "Tearing down existing containers..."
docker compose down
echo "Bringing up containers..."
docker compose up -d

echo "Import complete. Flowise should now be running with restored data."
