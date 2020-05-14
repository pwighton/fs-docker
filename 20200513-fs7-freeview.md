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

Build using neurodocker:
(`mesa-utils` can be eventually removed, used to test with glxgears)
```
neurodocker generate docker \
  --base thewtex/opengl:ubuntu1804 \
  --add-to-entrypoint "/usr/bin/supervisord -c /etc/supervisor/supervisord.conf" \
  --pkg-manager apt \
  --install qt5-default qtcreator libqt5x11extras5-dev mesa-utils \
  --env QT_QPA_PLATFORM_PLUGIN_PATH=/usr/lib/x86_64-linux-gnu/qt5/plugins \
  --freesurfer version=7.1.0 \
    | docker build -t pwighton/freeview:7.1.0 -
```

After editing neurodocker so `lib/qt` isn't excluded
```
neurodocker generate docker \
  --base thewtex/opengl:ubuntu1804 \
  --add-to-entrypoint "/usr/bin/supervisord -c /etc/supervisor/supervisord.conf" \
  --pkg-manager apt \
  --install mesa-utils \
  --freesurfer version=7.1.0 \
    | docker build -t pwighton/freeview:7.1.0-nd-edit-test -
```


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

