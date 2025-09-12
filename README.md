# ISCE2 installation guide

This guide provides instructions to install ISCE2 with Anaconda/Miniconda on a Linux/MacOS machine.
**NOTE**: this is not the **official** installation guide. It only serves to help users to install ISCE2 on some common and most recent platforms. Please check the [ISCE2](https://github.com/isce-framework/isce2) page for official guides and tutorials.

## Contents

   * [Linux with Anaconda3 : cmake with GPU support (updated September 2025)](#linux-with-anaconda3--cmake)
   * [Linux with Anaconda3 : scons (updated September 2025)](#linux-with-anaconda3--scons)
   * [MacOSX with Anaconda3 and homebrew: Apple Silicon (updated November 2024)](#macosx-with-anaconda3-and-homebrew-apple-silicon)
   * [MacOSX with Macports : Apple Silicon with mdx (updated Sepetember 2023)](#macosx-with-macports--apple-silicon-with-mdx)
   * [MacOSX with Anaconda3 : Intel (not updated)](#macosx-with-anaconda3--intel)


## Linux with Anaconda3 : cmake with GPU support

(Tested on Ubuntu 24.04 with GNU GCC/GFORTRAN 13.3.0 and CUDA 13, September 2025)

1. Prepare a conda or conda virtual environment

         conda create -n isce2
         conda activate isce2

(Any python version 3.7 - 3.13 should work).

The following steps will install isce2 to $CONDA_PREFIX.

         echo $CONDA_PREFIX

2. Install required packages

         conda install -c conda-forge git cmake cython gdal h5py \
             libgdal pytest numpy fftw scipy pybind11 shapely    \
             opencv openmotif-dev

``opencv`` and ``openmotif`` packages have been updated in conda-forge. If you have issues with these packages, or use an old version of conda and experience long wait time for the compatibility check, please

Use ``pip``.to install ``opencv``

        pip install opencv-python

Use linux system installed openmotif. You may use the command ``ldconfig -p | grep libXm`` to check whether it exists. If not, install openmotif by

        # Ubuntu/Debian
        sudo apt install libxm4
        # Redhat CentOS
        yum install motif, motif-devel

**Compilers**. GNU compilers coming with the system are recommended; GCC 4.8 - 13 are supported. **Only if you don't have access to a system installed compiler**, you may use conda gnu compilers,

        conda install gcc_linux-64 gxx_linux-64 gfortran_linux-64

**CUDA Compilers**. To use GPU-accelerated modules, you will need a CUDA compiler, which is usually located at `/usr/local/cuda` or can be loaded by `module load cuda`. CUDA compilers now can be [installed by conda](https://docs.nvidia.com/cuda/cuda-installation-guide-linux/#conda-installation) as well,

        conda install cuda -c nvidia

**Note** that CUDA compiler (``nvcc``) may have restrictions on host compilers, see [CUDA Documentaion](https://docs.nvidia.com/cuda/cuda-installation-guide-linux/index.html#host-compiler-support-policy) for more details.

**Note** CUDA 13.0 now requies C++17 support. If you have issues with pycuampcor with CUDA 13.0, apply [these patches](https://github.com/isce-framework/isce2/compare/main...lijun99:isce2:cuda-13) if they are not merged.

**Note** CUDA 13 has dropped support for devices < sm_75 (P100, V100, etc). CUDA 12 has dropped support for devices < sm_50 (K40 etc). Please use an approriate CUDA version for your device(s).


3. Download the source package

        mkdir -p $HOME/tools/src
        cd $HOME/tools/src
        git clone https://github.com/isce-framework/isce2.git

4. Compile and install isce2

       cd $HOME/tools/src/isce2
       # create a build directory
       mkdir build  && cd build
       # use a symbolic link instead of specify -DPYTHON_MODULE_DIR=lib/python3.xx/site-packages
       ln -sf `python3 -c 'import site; print(site.getsitepackages()[0])'` $CONDA_PREFIX/packages
       # run cmake config
       cmake .. -DCMAKE_INSTALL_PREFIX=$CONDA_PREFIX \
         -DCMAKE_CUDA_ARCHITECTURES=native \
         -DCMAKE_PREFIX_PATH=${CONDA_PREFIX} \
         -DCMAKE_BUILD_TYPE=Release
       # compile and install
       make -j && make install

* Some common issues
    * ``-DCMAKE_CUDA_ARCHITECTURES=native`` the native, or auto-detect gpu architecture option requres cmake >= 3.24. If you see a message like ``nvcc fatal : Unsupported gpu architecture 'compute_'``, you are using an old version of cmake and need to change native to your targeted gpu architecture(s). See details below.
    * Also make sure that ``cmake`` has identified the correct python interpreter from conda. Sometimes, it uses the system installed python instead. In this case, you may guide find_python by adding `` -DPython_EXECUTABLE=`which python3` ``.

* `DCMAKE_INSTALL_PREFIX` is where the package is to be installed. Here, we choose to install to the conda venv directly ($CONDA_PREFIX) such that the paths to isce2 commands/scripts are automatically set up, like other conda packages.
* `DPYTHON_MODULE_DIR` (no longer needed with the symbolic link) is the directory to install Python scripts, defined relative to the `DCMAKE_INSTALL_PREFIX` directory. Please check your conda venv python3 version, and set it accordingly, e.g., python3.7 instead of python3.9. One method to check the site-packages directory for your Python version is to run the command

        python3 -c 'import site; print(site.getsitepackages())'

* `DCMAKE_CUDA_ARCHITECTURES` targets optimizing the GPU code for a specific GPU architecture, or in terms of the CUDA Compute Capability, e.g.,  60 for P100, 70 for V100, 80 for A100, 90 for H100, ... If the GPU is installed on the same machine you are compiling the code, you may simply use `DCMAKE_CUDA_ARCHITECTURES=native` to auto-config. If you plan to run the code on multiple architectures, use a list such as `DCMAKE_CUDA_ARCHITECTURES="60;70;86"`, see [CMake Manual](https://cmake.org/cmake/help/latest/prop_tgt/CUDA_ARCHITECTURES.html) for more details.
* `DCMAKE_PREFIX_PATH` is for search path(s) of dependencies, such as gdal, fftw. Since we installed all dependencies through conda, we use ${CONDA_PREFIX}.
* `DCMAKE_BUILD_TYPE=(None, Debug, Release)`. Some isce2 modules (e.g. PyCuAmpcor) have debugging features which are turned on/off by the -DNDEBUG compilation flag. This flag is not included in Debug build type or not specified, i.e., debugging features are on. It is included in Release build type, and therefore debugging features are turned off. For end users, please use Release build type.
* If cmake cannot locate the desired compilers correctly, you can enforce the choice of compilers by adding

      -DCMAKE_C_COMPILER=/path/to/gcc -DCMAKE_CXX_COMPILER=/path/to/g++ -DCMAKE_Fortran_COMPILER=/path/to/gfortran

* If something is wrong in the compilation and you would like to check the details

      make VERBOSE=1

5. Check and Test

You may check whether ISCE2 is properly installed by

      cd $CONDA_PREFIX/bin
      ls -ltr
      # you should see mdx, and other python apps are installed
      cd ../lib/python3.x/site-packages
      ls -ltr
      # you should see isce2 and an additional link isce

You may try to run

      python3 -c 'import isce'
      topsApp.py -h
      ...

Next time, all you need to do to load isce2 is to

      codna activate # if you install to the base
      conda activate isce2 # if you install to an isce2 venv.

By default, the CUDA modules run on GPU device 0 (currently only one GPU per task is supported). If there are multiple tasks or multiple users sharing the same device, the program will run slow or even crash. If you have multiple GPUs installed (run `nvidia-smi` to check), you may spread your tasks to different GPUs, by using `CUDA_VISIBLE_DEVICES=n` to select the device, where `n=0,1,...` up to the number of GPUs installed. For example, to use device 2 (third GPU),

      export CUDA_VISIABLE_DEVICES=2
      topsApp.py ...
      # or one line
      CUDA_VISIBLE_DEVICES=2 topsApp.py ...

## Linux with Anaconda3 : scons

**Note: SCons with Conda doesn't work on Mac. You may need to use macports.**

**Note: If you plan to use Linux provided packages instead of Conda, please follow [Ubuntu 18.04 example](Ubuntu-18.04/SConfigISCE) to create a `SConfigISCE` config file.**

**Note (April 2025): Tested on Miniconda with python 3.13 and GNU gcc/g++/gfortran 13.3. You might need these [two patches](https://github.com/isce-framework/isce2/pull/946/commits) if they haven't been merged.**

1. Install Anaconda or Minoconda. If you only run isce2 with venv, miniconda is recommended.

2. If you prefer, prepare a conda virtual environment

       conda create -n isce2 python=3.13 # or 3.8 and above
       conda activate isce2

3. Install required packages

       conda install -c conda-forge git scons cython gdal h5py libgdal pytest numpy fftw scipy pybind11 shapely opencv

To compile/install mdx, you will also need `openmotif`.

       conda install -c conda-forge openmotif opencv

Sometimes `opencv` and `openmotif` are not updated in time and cause conflicts with other packages. If you have issues with them, please use `pip` install method for `opencv`,

       pip install opencv-python

and use the system installed openmotif

       # to check whether there is one
       ldconfig -p | grep libXm
       # if not present, install as follows (need root privilege)
       # Ubuntu/Debian
       sudo apt install libxm4
       # Redhat CentOS
       dnf install motif, motif-devel


You will need to make a symbolic link for cython3, (**this is important, otherwise, some packages will be skipped**)

       cd $CONDA_PREFIX/bin
       ln -sf cython cython3

4. Download isce2 for GitHub or prepare your own version

       # create a directory to save source files
       mkdir -p ${HOME}/tools/src
       cd {$HOME}/tools/src
       # glone a copy from github
       git clone https://github.com/isce-framework/isce2

The command shall pull a GitHub version of isce2 to your `${HOME}/tools/src/isce2` directory.

5. Configure a `SConfigISCE` file under, e.g. `${HOME}/.isce` directory

       PRJ_SCONS_BUILD=$HOME/build/isce_build
       PRJ_SCONS_INSTALL=$ISCE_HOME
       LIBPATH=$CONDA_PREFIX/lib
       CPPPATH=$CONDA_PREFIX/include $CONDA_PREFIX/include/python3.13/ $CONDA_PREFIX/lib/python3.13/site-packages/numpy/_core/include $CONDA_PREFIX/include/opencv4
       FORTRAN=gfortran
       CC=gcc
       CXX=g++
       FORTRANPATH=$CONDA_PREFIX/include
       # note: if you use system-installed openmotif, change the settings below accordingly
       MOTIFLIBPATH=$CONDA_PREFIX/lib
       X11LIBPATH=$CONDA_PREFIX/lib
       MOTIFINCPATH=$CONDA_PREFIX/include
       X11INCPATH=$CONDA_PREFIX/include
       RPATH=$CONDA_PREFIX/lib
       ENABLE_CUDA = True
       CUDA_TOOLKIT_PATH=/usr/local/cuda  # use 'which nvcc' to verify

 * `PRJ_SCONS_BUILD` is a directory to save temporary compiled files
 * `PRJ_SCONS_INSTALL` is where the isce2 will be installed. We use a `$ISCE_HOME` to be defined later
 * `LIBPATH` is where to look for the shared libraries, such as gdal, fftw
 * `CPPPATH` is where to look for C/C++ head files (#include) for libraries. Use the following commands to find the proper path(s) if you use a different python version or system,

       # Python.h location
       python3 -c "import sysconfig; print(sysconfig.get_path('include'))"
       # numpy include
       python3 -c "import numpy; print(numpy.get_include())"


 * `FORTRAN`, `CC`, `CXX` are the Fortran/C/C++ compilers to be used
 * `MOTIFLIBPATH` ... `X11INCPATH` are to set lib and include paths for motif and x11 libraries.
    * for Ubuntu 18.04, set `MOTIFLIBPATH1` and `X11LIBPATH` to `/usr/lib/x86_64-linux-gnu/` and set `MOTIFINCPATH`
and `X11INCPATH` to `/usr/include`.
    * for Redhat or CentOS 7, set `MOTIFLIBPATH1` and `X11LIBPATH` to `/lib64` and set `MOTIFINCPATH`
and `X11INCPATH` to `/usr/include`.
    * for conda installed packages, set them as `$CONDA_PREFIX/lib` and `$CONDA_PREFIX/include`.
 * `ENABLE_CUDA` = `True/False` whether to include some GPU/CUDA accelerated modules. If enabled, please also specify `CUDA_TOOLKIT_PATH` to where CUDA SDK is installed. Some manual configuration might be needed:
    * CUDA SDK Versions 11 and above are recommended.
    * The CUDA compiler 11 & 12 by default targets NVIDIA GPUs with compute capability 5.2 (if you use an older gpu such as 3.5 or 5.0, stay with an older version of isce2 and cuda compiler). If you prefer to compile CUDA code best suited to the GPU you have,  find `env['ENABLESHAREDNVCCFLAG']` in `${HOME}/tools/src/isce2/scons_tools/cuda.py` file, find the line `env['ENABLESHAREDNVCCFLAG'] = '-std=c++11 -shared`, add  `-arch=sm_60`
    for P100, `-arch=sm_70` for V100, or `-arch=native` to auto-select.
    * CUDA 13 requires c++17 support. If you see such complains when compiling pycuampcor, modify `env['ENABLESHAREDNVCCFLAG']` in `${HOME}/tools/src/isce2/scons_tools/cuda.py` file, change `-std=c++11` to `-std=c++17`. Also, apply [these patches](https://github.com/isce-framework/isce2/compare/main...lijun99:isce2:cuda-13) to isce2 if they have not been merged.

6. Some settings for environment variables before compile/install. You need to specify three environment variables
* `CONDA_PREFIX` where Anaconda3 is installed
* `ISCE_HOME` where isce2 will be installed
* `SCONS_CONFIG_DIR` where the `SConfigISCE` is located.
if they are not set. Check by, e.g.,  `echo $CONDA_PREFIX`.

For `csh`,

    setenv ISCE_HOME ${HOME}/tools/isce
    setenv SCONS_CONFIG_DIR ${HOME}/.isce

and for `bash`,

    export ISCE_HOME=${HOME}/tools/isce
    export SCONS_CONFIG_DIR=${HOME}/.isce

7. Compile/install isce2

    cd ${HOME}/tools/src/isce2
    scons install

If successful, you should obtain a compiled isce2 at `$ISCE_HOME` or `$HOME/tools/isce`.

Some common problems or questions:

* if you use conda installed X11 motif libraries, you might see an error `libXm.so not found` reported by scons. You may neglect and proceed; these libraries will be linked properly. But if you see error messages about gdal or fftw, please stop and check.

8. Set up environment variables to load/usr isce2.
* use environment module, .e.g., `module load/unload isce2.mod` where an example of `isce2.mod` is provided below.

      #%Module
      module-whatis {Description: ISCE2-github}
      set root $HOME/tools/isce
      prepend-path	LD_LIBRARY_PATH	$root/lib
      prepend-path	LIBRARY_PATH	$root/lib
      prepend-path	PATH		$root/bin:$root/applications
      prepend-path	PYTHONPATH	$HOME/tools:$root:$root/applications:$root/components:$root/library
      setenv 		ISCE_HOME       $root

Note that in order to `import isce` from python, you need to use the `isce` as the installation directory name and also set the directory where `isce` is located (in above case, `$HOME/tools`) to `PYTHONPATH`.

* use a resource file to load as `source isce2.rc`.
For `csh`,

      # isce2.cshrc
      setenv ISCE_HOME $HOME/tools/isce
      setenv PATH $ISCE_HOME/bin\:$ISCE_HOME/applications\:$PATH
      setenv LD_LIBRARY_PATH $ISCE_HOME/lib\:$LD_LIBRARY_PATH
      # check whether PYTHONPATH exists
      if ( ! $?PYTHONPATH ) then
        setenv PYTHONPATH $HOME\:$ISCE_HOME\:$ISCE_HOME/applications\:$ISCE_HOME/components\:$ISCE_HOME/library
      else
        setenv PYTHONPATH $HOME\:$ISCE_HOME\:$ISCE_HOME/applications\:$ISCE_HOME/components\:$ISCE_HOME/library\:$PYTHONPATH
      endif

 For `bash`,

      # isce2.rc
      export ISCE_HOME=$HOME/tools/isce
      export PATH=$ISCE_HOME/bin:$ISCE_HOME/applications:$PATH
      export LD_LIBRARY_PATH=$ISCE_HOME/lib:$LD_LIBRARY_PATH
      export PYTHONPATH=$ISCE_HOME:$ISCE_HOME/applications:$ISCE_HOME/components:$ISCE_HOME/library:$HOME/tools:$PYTHONPATH

If your `ISCE_HOME` is other than `$HOME/tools/isce`, make sure listing its parent directory, such as `$HOME/tools`, to `PYTHONPATH`.

To load the settings,

    source isce2.rc

To test whether everything is in order

    python3 -c "import isce"
    topsApp.py --help --steps
    # if you compiled mdx
    mdx # or mdx.py


9. Common questions/problems

## MacOSX with Anaconda3 and homebrew: Apple Silicon

(Testd on macOS Sequoia 15.1. This is the recommended method for MacOS - all packages are pre-compiled. However, after a major MacOS upgrade, e.g., from 13 to 14, a re-installation of Xcode Command Line Tools, conda, homebrew is recommended.)

1. Install Command Line Tools, Conda and gcc/g++/gfortran Compiler

Install Command Line Tools, (NOTE as 11/7/24: if you used Settings->Software Updates option, the CLT has a bug. Remove it and reinstall!!!)

      sudo rm -rf /Library/Developer/CommandLineTools/
      xcode-select --install

then follow the popup window to install.

Install an osx-arm64 build of Anaconda3 or [Miniconda3](https://docs.conda.io/projects/miniconda/en/latest/index.html) (recommended).

Taking miniconda as an example, you may follow the [Quick Command Line Install](https://docs.conda.io/projects/miniconda/en/latest/index.html#quick-command-line-install) method

      mkdir -p ~/miniconda3
      curl https://repo.anaconda.com/miniconda/Miniconda3-latest-MacOSX-arm64.sh -o ~/miniconda3/miniconda.sh
      bash ~/miniconda3/miniconda.sh -b -u -p ~/miniconda3
      rm -rf ~/miniconda3/miniconda.sh

Mamba is an alternative package installer to conda, which runs faster and is recommended,

       ~/miniconda3/bin/conda install mamba
       ~/miniconda3/bin/mamba init zsh # or bash
       source ~/.zshrc # not needed when you open a new Terminal


Install Homebrew (the pkg installer is the easiest method, download from [Homebrew Releases](https://github.com/Homebrew/brew/releases/)) -- find the most recent Homebrew-n.n.n.pkg file. For Apple Silions (osx-arm64), brew is installed to ``/opt/homebrew``.

        export PATH="/opt/homebrew/bin:$PATH"

and then install gfortran (current version GCC 14.2.0)

        brew install gfortran
        /opt/homebrew/bin/gfortran --version # check

If you need mdx (slc viewing software), install openmotif here (osx-arm64 version currently not available from conda)

        brew install openmotif

Also install [XQuartz](https://www.xquartz.org/).

2. Prepare a virtual environment with conda or mamba

       mamba create -n isce2
       mamba activate isce2

The following steps will install isce2 to $CONDA_PREFIX.

       echo $CONDA_PREFIX

3. Install required packages

       mamba install git cmake cython gdal h5py libgdal pytest numpy fftw scipy pybind11 shapely
       pip install opencv-python

``opencv`` has complex dependencies, which causes long delay to the conda compatibility check. We recommend installing it with ``pip``.

4. Compile and install isce2

Make a link to make the installation path easier (``-DPYTHON_MODULE_DIR`` not longer need)

       ln -sf `python3 -c 'import site; print(site.getsitepackages()[0])'` $CONDA_PREFIX/packages

Download ISCE2 from github

        git clone https://github.com/isce-framework/isce2.git

Compile ISCE2 with cmake,

        cd isce2
        mkdir build && cd build
        cmake .. -DCMAKE_INSTALL_PREFIX=$CONDA_PREFIX \
          -DCMAKE_PREFIX_PATH=${CONDA_PREFIX} \
          -DCMAKE_C_COMPILER="/opt/homebrew/bin/gcc-14" \
          -DCMAKE_CXX_COMPILER="/opt/homebrew/bin/g++-14" \
          -DCMAKE_Fortran_COMPILER="/opt/homebrew/bin/gfortran-14"
        make -j # to use multiple threads
        make install

We use gcc from homebrew instead of Apple Clang because of some compatibility issue (some source codes need to be updated).

5. Config and run isce2

If you follow the above steps, ISCE2 packages are installed to $CONDA_PREFIX/packages/isce2. You will only need to add the path to stack apps,

        export ISCE_HOME="$CONDA_PREFIX/packages/isce"
        export PATH="$ISCE_HOME/applications:$PATH"

If you have installed ISCE2 to a custom directory, e.g., ``$HOME/apps/isce2``, with ``-DCMAKE_INSTALL_PREFIX=$HOME/apps/isce2`` cmake option, you need to

        export ISCE_INSTALL_ROOT="$HOME/apps/isce2"
        export ISCE_HOME="$ISCE_INSTALL_ROOT/packages/isce"
        export PATH="$ISCE_HOME/applications:$ISCE_INSTALL_ROOT/bin:$PATH"
        export PYTHONPATH="$ISCE_INSTALL_ROOT/packages:$PYTHONPATH"

You may try the following to check whether ISCE2 has been properly installed,

        python3 -c "import isce"

To use mdx, you will need [XQuartz](https://www.xquartz.org/).

        mdx.py xxxxx.slc
        # show the slc picture (.xml description file needed)

Enjoy!

## MacOSX with Anaconda3 : Intel

**This is an old guide for Intel Macs (osx-64). It may also work for Apple Silicons with Rosetta 2, but may experience complexities on clang/gcc compilers for new versions of macOS.**

Please follow the instructions for Linux. You may need to install xcode or command-line-tools. GPU modules are not supported for MacOSX, unless you use an external GPU with NVIDIA cards. You will then need to install NVIDIA driver and CUDA.

**For Apple Silicon (M1, M2, ...)**, you may use the regular (x86_64) Conda releases (continue to work with Rosetta 2). Or you may install the native arm64 version from Anaconda, or [Miniforge](https://github.com/conda-forge/miniforge). However, openmotif is not currently supported by native arm64. If you need mdx, please use the x86_64 release with Rosetta 2.

Example with MacOSX 11.5.2 (Big Sur) and Apple Clang 12.0.5.

1. Prepare a conda or conda virtual environment

       conda create -n isce2
       conda activate isce2

The following steps will install isce2 to $CONDA_PREFIX.

       echo $CONDA_PREFIX

2. Install required packages

       conda install git cmake cython gdal h5py libgdal pytest numpy fftw scipy pybind11
       pip install opencv

``opencv`` has complex dependencies, which causes long delay to the conda compatibility check. We recommend installing it with ``pip``.

To compile/install mdx, you will also need

       conda install openmotif openmotif-dev xorg-libx11 xorg-libxt xorg-libxmu xorg-libxft libiconv xorg-libxrender xorg-libxau xorg-libxdmcp

3. Compilers

If you already have Xcode installed,

       sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
       which clang # show /usr/bin/clang
       clang --version # Apple clang version  12.0.5 (clang-1205.0.22.11)

If not, you may install the full version of Xcode, or simply the Command Line Tools,


      sudo xcode-select --install
      sudo xcode-select --switch /Library/Developer/CommandLineTools


Install gfortran through brew

       brew install gfortran
       which gfortran # show /usr/local/bin/gfortran
       gfortran --version # GNU Fortran (Homebrew GCC 11.2.0) 11.2.0

Or you may simply download the binary from [HPC MacOSX](http://hpc.sourceforge.net/): they have pre-compiled versions `gfortran-x.x-bin.tar.gz` for all MacOSX systems, including Apple Silicon.

4. Compile and install isce2

       cd $HOME/tools/src/isce2
       mkdir build  && cd build
       cmake .. -DCMAKE_INSTALL_PREFIX=$CONDA_PREFIX -DPYTHON_MODULE_DIR=lib/python3.9/site-packages  -DCMAKE_PREFIX_PATH=${CONDA_PREFIX}
       make -j # to use multiple threads
       make install


Change cmake options if necessary, e.g., `PYTHON_MODULE_DIR` to your installed python version. Enjoy!

Note that after each major MacOSX update, please try to update (or reinstall) Command Line Tools and update Conda.

You may notice warnings such as  ``was built for newer macOS version (11.5) than being linked (11.0)``. It is in general safe to neglect these warnings. To suppress the warnings, you may add ``-DCMAKE_OSX_DEPLOYMENT_TARGET=11.5`` to cmake command line.



## MacOSX with Macports : Apple Silicon with mdx
(Tested on macOS Ventura 13.5.1)

1. Install Xcode (or Command Line Tools) and Macports

Follow the [Macports Guide](https://www.macports.org/install.php) to download and install Macports. All the files, by default, will be installed to ``/opt/local``. The PATH will also be automatically added to your ``.zprofile`` or ``.profile``. If not, please run

        export PATH="/opt/local/bin:/opt/local/sbin:$PATH"

It is a good idea to perform a update at first,

        sudo port -v selfupdate

To run mdx (the SLC viewing software), please also install [XQuartz](https://www.xquartz.org/).

2. Install required packages

Compiler GCC/G++/Gfortran and OpenMP

        sudo port install gcc12 libomp
        sudo port select --set gcc mp-gcc12

Python and other libraries, (note: some additional python packages might be needed at runtime, you may always use ``sudo port install py311-xxxx`` to install them later.)

        sudo port install cmake python311 py311-cython py311-numpy py311-scipy py311-pybind11 pybind11 hdf5 py311-gdal fftw-3 fftw-3-single py311-opencv4-devel
        sudo port select --set python python311
        sudo port select --set python3 python311
        sudo port select --set cython cython311
        sudo port select --set gdal py311-gdal
        sudo ln -sf `python3 -c 'import site; print(site.getsitepackages()[0])'` /opt/local/packages

(Optional) To use mdx, install Openmotif

        sudo port install openmotif

3. Install ISCE2

Download ISCE2 from GitHub

        git clone https://github.com/isce-framework/isce2.git

Compile ISCE2 with cmake,

        cd isce2
        mkdir build && cd build
        cmake .. -DCMAKE_INSTALL_PREFIX=/opt/local \
          -DCMAKE_C_COMPILER=/opt/local/bin/gcc \
          -DCMAKE_CXX_COMPILER=/opt/local/bin/g++ \
          -DCMAKE_PREFIX_PATH="/opt/local" \
          -DOpenMP_C_FLAGS="-fopenmp=lomp" \
          -DOpenMP_CXX_FLAGS="-fopenmp=lomp" \
          -DOpenMP_C_LIB_NAMES="libomp" \
          -DOpenMP_CXX_LIB_NAMES="libomp" \
          -DOpenMP_libomp_LIBRARY="/opt/local/lib/libomp/libomp.dylib" \
          -DOpenMP_CXX_LIB_NAMES="libomp" \
          -DPython_ROOT_DIR="/opt/local/Library/Frameworks/Python.framework/Versions/3.11/"
        make -j
        sudo make install

(you may safely neglect the OpenCV warning.) Here, the installation path is set to ``/opt/local``, or MacPorts. You may choose a different directory, e.g., ``$HOME/apps/isce2``. But you will need to set ``PATH`` and ``PYTHONPATH`` manually by yourself.

4. Config and run isce2

``mdx`` command is installed to ``/opt/local/bin`` while the rest is installed to ``/opt/local/packages/isce2`` (or the actual location ``/opt/local/Library/Frameworks/Python.framework/Versions/3.11/lib/python3.11/site-packages/isce2``. You may try the following to check whether ISCE2 has been properly installed,

        python3 -c "import isce"
        # return "Using default ISCE Path: /opt/local/Library/Frameworks/Python.framework/Versions/3.11/lib/python3.11/site-packages/isce".

To use some python apps, it is convenient to set up some environmental variables,

        #isce2.rc
        export ISCE_HOME="/opt/local/Library/Frameworks/Python.framework/Versions/3.11/lib/python3.11/site-packages/isce"
        export PATH="$ISCE_HOME/applications:$PATH"

To use mdx, you will need XQuartz.

        mdx.py xxxxx.slc
        # show the slc picture (.xml description file needed)

(If you have a "cannot open DISPLAY" error, check [here](https://github.com/XQuartz/XQuartz/issues/295#issuecomment-1326693810). )

Problems & Questions, please post on the Issue.



