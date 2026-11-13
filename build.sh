#!/usr/bin/env bash
# Usage: ./build.sh [apk|exe|all]   (default: all)
# Override tool locations with GODOT or JAVA_HOME if they move.
set -euo pipefail

TOOLS="$USERPROFILE/Tools"
GODOT="${GODOT:-$TOOLS/Godot/Godot_v3.6.2-stable_win64.exe}"
export JAVA_HOME="${JAVA_HOME:-$TOOLS/jdk-17.0.21+9}"
export PATH="$JAVA_HOME/bin:$PATH"

cd "$(dirname "$0")"
mkdir -p build

build() {
	local mode=$1 preset=$2 out=$3
	echo "Building $out ..."
	rm -f "$out"
	"$GODOT" --no-window --audio-driver Dummy --path . "$mode" "$preset" "$out"
	if [ ! -f "$out" ]; then
		echo "Build failed: $out was not created" >&2
		exit 1
	fi
	echo "Built $out ($(du -h "$out" | cut -f1))"
}

case "${1:-all}" in
	apk) build --export-debug "Android" "build/The Last Ronin.apk" ;;
	exe) build --export "boang game" "build/The Last Ronin.exe" ;;
	all)
		build --export-debug "Android" "build/The Last Ronin.apk"
		build --export "boang game" "build/The Last Ronin.exe"
		;;
	*)
		echo "Usage: $0 [apk|exe|all]" >&2
		exit 1
		;;
esac
