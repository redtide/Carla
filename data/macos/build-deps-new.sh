#!/bin/bash

# NOTE: You need the following packages installed via MacPorts:
# automake, autoconf, cmake, libtool, p7zip, pkgconfig, aria2

# ---------------------------------------------------------------------------------------------------------------------
# stop on error

set -e

# ---------------------------------------------------------------------------------------------------------------------
# cd to correct path

if [ -f Makefile ]; then
  cd data/macos
fi

# ---------------------------------------------------------------------------------------------------------------------
# set variables

export DEPS_NEW=1
source common.env

# ---------------------------------------------------------------------------------------------------------------------
# function to remove old stuff

cleanup()
{

rm -rf $TARGETDIR/carla/ $TARGETDIR/carla32/ $TARGETDIR/carla64/
rm -rf cx_Freeze-*
rm -rf Python-*
rm -rf PyQt-*
rm -rf PyQt5_*
rm -rf file-*
rm -rf flac-*
rm -rf fltk-*
rm -rf fluidsynth-*
rm -rf fftw-*
rm -rf gettext-*
rm -rf glib-*
rm -rf libffi-*
rm -rf liblo-*
rm -rf libogg-*
rm -rf libsndfile-*
rm -rf libvorbis-*
rm -rf mxml-*
rm -rf pkg-config-*
rm -rf pyliblo-*
rm -rf qtbase-*
rm -rf qtmacextras-*
rm -rf qtsvg-*
rm -rf sip-*
rm -rf zlib-*
rm -rf PaxHeaders.*

}

# ---------------------------------------------------------------------------------------------------------------------
# function to build base libs

