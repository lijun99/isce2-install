# Install from conda-forge (default)

Works on `linux-64` (including Windows via WSL) and `osx-64` (Intel Mac), Python 3.9 – 3.12.
**No CUDA modules. No `osx-arm64` build** (openmotif is missing there). Apple Silicon users
should use [macos-homebrew.md](macos-homebrew.md) instead. An `osx-64` conda under Rosetta 2
might work but hasn't been tested.

## Steps

1. Pick an env. Either create a new one (preferred):

   ```bash
   conda create -n isce2 python=3.12
   conda activate isce2
   ```

   or use an existing env, after checking its Python is 3.9 – 3.12. If it isn't, ask before
   changing it with `conda install python=3.12`, because that can break other packages in the env.

2. Install:

   ```bash
   conda install -c conda-forge isce2
   ```

3. Test. It should print `Using default ISCE Path: $CONDA_PREFIX/lib/python3.X/site-packages/isce`:

   ```bash
   python3 -c "import isce"
   ```

4. Environment file. The conda package does **not** put apps or stack processors on `PATH`.
   Offer to write an `isce2.rc` that works the paths out, rather than hardcoding `python3.12`:

   ```bash
   # isce2.rc for conda-forge installation (source after `conda activate isce2`)
   export ISCE_HOME=$(python3 -c 'import isce, os; print(os.path.dirname(isce.__file__))' 2>/dev/null | tail -n1)
   export ISCE_STACK=$CONDA_PREFIX/share/isce2
   export PATH=$ISCE_HOME/bin:$ISCE_HOME/applications:$PATH
   export LD_LIBRARY_PATH=$ISCE_HOME/lib:$LD_LIBRARY_PATH
   export PYTHONPATH=$ISCE_HOME:$ISCE_HOME/applications:$ISCE_HOME/components:$ISCE_HOME/library:$ISCE_STACK:$PYTHONPATH
   ```

   (The README hardcodes `export ISCE_HOME=$CONDA_PREFIX/lib/python3.12/site-packages/isce`. If
   the user wants it static, use that form with the correct Python version.)

5. Smoke test after `source isce2.rc`:

   ```bash
   topsApp.py --help --steps
   mdx.py
   ```

   Stack processors already ship in `$CONDA_PREFIX/share/isce2`. Only the `PATH` line for the
   chosen stack is needed; see [stack-processors.md](stack-processors.md).
