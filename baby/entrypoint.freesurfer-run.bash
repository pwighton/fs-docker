#!/bin/bash

if [ -n "${FS_KEY}" ]; then
  echo "[entrypoint.bash] -- FS_KEY detected. Creating ${FREESURFER_HOME}/license.txt."
  echo $FS_KEY | base64 -d > ${FREESURFER_HOME}/license.txt
  echo "[entrypoint.bash] -- The file ${FREESURFER_HOME}/license.txt now looks like:"
  cat ${FREESURFER_HOME}/license.txt
  echo "[entrypoint.bash] -- EOF"
else
  echo "[entrypoint.bash] -- No FS_KEY environment variable detected."
  echo "[entrypoint.bash] -- Not creating ${FREESURFER_HOME}/license.txt file."
  echo "[entrypoint.bash] -- Freesurfer probably wont work."
fi

eval "$@"
