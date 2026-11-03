# macOS Apple Silicon: MacPorts, cmake (includes mdx)

Tested on macOS Ventura 13.5.1 and still works on Tahoe 26.0.1, with the changes marked
**[Tahoe]** below. Everything installs under `/opt/local` and needs `sudo`, so confirm the
whole plan with the user before starting.

## 1. MacPorts

Install Xcode or Command Line Tools, then MacPorts from https://www.macports.org/install.php.
Make sure it's on `PATH`: `export PATH="/opt/local/bin:/opt/local/sbin:$PATH"`. Then run:

```bash
sudo port -v selfupdate
```

mdx also needs [XQuartz](https://www.xquartz.org/).

## 2. Packages

```bash
# compiler + OpenMP   [Tahoe: use gcc13 / mp-gcc13]
sudo port install gcc12 libomp
sudo port select --set gcc mp-gcc12

# python + libraries (add any missing runtime modules later with `sudo port install py311-xxxx`)
sudo port install cmake python311 py311-cython py311-numpy py311-scipy py311-pybind11 pybind11 \
    hdf5 py311-gdal fftw-3 fftw-3-single py311-opencv4-devel
sudo port select --set python python311
sudo port select --set python3 python311
sudo port select --set cython cython311
sudo port select --set gdal py311-gdal
sudo ln -sf `python3 -c 'import site; print(site.getsitepackages()[0])'` /opt/local/packages

# optional, for mdx
sudo port install openmotif
```

## 3. Build

```bash
git clone https://github.com/isce-framework/isce2.git
cd isce2 && mkdir -p build && cd build
```

gcc12 (Ventura):

```bash
cmake .. -DCMAKE_INSTALL_PREFIX=/opt/local \
  -DCMAKE_C_COMPILER=/opt/local/bin/gcc \
  -DCMAKE_CXX_COMPILER=/opt/local/bin/g++ \
  -DCMAKE_PREFIX_PATH="/opt/local" \
  -DOpenMP_C_FLAGS="-fopenmp=lomp" \
  -DOpenMP_CXX_FLAGS="-fopenmp=lomp" \
  -DOpenMP_C_LIB_NAMES="libomp" \
  -DOpenMP_CXX_LIB_NAMES="libomp" \
  -DOpenMP_libomp_LIBRARY="/opt/local/lib/libomp/libomp.dylib" \
  -DPython_ROOT_DIR="/opt/local/Library/Frameworks/Python.framework/Versions/3.11/" 2>&1 | tee cmake.log
```

**[Tahoe]** gcc13 no longer needs the `-fopenmp=lomp` flags, so drop all the `-DOpenMP_*` options:

```bash
cmake .. -DCMAKE_INSTALL_PREFIX=/opt/local \
  -DCMAKE_C_COMPILER=/opt/local/bin/gcc \
  -DCMAKE_CXX_COMPILER=/opt/local/bin/g++ \
  -DCMAKE_PREFIX_PATH="/opt/local" \
  -DPython_ROOT_DIR="/opt/local/Library/Frameworks/Python.framework/Versions/3.11/" 2>&1 | tee cmake.log
```

Then build and install:

```bash
make -j 2>&1 | tee make.log
sudo make install 2>&1 | tee install.log
```

The OpenCV warning is harmless. On Tahoe, so are
`clang: warning: overriding deployment version from '16.0' to '26.0'` messages. A prefix other
than `/opt/local` (e.g. `$HOME/apps/isce2`) also works, but then `PATH`/`PYTHONPATH` must be
set by hand.

## 4. Environment

`mdx` goes in `/opt/local/bin`. Everything else goes in `/opt/local/packages/isce2`, which is
really `.../Python.framework/Versions/3.11/lib/python3.11/site-packages/isce2`.

```bash
python3 -c "import isce"
# Using default ISCE Path: /opt/local/Library/Frameworks/Python.framework/Versions/3.11/lib/python3.11/site-packages/isce

# isce2.rc
export ISCE_HOME="/opt/local/Library/Frameworks/Python.framework/Versions/3.11/lib/python3.11/site-packages/isce"
export PATH="$ISCE_HOME/applications:$PATH"
```

mdx: `mdx.py file.slc` with XQuartz running. For a "cannot open DISPLAY" error, see
https://github.com/XQuartz/XQuartz/issues/295#issuecomment-1326693810

Then, if the user wants them, set up the stack processors: [stack-processors.md](stack-processors.md).
