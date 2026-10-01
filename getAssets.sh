#!/usr/bin/env bash
#-------------------------------------------------------------------------------
# @file         getAssets.sh                             Last Change: 2026-09-29
# @author       Arthur.Taylor (NWS/OMD/MDSD)
# @brief        Downloads SLOSH assets from NWS server using parallel fallback.
#-------------------------------------------------------------------------------
set -Eeuo pipefail

readonly FALLBACK_DATES=("2026-09" "2024-07" "2021-05")

# @brief Displays CLI usage information.
usage() {
  cat << EOF
Download SLOSH assets from the NWS server.

Usage: $(basename "$0") <cmd> [args...]

Commands:
  all                      Download all standard assets
  basin [category] [date]  Download basin data
                           Categories: all, tropical, extra, bonus (Default: all)
  gui [date]               Download GUI data
  storm [date]             Download test storm input data
  regression <flavor> [date]
                           Download regression ans (e.g., gcc450-o3, gcc450-o0)
  clean                    Remove downloaded data in $TAR_DIR

Optional:
  [date]                   Force download from a specific historical snapshot.
                           Valid dates are: ${FALLBACK_DATES[@]}
EOF
}

# @brief Captures and logs errors with line numbers before exiting.
errorTrap() {
  echo "ERROR: Command '${2}' failed on line ${1} (Exit: ${3})" >&2
}
trap 'errorTrap ${LINENO} "${BASH_COMMAND}" $?' ERR

# ===== CONFIGURATION =====
readonly ASSET_URL="https://slosh.nws.noaa.gov/slosh/assets"

# Determine logical CPU cores, default to 4, cap at 8 to prevent throttling
CPUS=$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 4)
readonly MAX_JOBS=$(( CPUS > 8 ? 8 : CPUS ))

# --- Basin Categories ---
readonly COMMON_BSNS=(
    "a0102.pn2"  "a0401.pv2"  "a0503.ny3" "a0603.de3"  "a0904.cp5"
    "a1003.hor3" "a1104.ht3"  "a1203.il3" "a1303.hch2" "a1405.esv4"
    "f0103.ejx3" "f1003.etp3" "f1102.cd2" "f1203.ap3"  "f1303.hpa2"
    "f1404.epn3" "g0103.emo2" "g0309.ms7" "g0402.lf2"  "g0505.ebp3"
    "g0604.egl3" "g0702.ps2" "g0803.cr3" "g0903.ebr3"
)
readonly TROP_BSNS=(
    "f0403.eok3" "f0602.hsff" "f0603.hsfe" "f0604.hsfd" "i0302.evi2"
)
readonly ET_BSNS=(
    "f0202.co2"  "f0303.pb3"  "f0503.hmi3" "f0704.eke2" "f0903.efm2"
    "x0103.exm"  "x0205.eglc" "x0303.nep"  "x0401.egoa" "x0602.ebbc"
    "w0401.hakn" "w0501.home" "w0601.hotz" "w0701.hawi" "w0801.hscc"
)
# --- These are added for regression test cases ---
readonly BONUS_BSNS=(
    "g0310.hms8" "i0601.hnl" "i0702.hkw2" "i0202.hsju" "i0305.evi4"
)

# Combine for default operational suite
readonly REQ_BASINS=(
    "${COMMON_BSNS[@]}" "${TROP_BSNS[@]}" "${ET_BSNS[@]}" "${BONUS_BSNS[@]}"
)

readonly REQ_GUI=("SLOSH-GuiLib")
readonly REQ_STORMS=("testTrk")
readonly DEFAULT_REG="gcc450-o3"

# --- Section Directories ---
readonly TAR_DIR="./tar"

# ===== FUNCTIONS =====

# @brief Downloads a single file, updating a specific terminal line.
# @arg $1 string The file to download.
# @arg $2 string The target date (can be empty).
# @arg $3 integer The absolute terminal line number to write updates to.
fetchAssetUi() {
  local file="${1:-}"
  local reqDate="${2:-}"
  local cLine="${3:-}"
  local searchDates=()
  local pre="\033[${cLine};0H\033[2K"
  local ver url
  local colorReset="\033[0m"
  local -a colors=(
    "\033[1;32m" # Bright Green (1st choice)
    "\033[1;33m" # Bright Yellow (2nd choice)
    "\033[1;36m" # Bright Cyan (3rd choice)
    "\033[1;35m" # Bright Magenta (fallback)
  )

  if [[ -n "${reqDate}" ]]; then
    searchDates=("${reqDate}")
  else
    searchDates=("${FALLBACK_DATES[@]}")
  fi
  printf "${pre}%s: Searching..." "${file}"

  local dateIdx=0
  for ver in "${searchDates[@]}"; do
    url="${ASSET_URL}/${ver}/${file}"
    if curl -sfI "${url}" > /dev/null; then
      # Safely grab the color, defaulting to colorReset if out of bounds
      local tagColor="${colors[$dateIdx]:-$colorReset}"
      printf "${pre}%s: Downloading (from %s)..." "${file}" "${ver}"

      if curl -sf "${url}" -o "${TAR_DIR}/${file}"; then
        printf "${pre}%s: Done ${tagColor}[Found in %s]${colorReset}" "${file}" "${ver}"
        return 0
      fi
    fi
    dateIdx=$((dateIdx + 1))
  done
  printf "${pre}%s: \033[1;31mERROR (Not found)\033[0m" "${file}"
  return 1
}