build_base()
{

export CC=clang
export CXX=clang++

export PREFIX=${TARGETDIR}/carla${ARCH}
export PATH=${PREFIX}/bin:/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin
export PKG_CONFIG_PATH=${PREFIX}/lib/pkgconfig

export CFLAGS="-O3 -mtune=generic -msse -msse2 -fvisibility=hidden -fdata-sections -ffunction-sections"
export CFLAGS="${CFLAGS} -fPIC -DPIC -DNDEBUG -I${PREFIX}/include -mmacosx-version-min=10.12"

export LDFLAGS="-fdata-sections -ffunction-sections -Wl,-dead_strip -Wl,-dead_strip_dylibs"
export LDFLAGS="${LDFLAGS} -L${PREFIX}/lib -stdlib=libc++"

if [ "${MACOS_UNIVERSAL}" -eq 1 ]; then
    export CFLAGS="${CFLAGS} -arch x86_64 -arch arm64 -Wno-unused-command-line-argument"
    export LDFLAGS="${LDFLAGS} -arch x86_64 -arch arm64"
else
    export CFLAGS="${CFLAGS} -mfpmath=sse -m${ARCH}"
    export LDFLAGS="${LDFLAGS} -m${ARCH}"
fi

export CXXFLAGS="${CFLAGS} -fvisibility-inlines-hidden -std=gnu++11 -stdlib=libc++"

# ---------------------------------------------------------------------------------------------------------------------
# pkgconfig

if [ ! -d pkg-config-${PKG_CONFIG_VERSION} ]; then
  curl -O https://pkg-config.freedesktop.org/releases/pkg-config-${PKG_CONFIG_VERSION}.tar.gz
  tar -xf pkg-config-${PKG_CONFIG_VERSION}.tar.gz
fi

if [ ! -f pkg-config-${PKG_CONFIG_VERSION}_$ARCH/build-done ]; then
  cp -r pkg-config-${PKG_CONFIG_VERSION} pkg-config-${PKG_CONFIG_VERSION}_$ARCH
  cd pkg-config-${PKG_CONFIG_VERSION}_$ARCH
  ./configure --enable-indirect-deps --with-internal-glib --with-pc-path=$PKG_CONFIG_PATH --prefix=${PREFIX}
  make ${MAKE_ARGS}
  make install
  touch build-done
  cd ..
fi

# ---------------------------------------------------------------------------------------------------------------------
# liblo

if [ ! -d liblo-${LIBLO_VERSION} ]; then
  curl -L http://download.sourceforge.net/liblo/liblo-${LIBLO_VERSION}.tar.gz -o liblo-${LIBLO_VERSION}.tar.gz
  tar -xf liblo-${LIBLO_VERSION}.tar.gz
fi

if [ ! -f liblo-${LIBLO_VERSION}_$ARCH/build-done ]; then
  cp -r liblo-${LIBLO_VERSION} liblo-${LIBLO_VERSION}_$ARCH
  cd liblo-${LIBLO_VERSION}_$ARCH
  ./configure --enable-static --disable-shared --prefix=${PREFIX} \
    --enable-threads \
    --disable-examples --disable-tools
  make ${MAKE_ARGS}
  make install
  touch build-done
  cd ..
fi

# ---------------------------------------------------------------------------------------------------------------------

if [ x"${ARCH}" = x"32" ]; then
  return
fi

# ---------------------------------------------------------------------------------------------------------------------
# zlib

if [ ! -d zlib-${ZLIB_VERSION} ]; then
  /opt/local/bin/aria2c https://github.com/madler/zlib/archive/v${ZLIB_VERSION}.tar.gz
  tar -xf zlib-${ZLIB_VERSION}.tar.gz
fi

if [ ! -f zlib-${ZLIB_VERSION}/build-done ]; then
  cd zlib-${ZLIB_VERSION}
  ./configure --static --prefix=${PREFIX}
  make
  make install
  touch build-done
  cd ..
fi

# ---------------------------------------------------------------------------------------------------------------------
# file/magic

if [ ! -d file-${FILE_VERSION} ]; then
  curl -O ftp://ftp.astron.com/pub/file/file-${FILE_VERSION}.tar.gz
  tar -xf file-${FILE_VERSION}.tar.gz
fi

if [ ! -f file-${FILE_VERSION}/build-done ]; then
  cd file-${FILE_VERSION}
  ./configure --enable-static --disable-shared --prefix=${PREFIX}
  make ${MAKE_ARGS}
  make install
  touch build-done
  cd ..
fi

# ---------------------------------------------------------------------------------------------------------------------
# libogg

if [ ! -d libogg-${LIBOGG_VERSION} ]; then
  curl -O https://ftp.osuosl.org/pub/xiph/releases/ogg/libogg-${LIBOGG_VERSION}.tar.gz
  tar -xf libogg-${LIBOGG_VERSION}.tar.gz
fi

if [ ! -f libogg-${LIBOGG_VERSION}/build-done ]; then
  cd libogg-${LIBOGG_VERSION}
  sed -i -e 's/__MACH__/__MACH_SKIP__/' include/ogg/os_types.h
  ./configure --enable-static --disable-shared --prefix=${PREFIX}
  make ${MAKE_ARGS}
  make install
  touch build-done
  cd ..
fi

# ---------------------------------------------------------------------------------------------------------------------
# libvorbis

if [ ! -d libvorbis-${LIBVORBIS_VERSION} ]; then
  curl -O https://ftp.osuosl.org/pub/xiph/releases/vorbis/libvorbis-${LIBVORBIS_VERSION}.tar.gz
  tar -xf libvorbis-${LIBVORBIS_VERSION}.tar.gz
fi

if [ ! -f libvorbis-${LIBVORBIS_VERSION}/build-done ]; then
  cd libvorbis-${LIBVORBIS_VERSION}
  ./configure --enable-static --disable-shared --prefix=${PREFIX}
  make ${MAKE_ARGS}
  make install
  touch build-done
  cd ..
fi

# ---------------------------------------------------------------------------------------------------------------------
# flac

if [ ! -d flac-${FLAC_VERSION} ]; then
  curl -O https://ftp.osuosl.org/pub/xiph/releases/flac/flac-${FLAC_VERSION}.tar.xz
  /opt/local/bin/7z x flac-${FLAC_VERSION}.tar.xz
  /opt/local/bin/7z x flac-${FLAC_VERSION}.tar
fi

if [ ! -f flac-${FLAC_VERSION}/build-done ]; then
  cd flac-${FLAC_VERSION}
  chmod +x configure install-sh
  ./configure --enable-static --disable-shared --prefix=${PREFIX} \
    --disable-cpplibs
  make ${MAKE_ARGS}
  make install
  touch build-done
  cd ..
fi

# ---------------------------------------------------------------------------------------------------------------------
# libsndfile

if [ ! -d libsndfile-${LIBSNDFILE_VERSION} ]; then
  curl -O http://www.mega-nerd.com/libsndfile/files/libsndfile-${LIBSNDFILE_VERSION}.tar.gz
  tar -xf libsndfile-${LIBSNDFILE_VERSION}.tar.gz
fi

if [ ! -f libsndfile-${LIBSNDFILE_VERSION}/build-done ]; then
  cd libsndfile-${LIBSNDFILE_VERSION}
  ./configure --enable-static --disable-shared --prefix=${PREFIX} \
    --disable-full-suite --disable-alsa --disable-sqlite
  make ${MAKE_ARGS}
  make install
  touch build-done
  cd ..
fi

# ---------------------------------------------------------------------------------------------------------------------
# glib

if [ ! -d glib-${GLIB_VERSION} ]; then
  /opt/local/bin/aria2c http://caesar.ftp.acc.umu.se/pub/GNOME/sources/glib/${GLIB_MVERSION}/glib-${GLIB_VERSION}.tar.xz
  /opt/local/bin/7z x glib-${GLIB_VERSION}.tar.xz
  /opt/local/bin/7z x glib-${GLIB_VERSION}.tar
fi

if [ ! -f glib-${GLIB_VERSION}/build-done ]; then
  cd glib-${GLIB_VERSION}
  if [ ! -f patched ]; then
    patch -p1 -i ../../patches/glib_skip-gettext.patch
    rm m4macros/glib-gettext.m4
    touch patched
  fi
  chmod +x autogen.sh configure install-sh
  env PATH=/opt/local/bin:$PATH ./autogen.sh
  env PATH=/opt/local/bin:$PATH LDFLAGS="-L${PREFIX}/lib -m${ARCH}" \
    ./configure --enable-static --disable-shared --prefix=${PREFIX}
  env PATH=/opt/local/bin:$PATH make ${MAKE_ARGS} -k || true
  touch gio/gio-querymodules gio/glib-compile-resources gio/gsettings gio/gdbus gio/gresource gio/gapplication
  touch gobject/gobject-query tests/gobject/performance tests/gobject/performance-threaded
  env PATH=/opt/local/bin:$PATH make
  touch ${PREFIX}/bin/gtester-report
  env PATH=/opt/local/bin:$PATH make install
  touch build-done
  cd ..
fi

# ---------------------------------------------------------------------------------------------------------------------
# fluidsynth

if [ ! -d fluidsynth-${FLUIDSYNTH_VERSION} ]; then
  /opt/local/bin/aria2c https://github.com/FluidSynth/fluidsynth/archive/v${FLUIDSYNTH_VERSION}.tar.gz
  tar -xf fluidsynth-${FLUIDSYNTH_VERSION}.tar.gz
fi

if [ ! -f fluidsynth-${FLUIDSYNTH_VERSION}/build-done ]; then
  cd fluidsynth-${FLUIDSYNTH_VERSION}
  if [ ! -f patched ]; then
    patch -p1 -i ../../patches/fluidsynth-skip-drivers-build.patch
    touch patched
  fi
  sed -i -e 's/_init_lib_suffix "64"/_init_lib_suffix ""/' CMakeLists.txt
  /opt/local/bin/cmake . -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=${PREFIX} -DBUILD_SHARED_LIBS=OFF \
    -Denable-debug=OFF -Denable-profiling=OFF -Denable-ladspa=OFF -Denable-fpe-check=OFF -Denable-portaudio=OFF \
    -Denable-trap-on-fpe=OFF -Denable-aufile=OFF -Denable-dbus=OFF -Denable-ipv6=OFF -Denable-jack=OFF \
    -Denable-midishare=OFF -Denable-oss=OFF -Denable-pulseaudio=OFF -Denable-readline=OFF -Denable-ladcca=OFF \
    -Denable-lash=OFF -Denable-alsa=OFF -Denable-coreaudio=OFF -Denable-coremidi=OFF -Denable-framework=OFF \
    -Denable-floats=ON
  make ${MAKE_ARGS} -k  || true
  touch src/fluidsynth
  make
  make install
  sed -i -e "s|-lfluidsynth|-lfluidsynth -lglib-2.0 -lgthread-2.0 -lsndfile -lFLAC -lvorbisenc -lvorbis -logg -lpthread -lm -liconv|" ${PREFIX}/lib/pkgconfig/fluidsynth.pc
  touch build-done
  cd ..
fi

# ---------------------------------------------------------------------------------------------------------------------
# mxml

if [ ! -d mxml-${MXML_VERSION} ]; then
  /opt/local/bin/aria2c https://github.com/michaelrsweet/mxml/releases/download/v${MXML_VERSION}/mxml-${MXML_VERSION}.tar.gz
  tar -xf mxml-${MXML_VERSION}.tar.gz
fi

if [ ! -f mxml-${MXML_VERSION}/build-done ]; then
  cd mxml-${MXML_VERSION}
  ./configure --disable-shared --prefix=${PREFIX}
  make libmxml.a
  cp *.a    ${PREFIX}/lib/
  cp *.pc   ${PREFIX}/lib/pkgconfig/
  cp mxml.h ${PREFIX}/include/
  touch build-done
  cd ..
fi

# ---------------------------------------------------------------------------------------------------------------------
# fftw3 (needs to be last as it modifies C[XX]FLAGS)

if [ ! -d fftw-${FFTW3_VERSION} ]; then
  curl -O http://www.fftw.org/fftw-${FFTW3_VERSION}.tar.gz
  tar -xf fftw-${FFTW3_VERSION}.tar.gz
fi

if [ ! -f fftw-${FFTW3_VERSION}/build-done ]; then
  export CFLAGS="${CFLAGS} -ffast-math"
  export CXXFLAGS="${CXXFLAGS} -ffast-math"
  cd fftw-${FFTW3_VERSION}
  if [ "${MACOS_UNIVERSAL}" -eq 0 ]; then
      FFTW_EXTRAFLAGS="--enable-sse2"
  fi
  ./configure --enable-static ${FFTW_EXTRAFLAGS} --disable-shared --disable-debug --prefix=${PREFIX}
  make
  make install
  make clean
  if [ "${MACOS_UNIVERSAL}" -eq 0 ]; then
      FFTW_EXTRAFLAGS="${FFTW_EXTRAFLAGS} --enable-sse"
  fi
  ./configure --enable-static ${FFTW_EXTRAFLAGS} --enable-single --disable-shared --disable-debug --prefix=${PREFIX}
  make
  make install
  make clean
  touch build-done
  cd ..
fi

}

