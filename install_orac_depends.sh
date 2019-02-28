#!/bin/bash
#
# Install third-party libraries required for ORAC.
#
# This script will attempt to install the required libraries listed below,
# except RTTOV, on a Linux system with pre-installed Intel FORTRAN and GCC
# compilers and cURL.  Active internet connection is required to get the
# library sources.  RTTOV can be downloaded separately from NWP-SAF (free, but
# requires user registration) website
#   https://www.nwpsaf.eu/site/software/rttov/download
#
# szip: extended-Rice lossless compression algorithm (required for HDF).
# hdf5: data model, library, and file format for storing and managing data.
# hdf4: library and multi-object file format for storing and managing data
#       between machines. Very different technology than HDF5.
# hdf-eos2: HDF-EOS2 data format is standard HDF4 with ECS conventions,
#       data types, and metadata added.
# netcdf4: essentially it is the HDF5 data format, with some restrictions.
#       Data model adds Groups and user-defined Types to the classic netCDF
#       data model, but backward compatibility is preserved.
# netcdf-fortran: netCDF FORTRAN libraries.
# rttov: very fast radiative transfer model for passive visible, infra-red and
#       microwave downward-viewing satellite radiometers, spectrometers and
#       interferometers.
# seviri_util: is a C library that provides functionality to read, write, and
#       pre-process SEVIRI image data in the Native SEVIRI Level 1.5 format
#       distributed by U-MARF and the HRIT format from the MSG dissemination
#       service (EUMETCast and direct).
# eccodes: package developed by ECMWF which provides an application programming
#       interface and a set of tools for decoding and encoding messages in the
#       following formats:
#           WMO FM-92 GRIB edition 1 and edition 2
#           WMO FM-94 BUFR edition 3 and edition 4
#           WMO GTS abbreviated header (only decoding).
# emos: interpolation library (EMOSLIB) includes interpolation software and
#       BUFR & CREX encoding/decoding routines. It is used by the ECMWF
#       meteorological archival and retrieval system (MARS) and also by the
#       ECMWF workstation MetView.
#
# Met Office Notes:
#   1. For latest ifort compiler source prg_ifort-vsn, eg:
#       . prg_ifort-17.0_64
#   OR.
#       module unload ifort && module load ifort/17.0_64
#
#   2. For latest gcc/gfortran compilers load appropriate libraried:
#       module load libraries/gcc gcc
#
#
# 2018-06-28: Adam Povey, Yaswant Pradhan
# -----------------------------------------------------------------------------

set -e

# Default settings
# Compilers should be set-up by the shell
# export FC=ifort
export FC=gfortran
export CC=gcc
export CXX=g++
export CMAKE=cmake

# Folder where TAR files are stored locally
# Can be deleted after successful installation
STORE=/project/SatImagery/dust/orac/orac_lib_stock

# Folder where source code will be extracted and stored
# Can be deleted after successful installation
EXTRACT=/project/SatImagery/dust/orac/extract

# Folder where libraries will be installed
INSTALL=/project/SatImagery/dust/orac/orac-deps

# Set to 1 if libraries should be tested after installation
TEST=0
FORCE=0
START=$(date -u)

usage(){
cat <<EOF
$(basename $0) [OPTIONS]
  Options:
    -h, --help, -?
        Show this message.

    -d, --downloads <path>
        Local repository path where source codes for ORAC dependencies are
        stored. If the source code (tars) are missing, this script will attempt
        to download from the internet. This directory can be deleted after
        successful installation of all dependent libraries.

    -e, --extract-dir <path>
        Directory where the source codes will be extracted from local archive
        (i.e. downloads path). This directory can be deleted after successful
        installation of all dependent libraries.

    -f, --force
        Force full build of all dependencies. This will remove existing
        EXTRACT and INSTALL directories

    -i, --install-dir <path>
        Directory where the libraries will be installed.

    -t, --test
        Switch to test libraries after installation.
EOF
}
# Parse command-line arguments
while [[ $1 == -* ]]; do
    case "$1" in
        -h|--help|-\?) usage |more; exit 0;;
        -d|--downloads) STORE="$2"; shift 2;;
        -e|--extract-dir) EXTRACT="$2"; shift 2;;
        -i|--install-dir) INSTALL="$2"; shift 2;;
        -f|--force) FORCE=1; shift 1;;
        -t|--test-install) TEST=1; shift 1;;
        --) shift; break;;
        -*) echo "invalid option: $1" 1>&2; usage |more; exit 1;;
    esac