# @brief Manages parallel downloads with paginated terminal line updates.
# @arg $1 string The target date (can be empty).
# @arg $@ string The list of file names to download.
downloadParallel() {
  local targetDate="${1:-}"
  shift
  local fileList=("$@")
  local totalJobs=${#fileList[@]}
  local curJob=0

  if [[ ! -d "${TAR_DIR}" ]]; then
    mkdir -p "${TAR_DIR}"
  fi

  # Determine max safe lines based on terminal height (leave 2 lines for safety)
  local termHeight=$(tput lines 2>/dev/null || echo 24)
  local batchSize=$((termHeight - 2))
  if [[ ${batchSize} -lt 1 ]]; then batchSize=1; fi

  # Process downloads in UI-safe paginated batches
  while [[ ${curJob} -lt ${totalJobs} ]]; do
    local batchEnd=$((curJob + batchSize))
    if [[ ${batchEnd} -gt ${totalJobs} ]]; then
      batchEnd=${totalJobs}
    fi
    local numJobsInBatch=$((batchEnd - curJob))
    local activeJobs=0
    local -a pids=()
    local row=0

    # Pre-allocate lines for JUST this batch
    local i
    for (( i=0; i < numJobsInBatch; i++ )); do
      echo ""
    done

    # Measure cursor position
    echo -en "\033[6n" > /dev/tty || true
    IFS=';' read -s -r -d R -a pos < /dev/tty || true
    if [[ ${#pos[@]} -gt 0 && "${pos[0]:2}" =~ ^[0-9]+$ ]]; then
      row=$((${pos[0]:2} - 1 - numJobsInBatch))
      if [[ ${row} -lt 0 ]]; then row=0; fi
    fi

    local batchStartJob=${curJob}
    while [[ ${curJob} -lt ${batchEnd} || ${activeJobs} -gt 0 ]]; do
      # Start new jobs up to MAX_JOBS concurrency
      while [[ ${activeJobs} -lt MAX_JOBS && ${curJob} -lt ${batchEnd} ]]; do
        local file="${fileList[curJob]}"

        # cLine is relative to the start of the current batch
        local cLine=$(( row + (curJob - batchStartJob) + 1 ))
        fetchAssetUi "${file}" "${targetDate}" "${cLine}" &
        pids[activeJobs]=$!
        curJob=$((curJob + 1))
        activeJobs=$((activeJobs + 1))
      done

      wait -n 2>/dev/null || true

      local newPids=()
      local newActive=0
      for (( i=0; i < activeJobs; i++ )); do
        if kill -0 "${pids[i]}" 2>/dev/null; then
          newPids[newActive]=${pids[i]}
          newActive=$((newActive + 1))
        fi
      done
      activeJobs=${newActive}
      pids=("${newPids[@]:-}")
    done

    # Move cursor safely below the current batch without injecting an extra newline
    printf "\033[%d;0H" "$(( row + numJobsInBatch + 1 ))"
  done

  # Print a final newline only when all batches are entirely complete
  echo ""

  # Trigger the installation phase automatically
  if [[ -x "./installAssets.sh" ]]; then
    echo "Downloads complete."
    read -p "Do you want to install? (y/n): " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
      echo "Starting installation..."
      ./installAssets.sh
    fi
  fi
}

# ===== MAIN LOGIC =====
main() {
  if [[ $# -eq 0 || "${1}" == "help" ]]; then
    usage
    exit 0
  fi

  local cmd="${1}"
  shift

  case "${cmd}" in
    clean)
      echo "Cleaning ${TAR_DIR}..."
      rm -rf "${TAR_DIR}"
      if [[ -x "./installAssets.sh" ]]; then
        ./installAssets.sh clean
      fi
      ;;

    basin)
      local category="all"
      local dateArg=""
      local rawFiles=()

      # Determine if $1 is a date or a category
      if [[ "${1:-}" =~ ^[0-9]{4}-[0-9]{2}$ ]]; then
        dateArg="${1}"
      else
        category="${1:-all}"
        dateArg="${2:-}"
      fi

      case "${category}" in
        tropical) rawFiles=("${COMMON_BSNS[@]}" "${TROP_BSNS[@]}") ;;
        extra)    rawFiles=("${COMMON_BSNS[@]}" "${ET_BSNS[@]}") ;;
        bonus)    rawFiles=("${BONUS_BSNS[@]}") ;;
        all)      rawFiles=("${REQ_BSNS[@]}") ;;
        *)        echo "ERROR: Unknown basin category '${category}'" >&2; exit 1 ;;
      esac

      local files=("${rawFiles[@]/%/.tar.gz}")
      downloadParallel "${dateArg}" "${files[@]}"
      ;;

    gui)
      local files=("${REQ_GUI[@]/%/.tar.gz}")
      downloadParallel "${1:-}" "${files[@]}"
      ;;

    storm)
      local files=("${REQ_STORMS[@]/%/.tar.gz}")
      downloadParallel "${1:-}" "${files[@]}"
      ;;

    regression)
      local flavor="${1:-}"
      if [[ -z "${flavor}" ]]; then
        echo "ERROR: Must specify a regression flavor." >&2
        usage
        exit 1
      fi
      downloadParallel "${2:-}" "${flavor}.tar.gz"
      ;;

    all)
      echo "Downloading all standard assets (Default Regression: ${DEFAULT_REG}):"
      local allFiles=("${REQ_BASINS[@]/%/.tar.gz}" "${REQ_GUI[@]/%/.tar.gz}" "${REQ_STORMS[@]/%/.tar.gz}" "${DEFAULT_REG}.tar.gz")
      downloadParallel "${1:-}" "${allFiles[@]}"
      ;;

    *)
      echo "ERROR: Unknown command '${cmd}'" >&2
      usage
      exit 1
      ;;
  esac
}

main "$@"
