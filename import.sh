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


# 3. Only update code and restart containers, do not import any volumes or data
COMPOSE_DIR="${WORKDIR}/docker"                                   # where your compose file lives
COMPOSE_FILE="docker-compose.yml"
echo "Tearing down existing containers (using ${COMPOSE_DIR}/${COMPOSE_FILE})..."
cd "${COMPOSE_DIR}"
docker-compose down

echo "Bringing up containers..."
docker-compose up -d

echo "Import complete. Flowise should now be running (compose file: ${COMPOSE_DIR}/${COMPOSE_FILE})."
