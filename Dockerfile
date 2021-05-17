################################################################################
##  Dockerfile to build minimal OpenCV img with Python3.12 and Video support   ##
################################################################################
FROM alpine:3.12

ENV LANG=zh_CN.UTF-8 \
    SHELL=/bin/bash PS1="\u@\h:\w \$ " \
    PKG_CONFIG_PATH=/usr/local/lib64/pkgconfig \
    LD_LIBRARY_PATH=/usr/local/lib64/:/usr/local/include/

ARG OPENCV_VERSION=4.5.1

# Add Edge repos
RUN echo -e "\n\
@edgemain http://nl.alpinelinux.org/alpine/edge/main\n\
@edgecomm http://nl.alpinelinux.org/alpine/edge/community\n\
@edgetest http://nl.alpinelinux.org/alpine/edge/testing"\
  >> /etc/apk/repositories

RUN apk add --update --no-cache \
    # Build dependencies
    build-base clang clang-dev cmake pkgconf wget openblas openblas-dev \
    linux-headers \
    # Image IO packages
    libjpeg-turbo libjpeg-turbo-dev openjpeg-tools \
    libpng libpng-dev \
    libwebp libwebp-dev \
    tiff tiff-dev \
    jasper-libs jasper-dev \
    openexr openexr-dev \
    # Video depepndencies
    ffmpeg-libs ffmpeg-dev \
    python3 python3-dev \
    libavc1394 libavc1394-dev \
    musl@edgemain musl-dev@edgemain \
    gstreamer gstreamer-dev \
    libtbb@edgetest libtbb-dev@edgetest \
    gst-plugins-base gst-plugins-base-dev \
    libgphoto2 libgphoto2-dev && \
    cd /tmp && wget -L https://bootstrap.pypa.io/get-pip.py && \
    python3 get-pip.py && \
    # Make Python3 as default
    ln -vfs /usr/bin/python3 /usr/local/bin/python && \
    ln -vfs /usr/bin/pip3 /usr/local/bin/pip && \
    # Fix libpng path
    ln -vfs /usr/include/libpng16 /usr/include/libpng && \
    ln -vfs /usr/include/locale.h /usr/include/xlocale.h && \
    pip3 install -v --no-cache-dir --upgrade pip && \
    pip3 install -v --no-cache-dir numpy && \
    # Download OpenCV source
    cd /tmp && \
    wget https://github.com/opencv/opencv/archive/$OPENCV_VERSION.tar.gz && \
    tar -xvzf $OPENCV_VERSION.tar.gz && \
    rm -vrf $OPENCV_VERSION.tar.gz && \
    # Configure
    mkdir -vp /tmp/opencv-$OPENCV_VERSION/build && \
    cd /tmp/opencv-$OPENCV_VERSION/build && \
    cmake \
        # Compiler params
        -D CMAKE_BUILD_TYPE=RELEASE \
        -D CMAKE_C_COMPILER=/usr/bin/clang \
        -D CMAKE_CXX_COMPILER=/usr/bin/clang++ \
        -D CMAKE_INSTALL_PREFIX=/usr \
        # No examples
        -D INSTALL_PYTHON_EXAMPLES=NO \
        -D INSTALL_C_EXAMPLES=NO \
        # Support
        -D WITH_IPP=NO \
        -D WITH_1394=NO \
        -D WITH_LIBV4L=NO \
        -D WITH_V4l=YES \
        -D WITH_TBB=YES \
        -D WITH_FFMPEG=YES \
        -D WITH_GPHOTO2=YES \
        -D WITH_GSTREAMER=YES \
        # NO doc test and other bindings
        -D BUILD_DOCS=NO \
        -D BUILD_TESTS=NO \
        -D BUILD_PERF_TESTS=NO \
        -D BUILD_EXAMPLES=NO \
        -D BUILD_opencv_java=NO \
        -D BUILD_opencv_python2=NO \
        -D BUILD_ANDROID_EXAMPLES=NO \
        # Build Python3 bindings only
        -D PYTHON3_LIBRARY=`find /usr -name libpython3.so` \
        -D PYTHON_EXECUTABLE=`which python3` \
        -D PYTHON3_EXECUTABLE=`which python3` \
        -D OPENCV_GENERATE_PKGCONFIG=ON \
        -D BUILD_opencv_python3=YES .. && \
    # Build
    make -j`grep -c '^processor' /proc/cpuinfo` && \
    make install && \
    ln -s /usr/local/include/opencv4/opencv2/ /usr/local/include/opencv2 && \
    # Cleanup
    cd / && rm -vrf /tmp/opencv-$OPENCV_VERSION && \
    apk del --purge build-base clang clang-dev cmake pkgconf wget openblas-dev \
                    openexr-dev gstreamer-dev gst-plugins-base-dev libgphoto2-dev \
                    libtbb-dev libjpeg-turbo-dev libpng-dev tiff-dev jasper-dev \
                    ffmpeg-dev libavc1394-dev python3-dev musl-dev openjpeg-tools && \
    rm -vrf /var/cache/apk/* \
    rm -f /tmp/get-pip.py 