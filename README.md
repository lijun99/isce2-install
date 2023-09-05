# ISCE2 installation guide

This guide provides intructions to install ISCE2 with Anaconda/Miniconda on a Linux/MacOS machine. 
**NOTE**: this is not the **official** installation guide. It only serves to help users to install ISCE2 on some common and most recent platforms. Please check the [ISCE2](https://github.com/isce-framework/isce2) page for official guides and tutorials.  

## Contents 

   * [Linux with Anaconda3 : cmake (updated September 2023)](#linux-with-anaconda3--cmake)
   * [MacOSX with Anaconda3 and homebrew: Apple Silicon (updated September 2023)](#macosx-with-anaconda3-and-homebrew-apple-silicon))
   * [MacOSX with Macports : Apple Silicon with mdx (updated Sepetember 2023)](#macosx-with-macports--apple-silicon-with-mdx)
   * [Linux with Anaconda3 : scons (not updated)](#linux-with-anaconda3--scons)
   * [MacOSX with Anaconda3 : Intel (not updated)](#macosx-with-anaconda3--intel)


## Linux with Anaconda3 : cmake

1. Prepare a conda or conda virtual environment 

       conda create -n isce2
       conda activate isce2

(Any python version 3.7 - 3.11 should work). 

The following steps will install isce2 to $CONDA_PREFIX. 

       echo $CONDA_PREFIX

2. Install required packages

       conda install -c conda-forge git cmake cython gdal h5py libgdal pytest numpy fftw scipy pybind11 shapely
       pip install opencv-python basemap

``basemap`` and ``opencv`` have complex dependencies, which cause long delay of the conda compatibility check. We recommend installing them with ``pip``.    
       
To compile/install mdx, you will also need        
       
       conda install -c conda-forge openmotif openmotif-dev xorg-libx11 xorg-libxt xorg-libxmu xorg-libxft libiconv xorg-libxrender xorg-libxau xorg-libxdmcp 

Compilers. GNU compilers coming with the system are recommended; GCC 4.8 - 13 are supported. **ONly if you don't have access to a system installed compiler,**) you may use conda gnu compilers, 

       conda install gcc_linux-64 gxx_linux-64 gfortran_linux-64
       
To use GPU-accelerated modules, you will need a CUDA compiler, which is usually located at `/usr/local/cuda` or can be loaded by `module load cuda`. Note that CUDA compiler (``nvcc``) may have restrictions on host compilers, see [CUDA Documentaion](https://docs.nvidia.com/cuda/cuda-installation-guide-linux/index.html#host-compiler-support-policy) for more details.  Note also that CUDA 12 has dropped support for devices < sm_50, such as K40. Please use CUDA 11 for these old devices.  
      
3. Download the source package

       mkdir -p $HOME/tools/src
       cd $HOME/tools/src
       git clone https://github.com/isce-framework/isce2.git

4. Compile and install isce2

       cd $HOME/tools/src/isce2
       mkdir build  && cd build
       ln -sf `python3 -c 'import site; print(site.getsitepackages()[0])'` $CONDA_PREFIX/packages  # use a symbolic link instead of specify -DPYTHON_MODULE_DIR=lib/python3.xx/site-packages
       cmake .. -DCMAKE_INSTALL_PREFIX=$CONDA_PREFIX -DCMAKE_CUDA_ARCHITECTURES=native -DCMAKE_PREFIX_PATH=${CONDA_PREFIX} -DCMAKE_BUILD_TYPE=Release 
       make -j && make install
 
* `DCMAKE_INSTALL_PREFIX` is where the package is to be installed. Here, we choose to install to the conda venv directly ($CONDA_PREFIX) such that the paths to isce2 commands/scripts are automatically set up, like other conda packages. 
* `DPYTHON_MODULE_DIR` is the directory to install Python scripts, defined relative to the `DCMAKE_INSTALL_PREFIX` directory. Please check your conda venv python3 version, and set it accordingly, e.g., python3.7 instead of python3.9. One method to check the site-packages directory for your Python version is to run the command
 
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

1. Install Anaconda or Minoconda. If you only run isce2 with venv, miniconda is recommended. 

2. If you prefer, prepare a conda virtual enviroment 

       conda create -n isce2 python=3.8
       conda activate isce2

3. Install required packages

       conda install -c conda-forge git scons cython gdal h5py libgdal pytest numpy fftw scipy basemap opencv pybind11 shapely
       
To compile/install mdx, you will also need        
       
       conda install -c conda-forge openmotif openmotif-dev xorg-libx11 xorg-libxt xorg-libxmu xorg-libxft libiconv xorg-libxrender xorg-libxau xorg-libxdmcp 


You will need to make a symbolic link for cython3,
      
       cd $CONDA_PREFIX/bin
       ln -sf cython cython3
       
If you plan to use conda installed GNU compilers (note that currently there are some compatibility issues of conda compiler with Redhat 7 systems, don't install gcc_linux-64, .... If you already made the following links, please delete them.)  

       ln -sf x86_64-conda_cos6-linux-gnu-gcc gcc
       ln -sf x86_64-conda_cos6-linux-gnu-g++ g++
       ln -sf x86_64-conda_cos6-linux-gnu-gfortran gfortran
       ln -sf x86_64-conda_cos6-linux-gnu-ld ld
      
       # for some conda-forge builds (seems no longer an issue with python3.8)
       cd $CONDA_PREFIX/lib
       ln -sf libzstd.so.1.3.7 libzstd.so.1

    
4. Download isce2 for github or prepare your own version 
     
       # create a directory to save source files
       mkdir -p ${HOME}/tools/src 
       cd {$HOME}/tools/src
       # glone a copy from github
       git clone https://github.com/isce-framework/isce2

The command shall pull a github version of isce2 to your `${HOME}/tools/src/isce2` diectory. 

5. Configure a `SConfigISCE` file under, e.g. `${HOME}/.isce` directory

       PRJ_SCONS_BUILD=$HOME/build/isce_build
       PRJ_SCONS_INSTALL=$ISCE_HOME
       LIBPATH=$CONDA_PREFIX/lib
       CPPPATH=$CONDA_PREFIX/include $CONDA_PREFIX/include/python3.8/ $CONDA_PREFIX/lib/python3.8/site-packages/numpy/core/include $CONDA_PREFIX/include/opencv4
       FORTRAN=gfortran
       CC=gcc
       CXX=g++
       FORTRANPATH=$CONDA_PREFIX/include
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
 * `CPPPATH` is where to look for C/C++ head files (#include) for libraries
 * `FORTRAN`, `CC`, `CXX` are the Fortran/C/C++ compilers to be used
 * `MOTIFLIBPATH` ... `X11INCPATH` are to set lib and include paths for motif and x11 libraries. 
    * for Ubuntu 18.04, set `MOTIFLIBPATH1` and `X11LIBPATH` to `/usr/lib/x86_64-linux-gnu/` and set `MOTIFINCPATH` 
and `X11INCPATH` to `/usr/include`.
    * for Redhat or CentOS 7, set `MOTIFLIBPATH1` and `X11LIBPATH` to `/lib64` and set `MOTIFINCPATH` 
and `X11INCPATH` to `/usr/include`.
    * for conda installed packages, set them as `$CONDA_PREFIX/lib` and `$CONDA_PREFIX/include`.
 * `ENABLE_CUDA` = `True/False` whether to include some GPU/CUDA accelerated modules. If enabled, please also specify `CUDA_TOOLKIT_PATH` to where CUDA SDK is installed. Some manual configuration might be needed:
    * CUDA SDK Versions 9 and above are recommended. 
    * The CUDA compiler 9 & 10 by default targets NVIDIA GPUs with compute capability 3.5 (K40, K80). CUDA 11 uses sm_52 as default. If you prefer to compile CUDA code best suited to the GPU you have,  find `env['ENABLESHAREDNVCCFLAG']` in `${HOME}/tools/src/isce2/scons_tools/cuda.py` file, find the line `env['ENABLESHAREDNVCCFLAG'] = '-std=c++11 -shared`, add `-arch=sm_35` for K40/K80, `-arch=sm_60` for P100,  `-arch=sm_61` for GTX1080, `-arch=sm_70` for V100.  
 
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

* if you use conda installed X11 motif libraries, you might see an errror `libXm.so not found` reported by scons. You may neglect and proceed; these libraries will be linked properly. But if you see error messages about gdal or fftw, please stop and check. 

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
     

9. Common questions/problems

## MacOSX with Anaconda3 and homebrew: Apple Silicon 

(Testd on macOS Ventura 13.5.1) 

1. Install Xcode (or command line tools), Conda and gcc/g++/gfortran Compiler

Install an osx-arm64 build of Anaconda3 or [Miniconda3](https://docs.conda.io/projects/miniconda/en/latest/index.html) (recommended). 

Install Homebrew (the pkg installer is the easiest method, [Homebrew-4.1.9.pkg](https://github.com/Homebrew/brew/releases/download/4.1.9/Homebrew-4.1.9.pkg)). For Apple Silions (osx-arm64), brew is installed to ``/opt/homebrew``. 

        export PATH="/opt/homebrew/bin:$PATH"

and then install gfortran (current version GCC 13.2)

        brew install gfortran

If you need mdx (slc viewing software), install openmotif here (osx-arm64 version currently not available from conda)

        brew install openmotif

Also install XQuartz. 
        
2. Prepare a conda or conda virtual enviroment 

       conda create -n isce2
       conda activate isce2

The following steps will install isce2 to $CONDA_PREFIX. 

       echo $CONDA_PREFIX 

Make a link to make the installation path easier (``-DPYTHON_MODULE_DIR`` not longer need)

       ln -sf `python3 -c 'import site; print(site.getsitepackages()[0])'` $CONDA_PREFIX/packages

3. Install required packages

       conda install git cmake cython gdal h5py libgdal pytest numpy fftw scipy pybind11 shapely
       pip install basemap opencv-python
       
``basemap`` and ``opencv`` have complex dependencies, which cause long delay of the conda compatibility check. We recommend installing them with ``pip``. 
                     
4. Compile and install isce2

Download ISCE2 from github

        git clone https://github.com/isce-framework/isce2.git

Compile ISCE2 with cmake, 

        cd isce2
        mkdir build && cd build
        cmake .. -DCMAKE_INSTALL_PREFIX=$CONDA_PREFIX \
          -DCMAKE_PREFIX_PATH=${CONDA_PREFIX} \
          -DCMAKE_C_COMPILER="/opt/homebrew/bin/gcc-13" \
          -DCMAKE_CXX_COMPILER="/opt/homebrew/bin/g++-13" 
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

To use mdx, you will need [XQuartz](https://www.xquartz.org/). Currently, there is a restriction you may only run X11 apps from an X-Terminal, not Apple Terminal. Open XQuartz, from ``Appplications->Terminal`` to open an X-terminal, 

        mdx.py xxxxx.slc 
        # show the slc picture (.xml description file needed)

Enjoy!

## MacOSX with Anaconda3 : Intel 

**This is an old guide for Intel Macs (osx-64). It may also work for Apple Silicons with Rosetta 2, but may experience complexities on clang/gcc compilers for new versions of macOS.**

Please follow the instructions for Linux. You may need to install xcode or command-line-tools. GPU modules are not supported for MacOSX, unless you use an external GPU with NVIDIA cards. You will then need to install NVIDIA driver and CUDA.  

**For Apple Silicon (M1, M2, ...)**, you may use the regular (x86_64) Conda releases (continue to work with Rosetta 2). Or you may install the native arm64 version from Anaconda, or [Miniforge](https://github.com/conda-forge/miniforge). However, openmotif is not currently supported by native arm64. If you need mdx, please use the x86_64 release with Rosetta 2. 

Example with MacOSX 11.5.2 (Big Sur) and Apple Clang 12.0.5.

1. Prepare a conda or conda virtual enviroment 

       conda create -n isce2
       conda activate isce2

The following steps will install isce2 to $CONDA_PREFIX. 

       echo $CONDA_PREFIX        

2. Install required packages

       conda install git cmake cython gdal h5py libgdal pytest numpy fftw scipy basemap opencv 
       
To compile/install mdx, you will also need        
       
       conda install openmotif openmotif-dev xorg-libx11 xorg-libxt xorg-libxmu xorg-libxft libiconv xorg-libxrender xorg-libxau xorg-libxdmcp 
       
3. Compilers 

If you already have Xcode installed, 

       sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
       which clang # show /usr/bin/clang
       clang --version # Apple clang version  12.0.5 (clang-1205.0.22.11)

If not, you may install the full version of Xocde, or simply the Command Line Tools, 


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

Download ISCE2 from github

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

To use mdx, you will need XQuartz. Currently, there is a restriction you may only run X11 apps from an X-Terminal, not Apple Terminal. Open XQuartz, from ``Appplications->Terminal`` to open an X-terminal, 

        mdx.py xxxxx.slc 
        # show the slc picture (.xml description file needed)

Problems & Questions, please post on the Issue. 



