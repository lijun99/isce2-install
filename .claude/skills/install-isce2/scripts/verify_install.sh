#!/usr/bin/env bash
# Check that an ISCE2 install loads and runs. Run it inside the env/rc that loads isce2.

pass=0; fail=0
ok()  { echo "PASS  $1"; pass=$((pass+1)); }
bad() { echo "FAIL  $1"; [ -n "$2" ] && echo "$2" | tail -n5 | sed 's/^/      /'; fail=$((fail+1)); }
have() { command -v "$1" >/dev/null 2>&1; }

out=$(python3 -c 'import isce, os; print(os.path.dirname(isce.__file__))' 2>&1)
if [ $? -eq 0 ]; then ok "import isce -> $(echo "$out" | tail -n1)"; else bad "import isce" "$out"; fi

if [ -n "$ISCE_HOME" ]; then
  [ -d "$ISCE_HOME" ] && ok "ISCE_HOME=$ISCE_HOME" || bad "ISCE_HOME=$ISCE_HOME does not exist"
else
  echo "INFO  ISCE_HOME unset (fine for conda/cmake installs; required for scons)"
fi

if have topsApp.py; then
  # topsApp.py writes isce.log to the cwd; keep it out of the user's directory
  tmp=$(mktemp -d)
  out=$(cd "$tmp" && topsApp.py --help --steps 2>&1)
  [ $? -eq 0 ] && ok "topsApp.py --help --steps" || bad "topsApp.py --help --steps" "$out"
  rm -rf "$tmp"
else
  bad "topsApp.py not on PATH (add \$ISCE_HOME/applications to PATH)"
fi

if have mdx || have mdx.py; then ok "mdx found: $(command -v mdx || command -v mdx.py)"
else echo "INFO  mdx not found (only built when openmotif is available)"; fi

# CUDA modules: only meaningful if built with CUDA
out=$(python3 - 2>&1 <<'EOF'
import importlib
found = []
for m in ("isce.components.contrib.PyCuAmpcor.PyCuAmpcor",
          "isce.components.zerodop.GPUtopozero.GPUtopozero",
          "isce.components.zerodop.GPUgeo2rdr.GPUgeo2rdr"):
    try:
        importlib.import_module(m); found.append(m.rsplit(".", 1)[-1])
    except Exception:
        pass
print(" ".join(found) if found else "none")
EOF
)
echo "INFO  CUDA modules importable: $(echo "$out" | tail -n1)"

if [ -n "$ISCE_STACK" ]; then
  [ -d "$ISCE_STACK/topsStack" ] && ok "ISCE_STACK=$ISCE_STACK" || bad "ISCE_STACK=$ISCE_STACK has no topsStack/"
fi

echo; echo "$pass passed, $fail failed"
[ $fail -eq 0 ]
