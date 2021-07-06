# Samseg Atlas Breakdown

A description of how samseg atlases and how to create them.

## Environment

### Martinos

```
source ???
```

### Container

See [`pwighton/samseg-atlas-build`](https://hub.docker.com/r/pwighton/samseg-atlas-build), which can be built using [neurodocker](https://github.com/pwighton/fs-docker/blob/5c550330a107d626b6b79b87e0049f7a54eb087d/buildspec-samseg-atlas-build.yml#L30)

```
docker run pwighton/neurodocker:latest \
  generate docker \
    --base-image ubuntu:xenial \
    --pkg-manager apt \
    --yes \
    --freesurfer \
      license_base64=$FS_LICENSE \
      method=source \
      repo=https://github.com/pwighton/freesurfer.git \
      version=20210513-fs-infant-dev-merge \
      minimal=on \
      samseg_atlas_build=on \
      infant_module=off \
      install_python_deps=off \
      distribute_fspython=off | docker build --no-cache -t pwighton/samseg-atlas-build -
```

Note that when `samseg_atlas_build` is set to `on` in this container.  Building atlases occurs in a seperate environment, since mesh vertices must be moveable and are therefore implemented with ???, perfomance is considerably impacted.

## Example atlas

The directory `$FREESURFER_HOME/average/samseg/20Subjects_smoothing2_down2_smoothingForAffine2` contains the following files, a lot of info here copied from the `README`

- `README`
- `atlasForAffineRegistration.txt.gz`
  - 5-label mesh (?, WM, GM, CSF, Skull)
  - Used for initial affine registration
  - This registration may fail if the input image does not have extra cerebral-structures or only a single hemi
- `atlas_level1.txt.gz`
  - The 1st-level (low res) mesh
- `atlas_level2.txt.gz`
  - The 2nd-level (full res) mesh
- `compressionLookupTable.txt`
  - maps the labels numbers (eg, 0-43) to FreeSurfer color table names and numbers
- `modifiedFreeSurferColorLUT.txt`
  - FreeSurfer-style color table 
- `sharedGMMParameters.txt`
  - SAMSEG only runs the full optimization on 5-label mesh. 
  - Other structures (eg, hippocampus) are assigned to a given superstructure. 
  - Each superstructure may be modeled by several Gaussians. 
  - This file dictates which structures go into which superstructure and how many Gaussians each superstructure gets
- `template.nii`
  - intensity image of the SAMSEG atlas. This is not actually used in the normal course of SAMSEG execution, but it helpful to have to evaluate registration
- `template.seg.mgz`
  - SAMSEG segmentation of `template.nii`. 
  - This more-or-less gives an indication of what the SAMSEG atlas priors look like. 
  - This is not actually used in the normal course of SAMSEG execution.

A mesh can be read with `samseg.gems.KvlMeshCollection()`, eg:

```
from freesurfer import samseg
import os

meshCollection = samseg.gems.KvlMeshCollection()
meshCollectionFile = os.path.join(os.environ['FREESURFER_HOME'], \
  'average/samseg/20Subjects_smoothing2_down2_smoothingForAffine2/atlas_level1.txt.gz')
meshCollection.read(meshCollectionFile)
```

A [meshCollection](https://github.com/pwighton/freesurfer/blob/cb308919c03eef6e0ea80ae152b3e1aa504dce94/python/bindings/gems/pyKvlMesh.h#L50) object contains:
  - `self.read(fname)`
  - `self.write(fname)`
  - `self.k`
  - `self.mesh_count`
  - `self.reference_mesh`
  - `self.get_mesh(int)`

`meshCollection.reference_mesh` and `meshCollection.get_mesh(n)` both return a [`KvlMesh` object](https://github.com/pwighton/freesurfer/blob/cb308919c03eef6e0ea80ae152b3e1aa504dce94/python/bindings/gems/pyKvlMesh.h#L23) with the following properties
  - `self.point_count`
  - `self.points`
  - `self.alphas`

## Generating an Atlas

Meshes are created using `kvlBuildAtlasMesh`.  

Example invocation (for `pwighton/samseg-atlas-build`):

Setup:
```
mkdir -p /tmp/log--samseg-kvlBuildAtlasMesh
export SAMSEG_UPSAMPLING_STEPS=1
export SAMSEG_XYZ_MESH_SIZE="3 3 3"
export SAMSEG_STIFFNESS=0.1
export SAMSEG_LOGDIR=/tmp/log--samseg-kvlBuildAtlasMesh
export SAMSEG_ATLAS_BUILD_BINARY=/opt/freesurfer-20210513-fs-infant-dev-merge/gems/bin/kvlBuildAtlasMesh
export $SAMSEG_ATLAS_INFILES=/path/sub01.mgz /path/sub02.mgz
```

Run:
```
$SAMSEG_ATLAS_BUILD_BINARY \
  $SAMSEG_UPSAMPLING_STEPS \
  $SAMSEG_XYZ_MESH_SIZE \
  $SAMSEG_STIFFNESS \
  $SAMSEG_LOGDIR \
  $SAMSEG_ATLAS_INFILES
```  


