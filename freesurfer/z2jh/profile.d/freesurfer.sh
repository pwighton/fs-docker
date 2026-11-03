# FreeSurfer environment for each user's shells (sourced from /etc/bash.bashrc)
source "$FREESURFER_HOME/SetUpFreeSurfer.sh"
mkdir -p "$SUBJECTS_DIR"
[ -f "$FS_LICENSE" ] || echo "WARNING: FreeSurfer license not found at $FS_LICENSE — is the shared volume mounted?" >&2

# GPU nodes: the freeview wrapper in /opt/fs-z2jh/bin routes FreeView through
# VirtualGL (llvmpipe otherwise). It must come before $FREESURFER_HOME/bin, so
# drop any earlier copy (nested shells re-prepend FreeSurfer's bin) and re-add.
_path=":$PATH:"
_path="${_path//:\/opt\/fs-z2jh\/bin:/:}"
_path="${_path#:}"
export PATH="/opt/fs-z2jh/bin:${_path%:}"
unset _path

# Each user gets a private copy of the shared tutorial data, made once in the
# background (normally started with the Jupyter server; this is a fallback).
# Until it's done, say where it stands.
if [ ! -e "$HOME/.fs-tutorial-data.done" ]; then
  fs-tutorial-data setup --auto --background
  fs-tutorial-data status --short
fi
