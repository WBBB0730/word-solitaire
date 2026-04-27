#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PRESETS_FILE="$PROJECT_ROOT/export_presets.cfg"
MODE="debug"
GODOT_BIN="${GODOT_BIN:-}"
SELECTED_PRESETS=()

usage() {
	cat <<'USAGE'
Usage:
  tools/export_all.sh [--debug|--release] [preset...]

Examples:
  tools/export_all.sh
  tools/export_all.sh --release
  tools/export_all.sh Android
  tools/export_all.sh macOS
  tools/export_debug.sh
  tools/export_release.sh macOS

Environment:
  GODOT_BIN=/path/to/Godot tools/export_all.sh
USAGE
}

find_godot() {
	if [[ -n "$GODOT_BIN" ]]; then
		printf '%s\n' "$GODOT_BIN"
		return
	fi
	if command -v godot >/dev/null 2>&1; then
		command -v godot
		return
	fi
	if command -v godot4 >/dev/null 2>&1; then
		command -v godot4
		return
	fi
	if [[ -x "/Applications/Godot.app/Contents/MacOS/Godot" ]]; then
		printf '%s\n' "/Applications/Godot.app/Contents/MacOS/Godot"
		return
	fi
	printf 'Godot executable not found. Set GODOT_BIN=/path/to/Godot.\n' >&2
	exit 1
}

preset_rows() {
	awk '
		/^\[preset\.[0-9]+\]$/ {
			if (name != "" && path != "") print name "\t" path
			in_preset = 1
			name = ""
			path = ""
			next
		}
		/^\[/ {
			if (name != "" && path != "") print name "\t" path
			in_preset = 0
			name = ""
			path = ""
			next
		}
		in_preset && /^name=/ {
			name = $0
			sub(/^name="/, "", name)
			sub(/"$/, "", name)
			next
		}
		in_preset && /^export_path=/ {
			path = $0
			sub(/^export_path="/, "", path)
			sub(/"$/, "", path)
			next
		}
		END {
			if (name != "" && path != "") print name "\t" path
		}
	' "$PRESETS_FILE"
}

has_selected_preset() {
	local preset="$1"
	if [[ "${#SELECTED_PRESETS[@]}" -eq 0 ]]; then
		return 0
	fi
	local selected
	for selected in "${SELECTED_PRESETS[@]}"; do
		if [[ "$selected" == "$preset" ]]; then
			return 0
		fi
	done
	return 1
}

temp_export_path() {
	local export_path="$1"
	local dir
	local base
	local name
	local ext
	dir="$(dirname "$export_path")"
	base="$(basename "$export_path")"
	if [[ "$base" == *.* ]]; then
		name="${base%.*}"
		ext="${base##*.}"
		printf '%s/%s.tmp.%s\n' "$dir" "$name" "$ext"
	else
		printf '%s/%s.tmp\n' "$dir" "$base"
	fi
}

while [[ "$#" -gt 0 ]]; do
	case "$1" in
		--debug)
			MODE="debug"
			;;
		--release)
			MODE="release"
			;;
		-h|--help)
			usage
			exit 0
			;;
		*)
			SELECTED_PRESETS+=("$1")
			;;
	esac
	shift
done

if [[ ! -f "$PRESETS_FILE" ]]; then
	printf 'Missing export presets: %s\n' "$PRESETS_FILE" >&2
	exit 1
fi

GODOT="$(find_godot)"
EXPORT_FLAG="--export-debug"
if [[ "$MODE" == "release" ]]; then
	EXPORT_FLAG="--export-release"
fi

exported=0
while IFS=$'\t' read -r preset export_path; do
	if [[ -z "$preset" || -z "$export_path" ]]; then
		continue
	fi
	if ! has_selected_preset "$preset"; then
		continue
	fi
	mkdir -p "$PROJECT_ROOT/$(dirname "$export_path")"
	printf '\n==> Exporting %s (%s)\n' "$preset" "$MODE"
	tmp_path="$(temp_export_path "$export_path")"
	rm -f "$PROJECT_ROOT/$tmp_path" "$PROJECT_ROOT/$tmp_path.idsig"
	if "$GODOT" --headless --path "$PROJECT_ROOT" "$EXPORT_FLAG" "$preset" "$PROJECT_ROOT/$tmp_path"; then
		mv -f "$PROJECT_ROOT/$tmp_path" "$PROJECT_ROOT/$export_path"
		if [[ -f "$PROJECT_ROOT/$tmp_path.idsig" ]]; then
			mv -f "$PROJECT_ROOT/$tmp_path.idsig" "$PROJECT_ROOT/$export_path.idsig"
		else
			rm -f "$PROJECT_ROOT/$export_path.idsig"
		fi
	else
		status=$?
		rm -f "$PROJECT_ROOT/$tmp_path" "$PROJECT_ROOT/$tmp_path.idsig"
		exit "$status"
	fi
	exported=$((exported + 1))
done < <(preset_rows)

if [[ "$exported" -eq 0 ]]; then
	printf 'No matching presets found.\n' >&2
	exit 1
fi

printf '\nExported %d preset(s).\n' "$exported"
