WIP

Refs:
  - https://github.com/freesurfer/freesurfer/pull/444/commits/b3f104db19ffbf1234b6731186edebc46b0668e2#diff-9b9627d4b3cab70fb9be48e21f94d548
  - https://github.com/freesurfer/freesurfer/pull/444
  - https://github.com/freesurfer/freesurfer/issues/264
  - http://wiki.ros.org/docker/Tutorials/GUI
  - utensils/opengl:stable
  - https://github.com/utensils/docker-opengl
  - https://github.com/thewtex/docker-opengl
---------------------------------------


## Working
Build using neurodocker:
(`mesa-utils` can be eventually removed, used to test with glxgears)
```
neurodocker generate docker \
  --base thewtex/opengl:ubuntu1804 \
  --add-to-entrypoint "/usr/bin/supervisord -c /etc/supervisor/supervisord.conf" \
  --freesurfer version=7.1.0 \
  --pkg-manager apt \
  --install libglu1-mesa mesa-utils \
    | docker build -t pwighton/freeview:7.1.0-thewtex -
```
then run
```
./run.sh -p 6081 -i pwighton/freeview:7.1.0-thewtex -r --env="APP=freeview" -v /home/paul/lcn/data/fs-course-20200310:/subs
```

## Yet another test
```
neurodocker generate docker \
  --base thewtex/opengl:ubuntu1804 \
  --pkg-manager apt \
  --install libglu1-mesa mesa-utils \
  --vnc passwd=paul123 start_at_runtime=true geometry=1920x1080 \
    | docker build -t pwighton/freeview:7.1.0-thewtex-test2 -
```

then run:
```
docker run --rm -it -p 5901:5901 \
    pwighton/freeview:7.1.0-thewtex-test2 \
      glxgears
```

## Another test

  --freesurfer version=7.1.0 \


```
neurodocker generate docker \
  --base nvidia/opengl:1.0-glvnd-runtime-ubuntu16.04 \
  --pkg-manager apt \
  --install mesa-utils \
  --vnc passwd=paul123 start_at_runtime=true geometry=1920x1080 \
    | docker build -t pwighton/freeview:7.1.0-nvidia -
```

docker run --rm -it -p 5901:5901 pwighton/freeview:7.1.0-utensils  glxgears



demos
docker pull 



## Not working yet

After editing neurodocker so `lib/qt` isn't excluded and trying to use vnc in neurodocker:
(`mesa-utils` can be eventually removed, used to test with glxgears)
```
neurodocker generate docker \
  --base continuumio/miniconda:4.7.12 \
  --pkg-manager apt \
  --install \
      libglu1-mesa \
      libgl1-mesa-dri \
      libgl1-mesa-glx \
      mesa-utils \
      libmng-dev \
      qt5-default \
      libqt5x11extras5-dev \
  --freesurfer version=7.1.0 \
  --vnc passwd=paul123 start_at_runtime=true geometry=1920x1080 \
  --run "pip install opencv-python-headless" \
    | docker build -t pwighton/freeview:7.1.0-neurodocker -
```

  -e QT_DEBUG_PLUGINS=1 \


then run:
```
docker run --rm -it -p 5901:5901 \
  -e LD_LIBRARY_PATH=/opt/freesurfer-7.1.0/lib/qt/lib:/usr/lib:/usr/lib/x86_64-linux-gnu:/lib/x86_64-linux-gnu \
  -e PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
  -e QMLSCENE_DEVICE=softwarecontext \
  -v $(pwd):$(pwd) \
  -w $(pwd) \
    pwighton/freeview:7.1.0-neurodocker \
      freeview
```
### temp intermediate step

pwighton/freesurfer:7.1.0-fv

Then run:
```
docker run --rm -it -p 5901:5901 \
  -e QT_DEBUG_PLUGINS=1 \
  -e LD_LIBRARY_PATH=/opt/freesurfer-7.1.0/lib/qt/lib:/usr/lib:/usr/lib/x86_64-linux-gnu:/lib/x86_64-linux-gnu \
  -e PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
  -e QMLSCENE_DEVICE=softwarecontext \
  -v $(pwd):$(pwd) \
  -w $(pwd) \
    pwighton/freesurfer:7.1.0-fv freeview
```

