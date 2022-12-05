# Running BIDS datasets though PetSurfer

BrainHack Nordic 2022

## Follow Along

To follow along on your machine, you'll need some data and a FreeSurfer env.

### Get some data:

```
wget 'https://drive.google.com/u/3/uc?id=1_2lMBBRfw4RU8Hiw9WQKbynhN7IsMV0w&export=download&confirm=yes' \
  -O ds001421.tar.gz
tar -zxvf ./ds001421.tar.gz
```

This is [OpenNeuro's ds001421 dataset](https://openneuro.org/datasets/ds001421/versions/1.0.1) as processed by `pwighton/petsurfer-bids:7.2.0` as follows (in bash):

```
export CONTAINER_NAME=pwighton/petsurfer-bids:7.2.0
export BASEDIR=/home/ec2-user/environment/ds001421__petsurfer-bids_7.2.0
export FS_LICENSE_FILE=/home/ec2-user/license.txt
export DATASET_S3_URI=s3://openneuro.org/ds001421

mkdir -p ${BASEDIR}
cd ${BASEDIR}
aws s3 sync ${DATASET_S3_URI} ./${DATASET_NAME}
docker pull ${CONTAINER_NAME}

docker run -it --rm \
  -u $(id -u):$(id -g) \
  -v $BASEDIR:$BASEDIR \
  -v $FS_LICENSE_FILE:/license.txt:ro \
  -e FS_LICENSE='/license.txt' \
  ${CONTAINER_NAME} \
    /opt/petpipeline/petpipeline/main.py \
      -c /opt/petpipeline/petpipeline/config.yaml \
      -e ${BASEDIR} \
      -o output \
      -w temp \
      -d ${BASEDIR}/${DATASET_NAME}
```

You can get a `license.txt file` for FreeSurfer [here](https://surfer.nmr.mgh.harvard.edu/registration.html)

The container `pwighton/petsurfer-bids:7.2.0` was created using [this Dockerfile](https://github.com/pwighton/fs-docker/blob/master/petsurfer-bids/dockerfile) which installes this [nipype pipeline](https://github.com/openneuropet/PET_pipelines/tree/main/pet_nipype).  The parent container of `pwighton/petsurfer-bids:7.2.0` is `pwighton/petsurfer:7.2.0` which was created with the following [neurodocker](https://github.com/ReproNim/neurodocker) command:

```
docker run pwighton/neurodocker:20220822 generate docker \
    --yes \
    --base-image python:3.8-buster \
    --pkg-manager apt \
    --fsl \
      version=5.0.10 \
      method=binaries \
    --freesurfer \
      version=7.2.0 \
    | docker build -t pwighton/petsurfer:7.2.0 -
```

### Setup a FreeSurfer env

There are several ways to get a FreeSurfer env

**1) BrainHack Cloud**
- https://bhnam.neurodesk.org/
- Authenticate via github to get a [neurodesk](https://www.neurodesk.org/) env with
  - 32CPUs
  - 256GB RAM
  - 500GB of scratch
- `module load freesurfer` in a terminal window to activate freesurfer env
- Use neurodesktop icon to run FreeView!
- Thanks to [stebo85](https://github.com/stebo85) :heart:

**2) Downalod and Install**
- https://surfer.nmr.mgh.harvard.edu/fswiki/rel7downloads
- Make a directory for subject data
- `SUBJECTS export_DIR=/home/my/freesurfer-subjects-dir`
- `export FREESURFER_HOME=/home/my/freesurfer-dir`
- `source $FREESURFER_HOME/SetUpFreeSurfer.sh`

**3) Downlod a Virtual Machine**
- And run it in virtualbox
- [Instructions](https://surfer.nmr.mgh.harvard.edu/fswiki/VM_67)



## Exploring the data

```
tree -d -L 2
```

Gives
```
.
├── derivatives
│   ├── coregistration
│   ├── km
│   ├── km2
│   ├── motion_correction
│   └── pvc
├── ds001421_openneuro.org
│   ├── derivatives
│   └── sub-01
├── freesurfer
│   ├── baseline_01
│   └── rescan_01
└── temp
    └── preprocessing
```
