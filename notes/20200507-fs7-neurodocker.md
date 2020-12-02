# Docker Containers for FreeSurfer 7

[FreeSurfer 7](https://surfer.nmr.mgh.harvard.edu/fswiki/rel7downloads) docker containers.  Created using [neurodocker](https://github.com/ReproNim/neurodocker).  Big thanks to @kaczmarj and @satra for their [guidance](https://github.com/ReproNim/neurodocker/issues/333) and for making such an amazing tool!

This documents how the following containers were created using [this fork](https://github.com/pwighton/neurodocker/tree/20200430-fs7) of neurodocker.
- `pwighton/freesurfer:7.0.0` (6.21GB)
  - Installs FS7 tarball.  Most of FS7 should work, but [Matlab MCR](https://www.mathworks.com/products/compiler/matlab-runtime.html) is not in the container.
- `pwighton/freesurfer:7.0.0-mcr` (7.76GB)
  - Installs FS7 tarball and Matlab MCR 2014b
- `pwighton/freesurfer:7.0.0-min` (1.33GB)
  - Installs FS7, but then removes every file from the container that is not used during `recon-all`
- `pwighton/freesurfer:7.0.0-min-mcr` (2.93GB)
  - Installs FS7, but then removes every file from the container that is not used during
    - `recon-all`
    - `segmentBS.sh` 
    - `segmentHA_T2.sh`

## `freesurfer:7.0.0` 
```
neurodocker generate docker \
  --base continuumio/miniconda:4.7.12 \
  --pkg-manager apt \
  --freesurfer version=7.0.0 \
    | docker build -t pwighton/freesurfer:7.0.0 -
```

## `freesurfer:7.0.0-mcr`
```
neurodocker generate docker \
  --base continuumio/miniconda:4.7.12 \
  --pkg-manager apt \
  --freesurfer version=7.0.0 \
  --matlabmcr version=2014b install_path=/opt/MCRv84 \
  --run "ln -s /opt/MCRv84/v84 /opt/freesurfer-7.0.0/MCRv84" \
    | docker build -t pwighton/freesurfer:7.0.0-mcr -
```

## `freesurfer:7.0.0-min` 
Grab ref data:
```
rsync -aL psydata.ovgu.de::studyforrest/structural/sub-01 \
  /home/paul/cmet/data/studyforrest-data-structural
```

Create a subjects dir:
```
mkdir -p /tmp/fs-subs
```

Generate the `freesurfer:7.0.0` container, then invoke it:
```
docker run --rm -it --security-opt seccomp:unconfined \
  -v /home/paul/cmet/data/studyforrest-data-structural:/data \
  -v /tmp/fs-subs:/fsdata \
  -v /home/paul/cmet/license.txt:/license.txt \
  -e FS_LICENSE='/license.txt' \
  -e SUBJECTS_DIR='/fsdata' \
  --name fs7 \
  pwighton/freesurfer:7.0.0 \
    /bin/bash
```

In another terminal, trace the following commands:
```
cmd1="recon-all -s sub-01 -all -i /data/sub-01/anat/sub-01_T1w.nii.gz -T2 /data/sub-01/anat/sub-01_T2w.nii.gz -T2pial"
cmd2="asegstats2table --subjects sub-01 --segno 11 17 18 --meas mean --tablefile aseg.mean-intensity.table"
cmd3="aparcstats2table --hemi lh --subjects sub-01 --tablefile lh.aparc.area.table"
```

With `neurodocker-minify`
```
neurodocker-minify --container fs7 \
  --dirs-to-prune /opt/freesurfer-7.0.0 \
  --commands "$cmd1" "$cmd2" "$cmd3"
```

Enter 'y' when prompted and tag resulting container as `freesurfer:7.0.0-min`

## `freesurfer:7.0.0-min-mcr`
Grab ref data:
```
rsync -aL psydata.ovgu.de::studyforrest/structural/sub-01 \
  /home/paul/cmet/data/studyforrest-data-structural
```

Create a subjects dir:
```
mkdir -p /tmp/fs-subs
```

Generate the `freesurfer:7.0.0-mcr` container, then invoke it:
```
docker run --rm -it --security-opt seccomp:unconfined \
  -v /home/paul/cmet/data/studyforrest-data-structural:/data \
  -v /tmp/fs-subs:/fsdata \
  -v /home/paul/cmet/license.txt:/license.txt \
  -e FS_LICENSE='/license.txt' \
  -e SUBJECTS_DIR='/fsdata' \
  --name fs7 \
  pwighton/freesurfer:7.0.0-mcr \
    /bin/bash
```

In another terminal, trace the following commands:
```
cmd1="recon-all -s sub-01 -all -i /data/sub-01/anat/sub-01_T1w.nii.gz -T2 /data/sub-01/anat/sub-01_T2w.nii.gz -T2pial"
cmd2="segmentBS.sh sub-01"
cmd3="segmentHA_T2.sh sub-01 /data/sub-01/anat/sub-01_T2w.nii.gz t2 1"
cmd4="asegstats2table --subjects sub-01 --segno 11 17 18 --meas mean --tablefile aseg.mean-intensity.table"
cmd5="aparcstats2table --hemi lh --subjects sub-01 --tablefile lh.aparc.area.table"
```

With `neurodocker-minify`:
```
neurodocker-minify --container fs7 \
  --dirs-to-prune /opt/freesurfer-7.0.0 \
  --commands "$cmd1" "$cmd2" "$cmd3" "$cmd4" "$cmd5" 
```

Enter 'y' when prompted and tag resulting container as `freesurfer:7.0.0-min-mcr`