done

echo -e "\nROOT_DIR=$STORE"
echo "EXTRACT_DIR=$EXTRACT"
echo -e "INSTALL_DIR=$INSTALL\n"
read -p "Proceed with installation (y|n)?: " choice
[[ $choice != y ]] && { echo "Aborted."; exit 1; }

(( $FORCE )) && rm -rf $EXTRACT $INSTALL
[ ! -d $STORE ] && mkdir -p $STORE
[ ! -d $EXTRACT ] && mkdir -p $EXTRACT
[ ! -d $INSTALL ] && mkdir -p $INSTALL

# -----------------------------------------------------------------------------
# 1. SZIP: Where to get the source?
# https://support.hdfgroup.org/ftp/lib-external/szip/2.1.1/src/
# szip-2.1.1.tar.gz
# -----------------------------------------------------------------------------
PROG=szip-2.1.1
SZIP_DIR=$INSTALL/szip
if [ ! -d "$SZIP_DIR" ] || (( $FORCE )) ; then
    cd $EXTRACT
    # Download...
    if [ ! -f $STORE/$PROG.tar.gz ]; then
        echo "Downloading $PROG ..."
        curl -C - -o $STORE/$PROG.tar.gz -L https://bit.ly/2IRdOXS
    fi
    # Extract...
    tar -xzf $STORE/$PROG.tar.gz
    cd $PROG
    [ ! -d $SZIP_DIR ] && mkdir $SZIP_DIR
    echo "Installing $PROG ..."
    CFLAGS="-fPIC -O3 -w" ./configure --prefix=$SZIP_DIR
    make
    if (( $TEST )); then
        make check
    fi
    make install
    # rm -rf $EXTRACT/$PROG
fi
export LD_LIBRARY_PATH=$SZIP_DIR/lib:$LD_LIBRARY_PATH


# -----------------------------------------------------------------------------
# 2. HDF5: Where to get the source?
# https://www.hdfgroup.org/downloads/hdf5/source-code/
# https://www.hdfgroup.org/package/source-gzip-2/?wpdmdl=
# 11810&refresh=5b3baeefa7e151530638063
# -----------------------------------------------------------------------------
PROG=hdf5-1.10.2
HDF5_DIR=$INSTALL/hdf5
if [ ! -d "$HDF5_DIR" ] || (( $FORCE )) ; then
    cd $EXTRACT
    if [ ! -f $STORE/$PROG.tar.gz ]; then
        echo "Downloading $PROG ..."
        curl -C - -o $STORE/$PROG.tar.gz -L https://bit.ly/2z3It4R
        # wget -nd -O $STORE/$PROG.tar.gz https://bit.ly/2z3It4R
    fi
    tar -xzf $STORE/$PROG.tar.gz
    cd $PROG
    [ ! -d $HDF5_DIR ] && mkdir $HDF5_DIR
    echo "Installing $PROG ..."
    CFLAGS="-fPIC -w" CXXFLAGS="-fPIC -w" FFLAGS="-fPIC -w" \
        ./configure --prefix=$HDF5_DIR --enable-build-mode=production \
        --enable-fortran --enable-cxx --with-szlib=$SZIP_DIR
    make
    if (( $TEST )); then
        make check
    fi
    make install
    if (( $TEST )); then
        make check-install
    fi
    # rm -rf $EXTRACT/$PROG
fi
export LD_LIBRARY_PATH=$HDF5_DIR/lib:$LD_LIBRARY_PATH


