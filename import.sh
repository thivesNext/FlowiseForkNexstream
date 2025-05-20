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



# 3. Stop containers before restoring data
COMPOSE_DIR="${WORKDIR}/docker"                                   # where your compose file lives
COMPOSE_FILE="docker-compose.yml"
echo "Tearing down existing containers (using ${COMPOSE_DIR}/${COMPOSE_FILE})..."
cd "${COMPOSE_DIR}"
docker-compose down
cd "${WORKDIR}"

# 4. Restore Flowise data snapshot (if present)
SNAPSHOT_FILE="flowise_data_latest.tar.gz"
if [ -f "${SNAPSHOT_FILE}" ]; then
  echo "Found data snapshot: ${SNAPSHOT_FILE}"
  echo "Purging old ~/.flowise directory..."
  rm -rf ~/.flowise
  echo "Extracting ${SNAPSHOT_FILE} to ~/.flowise..."
  tar xzf "${SNAPSHOT_FILE}" -C "$HOME"
  echo "Data restored."
else
  echo "No snapshot file found (${SNAPSHOT_FILE}); skipping data restore."
fi

# 5. Restore Postgres Docker volume (if present)
PG_SNAPSHOT_FILE="pgdata_latest.tar.gz"
if [ -f "${PG_SNAPSHOT_FILE}" ]; then
  echo "Found Postgres data snapshot: ${PG_SNAPSHOT_FILE}"
  echo "Restoring to Docker volume 'pgdata'..."
  docker volume create pgdata >/dev/null 2>&1 || true
  docker run --rm -v pgdata:/volume -v "${WORKDIR}":/backup alpine \
    sh -c "rm -rf /volume/* && tar xzf /backup/${PG_SNAPSHOT_FILE} -C /volume"
  echo "Postgres data restored."
  echo "Listing contents of pgdata volume after restore:"
  docker run --rm -v pgdata:/volume alpine ls -l /volume
else
  echo "No Postgres snapshot file found (${PG_SNAPSHOT_FILE}); skipping Postgres data restore."
fi

# 6. Start containers again
cd "${COMPOSE_DIR}"
echo "Bringing up containers..."
docker-compose up -d

echo "Import complete. Flowise should now be running (compose file: ${COMPOSE_DIR}/${COMPOSE_FILE})."
