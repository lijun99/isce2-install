---
name: install-isce2
description: Install ISCE2 (InSAR Scientific Computing Environment) on Linux or macOS — from conda-forge, or custom builds with cmake/scons (CUDA/GPU support) or Homebrew/MacPorts (Apple Silicon). Use when the user asks to install, build, compile, reinstall or set up isce2/ISCE, its CUDA modules (PyCuAmpcor etc.), mdx, or the stack processors (topsStack, stripmapStack, alosStack).
argument-hint: "[conda-forge | cmake | scons | homebrew | macports] [--cuda] [--env NAME]"
---

# Install ISCE2

This is the unofficial guide from the isce2-install repo (`README.md`), turned into
steps. Official project: https://github.com/isce-framework/isce2

## 0. Ground rules

- **Ask before anything that needs root or can't easily be undone**: `sudo`, `apt`/`dnf`/`yum`,
  `brew install`, `port install`, removing CommandLineTools, writing to `/opt/local`, and
  editing `~/.bashrc`/`~/.zshrc`. Creating a conda env or cloning into `~/tools/src` is fine
  once the user has agreed to the plan.
- Long builds (`make -j`, `scons install`) should `tee` their output to a log file inside the
  build directory, so you can read the log if the build fails.
- Never hardcode the Python minor version in paths. Work it out:
  `python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")'`.
- Run `conda activate` and the build in the **same** shell command. Shell state does not carry
  between tool calls, so start each step with `source "$(conda info --base)/etc/profile.d/conda.sh" && conda activate <env> && ...`.

## 1. Probe the machine

Run the bundled probe and read the whole report. `scripts/` and `references/` sit next to this
SKILL.md, so use its absolute path; the current directory won't do.

```bash
bash <skill-dir>/scripts/detect_env.sh
```

It reports OS/arch, conda/mamba, active env and Python, compilers (gcc/g++/gfortran and
versions), CUDA (`nvcc`, `nvidia-smi`, GPU compute capability), cmake/scons, system
openmotif (`libXm`), and whether `isce` already imports.

## 2. Choose a method

| Situation | Method | Reference |
|---|---|---|
| linux-64 or osx-64, no GPU needed (**default, easiest**) | conda-forge package | [references/conda-forge.md](references/conda-forge.md) |
| Linux, wants CUDA/GPU modules, or a dev/patched isce2 | cmake from source | [references/linux-cmake.md](references/linux-cmake.md) |
| Linux, user prefers scons / existing `SConfigISCE` workflow | scons from source | [references/linux-scons.md](references/linux-scons.md) |
| macOS Apple Silicon (osx-arm64) — recommended | conda + Homebrew gcc, cmake | [references/macos-homebrew.md](references/macos-homebrew.md) |
| macOS Apple Silicon, needs everything from MacPorts | MacPorts, cmake | [references/macos-macports.md](references/macos-macports.md) |
| Stack processors (any method) | post-install step | [references/stack-processors.md](references/stack-processors.md) |

The conda-forge package has **no CUDA modules** and **no osx-arm64 build**. If the user hasn't
said whether they need the GPU modules and the machine has an NVIDIA GPU, ask. Otherwise pick
the default from the table, say which one you picked, and carry on. The old Intel-Mac
conda+clang route ("MacOSX with Anaconda3 : Intel" in the README) is no longer maintained;
use conda-forge on osx-64 instead.

Read **only** the reference file for the chosen method, then follow it.

## 3. Version guardrails for custom builds (April 2026)

Stay on proven versions unless the user is an experienced developer who knows how to patch:

- Python **3.9 – 3.13** (3.14+ not fully tested; conda-forge package: 3.9 – 3.12)
- numpy **<= 1.26.4** (2.x may have runtime issues): pin it with `"numpy<=1.26.4"`. numpy 1.26
  has no Python 3.13 builds, so with the pin use Python **<= 3.12**. If the user needs 3.13,
  drop the pin and warn them about numpy 2.x.
- CUDA **11 – 12** (e.g. 12.9); avoid 13
- GNU gcc/g++/gfortran **<= 14** (e.g. 13); avoid 15

If the probe finds versions outside these ranges, tell the user and suggest a fix: a different
system compiler, conda `gcc_linux-64=13`-style compilers, `brew install gcc@14`, or
`conda install cuda=12.9 -c nvidia`.

**CUDA 13 caveats** (only if it can't be avoided):
- It needs C++17 and these patches if they haven't been merged yet:
  https://github.com/isce-framework/isce2/compare/main...lijun99:isce2:cuda-13
- It drops GPUs below sm_75 (P100, V100, ...). CUDA 12 drops GPUs below sm_50 (K40, ...).
  Match the CUDA version to the GPU's compute capability from the probe.
- `nvcc` limits which host gcc versions it accepts (NVIDIA host-compiler support policy).

## 4. Verify

```bash
bash <skill-dir>/scripts/verify_install.sh
```

It checks `import isce`, `ISCE_HOME`, `topsApp.py --help --steps`, `mdx` (if built), and the
CUDA modules (PyCuAmpcor etc.) if built. Report what passed and what failed, quoting the output.

## 5. Hand off

Tell the user:
- where isce2 was installed and which env/rc file loads it (offer to write an `isce2.rc`; only
  add it to their shell rc if they say so)
- how to choose a GPU: `CUDA_VISIBLE_DEVICES=n topsApp.py ...` (one GPU per task; running
  several tasks on one device slows them down or crashes them)
- that only **one** stack processor should be on `PATH` per shell (see stack-processors.md)
- where the build log is, if the build had warnings