# ---------------------------------------------------------------------------------------------------------------------
# build base libs

# cleanup

if [ $(clang -v  2>&1 | grep version | cut -d' ' -f4 | cut -d'.' -f1) -lt 11 ]; then
  export ARCH=32
  build_base
fi

export ARCH=64
build_base

# ---------------------------------------------------------------------------------------------------------------------
# set flags for qt stuff

export PREFIX=${TARGETDIR}/carla
export PATH=${PREFIX}/bin:/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin
export PKG_CONFIG_PATH=${PREFIX}/lib/pkgconfig
export PKG_CONFIG=${TARGETDIR}/carla64/bin/pkg-config

export CFLAGS="-O3 -mtune=generic -msse -msse2 -fPIC -DPIC -DNDEBUG -I${PREFIX}/include -mmacosx-version-min=10.12"
export LDFLAGS="-L${PREFIX}/lib -stdlib=libc++"

if [ "${MACOS_UNIVERSAL}" -eq 1 ]; then
    export CFLAGS="${CFLAGS} -arch x86_64 -arch arm64 -Wno-unused-command-line-argument"
    export LDFLAGS="${LDFLAGS} -arch x86_64 -arch arm64"
else
    export CFLAGS="${CFLAGS} -mfpmath=sse -m${ARCH}"
    export LDFLAGS="${LDFLAGS} -m${ARCH}"
