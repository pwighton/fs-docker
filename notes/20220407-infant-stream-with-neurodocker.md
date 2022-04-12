# Containers for running FreeSurfer's infant pipeline

## Background

FreeSurfer's infant pipeline provides a morphological analysis of human neuroanatomy from MRI scans of subjects that are beween XXX and YYY months old.

The input to the pipeline is an MRI image that has been optimized to maximize the contrast between grey matter, white matter and cerebral spinal fluid (CSF). See [this document](https://www.nmr.mgh.harvard.edu/~andre/FreeSurfer_recommended_morphometry_protocols.pdf) for guidance on how to configure your MRI scanner to generate these images.

The output of the pipeline is ???

In order to increase reproducibilirty and make the pipeline easier to use, we have packaged it into *containers*.

**TODO Insert background on containers**

## Pre-requisites

TODO
- docker
- RAM
- test data

## Generating Containers to run FreeSurfer's infant pipeline

The FreeSurfer codebase comes with a [dockerfile](https://github.com/freesurfer/freesurfer/blob/dev/Dockerfile) which is available on [dockerhub](https://hub.docker.com/) at [`freesurfer/freesurfer`](https://hub.docker.com/r/freesurfer/freesurfer) however this only contains the FreeSurfer distribution and does not include any third-party tools.

The infant pipeline has serveral dependencies, in addition to freesurfer, including:
- [FSL](https://fsl.fmrib.ox.ac.uk/fsl/fslwiki)
- [NiftyReg](http://cmictig.cs.ucl.ac.uk/wiki/index.php/NiftyReg)
- [Tensorflow](https://www.tensorflow.org/) v1.5

One could create a docker container that inherits from the FreeSurfer container and install the required dependencies, or one could use [neurodokcer](https://www.repronim.org/neurodocker/).  Neurodocker is a "command-line program that generates custom Dockerfiles and Singularity recipes for neuroimaging".

[This fork](https://github.com/pwighton/neurodocker/tree/20220328-infant-model-inside-container-take2) of neurodocker includes support for installing FreeSurfer, compiling FreeSurfer from source, and installing the dependencies required by the infant pipeline.  The resulting container for this fork is available at [`pwighton/neurodocker`](https://hub.docker.com/r/pwighton/neurodocker).  It can be invoked to create a container to run the infant pipeline with:

```
docker run pwighton/neurodocker:latest generate docker \
    --base-image ubuntu:xenial \
    --pkg-manager apt \
    --yes \
    --niftyreg \
      version=master \
    --fsl \
      version=5.0.10 \
      method=binaries \
    --freesurfer \
      method=source \
      repo=https://github.com/freesurfer/freesurfer.git \
      branch=dev \
      infant_module=ON \
      dev_tools=ON \
      infant_model_s3=s3://freesurfer-annex/infant/model/dev/ \
      infant_model_s3_region=us-east-2 \
    --entrypoint '/bin/infant-container-entrypoint-aws.bash' \
| docker build --no-cache --network host -t pwighton/fs-infant-dev:nl -
```

This builds a container called `pwighton/fs-infant-dev:nl` that:
  - Compiles and installs freesurfer from source using the reprository `https://github.com/freesurfer/freesurfer.git` and the branch `dev`
  - Configures freesurfer to run the infant stream (`infant_module=ON`)
  - Installs fsl v5.0.10 from binaries
  - Compiles and installs niftyreg from source
  - Does not include a FreeSurfer License key (hence the `nl` tag on the container name)

Instead of building FreeSurfer from source, Neurodocker can also be used to create containers with a released version of freesurfer, however the latest release of FreeSurfer (v7.2) does not include the pre-requisites to run the infanf pipeline.

### Managing the FreeSurfer License Key

While this container above has all the software needed to run the infant pipeline, it lacks a license key required by FreeSurfer.  FreeSurfer license keys are freely available [here](https://surfer.nmr.mgh.harvard.edu/registration.html)

This can be tested by attempting to run a freesurfer binary, for example trying to run `mri_convert`:

```
docker run -it --rm pwighton/fs-infant-dev:nl \
  mri_convert \
    /opt/freesurfer-20220224-gems-cmake-rework/subjects/fsaverage/mri/aseg.mgz \
    /tmp/aseg.nii.gz
```

will generate the following error:

```
ERROR: FreeSurfer license file /opt/license.txt not found.
  If you are outside the NMR-Martinos Center,
  go to http://surfer.nmr.mgh.harvard.edu/registration.html to 
  get a valid license file (it's free).
  If you are inside the NMR-Martinos Center,
  make sure to source the standard environment.
  A path to an alternative license file can also be
  specified with the FS_LICENSE environmental variable.
```

The license key can be passed to the container at runtime via a [docker bind mount](https://docs.docker.com/storage/bind-mounts/) and setting the environment variable `FS_LICENSE` which points to the location of license file.

For example, suppose the FreeSurfer license file is at `$HOME/license.txt` outside of the contianer. The license file can bind mounted to `/license.txt` inside the container by passing `-v $HOME/license.txt:/license.txt:ro` to `docker run`.  Similarily the environment variable `FS_LICENSE` tell FreeSurfer where the license file is located.  It can be set to point to `/license.txt` by passing `-e FS_LICENSE=/license.txt` to `docker run`, e.g:

```
docker run -it --rm \
  -v $HOME/license.txt:/license.txt:ro \
  -e FS_LICENSE='/license.txt' \
  pwighton/fs-infant-dev:nl \
    mri_convert \
      /opt/freesurfer-dev/subjects/fsaverage/mri/aseg.mgz \
      /tmp/aseg.nii.gz
```

Alternatively, you can pass the license key as a parameter to neurodocker and it will include it in the container it builds, eliminating the need to pass it in at runtime.

First, [base64 encode](https://en.wikipedia.org/wiki/Base64) your FreeSurfer license file:

```
cat $HOME/license.txt |base64 -w 999
```

This will generate a string similar to 

```
cHdpZ2h0b25AbWdoLmhhcnZhcmQuZWR1----EXAMPLE----4V25Gc2V3M3MuCiBGU2VJb1Q4Sklha1prCg==
cHdpZ2h0b25AbWdoLmhhcnZhcmQuZWR1CjU1NDc4CiAqQ0Y4V25Gc2V3M3MuCiBGU2VJb1Q4Sklha1prCg==
```

Next, pass this string to neurodocker as `license_base64`, e.g:

```
docker run pwighton/neurodocker:latest generate docker \
	    --base-image ubuntu:xenial \
	    --pkg-manager apt \
	    --yes \
	    --niftyreg \
	      version=master \
	    --fsl \
	      version=5.0.10 \
	      method=binaries \
	    --freesurfer \
	      method=source \
	      repo=https://github.com/pwighton/freesurfer.git \
	      branch=20220224-gems-cmake-rework \
	      license_base64=cHdpZ2h0b25AbWdoLmhhcnZhcmQuZWR1----EXAMPLE----4V25Gc2V3M3MuCiBGU2VJb1Q4Sklha1prCg== \
	      infant_module=ON \
	      dev_tools=ON \
	      infant_model_s3=s3://freesurfer-annex/infant/model/dev/ \
	      infant_model_s3_region=us-east-2 \
	    --entrypoint '/bin/infant-container-entrypoint-aws.bash' \
	| docker build --no-cache --network host -t pwighton/fs-infant-dev:latest -
```

If the `license_base64` parameter is used when the container is built, nothing further needs to be done when running the container, e.g the `docker run` test command above should work without having to bind-mount the license file

```
docker run -it --rm pwighton/fs-infant-dev:latest \
  mri_convert \
    /opt/freesurfer-dev/subjects/fsaverage/mri/aseg.mgz \
    /tmp/aseg.nii.gz
```

## Running FreeSurfer's infant pipeline

### Running the pipeline with docker

You can follow the steps above to create a docker container to run the pipeline.  Alternativly, you can pull an existing container

```
docker pull pwighton/fs-infant-dev:latest
```

You can download test data from **TODO**

In order to run the infant pipeline, the input data must be in a subfolder of the FreeSurfer's subject diretory.  The name of this subfolder is the subect's name.  Inside this subfolder should be a single file named `mprage.mgz` 

Let's setup this directory structure outside of the cotnainer and set some environment variables to help manage things.  Let's define the FreeSurfer subject's directory ouside the cotnainer as `$HOME/fs-subjects`.  Inside the container, the subject's drectory defaults to `/ext/fs-subjects`.  This can be changed at runtime (e.g `docker run -e SUBJECTS_DIR=/ext/foo..`) however we will use the default.  The other two peices of information the pipeline needs is the subject's name (`sub-CC00656XX13_ses-217601`) as well as the age of the subject in months (`0`)

```
export FS_SUBJECT_DIR_OUT_CONTAINER=$HOME/fs-subjects
export FS_SUBJECT_DIR_IN_CONTAINER=/ext/fs-subjects
export FS_SUB_NAME=sub-CC00656XX13_ses-217601
export FS_INFANT_AGE=0
```

Now lets create the directory structure
```
mkdir -p $FS_SUBJECT_DIR_OUT_CONTAINER/$FS_SUB_NAME
aws s3 cp s3://fs-infant/test/smoke/sub-CC00656XX13_ses-217601_desc-restore_space-T2w_T1w.nii.gz $FS_SUBJECT_DIR_OUT_CONTAINER/$FS_SUB_NAME/mprage.nii.gz
```

Now, lets run the infant pipeline inside the container and bind-mount the FreeSurfer's subject directory so that's it's available inside the container

```
docker run -it --rm \
  -v $FS_SUBJECT_DIR_OUT_CONTAINER:$FS_SUBJECT_DIR_IN_CONTAINER \
  -e SSCNN_MODEL_DIR=/opt/fs-infant-model/sscnn_skullstrip \
  -u ${UID}:${GID} \
  pwighton/fs-infant-dev:latest \
    infant_recon_all --s ${FS_SUB_NAME} --age ${FS_INFANT_AGE}
```

**TODO** set SCNN_MODEL_DIR by default so we don't need to specify it at runtime

## References







