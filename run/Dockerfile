# Dockerfile to run recon-all (from the 'dev' branch of FreeSurfer)
# Based on Ubuntu 16.04.3 LTS (Xenial Xerus)
#
# This environment assumes:
#   - The freesurfer install diretory ($FREESURFER_HOME) is: `/fs-bin`
#   - The freesurfer subject's directory ($SUBJECTS_DIR) is: `/fs-sub`
#
# These must be mounted by the user.

FROM ubuntu:xenial

RUN apt-get update && \
    apt-get install -y \
      bc \
      binutils \
      libgomp1 \
      net-tools \
      perl \
      psmisc \
      sudo \
      tar \
      tcsh \
      unzip \
      uuid-dev \
      vim-common

# Mount point for FreeSurfer binaries (result of compilation)
VOLUME /fs-bin
ENV FREESURFER_HOME=/fs-bin
ENV PATH $FREESURFER_HOME/bin:$PATH

# Mount point for $SUBJECTS_DIR dir
VOLUME /fs-sub
ENV SUBJECTS_DIR /fs-sub

# Add entrypoint script for licence key management
ADD entrypoint.freesurfer-run.bash /usr/local/bin/entrypoint.bash
RUN chmod +rx /usr/local/bin/entrypoint.bash
ENTRYPOINT ["/usr/local/bin/entrypoint.bash"]

# ENV vals from https://surfer.nmr.mgh.harvard.edu/pub/dist/freesurfer/infant/Dockerfile
ENV OS Linux
ENV FREESURFER $FREESURFER_HOME
ENV FS_OVERRIDE 0
ENV PERL5LIB $FREESURFER_HOME/mni/share/perl5
ENV LOCAL_DIR $FREESURFER_HOME/local
ENV FSFAST_HOME $FREESURFER_HOME/fsfast
ENV FMRI_ANALYSIS_DIR $FREESURFER_HOME/fsfast
ENV FSF_OUTPUT_FORMAT nii.gz
ENV MINC_BIN_DIR $FREESURFER_HOME/mni/bin
ENV FUNCTIONALS_DIR $FREESURFER_HOME/sessions
ENV MINC_LIB_DIR $FREESURFER_HOME/mni/lib
ENV MNI_DIR $FREESURFER_HOME/mni
ENV MNI_DATAPATH $FREESURFER_HOME/mni/data
ENV MNI_PERL5LIB $FREESURFER_HOME/mni/share/perl5
ENV FIX_VERTEX_AREA ""
ENV FSLOUTPUTTYPE NIFTI_GZ

## to supress a `Could not set locale` error when `mri_convert` is run in recon-all
ENV FS_DISABLE_LANG 1

## for more POSIX-like behaviour (https://github.com/freesurfer/freesurfer/pull/83) 
# ENV FS_POSIX 1