```
docker run --rm -it -p 5901:5901 \
  -e QT_DEBUG_PLUGINS=1 \
  -e LD_LIBRARY_PATH=/opt/freesurfer-7.1.0/lib/qt/lib:/usr/lib:/usr/lib/x86_64-linux-gnu:/lib/x86_64-linux-gnu \
  -e PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
    pwighton/freesurfer:7.1.0-fv glxgears
```



interactive
```
docker run --rm -it \
  -e QT_DEBUG_PLUGINS=1 \
  -e LD_LIBRARY_PATH=/opt/freesurfer-7.1.0/lib/qt/lib:/usr/lib:/usr/lib/x86_64-linux-gnu:/lib/x86_64-linux-gnu \
  -v $(pwd):$(pwd) \
  -w $(pwd) \
    pwighton/freesurfer:7.1.0-fv /bin/bash
```

Error
```
Got keys from plugin meta data ("webp")
QFactoryLoader::QFactoryLoader() checking directory path "/opt/freesurfer-7.1.0/bin/imageformats" ...
loaded library "/opt/freesurfer-7.1.0/lib/qt/plugins/imageformats/libqgif.so"
loaded library "/opt/freesurfer-7.1.0/lib/qt/plugins/imageformats/libqicns.so"
loaded library "/opt/freesurfer-7.1.0/lib/qt/plugins/imageformats/libqico.so"
loaded library "/opt/freesurfer-7.1.0/lib/qt/plugins/imageformats/libqjpeg.so"
Cannot load library /opt/freesurfer-7.1.0/lib/qt/plugins/imageformats/libqmng.so: (libmng.so.1: cannot open shared object file: No such file or directory)
QLibraryPrivate::loadPlugin failed on "/opt/freesurfer-7.1.0/lib/qt/plugins/imageformats/libqmng.so" : "Cannot load library /opt/freesurfer-7.1.0/lib/qt/plugins/imageformats/libqmng.so: (libmng.so.1: cannot open shared object file: No such file or directory)"
loaded library "/opt/freesurfer-7.1.0/lib/qt/plugins/imageformats/libqtga.so"
loaded library "/opt/freesurfer-7.1.0/lib/qt/plugins/imageformats/libqtiff.so"
loaded library "/opt/freesurfer-7.1.0/lib/qt/plugins/imageformats/libqwbmp.so"
loaded library "/opt/freesurfer-7.1.0/lib/qt/plugins/imageformats/libqwebp.so"
QFactoryLoader::QFactoryLoader() checking directory path "/opt/freesurfer-7.1.0/lib/qt/plugins/accessible" ...
QFactoryLoader::QFactoryLoader() checking directory path "/opt/freesurfer-7.1.0/bin/accessible" ...
/neurodocker/startup.sh: line 8:    36 Aborted                 (core dumped) "$@"
```


```
docker run --rm -it -p 5901:5901 \
  -e QT_DEBUG_PLUGINS=1 \
  -e LD_LIBRARY_PATH=/opt/freesurfer-7.1.0/lib/qt/lib:/usr/lib:/usr/lib/x86_64-linux-gnu:/lib/x86_64-linux-gnu \
  -e QT_QPA_PLATFORM_PLUGIN_PATH=/opt/freesurfer-7.1.0/lib/qt/plugins \
    pwighton/freesurfer:7.1.0-fv /bin/bash
```
  -e FS_QT_HOME=/opt/freesurfer-7.1.0/lib/qt \
  -e QTLIBPATH=/opt/freesurfer-7.1.0/lib/qt/lib \
  -e LD_LIBRARY_PATH=/opt/freesurfer-7.1.0/lib/qt/lib \
  -e DYLD_LIBRARY_PATH=/opt/freesurfer-7.1.0/lib/qt/lib \





```
docker run --rm -it -p 5901:5901 pwighton/freesurfer:7.1.0-fv freeview
```

## Alt
----------------------------------
Build using neurodocker:
(`mesa-utils` can be eventually removed, used to test with glxgears)
```
neurodocker generate docker \
  --base thewtex/opengl:ubuntu1804 \
  --add-to-entrypoint "/usr/bin/supervisord -c /etc/supervisor/supervisord.conf" \
  --pkg-manager apt \
  --install mesa-utils \
  --freesurfer version=7.1.0 \
    | docker build -t pwighton/freeview:7.1.0 -
```







