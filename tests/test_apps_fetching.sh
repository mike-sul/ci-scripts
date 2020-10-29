#!/usr/bin/env bash
# Copyright (c) 2020 Foundries.io
# SPDX-License-Identifier: Apache-2.0
set -euo pipefail

# examples
# sudo ./tests/test_apps_fetching.sh $FACTORY $OSF_TOKEN ./targets.json $PRELOAD_DIR $OUT_ARCHIVE_DIR app-07

# Input params
FACTORY=$1
OSF_TOKEN=$2
TARGET_FILE=$3
PRELOAD_DIR=$4
OUT_STORE_DIR=$5
APP_SHORTLIST="${6-""}"
GRAPH_DRIVER="${7-""}"

SHORTLIST=""
if [ "${APP_SHORTLIST}" ]; then
  SHORTLIST="--app-shortlist ${APP_SHORTLIST}"
fi

GRAPHDRIVER=""
if [ "${GRAPH_DRIVER}" ]; then
  GRAPHDRIVER="--graphdriver ${GRAPH_DRIVER}"
fi

CMD="/usr/local/bin/dind ./apps/fetch.py \
  --factory ${FACTORY} \
  --targets ${TARGET_FILE} \
  --token ${OSF_TOKEN} \
  --preload-dir /preload \
  --out-images-root-dir /out-store-dir \
  ${SHORTLIST} ${GRAPHDRIVER}"

docker run -v -it --rm --privileged \
  -e PYTHONPATH=/ci-scripts \
  -v "${PWD}":/ci-scripts \
  -v "${PRELOAD_DIR}":/preload \
  -v "${OUT_STORE_DIR}":/out-store-dir \
  -w /ci-scripts \
  -u "$(id -u ${USER})":"$(id -g ${USER})" \
  foundries/lmp-image-tools ${CMD}