fi

export CXXFLAGS="${CFLAGS} -std=gnu++11 -stdlib=libc++"

export MAKE=/usr/bin/make

# ---------------------------------------------------------------------------------------------------------------------
# qt5-base download

if [ ! -d qtbase-everywhere-src-${QT5_VERSION} ]; then
  curl -L http://download.qt.io/archive/qt/${QT5_MVERSION}/${QT5_VERSION}/submodules/qtbase-everywhere-src-${QT5_VERSION}.tar.xz -o qtbase-everywhere-src-${QT5_VERSION}.tar.xz
  /opt/local/bin/7z x qtbase-everywhere-src-${QT5_VERSION}.tar.xz
  /opt/local/bin/7z x qtbase-everywhere-src-${QT5_VERSION}.tar
fi

# ---------------------------------------------------------------------------------------------------------------------
# qt5-base (64bit, shared, framework)

if [ ! -f qtbase-everywhere-src-${QT5_VERSION}/build-done ]; then
  cd qtbase-everywhere-src-${QT5_VERSION}
  if [ ! -f configured ]; then
    sed -i -e "s/QT_MAC_SDK_VERSION_MIN = 10.13/QT_MAC_SDK_VERSION_MIN = 10.12/" mkspecs/common/macx.conf
    if [ "${MACOS_UNIVERSAL}" -eq 1 ]; then
      sed -i -e "s/QMAKE_APPLE_DEVICE_ARCHS = x86_64/QMAKE_APPLE_DEVICE_ARCHS = arm64 x86_64/" mkspecs/common/macx.conf
      QT5_EXTRAFLAGS="-no-sse2"
    else
      QT5_EXTRAFLAGS="-sse2"
    fi
    chmod +x configure
    ./configure -release -shared -opensource -confirm-license -platform macx-clang -framework \
                -prefix ${PREFIX} -plugindir ${PREFIX}/lib/qt5/plugins -headerdir ${PREFIX}/include/qt5 \
                -pkg-config -force-pkg-config -strip \
                ${QT5_EXTRAFLAGS} -no-sse3 -no-ssse3 -no-sse4.1 -no-sse4.2 -no-avx -no-avx2 -no-avx512 \
                -no-mips_dsp -no-mips_dspr2 \
                -no-pch -pkg-config \
                -make libs -make tools \
                -nomake examples -nomake tests \
                -no-compile-examples \
                -gui -widgets \
                -no-dbus \
                -no-glib -qt-pcre \
                -no-journald -no-syslog -no-slog2 \
                -no-openssl -no-securetransport -no-sctp -no-libproxy \
                -no-cups -no-fontconfig -qt-freetype -no-harfbuzz -no-gtk -opengl desktop -qpa cocoa \
                -no-directfb -no-eglfs -no-xcb -no-xcb-xlib \
                -no-evdev -no-libinput -no-mtdev \
                -no-gif -no-ico -qt-libpng -qt-libjpeg \
                -qt-sqlite
    touch configured
  fi
  make ${MAKE_ARGS}
  make install
  ln -s ${PREFIX}/lib/QtCore.framework/Headers    ${PREFIX}/include/qt5/QtCore
  ln -s ${PREFIX}/lib/QtGui.framework/Headers     ${PREFIX}/include/qt5/QtGui
  ln -s ${PREFIX}/lib/QtWidgets.framework/Headers ${PREFIX}/include/qt5/QtWidgets
  touch build-done
  cd ..