python-opencv-headless


docker run --rm -it -p 5901:5901 --env QT_QPA_PLATFORM_PLUGIN_PATH=/usr/lib/x86_64-linux-gnu/qt5/plugins pwighton/freeview:7.1.0 freeview



Now try


This works:
```
./run.sh -p 6081 -i pwighton/opengl-example -r --env="APP=glxgears"
```

./run.sh -p 6081 -i foo -r --env="APP=glxgears"

So hoping this will:
```
./run.sh -p 6081 -i pwighton/freeview:7.1.0 -r --env="APP=freeview"
```


```
./run.sh -p 6081 -i pwighton/freeview:7.1.0 -r --env="APP=glxgears"
```

```
./run.sh -p 6081 -i pwighton/freeview:7.1.0-nd-edit-test -r --env="APP=freeview"
```

```
./run.sh -p 6081 -i pwighton/freesurfer:7.1.0-fv -r --env="APP=freeview"
```

========================================================================
QT_X11_NO_MITSHM=1
"/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"


Run using https://github.com/thewtex/docker-opengl:
```
run.sh -i pwighton/freeview:7.1.0
```



run.sh -i pwighton/freeview:7.1.0 -p 9876 -r --env="APP=glxgears"
/neurodocker/startup.sh


This almost works locally:  GL windows are blank
```
docker run -it --rm \
  -u $(id -u):$(id -g) \
  -e DISPLAY=$DISPLAY \
  -e HOME=/tmp/home \
  -v="/etc/group:/etc/group:ro" \
  -v="/etc/passwd:/etc/passwd:ro" \
  -v="/etc/shadow:/etc/shadow:ro" \
  -v="/etc/sudoers.d:/etc/sudoers.d:ro" \
  -v="/tmp/.X11-unix:/tmp/.X11-unix:rw" \
  pwighton/freesurfer:7.1.0 \
    freeview
```

freeview: relocation error: freeview: symbol _ZN17QAbstractItemView11eventFilterEP7QObjectP6QEvent version Qt_5 not defined in file libQt5Widgets.so.5 with link time reference


```
docker run -it \
  -u $(id -u):$(id -g) \
  -e DISPLAY=$DISPLAY \
  --entrypoint /bin/bash \
  pwighton/freeview:7.1.0
```


      qt5-default \
      qtcreator \
      libqt5x11extras5-dev

-----------------------------------------
QStandardPaths: XDG_RUNTIME_DIR not set, defaulting to '/tmp/runtime-paul'
libGL error: No matching fbConfigs or visuals found
libGL error: failed to load driver: swrast
freeview: relocation error: freeview: symbol _ZN17QAbstractItemView11eventFilterEP7QObjectP6QEvent version Qt_5 not defined in file libQt5Widgets.so.5 with link time reference
-----------------------------------------
Build container
```
make fs-fv
```

Run freeview
```
docker run -it \
  -u $(id -u):$(id -g) \
  -e DISPLAY=$DISPLAY \
  -e HOME=/tmp/home \
  -v="/etc/group:/etc/group:ro" \
  -v="/etc/passwd:/etc/passwd:ro" \
  -v="/etc/shadow:/etc/shadow:ro" \
  -v="/etc/sudoers.d:/etc/sudoers.d:ro" \
  -v="/tmp/.X11-unix:/tmp/.X11-unix:rw" \
  -v $(pwd):$(pwd) \
  -w $(pwd) \
  pwighton/freesurfer:7.1.0-fv \
    freeview
```

Gives:
```

libGL error: No matching fbConfigs or visuals found
libGL error: failed to load driver: swrast
QXcbConnection: XCB error: 171 (Unknown), sequence: 1030, resource id: 65011737, major code: 154 (Unknown), minor code: 11
QXcbConnection: XCB error: 171 (Unknown), sequence: 1045, resource id: 65011752, major code: 154 (Unknown), minor code: 11
QXcbConnection: XCB error: 171 (Unknown), sequence: 1060, resource id: 65011755, major code: 154 (Unknown), minor code: 11
QXcbConnection: XCB error: 171 (Unknown), sequence: 1149, resource id: 65011737, major code: 154 (Unknown), mino
```

