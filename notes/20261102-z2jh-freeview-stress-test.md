# FreeView stress test on the Z2JH course cluster

How many students can share one node (e.g. a Jetstream2 g3.xl) before FreeView
slows down? Test users log in like students, each runs `fv-stress` in their
Desktop, and `fv-stress-report` combines the results into a table of frame rate
against the number of concurrent users.

Both tools are in the `freesurfer/freesurfer:8.2.0-z2jh` image
(`freesurfer/z2jh/bin/`).

## What `fv-stress` measures

- It opens fsaverage the way `tkmeditfv fsaverage orig.mgz -aparc+aseg -surfs -aparc`
  does, switches to the 3D view (`-viewport 3d`), waits for it to load
  (`--startup-wait`, 20 s), then rotates the camera `--step` degrees (3)
  `--rate` times per second (20) for `--duration` seconds (300).
- Rotation is sent through FreeView's `-stdin` option as lines like
  `freeview -cam Azimuth 3`. FreeView folds pending commands into its next
  frame, so if it can't keep up it simply renders as fast as it can.
- **FPS** is VirtualGL's profiler `Total` rate (`vglrun +pr`): frames drawn on
  the pod's X display, reported every ~2 s. An idle FreeView redraws twice a
  second, so 2 fps is the floor. On a GPU node FreeView renders through
  `vglrun -d egl0`; with no GPU it renders in software through
  `vglrun -d $DISPLAY` ("cpu" mode). That's fine for trying the tool, but the
  numbers aren't comparable to GPU runs.
- Alongside FPS it logs:
  - FreeView's own CPU
  - the X/VNC server's CPU (VNC encoding)
  - the pod's CPU, CPU limit, throttling and memory (cgroup)
  - the whole node's CPU
  - GPU utilisation and memory
- Results go to `~/shared/fv-stress/<tag>/` (or `~/fv-stress/<tag>/` if the
  shared volume isn't writable): one CSV and one JSON per run, named
  `<user>-<pod>-<time>`. Rows carry a node ID (the kernel boot ID, shared by all
  pods on a node) so the report can tell nodes apart.
- `-n K` runs K FreeViews in one Desktop, to simulate more users than you have
  test accounts. They share that user's VNC session and pod limits, so this
  understates per-user overhead slightly.

## Before the test

1. **Check how GPUs are shared.** Kubernetes normally gives a whole GPU to one
   pod unless time-slicing (or MPS) is configured, and that can cap users per
   node regardless of performance.
   ```bash
   kubectl get nodes -o wide
   kubectl describe node <g3.xl node> | grep -A8 -E '^(Capacity|Allocatable)'   # nvidia.com/gpu: N
   helm get values <release> -n <namespace> | grep -A15 singleuser             # cpu/memory/gpu limits
   ```
2. **Check that a user pod really renders on the GPU.** In its Desktop terminal:
   ```bash
   nvidia-smi
   vglrun -d egl0 glxinfo -B | grep -i renderer   # should name the NVIDIA GPU, not llvmpipe
   ```
3. **Create test accounts** `stress-01` … `stress-20`. With NativeAuthenticator,
   sign each up at `/hub/signup` and approve them at `/hub/authorize`.
4. **Put the pods on one node if you can.** Cordon the other GPU nodes for the
   test. Otherwise the report gives separate tables per node.

## Running a ramp

1. **One browser session per test user.** All tabs in a browser profile share
   the Hub login cookie. Use separate browser profiles, private windows or
   Firefox Multi-Account Containers.
2. **Keep every Desktop visible.** Tile the windows or spread them over a few
   machines. Browsers slow down hidden tabs, and VNC only sends frames the
   client asks for, so a hidden Desktop puts less load on the server than a real
   student would.
3. **Pick a tag** (e.g. `g3xl-ramp1`) and add one user about every minute. In
   each Desktop's terminal:
   ```bash
   fv-stress --tag g3xl-ramp1 --duration 1800
   ```
   Starting users at least `--startup-wait` + 10 s apart gives clean levels.
   Instances that are still loading add load but aren't counted as concurrent.
4. **Stop everyone.** Once the last level has run for a couple of minutes,
   press Ctrl-C in each terminal (results are saved), or let `--duration` run
   out.
5. **Make the report:**
   ```bash
   fv-stress-report ~/shared/fv-stress/g3xl-ramp1 --csv ~/shared/fv-stress/g3xl-ramp1-report.csv
   ```

## Reading the report

```
Node 08afed6c  mode=gpu  target=20 fps  runs=12  users=12  gpu=GPU-1a2b3c4d
inst users  win  median    p10  worst  fv cpu%  X cpu% node cpu%  gpu%  thr%
   1     1    6    19.9   19.8   19.7 ...
```

- **inst / users:** FreeViews rotating at the same time on that node, and how
  many distinct users they belong to.
- **win:** the number of 10 s windows at that level (`--window`).
- **median / p10 / worst:** delivered FPS across the instances at that level.
  The first level where p10 drops below 0.9 × target (`--threshold`) is marked
  `<- degraded`.
- **What's the bottleneck?**
  - `gpu%` near 100: the GPU.
  - `node cpu%` near 100: the node's CPUs (FreeView plus VNC encoding).
  - `thr%` above 0: the pod's CPU limit. Raising `singleuser.cpu.limit` may
    help more than adding nodes.
- **X cpu%:** the VNC server's share of the cost.

## Driving FreeView by hand

- `-viewport 3d` opens with the 3D view as the main view.
- `-cam Azimuth 30 Elevation 10` rotates the 3D camera; operations apply in
  order.
- `-view lateral` (also medial/left/right/anterior/…) picks a preset 3D view.
- `-stdin` makes FreeView accept commands on standard input. Each line is
  written like a FreeView command line, starting with `freeview`:
  ```bash
  S=$FREESURFER_HOME/subjects/fsaverage
  (sleep 20; while :; do echo "freeview -cam Azimuth 3"; sleep 0.05; done) |
    VGL_PROFILE=1 freeview -v $S/mri/orig.mgz -f $S/surf/lh.pial -viewport 3d -stdin
  ```
  On a GPU node the `freeview` wrapper runs it under `vglrun`, and
  `VGL_PROFILE=1` makes VirtualGL print its `Readback`/`Blit`/`Total` profile
  every ~2 s. `Total` is the frame rate. Without a GPU there's no VirtualGL, so
  no profile is printed; use `fv-stress` instead.

## Trying it locally

With `docker run` and no GPU, `fv-stress -n 1 --duration 30` in the Desktop
terminal runs in cpu mode. It shows the tool working end to end, at software
rendering speeds.
