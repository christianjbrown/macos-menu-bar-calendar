#!/bin/zsh
# Builds instrumented binaries, runs the unit tests (including an end-to-end launch of
# the app), and fails unless every source file is 100% covered by lines, functions and
# regions, and every type has run.
#
# Swift does not emit llvm-cov branch counters. Instead every branch arm (each side of
# an if, guard, switch case, ternary, && or ||) is its own coverage region, so 100%
# region coverage is the branch coverage gate.
set -euo pipefail
cd "${0:A:h}/.."

build=.build/coverage
profiles="$build/profiles"
flags=(-Xswiftc -profile-generate -Xswiftc -profile-coverage-mapping)

mkdir -p "$build"
if ! swift build --build-path "$build" "${flags[@]}" > "$build/build.log" 2>&1; then
  grep -E "error" "$build/build.log" >&2
  exit 1
fi
bin="$(swift build --build-path "$build" --show-bin-path)"

rm -rf "$profiles" && mkdir -p "$profiles"
# %p gives each process its own file, so the launched app writes its own profile.
LLVM_PROFILE_FILE="$PWD/$profiles/%p.profraw" MBC_APP_BINARY="$bin/MenuBarCalendar" \
  "$bin/MenuBarCalendarTests"

xcrun llvm-profdata merge -sparse "$profiles"/*.profraw -o "$profiles/merged.profdata"
cov_args=("$bin/MenuBarCalendarTests" -object "$bin/MenuBarCalendar"
          -instr-profile "$profiles/merged.profdata" -ignore-filename-regex "(Tests|\.build)/")

xcrun llvm-cov report "${cov_args[@]}"
xcrun llvm-cov export "${cov_args[@]}" > "$profiles/coverage.json"
python3 -I scripts/check_coverage.py "$profiles/coverage.json" Sources