# -----------------------------------------------------------------------------
# 3. HDF4: Where to get the source?
# https://support.hdfgroup.org/release4/obtain.html
# https://support.hdfgroup.org/ftp/HDF/HDF_Current/src/hdf-4.2.13.tar
# -----------------------------------------------------------------------------
PROG=hdf-4.2.13
HDF4_DIR=$INSTALL/hdf4
if [ ! -d "$HDF4_DIR" ] || (( $FORCE )) ; then
    cd $EXTRACT
    if [ ! -f $STORE/$PROG.tar ]; then
        echo "Downloading $PROG ..."
        curl -C - -o $STORE/$PROG.tar -L https://bit.ly/2NnI9Ru
    fi
    tar -xf $STORE/$PROG.tar
    cd $PROG
    [ ! -d $HDF4_DIR ] && mkdir $HDF4_DIR
    echo "Installing $PROG ..."
    F77=$FC CFLAGS="-fPIC -w" CXXFLAGS="-fPIC -w" FFLAGS="-fPIC -w" \
        ./configure --prefix=$HDF4_DIR --disable-netcdf \
        --with-szlib=$SZIP_DIR
    make
    if (( $TEST )); then
        make check
    fi
    make install
    if (( $TEST )); then
        make installcheck
    fi
    # rm -rf $EXTRACT/$PROG
fi
export LD_LIBRARY_PATH=$HDF4_DIR/lib:$LD_LIBRARY_PATH


# -----------------------------------------------------------------------------
# 4. HDF-EOS2: Where to get the source?
# ftp://edhs1.gsfc.nasa.gov/edhs/hdfeos/latest_release/
# ftp://edhs1.gsfc.nasa.gov/edhs/hdfeos/latest_release/HDF-EOS2.20v1.00.tar.Z
# ftp://edhs1.gsfc.nasa.gov/edhs/hdfeos/latest_release/
# HDF-EOS2.20v1.00_TestDriver.tar.Z
# -----------------------------------------------------------------------------
PROG=HDF-EOS2.20
EOS_DIR=$INSTALL/hdfeos
if [ ! -d "$EOS_DIR" ] || (( $FORCE )) ; then
    cd $EXTRACT
    if [ ! -f $STORE/${PROG}v1.00.tar.Z ]; then
        echo "Downloading $PROG ..."
        curl -C - -o $STORE/${PROG}v1.00.tar.Z -L https://go.nasa.gov/2KIYSgm

        curl -C - -o $STORE/${PROG}v1.00_TestDriver.tar.Z \
            -L https://go.nasa.gov/2MNQJrw
    fi
    tar -xzf $STORE/${PROG}v1.00.tar.Z
    if (( $TEST )); then
        tar -xzf $STORE/${PROG}v1.00_TestDriver.tar.Z
    fi
    mv $EXTRACT/hdfeos $EXTRACT/$PROG
    cd $PROG
    [ ! -d $EOS_DIR ] && mkdir $EOS_DIR
    echo "Installing $PROG ..."
    FC=$FC FFLAGS="-fPIC -O0 -w" CFLAGS="-fPIC -Df2cFortran -O0 -w" \
        CXXFLAGS="-fPIC -Df2cFortran -O0 -w" CC=$HDF4_DIR/bin/h4cc ./configure \
        --prefix=$EOS_DIR --libdir=$EOS_DIR/lib --with-hdf4=$HDF4_DIR \
        --enable-install-include --with-szlib=$SZIP_DIR
    make
    if (( $TEST )); then
        # Fails as:
        # " No rule to make target `testswath77.o', needed by `testswath_f77'."
        make check
    fi
    make install
    if (( $TEST )); then
        make installcheck
    fi
    # rm -rf $EXTRACT/$PROG
fi
export LD_LIBRARY_PATH=$EOS_DIR/lib:$LD_LIBRARY_PATH


