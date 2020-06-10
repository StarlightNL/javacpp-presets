#!/bin/bash
# This file is meant to be included by the parent cppbuild.sh script
if [[ -z "$PLATFORM" ]]; then
    pushd ..
    bash cppbuild.sh "$@" librealsense2
    popd
    exit
fi

LIBREALSENSE2_VERSION=2.33.1
download https://github.com/IntelRealSense/librealsense/archive/v$LIBREALSENSE2_VERSION.tar.gz librealsense-$LIBREALSENSE2_VERSION.tar.gz

mkdir -p "$PLATFORM$EXTENSION"
cd "$PLATFORM$EXTENSION"

mkdir -p include lib bin
INSTALL_PATH=`pwd`
echo "Decompressing archives..."
tar --totals -xzf ../librealsense-$LIBREALSENSE2_VERSION.tar.gz

cd librealsense-$LIBREALSENSE2_VERSION
patch -Np1 < ../../../librealsense2.patch || true
#sedinplace 's/float_t/float/g' `find third-party/libtm/ -type f`

GPU_FLAGS="-DBUILD_WITH_CUDA=OFF"
if [[ "$EXTENSION" == *gpu ]]; then
    GPU_FLAGS="-DBUILD_WITH_CUDA=ON"
fi
echo $INSTALL_PATH
case $PLATFORM in
    linux-arm64)
        cd ../librealsense-$LIBREALSENSE2_VERSION
        CC="aarch64-linux-gnu-gcc " CXX="aarch64-linux-gnu-g++" "$CMAKE" -DCMAKE_INSTALL_PREFIX="$INSTALL_PATH" -DFORCE_RSUSB_BACKEND=ON -DBUILD_UNIT_TESTS=OFF -DBUILD_EXAMPLES=OFF -DBUILD_GRAPHICAL_EXAMPLES=OFF $GPU_FLAGS .
        make -j $MAKEJ
        make install
        ;;
    linux-x86)
        cd ../librealsense-$LIBREALSENSE2_VERSION
        CC="gcc -m32" CXX="g++ -m32" "$CMAKE" -DCMAKE_INSTALL_PREFIX="$INSTALL_PATH" -DFORCE_RSUSB_BACKEND=ON -DBUILD_UNIT_TESTS=OFF -DBUILD_EXAMPLES=OFF -DBUILD_GRAPHICAL_EXAMPLES=OFF $GPU_FLAGS .
        make -j $MAKEJ
        make install/strip
        ;;
    linux-x86_64)
        cd ../librealsense-$LIBREALSENSE2_VERSION
        CC="gcc -m64" CXX="g++ -m64" "$CMAKE" -DCMAKE_INSTALL_PREFIX="$INSTALL_PATH" -DFORCE_RSUSB_BACKEND=ON -DBUILD_UNIT_TESTS=OFF -DBUILD_EXAMPLES=OFF -DBUILD_GRAPHICAL_EXAMPLES=OFF $GPU_FLAGS .
        make -j $MAKEJ
        make install/strip
        ;;
    macosx-x86_64)
        "$CMAKE" -DCMAKE_INSTALL_PREFIX="$INSTALL_PATH" -DFORCE_RSUSB_BACKEND=ON -DBUILD_UNIT_TESTS=OFF -DBUILD_EXAMPLES=OFF -DBUILD_GRAPHICAL_EXAMPLES=OFF $GPU_FLAGS .
        make -j $MAKEJ
        make install/strip
        ;;
    windows-x86)
        mkdir -p build
        cd build
        "$CMAKE" -G "Visual Studio 15 2017" -DCMAKE_INSTALL_PREFIX="$INSTALL_PATH" -DFORCE_RSUSB_BACKEND=ON -DBUILD_UNIT_TESTS=OFF -DBUILD_EXAMPLES=OFF -DBUILD_GRAPHICAL_EXAMPLES=OFF $GPU_FLAGS .
        MSBuild.exe INSTALL.vcxproj //p:Configuration=Release
        cd ..
        cp -a include/* ../include/
        cp -a build/Release/* ../lib/
        ;;
    windows-x86_64)
        mkdir -p build
        cd build
        "$CMAKE" -G "Visual Studio 15 2017 Win64" -DCMAKE_INSTALL_PREFIX="$INSTALL_PATH" -DFORCE_RSUSB_BACKEND=ON -DBUILD_UNIT_TESTS=OFF -DBUILD_EXAMPLES=OFF -DBUILD_GRAPHICAL_EXAMPLES=OFF $GPU_FLAGS .
        MSBuild.exe INSTALL.vcxproj //p:Configuration=Release
        cd ..
        cp -a include/* ../include/
        cp -a build/Release/* ../lib/
        ;;
    *)
        echo "Error: Platform \"$PLATFORM\" is not supported"
        ;;
esac

cd ../..
