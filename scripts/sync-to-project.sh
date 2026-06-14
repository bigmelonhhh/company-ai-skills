#!/usr/bin/env bash
set -euo pipefail

REPO_URL="https://github.com/bigmelonhhh/company-ai-skills.git"
PROJECT_PATH="$(pwd)"
SOURCE_REPO_PATH=""
CACHE_PATH="${HOME}/.company-ai/company-ai-skills"
SKIP_PULL=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    --project-path)
      PROJECT_PATH="$2"
      shift 2
      ;;
    --source-repo-path)
      SOURCE_REPO_PATH="$2"
      shift 2
      ;;
    --repo-url)
      REPO_URL="$2"
      shift 2
      ;;
    --cache-path)
      CACHE_PATH="$2"
      shift 2
      ;;
    --skip-pull)
      SKIP_PULL=1
      shift
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 2
      ;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_REPO="$(cd "${SCRIPT_DIR}/.." && pwd)"

if [ -n "${SOURCE_REPO_PATH}" ]; then
  SOURCE_REPO="$(cd "${SOURCE_REPO_PATH}" && pwd)"
elif [ -d "${SCRIPT_REPO}/skills" ]; then
  SOURCE_REPO="${SCRIPT_REPO}"
else
  if ! command -v git >/dev/null 2>&1; then
    echo "git is required when --source-repo-path is not provided." >&2
    exit 1
  fi

  if [ ! -d "${CACHE_PATH}/.git" ]; then
    mkdir -p "$(dirname "${CACHE_PATH}")"
    git clone "${REPO_URL}" "${CACHE_PATH}"
  elif [ "${SKIP_PULL}" -eq 0 ]; then
    git -C "${CACHE_PATH}" pull --ff-only
  fi

  SOURCE_REPO="$(cd "${CACHE_PATH}" && pwd)"
fi

SOURCE_SKILLS="${SOURCE_REPO}/skills"
PROJECT_ROOT="$(mkdir -p "${PROJECT_PATH}" && cd "${PROJECT_PATH}" && pwd)"
CODEX_DIR="${PROJECT_ROOT}/.codex"
TARGET_DIR="${CODEX_DIR}/skills"
LOCK_FILE="${CODEX_DIR}/skills.lock.json"

if [ ! -d "${SOURCE_SKILLS}" ]; then
  echo "Source repository does not contain a skills directory: ${SOURCE_SKILLS}" >&2
  exit 1
fi

if ! command -v rsync >/dev/null 2>&1; then
  echo "rsync is required for filtered sync. On Windows, use scripts/sync-to-project.ps1." >&2
  exit 1
fi

mkdir -p "${TARGET_DIR}"

rsync -a --delete \
  --exclude='.installed-version' \
  --exclude='.DS_Store' \
  --exclude='*.tmp' \
  --exclude='*.log' \
  --exclude='node_modules/' \
  --exclude='__pycache__/' \
  "${SOURCE_SKILLS}/" "${TARGET_DIR}/"

COMMIT_SHA="unknown"
if [ -d "${SOURCE_REPO}/.git" ]; then
  COMMIT_SHA="$(git -C "${SOURCE_REPO}" rev-parse HEAD 2>/dev/null || echo unknown)"
fi

SKILL_COUNT="$(find "${TARGET_DIR}" -mindepth 2 -maxdepth 2 -name SKILL.md | wc -l | tr -d ' ')"
SYNCED_AT="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

cat > "${LOCK_FILE}" <<EOF
{
  "source": "${REPO_URL}",
  "sourceRepoPath": "${SOURCE_REPO}",
  "commit": "${COMMIT_SHA}",
  "syncedAt": "${SYNCED_AT}",
  "targetDir": ".codex/skills",
  "skillCount": ${SKILL_COUNT}
}
EOF

echo "Skills synced to ${TARGET_DIR}"
echo "Source commit: ${COMMIT_SHA}"
echo "Skill count: ${SKILL_COUNT}"
