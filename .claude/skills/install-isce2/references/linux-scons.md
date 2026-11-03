# Linux: build from source with scons

**scons + conda does not work on macOS.** Use cmake there.
Last tested on Miniconda, Python 3.13, GNU gcc/g++/gfortran 13.3 (April 2025). These two
patches may be needed if they haven't been merged yet: https://github.com/isce-framework/isce2/pull/946/commits

isce2 installs into a separate directory, `$ISCE_HOME` (default `$HOME/apps/isce`). **The last
path component must be `isce`.**

## 1. Conda env (Miniconda is enough)

```bash
conda create -n isce2 python=3.12      # 3.9 – 3.12 with the numpy<=1.26.4 pin; 3.13 needs numpy 2.x
conda activate isce2
```

## 2. Dependencies

```bash
conda install -c conda-forge git scons cython gdal h5py libgdal pytest "numpy<=1.26.4" \
    fftw scipy pybind11 shapely opencv
conda install -c conda-forge openmotif     # only needed for mdx
```

If opencv or openmotif conflict, use `pip install opencv-python` and the system motif instead.
Check with `ldconfig -p | grep 'libXm\.so'`. If it's missing, ask the user before running
`sudo apt install libxm4 libmotif-dev` or `sudo dnf install motif motif-devel`.

**Required:** add a `cython3` link. Without it scons **silently skips** some packages:

```bash
ln -sf $CONDA_PREFIX/bin/cython $CONDA_PREFIX/bin/cython3
```

## 3. Source

```bash
mkdir -p $HOME/tools/src && cd $HOME/tools/src
git clone https://github.com/isce-framework/isce2
```

## 4. Write `SConfigISCE`

Put it in `$HOME/.isce/SConfigISCE` unless the user has another location. **If the file already
exists, show it to the user and ask before overwriting.**

Work out the version-specific paths; don't copy them from an example:

```bash
PYINC=$(python3 -c "import sysconfig; print(sysconfig.get_path('include'))")
NPINC=$(python3 -c "import numpy; print(numpy.get_include())")
CUDA=$(dirname $(dirname $(which nvcc)))     # e.g. /usr/local/cuda; skip if no CUDA
```

Template (conda-provided libraries and motif). Replace `$PYINC`, `$NPINC` and `$CUDA` with the
literal values worked out above. `$HOME` and `$CONDA_PREFIX` can stay as they are, because
scons expands environment variables.

```
# SConfigISCE
# directory for temporary build files
PRJ_SCONS_BUILD=$HOME/build/isce_build
# install directory ($ISCE_HOME); the last component MUST be named isce
PRJ_SCONS_INSTALL=$HOME/apps/isce
# lib path for gdal, fftw, ...
LIBPATH=$CUDA/lib64 $CONDA_PREFIX/lib
# include paths
CPPPATH=$CUDA/include $CONDA_PREFIX/include $PYINC $NPINC $CONDA_PREFIX/include/opencv4
# compilers
FORTRAN=gfortran
CC=gcc
CXX=g++
# fftw fortran module
FORTRANPATH=$CONDA_PREFIX/include
# motif / X11 (see below for system-installed motif)
MOTIFLIBPATH=$CONDA_PREFIX/lib
X11LIBPATH=$CONDA_PREFIX/lib
MOTIFINCPATH=$CONDA_PREFIX/include
X11INCPATH=$CONDA_PREFIX/include
# runtime lib paths
RPATH=$CUDA/lib64 $CONDA_PREFIX/lib
# cuda modules
ENABLE_CUDA = True
CUDA_TOOLKIT_PATH=$CUDA
```

- Without CUDA: set `ENABLE_CUDA = False` and remove the `$CUDA/...` entries and `CUDA_TOOLKIT_PATH`.
- Motif/X11 paths when using the system copy:
  - Ubuntu/Debian: `MOTIFLIBPATH`/`X11LIBPATH` = `/usr/lib/x86_64-linux-gnu`, `MOTIFINCPATH`/`X11INCPATH` = `/usr/include`
  - RHEL/CentOS: libs = `/lib64`, includes = `/usr/include`
- For a build that uses only system packages (no conda), the README's
  `Ubuntu-18.04/SConfigISCE` is a template. It uses `/usr/include/gdal`,
  `/usr/include/hdf5/serial` and `/usr/include/python3.X`.

### CUDA tweaks in `$HOME/tools/src/isce2/scons_tools/cuda.py`

Find the line `env['ENABLESHAREDNVCCFLAG'] = '-std=c++11 -shared ...'`:
- To build for a specific GPU (CUDA 11/12 default to sm_52), add `-arch=sm_60` (P100),
  `-arch=sm_70` (V100), or `-arch=native`.
- With CUDA 13: change `-std=c++11` to `-std=c++17` and apply
  https://github.com/isce-framework/isce2/compare/main...lijun99:isce2:cuda-13 if it hasn't been merged.

Editing `cuda.py` changes the user's source tree, so tell them which line you changed.

## 5. Build

```bash
export ISCE_HOME=$HOME/apps/isce
export SCONS_CONFIG_DIR=$HOME/.isce
cd $HOME/tools/src/isce2
scons install 2>&1 | tee $HOME/build/isce_build/scons.log   # create the log's directory first
```

- A `libXm.so not found` message when using conda motif can be **ignored**, because it links
  correctly anyway. Errors about **gdal or fftw** are real: stop and check `LIBPATH`/`CPPPATH`.
- Check that the log doesn't say components were skipped. If it does, the usual causes are the
  missing `cython3` link or a wrong numpy include path.

## 6. Environment

`isce2.rc` (offer to write it, e.g. as `$HOME/apps/isce2.rc`):

```bash
# isce2.rc
export ISCE_INSTALL_ROOT=$HOME/apps
export ISCE_HOME=$ISCE_INSTALL_ROOT/isce
export PATH=$ISCE_HOME/bin:$ISCE_HOME/applications:$PATH
export LD_LIBRARY_PATH=$ISCE_HOME/lib:$LD_LIBRARY_PATH
export PYTHONPATH=$ISCE_HOME:$ISCE_HOME/applications:$ISCE_HOME/components:$ISCE_HOME/library:$ISCE_INSTALL_ROOT:$PYTHONPATH
```

The **parent** directory of `isce` (here `$HOME/apps`) must be on `PYTHONPATH`, or
`import isce` fails.

Or, for systems with environment modules, write an `isce2.mod`:

```
#%Module
module-whatis {Description: ISCE2-github}
set root $HOME/apps/isce
prepend-path	LD_LIBRARY_PATH	$root/lib
prepend-path	LIBRARY_PATH	$root/lib
prepend-path	PATH		$root/bin:$root/applications
prepend-path	PYTHONPATH	$HOME/apps:$root:$root/applications:$root/components:$root/library
setenv 		ISCE_HOME       $root
```

Test (with the conda env active):

```bash
source isce2.rc
python3 -c "import isce"
topsApp.py --help --steps
mdx            # or mdx.py, if built
```

Then, if the user wants them, set up the stack processors: [stack-processors.md](stack-processors.md).
