# Linux with Anaconda3

1. Download Anaconda3 from https://www.anaconda.com/distribution/
2. Install Anaconda3 to, e.g., ${HOME}/anaconda3, the directory will be set as `CONDA_PREFIX`. 

activate Anaconda3 by `conda init bash`. 

3. Install required packages

       conda install gdal fftw scons
       # for Linux
       conda install -c conda-forge gcc_linux-64 gxx_linux-64 gfortran_linux-64 make openmpi hdf5
      
       cd ${HOME}/anaconda3/bin
       ln -sf make gmake
       ln -sf cython cython3
       ln -sf x86_64-conda_cos6-linux-gnu-gcc gcc
       ln -sf x86_64-conda_cos6-linux-gnu-g++ g++
       ln -sf x86_64-conda_cos6-linux-gnu-gfortran gfortran
       ln -sf x86_64-conda_cos6-linux-gnu-ld ld

If your system doesn't have a complete X11/openmotif development packages

       conda install -c conda-forge openmotif openmotif-dev xorg-libx11 xorg-libxt xorg-libxmu xorg-libxft xorg-libiconv xorg-libxrender xorg-libxau xorg-libxdmcp 
    
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
       CPPPATH=$CONDA_PREFIX/include $CONDA_PREFIX/include/python3.7m/ 
       FORTRAN=gfortran
       CC=gcc
       CXX=g++
       FORTRANPATH=$CONDA_PREFIX/include
       MOTIFLIBPATH=$CONDA_PREFIX/lib
       X11LIBPATH=$CONDA_PREFIX/lib
       MOTIFINCPATH=$CONDA_PREFIX/include
       X11INCPATH=$CONDA_PREFIX/include
       ENABLE_CUDA = True
       CUDA_TOOLKIT_PATH=/usr/local/cuda

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
    * CUDA SDK Versions up to 9 are recommended. If you use CUDA>=10, remove `SConscript('GPUampcor/SConscript')` from `isce2/components/zerodop/SConscript` file: this module uses a device cublas feature which is no longer supported. There are other GPU accelerated ampcor utilities available. 
    * The CUDA compiler by default targets NVIDIA GPUs with compute capability 3.5 (K40, K80). If you prefer to compile CUDA code best suited to the GPU you have,  find `env['ENABLESHAREDNVCCFLAG']` in `${HOME}/tools/src/isce2/scons_tools/cuda.py` file, and change `-arch=sm_35` to an approiate setting, e.g., P100 `-arch=sm_60`, GTX1080 `-arch=sm_61`, V100 `-arch=sm_70`. 
    * `libcuda.so` is in general installed to a system directory. You may need to add that directory to `CUDALIBPATH`, either to `SConfigISCE` or in `${HOME}/tools/src/isce2/scons_tools/cuda.py` file, change the relevant file to 
       
          env.Append(CUDALIBPATH=[cudaToolkitPath + '/lib', cudaToolkitPath + '/lib64'], '/lib64')
         where `/lib64` is the directory to find `libcuda.so` file. (actually, this shared library is not needed to compile isce2 modules; we will remove it later). 
 
6. Some settings for environment variables before compile/install. You need to specify three environment variables 
* `CONDA_PREFIX` where Anaconda3 is installed
* `ISCE_HOME` where isce2 will be installed
* `SCONS_CONFIG_DIR` where the `SConfigISCE` is located. 
if they are not set. Check by, e.g.,  `echo $CONDA_PREFIX`. 

For `csh`, 

       setenv CUDA_PREFIX ${HOME}/anaconda3
       setenv ISCE_HOME ${HOME}/tools/isce
       setenv SCONS_CONFIG_DIR ${HOME}/.isce

and for `bash`, 

       export CUDA_PREFIX=${HOME}/anaconda3
       export ISCE_HOME=${HOME}/tools/isce
       export SCONS_CONFIG_DIR=${HOME}/.isce
       
7. Compile/install isce2

       cd ${HOME}/tools/src/isce
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
      setenv ISCE_HOME $HOME/isce
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

 



 

