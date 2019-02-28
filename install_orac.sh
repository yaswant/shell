#!/bin/bash
# Build ORAC
#   The script assumes that all dependent libraries are installed in LIB_ROOT.
#
#   Dependent libraries tars    : $LIB_ROOT
#   Dependent libraries source  : $LIB_ROOT/extract
#   Dependent libraries path    : $LIB_ROOT/orac-deps
#   ORAC library path           : $LIB_ROOT/orac
#
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
# 2018-06-29 yaswant.pradhan, adam.povey
# -----------------------------------------------------------------------------

LIB_ROOT=$SCRATCH/ORAC
INSTALL_DEPS=0
FORCE=0
DEBUG=0
START=$(date -u)

# -----------------------------------------------------------------------------
usage(){
cat <<EOF
$(basename $0) [OPTIONS]
  Options:
    -h, --help, -?
        Show this message.

    -p, --prefix <path>
        Root path (LIB_ROOT) where the libraries will be installed.

    -i, --install-dependencies
        Instsallation of ORAC requires several other libraries pre-installed.
        This option will install those libraries in LIB_ROOT (-p option),
        before building orac. Default is 0 (false).
    -d, --debug
        Compile orac in debug mode.
    -f, --force
        Force a full clean build of all libraries.
EOF
}
# Parse command-line arguments
while [[ $1 == -* ]]; do
    case "$1" in
        -h|--help|-\?) usage |more; exit 0 ;;
        -p|--prefix) export LIB_ROOT="$2"; shift 2 ;;
        -i|--install-dependencies) INSTALL_DEPS=1; shift 1 ;;
        -d|--debug) DEBUG=1; shift 1 ;;
        -f|--force) FORCE=1; shift 1 ;;
        --) shift; break ;;
        -*) echo "invalid option: $1" 1>&2; usage |more; exit 1 ;;
    esac
done
# Install ORAC dependencies if specified
if (( $INSTALL_DEPS )); then
    echo "Installing ORAC dependencies..."
    install_orac_depends.sh \
        -d "$LIB_ROOT" \
        -e "$LIB_ROOT/extract" \
        -i "$LIB_ROOT/orac-deps" \
        -f "$FORCE" \
        || exit
fi

cd $LIB_ROOT
(( $FORCE )) \
    && echo -e '\norac: clean old repository\n' && rm -rf $LIB_ROOT/orac
echo "Installing orac in $LIB_ROOT ..."
# -----------------------------------------------------------------------------


# Clone ORAC git repository if not already exist
if [ -d orac ]; then
    cd orac
    git pull
    make clean clean_parser
else
    # git clone git@github.com:ORAC-CC/orac.git
    git clone https://github.com/ORAC-CC/orac.git
    cd orac || exit

    # Generate directories for compiled object files
    mkdir common/obj
    mkdir pre_processing/obj
    mkdir src/obj
    mkdir post_processing/obj
    mkdir derived_products/broadband_fluxes/obj
    mkdir derived_products/broadband_fluxes/bugsrad/obj

    # Generate lib and arch files
    cat <<EOF > config/lib.inc

# Met Office locally installed required libraries.

LIB_ROOT = ${LIB_ROOT}

# EMOS
EMOSLIB = \$(LIB_ROOT)/orac-deps/emos/lib

# HDF-EOS
EOSLIB = \$(LIB_ROOT)/orac-deps/hdfeos/lib
EOSINCLUDE = \$(LIB_ROOT)/orac-deps/hdfeos/include

# EPR_API
EPR_APILIB =
EPR_APIINCLUDE =

# Fu and Liou
FULIOULIB =
FULIOUINCLUDE =

# ECCODES (opens GRIB files)
GRIBLIB = \$(LIB_ROOT)/orac-deps/eccodes/lib
GRIBINCLUDE = \$(LIB_ROOT)/orac-deps/eccodes/include

# HDF4 has to be compiled without the HDF4 versions of NetCDF APIs.
HDFLIB = \$(LIB_ROOT)/orac-deps/hdf4/lib
HDFINCLUDE = \$(LIB_ROOT)/orac-deps/hdf4/include

# HDF5
HDF5LIB = \$(LIB_ROOT)/orac-deps/hdf5/lib
HDF5INCLUDE = \$(LIB_ROOT)/orac-deps/hdf5/include

# NetCDF
NCDFLIB = \$(LIB_ROOT)/orac-deps/netcdf/lib
NCDFINCLUDE = \$(LIB_ROOT)/orac-deps/netcdf/include
NCDF_FORTRAN_LIB = \$(LIB_ROOT)/orac-deps/ncdff/lib
NCDF_FORTRAN_INCLUDE = \$(LIB_ROOT)/orac-deps/ncdff/include

# Numerical Recipes in Fortran 77
NRLIB =
NRINCLUDE =

# RTTOV
RTTOVLIB = \$(LIB_ROOT)/orac-deps/rttov/lib
RTTOVINCLUDE = \$(LIB_ROOT)/orac-deps/rttov/include
RTTOVMODULE = \$(LIB_ROOT)/orac-deps/rttov/mod

# Himawari_HSD_Reader
HIMAWARI_HSD_READER_LIB =
HIMAWARI_HSD_READER_INCLUDE =

# seviri_util
SEVIRI_UTIL_LIB = \$(LIB_ROOT)/orac-deps/seviri_util
SEVIRI_UTIL_INCLUDE = \$(LIB_ROOT)/orac-deps/seviri_util

SZLIB = \$(LIB_ROOT)/orac-deps/szip/lib

