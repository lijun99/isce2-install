#!/usr/bin/env bash
# Probe the machine for what an ISCE2 install needs. Read-only; changes nothing.

section() { printf '\n== %s ==\n' "$1"; }
have() { command -v "$1" >/dev/null 2>&1; }
ver() { have "$1" && { printf '%-10s %s\n' "$1" "$(command -v "$1")"; "$1" --version 2>&1 | grep -m1 -Ei 'version|release|v[0-9]' | sed 's/^/           /'; } || printf '%-10s (not found)\n' "$1"; }

section "Platform"
echo "os/arch:   $(uname -s) $(uname -m)"
if [ -r /etc/os-release ]; then . /etc/os-release; echo "distro:    $PRETTY_NAME"; fi
have sw_vers && echo "macOS:     $(sw_vers -productVersion)"
grep -qi microsoft /proc/version 2>/dev/null && echo "WSL:       yes"

section "Conda"
for c in conda mamba micromamba; do have "$c" && echo "$c: $(command -v "$c")"; done
have conda && echo "base:      $(conda info --base 2>/dev/null)"
echo "CONDA_PREFIX=${CONDA_PREFIX:-(unset)}  CONDA_DEFAULT_ENV=${CONDA_DEFAULT_ENV:-(unset)}"
have conda && { echo "envs:"; conda env list 2>/dev/null | grep -v '^#' | sed '/^$/d;s/^/  /'; }

section "Python"
if have python3; then
  echo "python3:   $(command -v python3)  ($(python3 -c 'import sys; print(sys.version.split()[0])'))"
  python3 - <<'EOF' 2>/dev/null
import importlib, sysconfig
print("include:  ", sysconfig.get_path("include"))
for m in ("numpy", "scipy", "osgeo.gdal", "h5py", "cv2", "Cython", "pybind11", "shapely"):
    try:
        mod = importlib.import_module(m)
        print(f"  {m:<11} {getattr(mod, '__version__', 'ok')}")
    except Exception:
        print(f"  {m:<11} (missing)")
EOF
else
  echo "python3: (not found)"
fi

section "Compilers"
for c in gcc g++ gfortran cc; do ver "$c"; done
if [ "$(uname -s)" = Darwin ]; then
  for c in gcc-14 gfortran-14 gcc-13; do have "$c" && ver "$c"; done
  [ -d /opt/homebrew ] && echo "homebrew:  /opt/homebrew" ; have brew && echo "brew:      $(command -v brew)"
  have port && echo "macports:  $(command -v port)"
  xcode-select -p 2>/dev/null | sed 's/^/xcode:     /'
fi

section "Build tools"
ver cmake; ver scons; ver git
have cython && ! have cython3 && echo "note: cython present but no cython3 link (scons needs it)"

section "CUDA / GPU"
ver nvcc
[ -x /usr/local/cuda/bin/nvcc ] && ! have nvcc && echo "nvcc found at /usr/local/cuda/bin/nvcc (not on PATH)"
if have nvidia-smi; then
  nvidia-smi --query-gpu=index,name,compute_cap,driver_version,memory.total --format=csv 2>&1 | head -n9
else
  echo "nvidia-smi: (not found — no NVIDIA GPU/driver visible)"
fi
have module && echo "environment modules available (try: module avail cuda)"

section "Motif (for mdx)"
if [ "$(uname -s)" = Linux ]; then
  ldconfig -p 2>/dev/null | grep -E -m3 'libXm\.so' || echo "system libXm: (not found)"
fi
[ -n "$CONDA_PREFIX" ] && ls "$CONDA_PREFIX"/lib/libXm.* 2>/dev/null | head -n1 | sed 's/^/conda libXm: /'

section "Existing ISCE2"
echo "ISCE_HOME=${ISCE_HOME:-(unset)}  ISCE_STACK=${ISCE_STACK:-(unset)}"
have python3 && python3 -c 'import isce, os; print("import isce OK:", os.path.dirname(isce.__file__))' 2>&1 | tail -n1
for c in topsApp.py mdx mdx.py; do have "$c" && echo "$c: $(command -v "$c")"; done
[ -d "$HOME/tools/src/isce2/.git" ] && echo "source tree: $HOME/tools/src/isce2 ($(git -C "$HOME/tools/src/isce2" log -1 --format='%h %cs' 2>/dev/null))"
[ -f "$HOME/.isce/SConfigISCE" ] && echo "SConfigISCE: $HOME/.isce/SConfigISCE"
exit 0