fi

# ---------------------------------------------------------------------------------------------------------------------
# qt5-mac-extras

if [ ! -d qtmacextras-everywhere-src-${QT5_VERSION} ]; then
  curl -L http://download.qt.io/archive/qt/${QT5_MVERSION}/${QT5_VERSION}/submodules/qtmacextras-everywhere-src-${QT5_VERSION}.tar.xz -o qtmacextras-everywhere-src-${QT5_VERSION}.tar.xz
  /opt/local/bin/7z x qtmacextras-everywhere-src-${QT5_VERSION}.tar.xz
  /opt/local/bin/7z x qtmacextras-everywhere-src-${QT5_VERSION}.tar
fi

if [ ! -f qtmacextras-everywhere-src-${QT5_VERSION}/build-done ]; then
  cd qtmacextras-everywhere-src-${QT5_VERSION}
  qmake
  make ${MAKE_ARGS}
  make install
  touch build-done
  cd ..
fi

# ---------------------------------------------------------------------------------------------------------------------
# qt5-svg

if [ ! -d qtsvg-everywhere-src-${QT5_VERSION} ]; then
  curl -L http://download.qt.io/archive/qt/${QT5_MVERSION}/${QT5_VERSION}/submodules/qtsvg-everywhere-src-${QT5_VERSION}.tar.xz -o qtsvg-everywhere-src-${QT5_VERSION}.tar.xz
  /opt/local/bin/7z x qtsvg-everywhere-src-${QT5_VERSION}.tar.xz
  /opt/local/bin/7z x qtsvg-everywhere-src-${QT5_VERSION}.tar
