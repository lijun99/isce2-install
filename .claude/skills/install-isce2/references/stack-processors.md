# Stack processors (topsStack, stripmapStack, alosStack)

The conda-forge package already ships them in `$CONDA_PREFIX/share/isce2`. Just set
`ISCE_STACK` to that and skip to "Load one stack" below. Source builds need one of these
three setups. Ask which the user wants; option B is the default for installs into `$CONDA_PREFIX`.

**A. Use them straight from the source tree** (good for development):

```bash
export ISCE_STACK=${HOME}/tools/src/isce2/contrib/stack
export PYTHONPATH=${PYTHONPATH}:${ISCE_STACK}
```

**B. isce2 installed into `$CONDA_PREFIX`** (copies them the same way the conda-forge recipe does):

```bash
mkdir -p $CONDA_PREFIX/share/isce2
cp -R $HOME/tools/src/isce2/contrib/stack/* $CONDA_PREFIX/share/isce2
export ISCE_STACK=$CONDA_PREFIX/share/isce2
export PYTHONPATH=${PYTHONPATH}:${ISCE_STACK}
```

**C. isce2 installed into a custom `$ISCE_HOME`** (cmake or scons):

```bash
echo $ISCE_HOME            # make sure it's set
cp -R $HOME/tools/src/isce2/contrib/stack $ISCE_HOME
export ISCE_STACK=$ISCE_HOME/stack
export PYTHONPATH=${PYTHONPATH}:${ISCE_STACK}
```

## Load one stack

```bash
export PATH=${PATH}:${ISCE_STACK}/topsStack       # Sentinel-1 TOPS
export PATH=${PATH}:${ISCE_STACK}/stripmapStack   # StripMap
export PATH=${PATH}:${ISCE_STACK}/alosStack       # ALOS-2
```

**Load only one at a time.** The stacks share submodule names
(https://github.com/isce-framework/isce2/tree/main/contrib/stack#important-note). To switch
stacks, open a new shell. Don't put more than one of these lines in an rc file that every
shell loads.