# Set up libraries and includes
LIBS = -L\$(EMOSLIB) -lemosR64 -lemos -lfftw3 \\
       -L\$(EOSLIB) -lhdfeos -lGctp \\
       -L\$(GRIBLIB) -leccodes_f90 -leccodes \\
       -L\$(HDFLIB) -lmfhdf -ldf \\
       -L\$(NCDF_FORTRAN_LIB) -lnetcdff \\
       -L\$(NCDFLIB) -lnetcdf \\
       -L\$(RTTOVLIB) -lrttov12_coef_io -lrttov12_emis_atlas -lrttov12_hdf \\
                     -lrttov12_parallel -lrttov12_main -lrttov12_other \\
       -L\$(HDF5LIB) -lhdf5 -lhdf5_fortran -lhdf5_hl -lhdf5hl_fortran \\
       -L\$(SZLIB) -lsz \\
       -ljpeg -lm -lz -lstdc++ -lblas -llapack

INC = -I./ \\
      -I\$(EOSINCLUDE) \\
      -I\$(GRIBINCLUDE) \\
      -I\$(HDFINCLUDE) \\
      -I\$(HDF5INCLUDE) \\
      -I\$(NCDFINCLUDE) \\
      -I\$(NCDF_FORTRAN_INCLUDE)  \\
      -I\$(RTTOVINCLUDE) \\
      -I\$(RTTOVMODULE)

CINC = -I./


# Configuration options

# Uncomment if you want to enable OpenMP for RTTOV computations.
INC  += -DINCLUDE_RTTOV_OPENMP

# Uncomment if ATSR support is desired.
#LIBS += -L\$(EPR_APILIB) -lepr_api
#INC  += -I\$(EPR_APIINCLUDE)
#CINC += -I\$(EPR_APIINCLUDE)

# Uncomment if Numerical Recipes is available for cubic spline profile
# interpolation and bilinear LUT interpolation.
#LIBS += -L\$(NRLIB) -lnr
#INC  += -I\$(NRINCLUDE) -DINCLUDE_NR

# Uncomment if Fu_Liou support is desired for broadband fluxes.
#LIBS += -L\$(FULIOULIB) -lEd3Fu_201212
#INC  += -I\$(FULIOUINCLUDE) -DINCLUDE_FU_LIOU_SUPPORT

# Uncomment if Himawari support is desired.
#LIBS += -L\$(HIMAWARI_HSD_READER_LIB) -lhimawari_util
#INC  += -I\$(HIMAWARI_HSD_READER_INCLUDE) -DINCLUDE_HIMAWARI_SUPPORT

# Uncomment if SEVIRI support is desired.
LIBS += -L\$(SEVIRI_UTIL_LIB) -lseviri_util
INC  += -I\$(SEVIRI_UTIL_INCLUDE) -DINCLUDE_SEVIRI_SUPPORT
EOF

#    cat <<EOF > config/arch.ifort.inc
#     cat <<EOF > config/arch.gfortran.inc
# # Directory for object files
# OBJS = obj

# # Define Fortran 77 compiler
# #F77 = ifort
# F77 = gfortran

# # Define Fortran 90 compiler
# #F90 = ifort
# F90 = gfortran

# # Define C compiler
# CC = gcc

# # Define C++ compiler
# CXX = gcc

# # Set Fortran 77 compiler flags
# F77FLAGS = -O3 -cpp -g

# # Set Fortran 90 compiler flags
# FFLAGS   = -O3 -cpp -g
# # Uncomment if OpenMP support is desired (-openmp for old compilers)
# #FFLAGS  += -qopenmp
# FFLAGS  += -fopenmp

# #LFLAGS = -lifcore -qopenmp
# LFLAGS = -fopenmp

# # Set C compiler  flags
# CFLAGS = -O3 -g

# AUXFLAGS = -module \$(OBJS)

# # Set Bison/Flex parser flags
# FLEXFLAGS =
# BISONFLAGS =
# EOF

    # A hack required to deal with an old version of ifort
#    cat <<EOF > patches/IntCTP
#diff --git a/src/IntCTP.F90 b/src/IntCTP.F90
#index 7036c46..4077ec6 100644
#--- a/src/IntCTP.F90
#+++ b/src/IntCTP.F90
#@@ -62,9 +62,10 @@
#
# subroutine Int_CTP(SPixel, Ctrl, BT, CTP, status)
#
#+   use common_constants_m, only : g_wmo
#    use Ctrl_m
#    use Int_Routines_m
#-   use ORAC_Constants_m, only : g_wmo, XMDADBounds
#+   use ORAC_Constants_m, only : XMDADBounds
#    use planck_m
#    use SAD_Chan_m
#EOF
#    patch src/IntCTP.F90 patches/IntCTP
fi

# Prepare build environment
#export ORAC_ARCH=$PWD/config/arch.ifort.inc
export ORAC_ARCH=$PWD/config/arch.gfortran.inc
export ORAC_LIB=$PWD/config/lib.inc

if (( $DEBUG )); then
    echo -e "\norac: compile in debug-mode\n"
    # Create $PWD/config/arch.ifort.debug.inc
    ORAC_ARCH_DEBUG=${ORAC_ARCH%%.inc*}.debug.inc
    F77FLAGS='F77FLAGS = -O3 -cpp -g'
    sed $ORAC_ARCH \
        -e "s:F77FLAGS = -O3 -cpp -g:F77FLAGS = -cpp -g:" \
        -e "s:FFLAGS   = -O3 -cpp -g:FFLAGS   = -cpp -g -C -traceback -assume protect_parens -DDEBUG:" \
        -e "s:CFLAGS = -O3 -g:CFLAGS = -g -Wall:" > \
        $ORAC_ARCH_DEBUG

    export ORAC_ARCH=$ORAC_ARCH_DEBUG
fi

make -j7

echo "ORAC build stared on    $START"
echo "ORAC build completed on $(date -u)"
