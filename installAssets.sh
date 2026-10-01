#!/usr/bin/env bash
#-------------------------------------------------------------------------------
# @file         installAssets.sh                         Last Change: 2026-09-30
# @author       Arthur.Taylor (NWS/OMD/MDSD)
# @brief        Extracts and installs SLOSH assets with paginated parallel UI.
#-------------------------------------------------------------------------------
set -Eeuo pipefail

# @brief Displays CLI usage information.
usage() {
  cat << EOF
Extract and install SLOSH assets from the local tar directory.

Usage: $(basename "$0") [clean | help]

Commands:
  clean       Remove all installed assets (gui, storms, parm)
  help        Display this message and exit
EOF
}

# @brief Captures and logs errors with line numbers before exiting.
errorTrap() {
  echo "ERROR: Command '${2}' failed on line ${1} (Exit: ${3})" >&2
}
trap 'errorTrap ${LINENO} "${BASH_COMMAND}" $?' ERR

# ===== CONFIGURATION =====
readonly SRC_DIR=$(pwd)
readonly TAR_DIR="${SRC_DIR}/tar"
readonly DEV_DIR="${SRC_DIR}/dev"
readonly GUI_DIR="${SRC_DIR}/gui"
readonly PARM_DIR="${SRC_DIR}/parm"
readonly DOCS_DIR="${SRC_DIR}/docs"
readonly STAGE_DIR="${PARM_DIR}/.stage"

# Determine logical CPU cores, default to 4, cap at 8 to prevent I/O thrashing
CPUS=$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 4)
readonly MAX_JOBS=$(( CPUS > 8 ? 8 : CPUS ))

# --- Subdirectories ---
readonly GUI_EXEC_DIR="${GUI_DIR}/exec"
readonly GUI_GEO_DIR="${GUI_DIR}/geodata"
readonly GUI_INC_DIR="${GUI_DIR}/include"
readonly GUI_LIB_DIR="${GUI_DIR}/lib"
readonly BNT_DIR="${PARM_DIR}/bnt"
readonly TIDE_DIR="${PARM_DIR}/tidefile.ec2014"

# --- Registry Files ---
readonly BNT_FILE="${BNT_DIR}/sloshdsp.bnt"
readonly CAVEAT_FILE="${TIDE_DIR}/tide_caveats.txt"
readonly FLAVOR_FILE="${TIDE_DIR}/tide_flavor.txt"

# ===== PHASE 1: EXTRACTION WORKERS =====

# @brief Installs GUI components in an isolated workspace.
installGui() {
  local file="$1"
  local tmpDir="${TAR_DIR}/_gui_tmp"
  mkdir -p "${tmpDir}"
  tar -xzf "${TAR_DIR}/${file}" -C "${tmpDir}"

  local dName="${file//.tar.gz/}"
  mkdir -p "${GUI_EXEC_DIR}" "${GUI_GEO_DIR}" "${GUI_INC_DIR}" "${GUI_LIB_DIR}"

  cp -rp "${tmpDir}/${dName}/exec/"* "${GUI_EXEC_DIR}/"
  cp -rp "${tmpDir}/${dName}/geodata/"* "${GUI_GEO_DIR}/"
  cp -rp "${tmpDir}/${dName}/include/"* "${GUI_INC_DIR}/"
  cp -rp "${tmpDir}/${dName}/lib/"* "${GUI_LIB_DIR}/"

  rm -rf "${tmpDir}"
}

# @brief Installs storm or regression answer datasets.
installStorm() {
  local file="$1"
  local name="${file//.tar.gz/}"
  local tmpDir="${TAR_DIR}/_storm_${name}"
  mkdir -p "${tmpDir}"
  tar -xzf "${TAR_DIR}/${file}" -C "${tmpDir}"

  local stormDir="${SRC_DIR}/storms"
  if [[ "${name}" == "testTrk" ]]; then
    mkdir -p "${stormDir}/testTrk"
    cp -rp "${tmpDir}/${name}/"* "${stormDir}/testTrk/"
  else
    mkdir -p "${stormDir}/testAns/${name}"
    cp -rp "${tmpDir}/${name}/"* "${stormDir}/testAns/${name}/"
  fi

  rm -rf "${tmpDir}"
}

# @brief Removes all installed asset directories and staged metadata.
cleanAll() {
  echo "Cleaning installed SLOSH assets..."
  rm -rf "${PARM_DIR}"
  rm -rf "${GUI_EXEC_DIR}" "${GUI_GEO_DIR}" "${GUI_INC_DIR}" "${GUI_LIB_DIR}"
  rm -rf "${SRC_DIR}/storms/testTrk" "${SRC_DIR}/storms/testAns"
  rm -rf "${STAGE_DIR}"
  echo "Installed assets cleaned."
}

