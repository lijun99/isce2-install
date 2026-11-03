# Linux: build from source with cmake (GPU support)

Last tested on Ubuntu 24.04, GNU GCC/GFORTRAN 13.3.0, CUDA 13 (September 2025).
isce2 installs **into the conda env** (`$CONDA_PREFIX`), so apps end up on `PATH` the same way
any other conda package does.

## 1. Conda env

```bash
conda create -n isce2 python=3.12      # 3.9 – 3.12 with the numpy<=1.26.4 pin; 3.13 needs numpy 2.x
conda activate isce2
echo $CONDA_PREFIX
```

## 2. Dependencies

```bash
conda install -c conda-forge git cmake cython gdal h5py \
    libgdal pytest "numpy<=1.26.4" fftw scipy pybind11 shapely \
    opencv openmotif-dev
```

If `opencv` or `openmotif` conflict or the solve takes forever:
- opencv: drop it from the line above and run `pip install opencv-python`
- openmotif: use the system copy. Check with `ldconfig -p | grep 'libXm\.so'`. If it's missing,
  ask the user before running `sudo apt install libxm4 libmotif-dev` (Debian/Ubuntu) or
  `sudo dnf install motif motif-devel` (RHEL/CentOS).

**Compilers.** Prefer the system GNU compilers (gcc 4.8 – 14 are OK; avoid 15). Only if there's
no usable system compiler: `conda install gcc_linux-64 gxx_linux-64 gfortran_linux-64` (pin a
version such as `=13` if needed).

**CUDA** (only if GPU modules are wanted). `nvcc` usually lives in `/usr/local/cuda/bin`, or comes
from `module load cuda`, or can be installed with conda: `conda install cuda=12.9 -c nvidia`.
- Match the CUDA version to the GPU (see the CUDA 13 caveats in SKILL.md).
- With CUDA 13: pycuampcor needs C++17 plus these patches if they haven't been merged:
  https://github.com/isce-framework/isce2/compare/main...lijun99:isce2:cuda-13
- `nvcc` limits which host gcc versions it accepts. Check the NVIDIA host-compiler support policy
  if cmake fails with an "unsupported GNU version" error.

## 3. Source

```bash
mkdir -p $HOME/tools/src && cd $HOME/tools/src
git clone https://github.com/isce-framework/isce2.git
```

If `~/tools/src/isce2` already exists, ask before pulling, resetting or re-cloning. It may hold
the user's own patches.

## 4. Configure, build, install

```bash
cd $HOME/tools/src/isce2
mkdir -p build && cd build
# a symlink saves passing -DPYTHON_MODULE_DIR=lib/python3.xx/site-packages
ln -sf `python3 -c 'import site; print(site.getsitepackages()[0])'` $CONDA_PREFIX/packages
cmake .. -DCMAKE_INSTALL_PREFIX=$CONDA_PREFIX \
  -DCMAKE_CUDA_ARCHITECTURES=native \
  -DCMAKE_PREFIX_PATH=${CONDA_PREFIX} \
  -DCMAKE_BUILD_TYPE=Release \
  -DPython_EXECUTABLE=`which python3` 2>&1 | tee cmake.log
make -j 2>&1 | tee make.log && make install 2>&1 | tee install.log
```

What the options do:
- `CMAKE_INSTALL_PREFIX=$CONDA_PREFIX`: install into the env. A custom prefix such as
  `$HOME/apps/isce2` also works, but then `PATH`/`PYTHONPATH` must be set by hand (see
  macos-homebrew.md step 5 for that layout).
- `CMAKE_CUDA_ARCHITECTURES`: `native` needs **cmake >= 3.24** and a GPU on the build machine.
  Otherwise give compute capabilities explicitly, e.g. `60` (P100), `70` (V100), `80` (A100),
  `90` (H100), or a list such as `"60;70;86"` if the code will run on several GPU types. Leave the
  option out if there's no CUDA.
- `CMAKE_BUILD_TYPE=Release`: adds `-DNDEBUG`, which turns off PyCuAmpcor debug features. Use
  `Release` for end users.
- `Python_EXECUTABLE`: stops cmake from picking up the system Python instead of the conda one.
  Check `cmake.log` for the Python it found.
- To force particular compilers:
  `-DCMAKE_C_COMPILER=/path/to/gcc -DCMAKE_CXX_COMPILER=/path/to/g++ -DCMAKE_Fortran_COMPILER=/path/to/gfortran`

## Troubleshooting

- `nvcc fatal : Unsupported gpu architecture 'compute_'`: cmake is older than 3.24 and doesn't
  understand `native`. Give explicit architectures instead.
- Wrong Python or numpy headers: add or fix `-DPython_EXECUTABLE`, then wipe `build/` and
  reconfigure.
- To see full compile commands: `make VERBOSE=1`.

## 5. Check

```bash
ls -ltr $CONDA_PREFIX/bin                 # mdx and the python apps should be here
ls -ltr $CONDA_PREFIX/packages/           # isce2 plus an `isce` symlink
python3 -c 'import isce'
topsApp.py -h
```

To load it next time, just run `conda activate isce2`.

Multiple GPUs: modules use device 0 by default, one GPU per task. Spread tasks with
`CUDA_VISIBLE_DEVICES=n topsApp.py ...` (`nvidia-smi` lists the devices).

Then, if the user wants them, set up the stack processors: [stack-processors.md](stack-processors.md).