# -----------------------------------------------------------------------------
# 5. NETCDF4: Where to get the source?
# https://www.unidata.ucar.edu/downloads/netcdf/index.jsp
# ftp://ftp.unidata.ucar.edu/pub/netcdf/netcdf-4.6.1.tar.gz
# -----------------------------------------------------------------------------
PROG=netcdf-4.6.1
NCDF4_DIR=$INSTALL/netcdf
if [ ! -d "$NCDF4_DIR" ] || (( $FORCE )) ; then
    cd $EXTRACT
    if [ ! -f $STORE/$PROG.tar.gz ]; then
        echo "Downloading $PROG ..."
        curl -C - -o $STORE/${PROG}.tar.gz -L https://bit.ly/2NlT5z0
    fi
    tar -xzf $STORE/$PROG.tar.gz
    cd $PROG
    [ ! -d $NCDF4_DIR ] && mkdir $NCDF4_DIR
    echo "Installing $PROG ..."
    FC=$FC FFLAGS="-fPIC -heap-arrays" \
        CFLAGS="-fPIC -I$HDF4_DIR/include -I$HDF5_DIR/include" \
        CPPFLAGS="-fPIC -I$HDF4_DIR/include -I$HDF5_DIR/include" \
        LDFLAGS="-L$HDF5_DIR/lib -L$HDF4_DIR/lib" ./configure \
        --prefix=$NCDF4_DIR --disable-dap
    if (( $TEST )); then
        # Fails as ncdump/ctest.c is empty
        make check
    fi
    make install
    # rm -rf $EXTRACT/$PROG
fi
export LD_LIBRARY_PATH=$NCDF4_DIR/lib:$LD_LIBRARY_PATH


# -----------------------------------------------------------------------------
# 6. NETCDF-FORTRAN: Where to get the source?
# https://www.unidata.ucar.edu/downloads/netcdf/index.jsp
# ftp://ftp.unidata.ucar.edu/pub/netcdf/netcdf-fortran-4.4.4.tar.gz
# -----------------------------------------------------------------------------
PROG=netcdf-fortran-4.4.4
NCDFDIR=$INSTALL/ncdff
if [ ! -d "$NCDFDIR" ] || (( $FORCE )) ; then
    cd $EXTRACT
    if [ ! -f $STORE/$PROG.tar.gz ]; then
        echo "Downloading $PROG ..."
        curl -C - -o $STORE/${PROG}.tar.gz -L https://bit.ly/2KQzRA8
    fi
    tar -xzf $STORE/$PROG.tar.gz
    cd $PROG
    [ ! -d $NCDFDIR ] && mkdir $NCDFDIR
    echo "Installing $PROG ..."
    FC=$FC FFLAGS="-fPIC" CFLAGS="-fPIC -I$NCDF4_DIR/include" \
        CPPFLAGS="-fPIC -I$NCDF4_DIR/include" LDFLAGS="-L$NCDF4_DIR/lib" \
        ./configure --prefix=$NCDFDIR
    if (( $TEST )); then
            # As previous
        make check
    fi
    make install
    # rm -rf $EXTRACT/$PROG
fi
export LD_LIBRARY_PATH=$NCDFDIR/lib:$LD_LIBRARY_PATH