# @brief Extracts basin files and stages metadata for Phase 2.
stageBasin() {
  local file="$1"
  local ray=(${file//./ })
  local geo=${ray[0]}
  local ocean=${geo:0:1}
  ocean=${ocean,,}
  local bsn=${ray[1]}
  local bsnRoot="${geo}.${bsn}"

  local tmpDir="${TAR_DIR}/_bsn_${bsn}"
  mkdir -p "${tmpDir}"
  tar -xzf "${TAR_DIR}/${file}" -C "${tmpDir}"
  local bDir="${tmpDir}/${bsnRoot}"

  local first bsnBnt bsnTide bsnDta
  if [[ ${#bsn} -eq 3 ]]; then
    first=""
    bsnBnt=":p:${bsn}"
    bsnTide=" ${bsn}"
    bsnDta="${bsn^^}"
  else
    first=${bsn:0:1}
    bsnBnt=":${first}:${bsn:1}"
    bsnTide="${first}${bsn:1}"
    bsnDta="${bsn:1}"
    bsnDta="${bsnDta^^}${first}"
  fi

  # 1. Copy Basin DTA File directly
  if [[ -e "${bDir}/${bsn}dta" ]]; then
    local dtaDir="${PARM_DIR}/dta"
    if [[ "${ocean}" == 'x' || "${ocean}" == 'w' ]]; then
      dtaDir="${PARM_DIR}/dta/etss"
    fi
    mkdir -p "${dtaDir}"
    cp "${bDir}/${bsn}dta" "${dtaDir}/"
  fi

  # 2. Process Tides (BHC, ADJ) directly
  if [[ -e "${bDir}/${bsn}.bhc" ]]; then
    local localTideDir="${TIDE_DIR}"
    if [[ "${ocean}" == 'x' ]]; then 
      localTideDir="${TIDE_DIR}/etss"
    fi
    mkdir -p "${localTideDir}"

    rm -f "${localTideDir}/${bsn}.bhc.gz"
    cp "${bDir}/${bsn}.bhc" "${localTideDir}/"
    touch -d "2015-01-01" "${localTideDir}/${bsn}.bhc"
    gzip "${localTideDir}/${bsn}.bhc"

    if [[ -e "${bDir}/${bsn}.adj" ]]; then
      rm -f "${localTideDir}/${bsn}.adj.gz"
      cp "${bDir}/${bsn}.adj" "${localTideDir}/"
      touch -d "2015-01-01" "${localTideDir}/${bsn}.adj"
      gzip "${localTideDir}/${bsn}.adj"
    fi
  fi

  # 3. Stage Metadata Snippets for Phase 2 (Geographically named & \r stripped)
  mkdir -p "${STAGE_DIR}"
  local stagePrefix="${STAGE_DIR}/${geo}.${bsn}"

  if [[ -f "${bDir}/${bsn}_sloshdsp.bnt" ]]; then
    local bntContent
    bntContent=$(head -n 1 "${bDir}/${bsn}_sloshdsp.bnt" | tr -d '\r')
    if [[ -n "${bntContent}" ]]; then
      echo "${bsnBnt}|${bntContent}" > "${stagePrefix}.bnt_meta"
    fi
  fi

  if [[ -f "${bDir}/${bsn}_${first}basins.dta" ]]; then
    local dtaContent
    dtaContent=$(head -n 1 "${bDir}/${bsn}_${first}basins.dta" | tr -d '\r')
    if [[ -n "${dtaContent}" ]]; then
      echo "${first}|${bsnDta}|${dtaContent}" > "${stagePrefix}.dta_meta"
    fi
  fi

  if [[ -f "${bDir}/${bsn}_tideFlavor.txt" ]]; then
    local flavorContent
    flavorContent=$(head -n 1 "${bDir}/${bsn}_tideFlavor.txt" | tr -d '\r')
    if [[ -n "${flavorContent}" ]]; then
      echo "${bsnTide}|${flavorContent}" > "${stagePrefix}.flavor_meta"
    fi
  fi

  rm -rf "${tmpDir}"
}

# ===== UI & PARALLEL CONTROLLER =====

# @brief Executes a single extraction job with dynamic terminal status updates.
# @arg $1 string The file to process.
# @arg $2 string The job type ('gui', 'storm', or 'basin').
# @arg $3 integer The absolute terminal line number to write updates to.
installWorkerUi() {
  local file="${1:-}"
  local type="${2:-}"
  local cLine="${3:-}"
  local pre="\033[${cLine};0H\033[2K"
  local colorReset="\033[0m"
  local colorActive="\033[1;33m" # Bright Yellow
  local colorDone="\033[1;32m"   # Bright Green
  local colorError="\033[1;31m"  # Bright Red

  local action="Extracting"
  if [[ "${type}" == "basin" ]]; then action="Staging"; fi

  printf "${pre}%s: ${colorActive}%s...${colorReset}" "${file}" "${action}"

  local status=0
  if [[ "${type}" == "gui" ]]; then
    installGui "${file}" >/dev/null 2>&1 || status=$?
  elif [[ "${type}" == "storm" ]]; then
    installStorm "${file}" >/dev/null 2>&1 || status=$?
  else
    stageBasin "${file}" >/dev/null 2>&1 || status=$?
  fi

  if [[ ${status} -eq 0 ]]; then
    printf "${pre}%s: ${colorDone}Done${colorReset}" "${file}"
    return 0
  else
    printf "${pre}%s: ${colorError}ERROR (Failed)${colorReset}" "${file}"
    return 1
  fi
}

# @brief Manages parallel extractions with paginated terminal line updates.
# @arg $@ string The list of file names to process.
installParallel() {
  local fileList=("$@")
  local totalJobs=${#fileList[@]}
  local curJob=0

  local termHeight=$(tput lines 2>/dev/null || echo 24)
  local batchSize=$((termHeight - 2))
  if [[ ${batchSize} -lt 1 ]]; then batchSize=1; fi

  while [[ ${curJob} -lt ${totalJobs} ]]; do
    local batchEnd=$((curJob + batchSize))
    if [[ ${batchEnd} -gt ${totalJobs} ]]; then
      batchEnd=${totalJobs}
    fi
    local numJobsInBatch=$((batchEnd - curJob))
    local activeJobs=0
    local -a pids=()
    local row=0

    # Reserve lines for this batch
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
      while [[ ${activeJobs} -lt MAX_JOBS && ${curJob} -lt ${batchEnd} ]]; do
        local file="${fileList[curJob]}"
        local type="basin"

        if [[ "${file}" == "SLOSH-GuiLib.tar.gz" ]]; then
          type="gui"
        elif [[ "${file}" == "testTrk.tar.gz" || "${file}" == gcc* ]]; then
          type="storm"
        fi

        local cLine=$(( row + (curJob - batchStartJob) + 1 ))
        installWorkerUi "${file}" "${type}" "${cLine}" &
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

    # Position cursor safely past batch block
    printf "\033[%d;0H" "$(( row + numJobsInBatch + 1 ))"
  done

  echo ""
}

# ===== PHASE 2: SEQUENTIAL ASSEMBLY =====

# @brief Compiles all staged metadata into master registries sequentially.
finalizeBasins() {
  if [[ ! -d "${STAGE_DIR}" ]]; then return; fi
  echo "Phase 2: Compiling basin registries..."

  mkdir -p "${BNT_DIR}" "${TIDE_DIR}"

  if [[ ! -e "${BNT_FILE}" ]]; then
    echo "<+,* Operational, -,* On Machine>:<type>:<Jye's abbrev>:<Will's abbrev>:<Full name of basin>:<imin> <imax> <jmin> <jmax>:<NAVD_ADJ(9999 = already NAVD)>" \
      > "${BNT_FILE}"
  fi
  if [[ ! -e "${CAVEAT_FILE}" ]]; then
    echo "# Tides in SLOSH Caveats. Amy Haase/ MDL 8/3/2012." > "${CAVEAT_FILE}"
    echo "#<bsnabrev>: comment" >> "${CAVEAT_FILE}"
  fi
  if [[ ! -e "${FLAVOR_FILE}" ]]; then
    echo "# This contains a basin and the preferred tide flavor." \
      > "${FLAVOR_FILE}"
    echo "# Choices are V1, V2, V2.1.X, V2.2.X, V3" >> "${FLAVOR_FILE}"
    echo "# NAVD-88 basins in P-Surge 2.0" >> "${FLAVOR_FILE}"
  fi

  local f bsnBnt oldEntry newEntry first bsnDta bsnTide

  # Process BNT Meta (Glob expands in geographic order due to ${geo} prefix)
  for f in "${STAGE_DIR}"/*.bnt_meta; do
    [[ -e "$f" ]] || continue
    IFS='|' read -r bsnBnt newEntry < "$f"
    if grep -q "${bsnBnt}" "${BNT_FILE}"; then
      oldEntry=$(grep "${bsnBnt}" "${BNT_FILE}" | head -n 1)
      if [[ "${newEntry}" != "${oldEntry}" ]]; then
        sed -i -e "s|${oldEntry}|${newEntry}|" "${BNT_FILE}"
      fi
    else
      echo "${newEntry}" >> "${BNT_FILE}"
    fi
  done

  # Process Flavor Meta (Geographic order)
  for f in "${STAGE_DIR}"/*.flavor_meta; do
    [[ -e "$f" ]] || continue
    IFS='|' read -r bsnTide newEntry < "$f"
    if grep -v "#" "${FLAVOR_FILE}" | grep -q "${bsnTide}"; then
      oldEntry=$(grep -v "#" "${FLAVOR_FILE}" | grep "${bsnTide}" | head -n 1)
      if [[ "${newEntry:1}" != "${oldEntry:1}" ]]; then
        sed -i -e "s|${oldEntry}|${newEntry}|" "${FLAVOR_FILE}"
      fi
    else
      echo "${newEntry}" >> "${FLAVOR_FILE}"
    fi
  done

  # Process DTA Meta
  for f in "${STAGE_DIR}"/*.dta_meta; do
    [[ -e "$f" ]] || continue
    IFS='|' read -r first bsnDta newEntry < "$f"
    local dtaFile="${BNT_DIR}/${first}basins.dta"
    touch "${dtaFile}"
    if grep -q "^${bsnDta}" "${dtaFile}"; then
      oldEntry=$(grep "^${bsnDta}" "${dtaFile}" | head -n 1)
      if [[ "${newEntry}" != "${oldEntry}" ]]; then
        sed -i -e "s|${oldEntry}|${newEntry}|" "${dtaFile}"
      fi
    else
      echo "${newEntry}" >> "${dtaFile}"
    fi
  done

  # Process Flavor Meta
  for f in "${STAGE_DIR}"/*.flavor_meta; do
    [[ -e "$f" ]] || continue
    IFS='|' read -r bsnTide newEntry < "$f"
    if grep -v "#" "${FLAVOR_FILE}" | grep -q "${bsnTide}"; then
      oldEntry=$(grep -v "#" "${FLAVOR_FILE}" | grep "${bsnTide}" | head -n 1)
      if [[ "${newEntry:1}" != "${oldEntry:1}" ]]; then
        sed -i -e "s|${oldEntry}|${newEntry}|" "${FLAVOR_FILE}"
      fi
    else
      echo "${newEntry}" >> "${FLAVOR_FILE}"
    fi
  done

  for f in "${BNT_DIR}/basins.dta" "${BNT_DIR}/ebasins.dta" "${BNT_DIR}/hbasins.dta"; do
    if [[ -e "${f}" ]]; then
      sort -u "${f}" > "${f}.tmp"
      mv "${f}.tmp" "${f}"
    fi
  done

  if [[ -f "${DOCS_DIR}/ft03.dta" ]]; then
    cp "${DOCS_DIR}/ft03.dta" "${TIDE_DIR}/"
  fi
  if [[ -f "${DOCS_DIR}/parm_README.md" ]]; then
    cp "${DOCS_DIR}/parm_README.md" "${PARM_DIR}/README.md"
  fi

  # Purge empty lines and carriage returns from all master registry files
  local regFile
  for regFile in "${BNT_FILE}" "${FLAVOR_FILE}" "${CAVEAT_FILE}" "${BNT_DIR}"/*.dta; do
    if [[ -f "${regFile}" ]]; then
      sed -i -e 's/\r//g' -e '/^[[:space:]]*$/d' "${regFile}"
    fi
  done

  rm -rf "${STAGE_DIR}"
  echo "Registry compilation complete."
}

# ===== MAIN LOGIC =====
main() {
  local cmd="${1:-}"

  case "${cmd}" in
    clean)
      cleanAll
      exit 0
      ;;
    help|-h|--help)
      usage
      exit 0
      ;;
    "")
      # Proceed with normal installation logic...
      ;;
    *)
      echo "ERROR: Unknown command '${cmd}'" >&2
      usage
      exit 1
      ;;
  esac

  if [[ ! -d "${TAR_DIR}" ]]; then
    echo "Notice: No '${TAR_DIR}' directory found. Nothing to install."
    exit 0
  fi

  local tarFiles=()
  while IFS= read -r -d $'\0'; do
      tarFiles+=("$REPLY")
  done < <(find "${TAR_DIR}" -maxdepth 1 -name "*.tar.gz" -print0)

  if [[ ${#tarFiles[@]} -eq 0 ]]; then
    echo "Notice: No .tar.gz files found in '${TAR_DIR}'. Nothing to install."
    exit 0
  fi

  # Sort list: Heavy assets (GUI/Regressions) go first to maximize background usage
  local priorityFiles=()
  local basinFiles=()
  for path in "${tarFiles[@]}"; do
    local file=$(basename "${path}")
    if [[ "${file}" == "SLOSH-GuiLib.tar.gz" || "${file}" == "testTrk.tar.gz" || "${file}" == gcc* ]]; then
      priorityFiles+=("${file}")
    else
      basinFiles+=("${file}")
    fi
  done

  local sortedList=("${priorityFiles[@]:-}" "${basinFiles[@]:-}")

  echo "Phase 1: Extracting assets (MAX_JOBS=${MAX_JOBS})..."
  installParallel "${sortedList[@]}"

  # Phase 2: Run safe sequential assembly
  finalizeBasins

  echo "All assets installed successfully."
}

main "$@"
