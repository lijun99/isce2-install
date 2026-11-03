# macOS Apple Silicon: conda + Homebrew gcc, cmake (recommended for Macs)

Tested on macOS Tahoe 26.0. All dependencies come pre-compiled. After a **major** macOS
upgrade (e.g. 15 → 26), reinstall Command Line Tools, conda and Homebrew. Minor upgrades are
usually fine. No CUDA on macOS.

## 1. Toolchain

Every step here installs system software, so confirm each one with the user first and skip any
that the probe shows is already in place.

- **Command Line Tools**: `xcode-select --install` (the user has to click through a popup).
  Only if it's broken: `sudo rm -rf /Library/Developer/CommandLineTools/` first. **Always ask
  before running this.**
- **Conda**: an osx-arm64 Miniconda (recommended):

  ```bash
  mkdir -p ~/miniconda3
  curl https://repo.anaconda.com/miniconda/Miniconda3-latest-MacOSX-arm64.sh -o ~/miniconda3/miniconda.sh
  bash ~/miniconda3/miniconda.sh -b -u -p ~/miniconda3
  rm -rf ~/miniconda3/miniconda.sh
  ```

  Mamba is faster and recommended: `~/miniconda3/bin/conda install mamba`, then
  `~/miniconda3/bin/mamba init zsh`. That edits the shell rc, so ask first.
- **Homebrew**: the `.pkg` installer from https://github.com/Homebrew/brew/releases is the
  easiest route. It installs to `/opt/homebrew`. Run `export PATH="/opt/homebrew/bin:$PATH"`.
- **GCC 14** (GCC 15 is too strict for parts of the code base): `brew install gcc@14`, then
  check with `/opt/homebrew/bin/gfortran-14 --version`.
- **mdx only**: `brew install openmotif` (there's no osx-arm64 conda build) and
  [XQuartz](https://www.xquartz.org/).

## 2. Env

```bash
mamba create -n isce2 python=3.12
mamba activate isce2
echo $CONDA_PREFIX
```

## 3. Dependencies

```bash
mamba install git cmake cython gdal h5py libgdal pytest "numpy<=1.26.4" fftw scipy pybind11 shapely opencv
```

## 4. Build

```bash
ln -sf `python3 -c 'import site; print(site.getsitepackages()[0])'` $CONDA_PREFIX/packages
mkdir -p $HOME/tools/src && cd $HOME/tools/src
git clone https://github.com/isce-framework/isce2.git
cd isce2 && mkdir -p build && cd build
cmake .. -DCMAKE_INSTALL_PREFIX=$CONDA_PREFIX \
  -DCMAKE_PREFIX_PATH=${CONDA_PREFIX} \
  -DCMAKE_C_COMPILER="/opt/homebrew/bin/gcc-14" \
  -DCMAKE_CXX_COMPILER="/opt/homebrew/bin/g++-14" \
  -DCMAKE_Fortran_COMPILER="/opt/homebrew/bin/gfortran-14" 2>&1 | tee cmake.log
make -j 2>&1 | tee make.log && make install 2>&1 | tee install.log
```

Use Homebrew gcc, not Apple Clang. Some sources don't compile with Clang yet.

## 5. Environment

Installed into the env (default):

```bash
export ISCE_HOME="$CONDA_PREFIX/packages/isce"
export PATH="$ISCE_HOME/applications:$PATH"
```

Custom prefix (`-DCMAKE_INSTALL_PREFIX=$HOME/apps/isce2`):

```bash
export ISCE_INSTALL_ROOT="$HOME/apps/isce2"
export ISCE_HOME="$ISCE_INSTALL_ROOT/packages/isce"
export PATH="$ISCE_HOME/applications:$ISCE_INSTALL_ROOT/bin:$PATH"
export PYTHONPATH="$ISCE_INSTALL_ROOT/packages:$PYTHONPATH"
```

Test with `python3 -c "import isce"`. mdx needs XQuartz running: `mdx.py file.slc` (the `.xml`
description file must be next to it).

Then, if the user wants them, set up the stack processors: [stack-processors.md](stack-processors.md).