# -----------------------------------------------------------------------------
# 7. RTTOV: Where to get the source?
# Locally /data/users/frhg/rttov122/rttov122.tar.gz OR from
# https://www.nwpsaf.eu/site/software/rttov/download/#Software
# -----------------------------------------------------------------------------
PROG=rttov-12.2
ARCH=$FC-openmp
RTTOV12_DIR=$INSTALL/rttov
if [ ! -d "$RTTOV12_DIR" ] || (( $FORCE )) ; then
    REL_PATH=`python -c "import os.path; print(os.path.relpath('$RTTOV12_DIR', '$EXTRACT/$PROG'))"`
    mkdir -p $EXTRACT/$PROG && cd $EXTRACT/$PROG
    if [ ! -f $STORE/$PROG.tar.gz ]; then
        echo "Linking RTTOV source from James Hocking's archive ..."
        ln -s /data/users/frhg/rttov122/rttov122.tar.gz $STORE/$PROG.tar.gz
    fi
    tar -xzf $STORE/$PROG.tar.gz
    cd src
    [ ! -d $RTTOV12_DIR ] && mkdir $RTTOV12_DIR
    echo "Installing $PROG ..."
    # Local Makefile
    FLINE='FFLAGS_HDF5  = -D_RTTOV_HDF $(FFLAG_MOD)$(HDF5_PREFIX)/include'
    LLINE='LDFLAGS_HDF5 = -L$(HDF5_PREFIX)/lib -lhdf5hl_fortran -lhdf5_hl -lhdf5_fortran -lhdf5 -lz'
    sed -i.bak ../build/Makefile.local \
        -e "s:path-to-hdf-install:$HDF5_DIR:" \
        -e "s:# $FLINE:$FLINE:" -e "s:# $LLINE:$LLINE:"
    ../build/Makefile.PL RTTOV_HDF=1 RTTOV_F2PY=1

    # for modern ifort compiler use -qopenmp
    sed -i.bak ../build/arch/$ARCH \
        -e "s:\-openmp:\-qopenmp:"

    make ARCH=$ARCH INSTALLDIR=$REL_PATH
    if (( $TEST )); then
        cd ../rttov_test
        # ulimit -s unlimited
        ./test_fwd.sh ARCH=$ARCH BIN=$REL_PATH/bin
        ./test_rttov12.sh ARCH=$ARCH BIN=$REL_PATH/bin
        ./test_solar.sh ARCH=$ARCH BIN=$REL_PATH/bin
        ./test_coef_io.sh ARCH=$ARCH BIN=$REL_PATH/bin
        ./test_coef_io_hdf.sh ARCH=$ARCH BIN=$REL_PATH/bin
    fi
    # rm -rf $EXTRACT/$PROG
fi

# -----------------------------------------------------------------------------
# SEVIRI_UTIL: Where to get the source?
# Direct pull from github github.com/gmcgarragh/seviri_util
# -----------------------------------------------------------------------------
PROG=seviri_util
SEVIRI_DIR=$INSTALL/seviri_util
if [ ! -d "$SEVIRI_DIR" ] || (( $FORCE )) ; then
    cd $EXTRACT
    echo "Downloading $PROG ..."
    git clone https://github.com/gmcgarragh/seviri_util
    cd $PROG
    [ ! -d $SEVIRI_DIR ] && mkdir $SEVIRI_DIR
    echo "Installing $PROG ..."
cat <<EOF > make.inc
# C compiler and C compiler flags

CC      = ${CC}
CCFLAGS = -O2

# Fortran compiler and Fortan compiler flags (required for the Fortran
# interface)
F90      = ${FC}
F90FLAGS = -O2

LINKS = -lm

# Uncomment to compile the Fortran interface and examples
OBJECTS          += seviri_util_f90.o
OPTIONAL_TARGETS += example_f90

# Uncomment to compile the IDL DLM interface and examples
# CCFLAGS          += -fPIC
# INCDIRS          += -I${HOME}/opt/exelis/idl/external
# OPTIONAL_TARGETS += seviri_util_dlm.so

# Uncomment to compile the Python interface and examples
# CCFLAGS          += -fPIC
# OPTIONAL_TARGETS += seviri_util.so

# Uncomment to compile optional utilities that may have external dependencies
# OPTIONAL_TARGETS += SEVIRI_util

# Include and lib directories for non standard locations required by SEVIRI_util
INCDIRS           += -I${HDF5_DIR}/include -I${NCDF4_DIR}/include
LIBDIRS           += -L${HDF5_DIR}/lib     -L${NCDF4_DIR}/lib
LINKS             += -lhdf5 -lnetcdf -ltiff -lm
EOF

    make all
    cp libseviri_util.a $SEVIRI_DIR/
    cp seviri_util.mod $SEVIRI_DIR/
    # rm -rf $EXTRACT/$PROG
fi