fi

if [ ! -f qtsvg-everywhere-src-${QT5_VERSION}/build-done ]; then
  cd qtsvg-everywhere-src-${QT5_VERSION}
  qmake
  make ${MAKE_ARGS}
  make install
  touch build-done
  cd ..
fi

# ---------------------------------------------------------------------------------------------------------------------
# python

if [ ! -d Python-${PYTHON_VERSION} ]; then
  /opt/local/bin/aria2c https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tgz
  tar -xf Python-${PYTHON_VERSION}.tgz
fi

if [ ! -f Python-${PYTHON_VERSION}/build-done ]; then
  cd Python-${PYTHON_VERSION}
  if [ "${MACOS_UNIVERSAL}" -ne 1 ]; then
    sed -i -e "s/#zlib zlibmodule.c/zlib zlibmodule.c/" Modules/Setup.dist
  fi
  ./configure --prefix=${PREFIX} ${PYTHON_EXTRAFLAGS} --enable-optimizations --enable-shared
  make
  make install
  touch build-done
  cd ..
fi

# ---------------------------------------------------------------------------------------------------------------------
# sip

if [ ! -d sip-${SIP_VERSION} ]; then
  /opt/local/bin/aria2c https://files.kde.org/krita/build/dependencies/sip-${SIP_VERSION}.tar.gz
  tar -xf sip-${SIP_VERSION}.tar.gz
fi

if [ ! -f sip-${SIP_VERSION}/build-done ]; then
  cd sip-${SIP_VERSION}
  python3 configure.py --sip-module PyQt5.sip
  make ${MAKE_ARGS} CFLAGS="${CFLAGS}" CXXFLAGS="${CXXFLAGS}" LIBS="${LDFLAGS}"
  make install
  touch build-done
  cd ..
fi

# ---------------------------------------------------------------------------------------------------------------------
# pyqt5

if [ ! -d PyQt5_gpl-${PYQT5_VERSION} ]; then
  /opt/local/bin/aria2c https://files.kde.org/krita/build/dependencies/PyQt5_gpl-${PYQT5_VERSION}.tar.gz
  tar -xf PyQt5_gpl-${PYQT5_VERSION}.tar.gz
fi

if [ ! -f PyQt5_gpl-${PYQT5_VERSION}/build-done ]; then
  cd PyQt5_gpl-${PYQT5_VERSION}
  python3 configure.py --concatenate --confirm-license -c
  make ${MAKE_ARGS}
  make install
  touch build-done
  cd ..
fi

# ---------------------------------------------------------------------------------------------------------------------
# pyliblo

if [ ! -d pyliblo-${PYLIBLO_VERSION} ]; then
  /opt/local/bin/aria2c http://das.nasophon.de/download/pyliblo-${PYLIBLO_VERSION}.tar.gz
  tar -xf pyliblo-${PYLIBLO_VERSION}.tar.gz
fi

if [ ! -f pyliblo-${PYLIBLO_VERSION}/build-done ]; then
  cd pyliblo-${PYLIBLO_VERSION}
  if [ ! -f patched ]; then
    patch -p1 -i ../../patches/pyliblo-python3.7.patch
    touch patched
  fi
  env CFLAGS="${CFLAGS} -I${TARGETDIR}/carla64/include" LDFLAGS="${LDFLAGS} -L${TARGETDIR}/carla64/lib" \
  python3 setup.py build
  python3 setup.py install --prefix=${PREFIX}
  touch build-done
  cd ..
fi

# ---------------------------------------------------------------------------------------------------------------------
# setuptools-scm

