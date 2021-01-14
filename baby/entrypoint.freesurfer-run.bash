#!/bin/bash
rm -f $FREESURFER_HOME/python/bin/python3
ln -s `which python` $FREESURFER_HOME/python/bin/python3

ln -s $FS_INFANT_MODEL/sscnn_skullstrip/cor_sscnn.h5 $FREESURFER_HOME/average/sscnn_skullstripping/cor_sscnn.h5
ln -s $FS_INFANT_MODEL/sscnn_skullstrip/ax_sscnn.h5 $FREESURFER_HOME/average/sscnn_skullstripping/ax_sscnn.h5
ln -s $FS_INFANT_MODEL/sscnn_skullstrip/sag_sscnn.h5 $FREESURFER_HOME/average/sscnn_skullstripping/sag_sscnn.h5 

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