# -----------------------------------------------------------------------------
# ECCODES: Where to get the source?
# https://software.ecmwf.int/wiki/download/attachments/45757960/
# eccodes-2.8.0-Source.tar.gz?api=v2
# -----------------------------------------------------------------------------
PROG=eccodes-2.8.0-Source
ECCODES_DIR=$INSTALL/eccodes
if [ ! -d "$ECCODES_DIR" ] || (( $FORCE )) ; then
    cd $EXTRACT
    if [ ! -f $STORE/$PROG.tar.gz ]; then
        echo "Downloading $PROG..."
        curl -C - -o $STORE/$PROG.tar.gz -L https://bit.ly/2lPY52u
    fi
    tar -xzf $STORE/$PROG.tar.gz
    mkdir $PROG/build
    cd $PROG/build
    [ ! -d $ECCODES_DIR ] && mkdir $ECCODES_DIR
    echo "Installing $PROG ..."
    export CMAKE_PREFIX_PATH=$LD_LIBRARY_PATH
    $CMAKE .. -DCMAKE_INSTALL_PREFIX=$ECCODES_DIR -DCMAKE_Fortran_COMPILER=$FC \
        -DCMAKE_C_COMPILER=$CC -DENABLE_JPG=ON -DENABLE_FORTRAN=ON \
        -DENABLE_PYTHON=OFF
    make
    if (( $TEST )); then
        ctest
    fi
    make install
    # rm -rf $EXTRACT/$PROG
fi


# -----------------------------------------------------------------------------
# EMOS: Where to get the source?
# https://software.ecmwf.int/wiki/download/attachments/3473472/
# libemos-4.5.5-Source.tar.gz?api=v2
# -----------------------------------------------------------------------------
PROG=libemos-4.5.5-Source
EMOS_DIR=$INSTALL/emos
if [ ! -d "$EMOS_DIR" ] || (( $FORCE )) ; then
    cd $EXTRACT
    if [ ! -f $STORE/$PROG.tar.gz ]; then
        echo "Downloading $PROG ..."
        curl -C - -o $STORE/$PROG.tar.gz -L https://bit.ly/2u5xhyP
    fi
    tar -xzf $STORE/$PROG.tar.gz
    # Correct function which clashes with HDF-EOS
    cd $PROG/gribex
    mv handleLocalDefinitions.c handleLocalDefinitions.c.in
    sed 's/init\([E(,:]\)/initemos\1/' handleLocalDefinitions.c.in \
        > handleLocalDefinitions.c
    mv handleLocalDefinitions.h handleLocalDefinitions.h.in
    sed 's:init;:initemos;:' handleLocalDefinitions.h.in \
        > handleLocalDefinitions.h

    mkdir ../build
    cd ../build
    [ ! -d $EMOS_DIR ] && mkdir $EMOS_DIR
    echo "Installing $PROG ..."
    export CMAKE_PREFIX_PATH=$LD_LIBRARY_PATH
    # $CMAKE .. -DENABLE_GRIBEX_ABORT=OFF -DCMAKE_INSTALL_PREFIX=$EMOS_DIR \
    #     -DECCODES_PATH=$ECCODES_DIR -DFFTW_PATH=$FFTW_DIR \
    #     -DFFTW_USE_STATIC_LIBS=ON -DCMAKE_Fortran_COMPILER=$FC \
    #     -DCMAKE_C_COMPILER=$CC
    $CMAKE .. -DENABLE_GRIBEX_ABORT=OFF -DCMAKE_INSTALL_PREFIX=$EMOS_DIR \
        -DECCODES_PATH=$ECCODES_DIR -DCMAKE_Fortran_COMPILER=$FC \
        -DCMAKE_C_COMPILER=$CC
    make
    if (( $TEST )); then
        make test
    fi
    make install
    # rm -rf $EXTRACT/$PROG
fi

# -----------------------------------------------------------------------------
# Housekeep: Remove $EXTRACT directory
# -----------------------------------------------------------------------------
rm -rf $EXTRACT

echo -e "orac-deps: build stared    $START"
echo -e "orac-deps: build completed $(date -u)\n\n"
