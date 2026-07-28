#!/usr/bin/env bash
#
# Benchmark local : Docker build cache + Trivy DB cache
# Usage : ./scripts/benchmark-ci-speed.sh
# Output: speed.md (a la racine du projet)
#

set -euo pipefail

# ── Config ─────────────────────────────────────────────
REPORT_FILE="speed.md"
IMAGE_TAG="myam-backend:test"
DOCKER_CONTEXT="backend"
TRIVY_CACHE_DIR="${HOME}/.cache/trivy"
RUNS=2

# ── Couleurs ───────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; NC='\033[0m'

ok()   { echo -e "  ${GREEN}OK${NC} $1"; }
info() { echo -e "  ${CYAN}INFO${NC} $1"; }
warn() { echo -e "  ${YELLOW}WARN${NC} $1"; }
err()  { echo -e "  ${RED}ERREUR${NC} $1"; }
hr()   { printf "────────────────────────────────────────\n"; }

# ── Helpers ────────────────────────────────────────────
timestamp_ms() {
    python3 -c "import time; print(int(time.time()*1000))" 2>/dev/null || \
    date +%s000
}

duration_ms() {
    local start="$1" end="$2"
    echo "$(( end - start ))"
}

measure() {
    local start end
    start=$(timestamp_ms)
    "$@" >/dev/null 2>&1
    end=$(timestamp_ms)
    duration_ms "$start" "$end"
}

avg() {
    local sum=0 n=0
    for v in "$@"; do sum=$((sum + v)); n=$((n + 1)); done
    echo $(( n > 0 ? sum / n : 0 ))
}

pct() {
    local num="$1" den="$2"
    if [[ "$den" -eq 0 ]]; then echo "0.0"; return; fi
    awk "BEGIN{printf \"%.1f\", ($num/$den)*100}"
}

# ── Verifications ──────────────────────────────────────
cd "$(dirname "$0")/.." || { err "impossible de trouver la racine"; exit 1; }

for cmd in docker trivy python3; do
    command -v "$cmd" &>/dev/null || { err "$cmd non trouve"; exit 1; }
done
docker info &>/dev/null || { err "daemon Docker inaccessible"; exit 1; }

# ── Benchmark ──────────────────────────────────────────
echo ""
echo -e "${CYAN}🔥 Benchmark CI local  |  ${RUNS} run(s)${NC}"
echo -e "${YELLOW}  Docker build${NC} : cold (--no-cache) vs warm"
echo -e "${YELLOW}  Trivy scan${NC}   : cold (DB supprimee) vs warm"
echo ""
hr

docker_cold_times=()
docker_warm_times=()
trivy_cold_times=()
trivy_warm_times=()

for i in $(seq 1 "$RUNS"); do
    echo -e "${CYAN}  --- Run $i / $RUNS ---${NC}"

    # ── Docker cold ──
    echo -n "  Docker cold ... "
    t=$(measure docker build --no-cache -t "$IMAGE_TAG" "$DOCKER_CONTEXT")
    docker_cold_times+=("$t")
    ok "${t} ms"

    # ── Docker warm ──
    echo -n "  Docker warm ... "
    t=$(measure docker build -t "$IMAGE_TAG" "$DOCKER_CONTEXT")
    docker_warm_times+=("$t")
    ok "${t} ms"

    # ── Trivy cold ──
    echo -n "  Trivy cold  ... "
    rm -rf "$TRIVY_CACHE_DIR"
    t=$(measure trivy image --severity HIGH,CRITICAL --scanners vuln --exit-code 0 "$IMAGE_TAG")
    trivy_cold_times+=("$t")
    ok "${t} ms"

    # ── Trivy warm ──
    echo -n "  Trivy warm  ... "
    t=$(measure trivy image --severity HIGH,CRITICAL --scanners vuln --exit-code 0 "$IMAGE_TAG")
    trivy_warm_times+=("$t")
    ok "${t} ms"

    info "run $i terminee"
    echo ""
done

# ── Calculs ────────────────────────────────────────────
docker_cold_avg=$(avg "${docker_cold_times[@]}")
docker_warm_avg=$(avg "${docker_warm_times[@]}")
trivy_cold_avg=$(avg "${trivy_cold_times[@]}")
trivy_warm_avg=$(avg "${trivy_warm_times[@]}")

docker_gain=$(( docker_cold_avg - docker_warm_avg ))
trivy_gain=$(( trivy_cold_avg - trivy_warm_avg ))
[[ $docker_gain -lt 0 ]] && docker_gain=0
[[ $trivy_gain  -lt 0 ]] && trivy_gain=0

docker_gain_pct=$(pct "$docker_gain" "$docker_cold_avg")
trivy_gain_pct=$(pct "$trivy_gain" "$trivy_cold_avg")

# ── Rapport ────────────────────────────────────────────
cat > "$REPORT_FILE" <<EOF
# Benchmark CI local — $(date '+%d/%m/%Y %H:%M')

## Résumé

| Métrique | Cold (ms) | Warm (ms) | Gain (ms) | Gain (%) |
|----------|----------:|----------:|----------:|--------:|
| **Docker build** | $docker_cold_avg | $docker_warm_avg | $docker_gain | $docker_gain_pct |
| **Trivy scan** | $trivy_cold_avg | $trivy_warm_avg | $trivy_gain | $trivy_gain_pct |

## Détail des runs

### Docker build (${RUNS} runs)

| Run | Cold (ms) | Warm (ms) |
|:---:|---------:|---------:|
$(for i in $(seq 0 $(( RUNS - 1 ))); do
    printf "| %d | %d | %d |\n" $(( i + 1 )) "${docker_cold_times[$i]}" "${docker_warm_times[$i]}"
done)
| **Moyenne** | **$docker_cold_avg** | **$docker_warm_avg** |

### Trivy scan (${RUNS} runs)

| Run | Cold (ms) | Warm (ms) |
|:---:|---------:|---------:|
$(for i in $(seq 0 $(( RUNS - 1 ))); do
    printf "| %d | %d | %d |\n" $(( i + 1 )) "${trivy_cold_times[$i]}" "${trivy_warm_times[$i]}"
done)
| **Moyenne** | **$trivy_cold_avg** | **$trivy_warm_avg** |

## Interprétation

| Si ... | Alors ... |
|--------|-----------|
| Gain Docker > 80% | Le cache GHA (\`type=gha,mode=min\`) sera tres efficace |
| Gain Docker < 50% | Verifier que le \`pom.xml\` est stable (pas de changements de dep.) |
| Gain Trivy > 90% | Le cache journalier de la DB est pertinent |
| Build warm < 15s | Objectif atteint |
| Scan warm < 5s | Objectif atteint |

\`\`\`
Cache Docker BuildKit local vs GHA : le backend \`type=gha\` est specifique a
GitHub Actions. Les temps mesurés ici utilisent le cache natif de BuildKit,
qui est fonctionnellement equivalent pour le warm.
\`\`\`

---
*Genere par \`scripts/benchmark-ci-speed.sh\`*
EOF

hr
echo ""
echo -e "${GREEN}Fichier genere :${NC} $REPORT_FILE"
echo ""