if [ ! -d setuptools_scm-${SETUPTOOLS_SCM_VERSION} ]; then
  /opt/local/bin/aria2c https://files.pythonhosted.org/packages/ed/b6/979bfa7b81878b2b4475dde092aac517e7f25dd33661796ec35664907b31/setuptools_scm-${SETUPTOOLS_SCM_VERSION}.tar.gz
  tar -xf setuptools_scm-${SETUPTOOLS_SCM_VERSION}.tar.gz
fi

if [ ! -f setuptools_scm-${SETUPTOOLS_SCM_VERSION}/build-done ]; then
  cd setuptools_scm-${SETUPTOOLS_SCM_VERSION}
  python3 setup.py build
  python3 setup.py install --prefix=${PREFIX}
  touch build-done
  cd ..
fi

# ---------------------------------------------------------------------------------------------------------------------
# toml

if [ ! -d toml-${TOML_VERSION} ]; then
  /opt/local/bin/aria2c https://files.pythonhosted.org/packages/be/ba/1f744cdc819428fc6b5084ec34d9b30660f6f9daaf70eead706e3203ec3c/toml-${TOML_VERSION}.tar.gz
  tar -xf toml-${TOML_VERSION}.tar.gz
fi

if [ ! -f toml-${TOML_VERSION}/build-done ]; then
  cd toml-${TOML_VERSION}
  python3 setup.py build
  python3 setup.py install --prefix=${PREFIX}
  touch build-done
  cd ..
fi

# ---------------------------------------------------------------------------------------------------------------------
# zipp

if [ ! -d zipp-${ZIPP_VERSION} ]; then
  /opt/local/bin/aria2c https://files.pythonhosted.org/packages/ce/b0/757db659e8b91cb3ea47d90350d7735817fe1df36086afc77c1c4610d559/zipp-${ZIPP_VERSION}.tar.gz
  tar -xf zipp-${ZIPP_VERSION}.tar.gz
fi

if [ ! -f zipp-${ZIPP_VERSION}/build-done ]; then
  cd zipp-${ZIPP_VERSION}
  python3 setup.py build
  python3 setup.py install --prefix=${PREFIX}
  touch build-done
  cd ..
fi

# ---------------------------------------------------------------------------------------------------------------------
# importlib_metadata

if [ ! -d importlib_metadata-${IMPORTLIB_METADATA_VERSION} ]; then
  /opt/local/bin/aria2c https://files.pythonhosted.org/packages/3f/a8/16dc098b0addd1c20719c18a86e985be851b3ec1e103e703297169bb22cc/importlib_metadata-${IMPORTLIB_METADATA_VERSION}.tar.gz
  tar -xf importlib_metadata-${IMPORTLIB_METADATA_VERSION}.tar.gz
fi

if [ ! -f importlib_metadata-${IMPORTLIB_METADATA_VERSION}/build-done ]; then
  cd importlib_metadata-${IMPORTLIB_METADATA_VERSION}
  python3 setup.py build
  python3 setup.py install --prefix=${PREFIX}
  touch build-done
  cd ..
fi

# ---------------------------------------------------------------------------------------------------------------------
# cxfreeze

if [ ! -d cx_Freeze-${CXFREEZE_VERSION} ]; then
  /opt/local/bin/aria2c https://github.com/anthony-tuininga/cx_Freeze/archive/${CXFREEZE_VERSION}.tar.gz
  tar -xf cx_Freeze-${CXFREEZE_VERSION}.tar.gz
fi

if [ ! -f cx_Freeze-${CXFREEZE_VERSION}/build-done ]; then
  cd cx_Freeze-${CXFREEZE_VERSION}
  sed -i -e 's/, use_builtin_types=False//' cx_Freeze/macdist.py
  sed -i -e 's/"python%s.%s"/"python%s.%sm"/' setup.py
  sed -i -e 's/extra_postargs=extraArgs,/extra_postargs=extraArgs+os.getenv("LDFLAGS").split(),/' setup.py
  python3 setup.py build
  python3 setup.py install --prefix=${PREFIX}
  touch build-done
  cd ..
fi

# ---------------------------------------------------------------------------------------------------------------------
