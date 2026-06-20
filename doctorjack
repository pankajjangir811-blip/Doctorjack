#!/usr/bin/env bash

# =================================================================
# Doctorjack - SQLi PRE-FILTERING TOOL | DATA-INTEGRITY EDITION v7.7
# =================================================================
# Purpose:
#   Build clean candidate lists for authorized SQLi/manual review.
#   Doctorjack does NOT prove SQL injection and does NOT run destructive tests.
#
# Main outputs:
#   dynamic_only.txt                    = URLs where basic response behavior changed
#   manual_review_priority.txt          = best manual-review shortlist, never left blank if candidates exist
#   final_review.tsv                    = categorized review file with notes
#   non_reflected_sqli_candidates.txt   = important SQLi candidates not reflected in response
#   metadata.txt                        = audit information for the run
#   vulnerability_testing_plan.html     = OSINT-style browser dashboard
#   report_data.json                    = structured dashboard data
#   input_prepared.txt                  = normalized URL-per-line input used internally/fallback
#
# Safety rule:
#   Use only on systems you own or have written permission to test.
# =================================================================

set -Eeuo pipefail

# --- Colors ---
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
WHITE='\033[1;37m'
NC='\033[0m'
BOLD='\033[1m'

INPUT=""
BASE_OUT="recon"
START_TIME=$(date +%s)
RUN_ID=$(date +"%Y-%m-%d_%H-%M-%S")
OUT="$BASE_OUT/run_$RUN_ID"
HTTPX_MATCH_CODES="200,201,204,301,302,307,308,401,403,405,500"
TOKEN_A="probe_${RUN_ID}_A"
TOKEN_B="probe_${RUN_ID}_B"
CONTENT_LENGTH_DELTA=20
RATE_LIMIT=""
TIMEOUT="10"
SHOW_ANIMATED_INTRO="1"

# Put Go tools first to avoid /usr/bin/httpx or Python httpx conflicts.
export GOPATH="${GOPATH:-$HOME/go}"
export PATH="$GOPATH/bin:$HOME/go/bin:/usr/local/go/bin:$PATH"

usage() {
    cat <<USAGE
Usage: doctorjack -f <url_file> [options]

Required:
  -f <file>        URL/input file

Options:
  -o <dir>         Base output directory. Default: recon
  -c <codes>       HTTP status codes for httpx -mc. Default: $HTTPX_MATCH_CODES
  -d <number>      Content-length delta threshold. Default: $CONTENT_LENGTH_DELTA
  -t <seconds>     HTTP timeout. Default: $TIMEOUT
  -r <rate>        Optional httpx rate limit, for example: -r 20
  --no-intro      Skip animated intro
  -h               Show help

Example:
  doctorjack -f urls.txt
  doctorjack -f urls.txt -o custom_recon -r 20 -t 15
USAGE
}

sleep_tick() {
    local seconds="${1:-0.03}"
    sleep "$seconds" 2>/dev/null || true
}

type_line() {
    local text="$1"
    local color="${2:-$WHITE}"
    local delay="${3:-0.01}"
    local i char
    echo -ne "$color"
    for ((i=0; i<${#text}; i++)); do
        char="${text:$i:1}"
        printf "%s" "$char"
        sleep_tick "$delay"
    done
    echo -e "${NC}"
}

boot_line() {
    local label="$1"
    local value="$2"
    printf "${CYAN}[+]${NC} %-24s" "$label"
    sleep_tick 0.10
    echo -e "${GREEN}$value${NC}"
}

matrix_sweep() {
    local frames=(
        "01001000 01100101 01101100 01101100 01101111"
        "11010011 00110101 10101010 01010101 11100011"
        "00110100 11101010 10011001 01001110 10100101"
    )
    local f
    for f in "${frames[@]}"; do
        echo -ne "${GREEN}\r$f${NC}"
        sleep_tick 0.08
    done
    printf "\r%*s\r" "70" ""
}

show_intro() {
    clear || true

    if [[ "${SHOW_ANIMATED_INTRO:-1}" != "1" ]]; then
        echo -e "${WHITE}${BOLD}Doctorjack Framework v7.7${NC}"
        echo -e "${YELLOW}SQLi Candidate Pre-Filter | Data-Integrity Edition${NC}"
        echo
        return
    fi

    matrix_sweep
    type_line "Initializing Doctorjack diagnostic console..." "$CYAN" 0.012
    boot_line "core" "loaded"
    boot_line "probe engine" "ready"
    boot_line "integrity checks" "enabled"
    boot_line "output mode" "audit-safe"
    sleep_tick 0.12
    echo

    echo -e "${BLUE}"
    cat <<'BANNER'
            ____             _             _             _
           |  _ \  ___   ___| |_ ___  _ __(_) __ _  ___| | __
           | | | |/ _ \ / __| __/ _ \| '__| |/ _` |/ __| |/ /
           | |_| | (_) | (__| || (_) | |  | | (_| | (__|   <
           |____/ \___/ \___|\__\___/|_| _/ |\__,_|\___|_|\_\
                                      |__/

                 [ D O C T O R J A C K   C O N S O L E ]
BANNER
    echo -e "${NC}"
    echo -e "${CYAN}======================================================================${NC}"
    type_line "  Doctorjack Framework v7.7" "$WHITE$BOLD" 0.006
    type_line "  SQLi Candidate Pre-Filter | Data-Integrity Edition" "$WHITE" 0.004
    echo -e "${CYAN}======================================================================${NC}"
    echo -e "${YELLOW}  Mode:${NC} authorized recon filtering only"
    echo -e "${YELLOW}  Flow:${NC} alive → normalize → params → SQLi patterns → reflection → behavior diff"
    echo -e "${YELLOW}  Output:${NC} manual_review_priority.txt | final_review.tsv | vulnerability_testing_plan.tsv | vulnerability_testing_plan.html | dynamic_only.txt"
    echo -e "${CYAN}======================================================================${NC}"
    echo
}

stage_animation() {
    local pid="$1"
    local step="$2"
    local total="$3"
    local name="$4"
    local width=34
    local tick=0
    local frames=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏")
    local pulses=("▁" "▂" "▃" "▄" "▅" "▆" "▇" "█" "▇" "▆" "▅" "▄" "▃" "▂")

    while kill -0 "$pid" 2>/dev/null; do
        local pos=$((tick % width))
        local bar=""
        for ((i=0; i<width; i++)); do
            if [[ "$i" -eq "$pos" ]]; then
                bar+="█"
            elif [[ $(( (i + tick) % 9 )) -eq 0 ]]; then
                bar+="▓"
            elif [[ $(( (i + tick) % 5 )) -eq 0 ]]; then
                bar+="▒"
            else
                bar+="░"
            fi
        done

        local frame="${frames[$((tick % ${#frames[@]}))]}"
        local pulse="${pulses[$((tick % ${#pulses[@]}))]}"
        printf "\r\033[K${CYAN}Stage %d/%d${NC} ${BLUE}[%s]${NC} ${YELLOW}%s${NC} %s %s..." "$step" "$total" "$bar" "$pulse" "$frame" "$name"
        sleep 0.08
        tick=$((tick + 1))
    done

    printf "\r\033[K"
}

count_lines() {
    local file="$1"
    [[ -f "$file" ]] && wc -l < "$file" | tr -d ' ' || echo "0"
}

count_tsv_data_lines() {
    local file="$1"
    if [[ -s "$file" ]]; then
        awk 'NR>1 && NF {c++} END {print c+0}' "$file"
    else
        echo "0"
    fi
}

run_stage() {
    local step="$1"
    local total="$2"
    local name="$3"
    shift 3

    "$@" &
    local pid=$!
    stage_animation "$pid" "$step" "$total" "$name"

    if wait "$pid"; then
        echo -e "${CYAN}Stage $step/$total${NC} ${GREEN}[DONE]${NC} $name"
    else
        local status=$?
        echo -e "${CYAN}Stage $step/$total${NC} ${RED}[FAILED]${NC} $name"
        echo -e "${RED}Stage failed:${NC} $name"
        echo -e "${YELLOW}Check logs in:${NC} $OUT/logs/"
        exit "$status"
    fi
}

warn_empty() {
    local file="$1"
    local label="$2"
    if [[ ! -s "$file" ]]; then
        echo -e "${YELLOW}Warning:${NC} $label is empty. Next dependent stages may also be empty."
    fi
}

check_input_file() {
    if [[ -z "$INPUT" || ! -f "$INPUT" ]]; then
        echo -e "${RED}Error:${NC} input file not found."
        usage
        exit 1
    fi

    INPUT=$(realpath "$INPUT")

    if [[ ! -s "$INPUT" ]]; then
        echo -e "${RED}Error:${NC} input file is empty: $INPUT"
        exit 1
    fi
}

check_dependencies() {
    local required=(httpx uro gf Gxss qsreplace python3)
    local missing=()

    for tool in "${required[@]}"; do
        if ! command -v "$tool" >/dev/null 2>&1; then
            missing+=("$tool")
        fi
    done

    if (( ${#missing[@]} > 0 )); then
        echo -e "${RED}Missing required tools:${NC} ${missing[*]}"
        echo "Run the installer first, then run this pipeline again."
        exit 1
    fi

    # Hard check for the correct ProjectDiscovery httpx.
    # Wrong /usr/bin/httpx or Python httpx usually fails these flags.
    if ! printf '%s\n' 'https://example.com' | httpx -silent -mc 200,301,302 -timeout 5 >/dev/null 2>"$OUT/logs/httpx_validation.err"; then
        echo -e "${RED}httpx exists but does not look like ProjectDiscovery httpx.${NC}"
        echo -e "${YELLOW}Current httpx:${NC} $(command -v httpx || true)"
        echo -e "${YELLOW}Fix:${NC} make sure ~/go/bin is first in PATH and remove conflicting /usr/bin/httpx."
        echo -e "${YELLOW}Log:${NC} $OUT/logs/httpx_validation.err"
        exit 1
    fi

    if ! printf '%s\n' 'https://example.com/item?id=1' | gf sqli >/dev/null 2>"$OUT/logs/gf_pattern_check.log"; then
        echo -e "${RED}gf is installed, but the 'sqli' pattern is missing or broken.${NC}"
        echo -e "${YELLOW}Details:${NC} $OUT/logs/gf_pattern_check.log"
        exit 1
    fi
}

write_metadata() {
    {
        echo "run_id=$RUN_ID"
        echo "input=$INPUT"
        echo "output_dir=$OUT"
        echo "started_at=$(date -Is)"
        echo "httpx_match_codes=$HTTPX_MATCH_CODES"
        echo "http_timeout=$TIMEOUT"
        echo "rate_limit=${RATE_LIMIT:-none}"
        echo "token_a=$TOKEN_A"
        echo "token_b=$TOKEN_B"
        echo "content_length_delta=$CONTENT_LENGTH_DELTA"
        echo "purpose=authorized pre-filtering and manual review"
        echo
        echo "tool_paths:"
        for t in httpx uro gf Gxss qsreplace python3; do
            command -v "$t" 2>/dev/null | sed "s/^/  $t: /" || true
        done
        echo
        echo "tool_versions:"
        httpx -version 2>/dev/null | sed 's/^/  httpx: /' || true
        uro --version 2>/dev/null | sed 's/^/  uro: /' || true
        gf -version 2>/dev/null | sed 's/^/  gf: /' || true
        python3 --version 2>/dev/null | sed 's/^/  python3: /' || true
    } > "$OUT/metadata.txt"
}

prepare_input_urls() {
    # Normalize user input before probing. Some tools export many URLs on one long
    # whitespace-separated line; httpx and the splitter work best with one URL per line.
    python3 - "$INPUT" "$OUT/input_prepared.txt" <<'PYPREP'
import sys, re
from pathlib import Path
src, dst = sys.argv[1], sys.argv[2]
raw = Path(src).read_text(encoding='utf-8', errors='replace')
# Split on whitespace, common separators, and accidental quote wrappers.
parts = re.split(r'[\s,]+', raw)
urls = []
seen = set()
for part in parts:
    u = part.strip().strip('"\'`<>[]()')
    if not u:
        continue
    m = re.search(r'https?://[^\s"\'<>]+', u)
    if m:
        u = m.group(0).rstrip('.,;')
    if not re.match(r'^https?://', u, re.I):
        continue
    if u not in seen:
        seen.add(u)
        urls.append(u)
Path(dst).write_text('\n'.join(urls) + ('\n' if urls else ''), encoding='utf-8')
PYPREP

    if [[ ! -s "$OUT/input_prepared.txt" ]]; then
        echo -e "${RED}Error:${NC} no valid http/https URLs found after input preparation."
        exit 1
    fi

    {
        echo "input_prepared=$OUT/input_prepared.txt"
        echo "input_prepared_count=$(count_lines "$OUT/input_prepared.txt")"
    } >> "$OUT/metadata.txt"
}

apply_parameter_fallback_if_needed() {
    # If alive probing returns zero, still analyze the original parameterized input.
    # This prevents false LOW reports when a host blocks probing, redirects oddly,
    # times out, or the input file contains FUZZ markers not accepted by httpx.
    if [[ -s "$OUT/clean.txt" ]]; then
        return 0
    fi

    if ! grep -q '?' "$OUT/input_prepared.txt" 2>/dev/null; then
        return 0
    fi

    echo -e "${YELLOW}Fallback:${NC} alive probing produced no URLs; continuing parameter analysis from prepared input."
    {
        echo "fallback_mode=enabled"
        echo "fallback_reason=alive_or_clean_empty_but_input_has_parameters"
        echo "parameter_source=$OUT/input_prepared.txt"
    } >> "$OUT/metadata.txt"

    if uro < "$OUT/input_prepared.txt" > "$OUT/clean.txt" 2>>"$OUT/logs/uro_fallback.err"; then
        sort -u "$OUT/clean.txt" -o "$OUT/clean.txt"
    else
        sort -u "$OUT/input_prepared.txt" > "$OUT/clean.txt"
        echo "uro fallback failed; used sort -u on prepared input" >> "$OUT/logs/uro_fallback.err"
    fi
}

# --- Args ---
NORMALIZED_ARGS=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        --no-intro)
            SHOW_ANIMATED_INTRO="0"
            shift
            ;;
        --)
            shift
            while [[ $# -gt 0 ]]; do NORMALIZED_ARGS+=("$1"); shift; done
            ;;
        *)
            NORMALIZED_ARGS+=("$1")
            shift
            ;;
    esac
done
set -- "${NORMALIZED_ARGS[@]}"
while getopts ":f:o:c:d:t:r:h" opt; do
    case "$opt" in
        f) INPUT="$OPTARG" ;;
        o) BASE_OUT="$OPTARG" ;;
        c) HTTPX_MATCH_CODES="$OPTARG" ;;
        d) CONTENT_LENGTH_DELTA="$OPTARG" ;;
        t) TIMEOUT="$OPTARG" ;;
        r) RATE_LIMIT="$OPTARG" ;;
        h) usage; exit 0 ;;
        *) usage; exit 1 ;;
    esac
done

if ! [[ "$CONTENT_LENGTH_DELTA" =~ ^[0-9]+$ ]]; then
    echo -e "${RED}Error:${NC} -d must be a number."
    exit 1
fi

if ! [[ "$TIMEOUT" =~ ^[0-9]+$ ]]; then
    echo -e "${RED}Error:${NC} -t must be a number."
    exit 1
fi

check_input_file
RUN_ID=$(date +"%Y-%m-%d_%H-%M-%S")
OUT="$BASE_OUT/run_$RUN_ID"
TOKEN_A="probe_${RUN_ID}_A"
TOKEN_B="probe_${RUN_ID}_B"
mkdir -p "$OUT/logs"

show_intro
echo -e "${WHITE}${BOLD}Target file:${NC} $INPUT"
echo -e "${WHITE}${BOLD}Output dir :${NC} $OUT"
echo -e "${WHITE}${BOLD}httpx path :${NC} $(command -v httpx 2>/dev/null || echo 'not found')\n"

check_dependencies
write_metadata
prepare_input_urls

TOTAL_STEPS=7

# Prepare files so summary never breaks.
touch "$OUT/input_prepared.txt" "$OUT/alive.txt" "$OUT/clean.txt" "$OUT/split_params.txt" "$OUT/full_params.txt" \
      "$OUT/all_param_candidates.txt" "$OUT/sqli_params.txt" "$OUT/reflected.txt" \
      "$OUT/non_reflected_sqli_candidates.txt" "$OUT/dynamic_candidates.txt" \
      "$OUT/dynamic_only.txt" "$OUT/manual_review_priority.txt" "$OUT/final_review.tsv" \
      "$OUT/parameter_type_analysis.tsv" "$OUT/vulnerability_testing_plan.tsv" "$OUT/vulnerability_testing_plan.html" "$OUT/report_data.json" "$OUT/resp_a.jsonl" "$OUT/resp_b.jsonl"

# Build optional rate flag safely.
HTTPX_RATE_ARGS=()
if [[ -n "$RATE_LIMIT" ]]; then
    HTTPX_RATE_ARGS=(-rl "$RATE_LIMIT")
fi

# Task 1: Alive URLs
run_stage 1 "$TOTAL_STEPS" "Task 1: Probing alive URLs" \
    bash -c 'httpx -silent -mc "$1" -timeout "$2" "${@:5}" < "$3" > "$4" 2> "$5"' \
    _ "$HTTPX_MATCH_CODES" "$TIMEOUT" "$OUT/input_prepared.txt" "$OUT/alive.txt" "$OUT/logs/httpx_alive.err" "${HTTPX_RATE_ARGS[@]}"
warn_empty "$OUT/alive.txt" "alive.txt"

# Task 2: Normalize and deduplicate
run_stage 2 "$TOTAL_STEPS" "Task 2: Normalizing and deduplicating" \
    bash -c 'uro < "$1" | sort -u > "$2" 2> "$3"' \
    _ "$OUT/alive.txt" "$OUT/clean.txt" "$OUT/logs/uro.err"
warn_empty "$OUT/clean.txt" "clean.txt"
apply_parameter_fallback_if_needed

# Task 3: Split query params while preserving original full-param URLs.
run_stage 3 "$TOTAL_STEPS" "Task 3: Extracting and splitting parameters" \
    bash -c '
        : > "$2"
        : > "$3"
        while IFS= read -r url; do
            [[ -z "$url" ]] && continue
            [[ "$url" != *"?"* ]] && continue

            echo "$url" >> "$3"
            base="${url%%\?*}"
            params="${url#*\?}"
            IFS="&" read -ra arr <<< "$params"
            for p in "${arr[@]}"; do
                [[ -n "$p" ]] && printf "%s?%s\n" "$base" "$p" >> "$2"
            done
        done < "$1"
        sort -u "$2" -o "$2"
        sort -u "$3" -o "$3"
    ' _ "$OUT/clean.txt" "$OUT/split_params.txt" "$OUT/full_params.txt"
warn_empty "$OUT/split_params.txt" "split_params.txt"

# Task 4: SQLi pattern filtering.
run_stage 4 "$TOTAL_STEPS" "Task 4: Filtering SQLi-looking parameters" \
    bash -c '
        gf sqli < "$1" | sort -u > "$2" 2> "$3"
        cp "$1" "$4"
    ' _ "$OUT/split_params.txt" "$OUT/sqli_params.txt" "$OUT/logs/gf_sqli.err" "$OUT/all_param_candidates.txt"
warn_empty "$OUT/sqli_params.txt" "sqli_params.txt"

# Task 5: Reflection scan.
# Reflection is enrichment only. Non-reflected SQLi candidates remain important.
run_stage 5 "$TOTAL_STEPS" "Task 5: Checking reflected candidates" \
    bash -c '
        if [[ -s "$1" ]]; then
            Gxss < "$1" | sort -u > "$2" 2> "$3"
        else
            : > "$2"
        fi
        comm -23 <(sort -u "$1") <(sort -u "$2") > "$4" || true
    ' _ "$OUT/sqli_params.txt" "$OUT/reflected.txt" "$OUT/logs/gxss.err" "$OUT/non_reflected_sqli_candidates.txt"
warn_empty "$OUT/reflected.txt" "reflected.txt"

# Task 6: Dynamic behavior check.
# Compares basic response metadata for two inert tokens.
run_stage 6 "$TOTAL_STEPS" "Task 6: Comparing response behavior" \
    bash -c '
        if [[ ! -s "$1" ]]; then
            : > "$4"; : > "$5"; : > "$6"
            exit 0
        fi

        qsreplace "$2" < "$1" | httpx -silent -json -sc -cl -title -mc "$7" -timeout "$11" "${@:12}" > "$4" 2> "$8"
        qsreplace "$3" < "$1" | httpx -silent -json -sc -cl -title -mc "$7" -timeout "$11" "${@:12}" > "$5" 2> "$9"

        python3 - "$4" "$5" "$2" "$3" "$6" "${10}" <<"PY"
import json
import sys

resp_a, resp_b, token_a, token_b, out_file, delta_raw = sys.argv[1:]
delta = int(delta_raw)

def canonical_url(url: str) -> str:
    return url.replace(token_a, "__TOKEN__").replace(token_b, "__TOKEN__")

def load(path):
    data = {}
    with open(path, "r", encoding="utf-8", errors="replace") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                obj = json.loads(line)
            except json.JSONDecodeError:
                continue
            url = obj.get("url") or obj.get("input") or ""
            if not url:
                continue
            key = canonical_url(url)
            data[key] = {
                "url": url,
                "status_code": obj.get("status_code"),
                "content_length": obj.get("content_length"),
                "title": obj.get("title"),
            }
    return data

a = load(resp_a)
b = load(resp_b)

with open(out_file, "w", encoding="utf-8") as out:
    for key in sorted(set(a) & set(b)):
        x, y = a[key], b[key]
        reasons = []

        if x.get("status_code") != y.get("status_code"):
            reasons.append(f"status:{x.get('status_code')}->{y.get('status_code')}")

        clx = x.get("content_length")
        cly = y.get("content_length")
        if isinstance(clx, int) and isinstance(cly, int) and abs(clx - cly) >= delta:
            reasons.append(f"content_length:{clx}->{cly}")

        if (x.get("title") or "") != (y.get("title") or ""):
            reasons.append("title_changed")

        if reasons:
            candidate = x["url"].replace(token_a, "FUZZ")
            out.write(candidate + "\t" + ",".join(reasons) + "\n")
PY
    ' _ "$OUT/reflected.txt" "$TOKEN_A" "$TOKEN_B" "$OUT/resp_a.jsonl" "$OUT/resp_b.jsonl" \
    "$OUT/dynamic_candidates.txt" "$HTTPX_MATCH_CODES" "$OUT/logs/httpx_resp_a.err" "$OUT/logs/httpx_resp_b.err" \
    "$CONTENT_LENGTH_DELTA" "$TIMEOUT" "${HTTPX_RATE_ARGS[@]}"

# Task 7: Build final review lists.
# This fixes the older blank final_review.tsv issue.
run_stage 7 "$TOTAL_STEPS" "Task 7: Building final review files" \
    bash -c '
        python3 - "$1" "$2" "$3" "$4" "$5" "$6" <<"PY"
import sys
from pathlib import Path

dynamic_file, sqli_file, non_ref_file, reflected_file, priority_out, review_out = sys.argv[1:]

rows = []
seen_review = set()
priority_seen = set()
priority = []

def add_priority(url):
    if url and url not in priority_seen:
        priority_seen.add(url)
        priority.append(url)

def add_row(category, url, note, reason=""):
    key = (category, url, note, reason)
    if url and key not in seen_review:
        seen_review.add(key)
        rows.append(key)
        add_priority(url)

def read_lines(path):
    p = Path(path)
    if not p.exists():
        return []
    return [line.strip() for line in p.read_text(encoding="utf-8", errors="replace").splitlines() if line.strip()]

for line in read_lines(dynamic_file):
    parts = line.split("\t", 1)
    url = parts[0]
    reason = parts[1] if len(parts) > 1 else "response_behavior_changed"
    add_row("dynamic_behavior", url, "Basic response metadata changed between inert probes", reason)

for url in read_lines(sqli_file):
    add_row("sqli_pattern", url, "Matched gf sqli pattern; manual review recommended")

for url in read_lines(non_ref_file):
    add_row("non_reflected_sqli_candidate", url, "Important: SQLi does not require reflection")

for url in read_lines(reflected_file):
    add_row("reflected_candidate", url, "Parameter appears reflected; useful enrichment signal")

Path(priority_out).write_text("\n".join(priority) + ("\n" if priority else ""), encoding="utf-8")

with open(review_out, "w", encoding="utf-8") as f:
    f.write("category\turl\tnote\treason\n")
    for category, url, note, reason in rows:
        f.write(f"{category}\t{url}\t{note}\t{reason}\n")
PY

        if [[ -s "$1" ]]; then
            cut -f1 "$1" | sort -u > "$7"
        else
            : > "$7"
        fi
    ' _ "$OUT/dynamic_candidates.txt" "$OUT/sqli_params.txt" "$OUT/non_reflected_sqli_candidates.txt" \
    "$OUT/reflected.txt" "$OUT/manual_review_priority.txt" "$OUT/final_review.tsv" "$OUT/dynamic_only.txt"

# Parameter value type + priority scoring.
# This helps separate numeric-like, string-like, FUZZ marker, empty, and mixed parameter values.
build_parameter_type_analysis() {
    local out_file="$OUT/parameter_type_analysis.tsv"
    python3 - "$OUT/split_params.txt" "$OUT/sqli_params.txt" "$OUT/reflected.txt" "$OUT/non_reflected_sqli_candidates.txt" "$OUT/dynamic_only.txt" "$OUT/manual_review_priority.txt" "$out_file" <<'PYPARAM'
import sys, re, csv
from pathlib import Path
from urllib.parse import urlsplit, parse_qsl, unquote_plus

split_file, sqli_file, reflected_file, nonref_file, dynamic_file, manual_file, out_file = sys.argv[1:]

SQLI_NAMES = {
    'id','uid','user_id','userid','pid','product_id','page_id','post_id','blog_id','news_id','article_id',
    'cat','cat_id','category_id','course_id','item_id','order_id','invoice_id','mid','cid','sid','rid'
}
STRING_NAMES = {'q','query','search','keyword','s','term','name','title','slug','category','city','type','sort','filter'}
REDIRECT_NAMES = {'url','uri','redirect','redirect_url','return','return_url','next','continue','callback','dest','destination','goto'}
PATH_NAMES = {'file','path','page','template','folder','dir','download','document','doc'}
TRACKING_NAMES = {'utm_source','utm_medium','utm_campaign','utm_term','utm_content','fbclid','gclid','ref','source'}
FUZZ_MARKERS = {'FUZZ','INJECT','PAYLOAD','TEST','DOCTORJACK_PROBE','JACK_T1','JACK_T2'}

def read_set(path):
    p=Path(path)
    if not p.exists():
        return set()
    values=set()
    for line in p.read_text(encoding='utf-8', errors='replace').splitlines():
        line=line.strip()
        if not line:
            continue
        values.add(line.split('\t',1)[0])
    return values

sqli_set=read_set(sqli_file)
ref_set=read_set(reflected_file)
nonref_set=read_set(nonref_file)
dyn_set=read_set(dynamic_file)
manual_set=read_set(manual_file)

def value_type(value):
    raw = value if value is not None else ''
    decoded = unquote_plus(raw).strip()
    upper = decoded.upper()
    if decoded == '':
        return 'EMPTY'
    if upper in FUZZ_MARKERS or 'FUZZ' in upper:
        return 'FUZZ_MARKER'
    if re.fullmatch(r'-?\d+(\.\d+)?', decoded):
        return 'NUMERIC_LIKE'
    if re.search(r'[A-Za-z]', decoded) and re.search(r'\d', decoded):
        return 'MIXED_ALPHA_NUMERIC'
    if re.search(r'%[0-9A-Fa-f]{2}', raw):
        return 'ENCODED_STRING'
    if re.fullmatch(r'[A-Za-z_\-\.]+', decoded):
        return 'STRING_LIKE'
    return 'COMPLEX_STRING'

def score_param(url, name, vtype):
    lname = (name or '').lower()
    score = 0
    reasons=[]
    vulns=[]
    if lname in SQLI_NAMES or lname.endswith('_id') or lname.endswith('id'):
        score += 45; reasons.append('id-like parameter name'); vulns.append('SQL Injection / IDOR')
    elif lname in STRING_NAMES:
        score += 28; reasons.append('search/string parameter name'); vulns.append('SQL Injection / XSS')
    elif lname in REDIRECT_NAMES:
        score += 38; reasons.append('redirect/url parameter name'); vulns.append('Open Redirect / SSRF')
    elif lname in PATH_NAMES:
        score += 38; reasons.append('file/path/page parameter name'); vulns.append('LFI / Path Traversal')
    elif lname in TRACKING_NAMES:
        score += 8; reasons.append('tracking/noisy parameter name'); vulns.append('Low-signal parameter review')
    else:
        score += 18; reasons.append('generic parameter') ; vulns.append('Input Handling')

    if vtype == 'NUMERIC_LIKE':
        score += 25; reasons.append('numeric-like value')
    elif vtype == 'FUZZ_MARKER':
        score += 22; reasons.append('FUZZ marker value')
    elif vtype == 'EMPTY':
        score += 15; reasons.append('empty value')
    elif vtype == 'MIXED_ALPHA_NUMERIC':
        score += 13; reasons.append('mixed alpha-numeric value')
    elif vtype in ('STRING_LIKE','ENCODED_STRING','COMPLEX_STRING'):
        score += 10; reasons.append('string-like value')

    if url in dyn_set:
        score += 30; reasons.append('dynamic behavior signal')
    if url in sqli_set:
        score += 22; reasons.append('gf sqli pattern match')
    if url in nonref_set:
        score += 18; reasons.append('non-reflected SQLi candidate')
    if url in ref_set:
        score += 12; reasons.append('reflection signal')
    if url in manual_set:
        score += 10; reasons.append('manual priority shortlist')

    score = min(score, 100)
    if score >= 75:
        priority='P1'; label='HIGH PRIORITY'
    elif score >= 55:
        priority='P2'; label='REVIEW'
    elif score >= 30:
        priority='P3'; label='WATCH'
    else:
        priority='P4'; label='LOW SIGNAL'

    if lname in SQLI_NAMES or lname.endswith('_id') or lname.endswith('id') or url in sqli_set or url in nonref_set:
        action='Manual SQLi review first; numeric or FUZZ values are not required but improve triage confidence.'
        tools='Burp Suite Repeater, sqlmap, curl'
        command='sqlmap -u "URL_HERE" --batch --level 1 --risk 1 --random-agent'
    elif lname in REDIRECT_NAMES:
        action='Review redirect destination validation and allow-list behavior.'
        tools='Burp Suite Repeater, curl'
        command='curl -I "URL_HERE"'
    elif lname in PATH_NAMES:
        action='Review path/file handling safely; do not run destructive payloads.'
        tools='Burp Suite Repeater, curl'
        command='curl -I "URL_HERE"'
    else:
        action='Review input handling and response behavior manually.'
        tools='Burp Suite Repeater, curl, httpx'
        command='echo "URL_HERE" | httpx -silent -sc -cl -title'
    return score, priority, label, '; '.join(dict.fromkeys(reasons)), ', '.join(dict.fromkeys(vulns)), action, tools, command

rows=[]
seen=set()
p=Path(split_file)
if p.exists():
    for url in p.read_text(encoding='utf-8', errors='replace').splitlines():
        url=url.strip()
        if not url or '?' not in url:
            continue
        try:
            pairs=parse_qsl(urlsplit(url).query, keep_blank_values=True)
        except Exception:
            pairs=[]
        if not pairs:
            continue
        for name, value in pairs:
            key=(url,name,value)
            if key in seen:
                continue
            seen.add(key)
            vt=value_type(value)
            score, pri, label, reason, vulns, action, tools, cmd = score_param(url, name, vt)
            rows.append({
                'priority': pri,
                'score': score,
                'label': label,
                'param_name': name,
                'value_type': vt,
                'value_sample': value,
                'url': url,
                'related_vulnerabilities': vulns,
                'reason': reason,
                'recommended_next_action': action,
                'suggested_tools': tools,
                'safe_command_template': cmd,
            })

rows.sort(key=lambda r: (-int(r['score']), r['priority'], r['param_name'], r['url']))
fields=['priority','score','label','param_name','value_type','value_sample','url','related_vulnerabilities','reason','recommended_next_action','suggested_tools','safe_command_template']
with open(out_file, 'w', encoding='utf-8', newline='') as f:
    w=csv.DictWriter(f, fieldnames=fields, delimiter='\t')
    w.writeheader()
    for r in rows:
        w.writerow(r)
PYPARAM
}

build_parameter_type_analysis
PARAM_ANALYSIS_TOTAL=$(awk 'NR>1 && NF {c++} END{print c+0}' "$OUT/parameter_type_analysis.tsv")

warn_empty "$OUT/manual_review_priority.txt" "manual_review_priority.txt"

# --- Enhanced Summary UI ---
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))
{
    echo "completed_at=$(date -Is)"
    echo "duration_seconds=$DURATION"
} >> "$OUT/metadata.txt"

metric_count() {
    count_lines "$1"
}

metric_tsv_count() {
    count_tsv_data_lines "$1"
}

pct_of() {
    local part="${1:-0}"
    local total="${2:-0}"
    if [[ "$total" -le 0 ]]; then
        echo "0.0%"
    else
        awk -v p="$part" -v t="$total" 'BEGIN { printf "%.1f%%", (p/t)*100 }'
    fi
}

mini_bar() {
    local value="${1:-0}"
    local max="${2:-0}"
    local width="${3:-20}"
    if [[ "$max" -le 0 ]]; then
        printf '%*s' "$width" '' | tr ' ' '░'
        return
    fi
    python3 - "$value" "$max" "$width" <<'PYBAR'
import sys
value=int(float(sys.argv[1]))
maxv=max(1, int(float(sys.argv[2])))
width=int(sys.argv[3])
filled=round((value/maxv)*width)
filled=max(0, min(width, filled))
print("█"*filled + "░"*(width-filled), end="")
PYBAR
}

signal_tag() {
    local value="${1:-0}"
    local kind="${2:-normal}"
    if [[ "$value" -le 0 ]]; then
        echo -e "${BLUE}LOW${NC}"
    elif [[ "$kind" == "dynamic" ]]; then
        echo -e "${RED}HIGH${NC}"
    elif [[ "$kind" == "review" ]]; then
        echo -e "${YELLOW}REVIEW${NC}"
    else
        echo -e "${GREEN}OK${NC}"
    fi
}

INPUT_TOTAL=$(metric_count "$INPUT")
PREPARED_TOTAL=$(metric_count "$OUT/input_prepared.txt")
ALIVE_TOTAL=$(metric_count "$OUT/alive.txt")
CLEAN_TOTAL=$(metric_count "$OUT/clean.txt")
FULL_PARAM_TOTAL=$(metric_count "$OUT/full_params.txt")
SPLIT_TOTAL=$(metric_count "$OUT/split_params.txt")
ALL_PARAM_TOTAL=$(metric_count "$OUT/all_param_candidates.txt")
SQLI_TOTAL=$(metric_count "$OUT/sqli_params.txt")
REFLECTED_TOTAL=$(metric_count "$OUT/reflected.txt")
NONREF_TOTAL=$(metric_count "$OUT/non_reflected_sqli_candidates.txt")
DYNAMIC_TOTAL=$(metric_count "$OUT/dynamic_only.txt")
PRIORITY_TOTAL=$(metric_count "$OUT/manual_review_priority.txt")
REVIEW_TOTAL=$(metric_tsv_count "$OUT/final_review.tsv")
PLAN_TOTAL=0

if [[ "$DYNAMIC_TOTAL" -gt 0 ]]; then
    OVERALL_SIGNAL="${RED}HIGH PRIORITY${NC}"
    NEXT_ACTION="Review dynamic_only.txt first, then manual_review_priority.txt"
elif [[ "$PRIORITY_TOTAL" -gt 0 ]]; then
    OVERALL_SIGNAL="${YELLOW}MANUAL REVIEW${NC}"
    NEXT_ACTION="Start with manual_review_priority.txt"
else
    OVERALL_SIGNAL="${BLUE}LOW SIGNAL${NC}"
    NEXT_ACTION="No strong candidates generated from this input"
fi

# Suggested vulnerability testing plan.
# This is guidance for authorized manual review. It does not confirm vulnerabilities.
build_testing_plan() {
    local plan_file="$OUT/vulnerability_testing_plan.tsv"
    cat > "$plan_file" <<EOF
priority	source_file	what_to_test	suggested_tools	safe_command_or_script_template	note
P1	manual_review_priority.txt	SQL injection manual review and input-handling validation	Burp Suite Repeater, sqlmap, curl	sqlmap -m "$OUT/manual_review_priority.txt" --batch --level 1 --risk 1 --random-agent	Use only with authorization; low-risk template for triage, not proof.
P1	dynamic_only.txt	Response-difference review; possible injection, logic, or backend behavior change	Burp Suite Comparer/Repeater, httpx, curl	cut -f1 "$OUT/dynamic_candidates.txt" | sort -u > "$OUT/dynamic_only.txt"	Start here if this file has hits because behavior changed between inert probes.
P1	sqli_params.txt	SQLi-looking parameters such as id, page_id, blog_id, product_id	Burp Suite, sqlmap, manual browser testing	sqlmap -m "$OUT/sqli_params.txt" --batch --level 1 --risk 1 --random-agent	Pattern match only; verify manually before reporting.
P1	parameter_type_analysis.tsv	Parameter value-type scoring: numeric, string, FUZZ marker, empty, mixed	Burp Suite Repeater, sqlmap, curl	column -t -s $'\t' "$OUT/parameter_type_analysis.tsv" | less -S	Use this to prioritize which parameters deserve manual testing first; alpha values are valid too.
P1	non_reflected_sqli_candidates.txt	Blind/non-reflected SQLi review	Burp Suite, sqlmap, timing/boolean comparison workflow	sqlmap -m "$OUT/non_reflected_sqli_candidates.txt" --batch --level 1 --risk 1 --random-agent	SQLi does not require reflection, so do not ignore this file.
P2	reflected.txt	Reflected input handling; XSS and output encoding review	Burp Suite, Dalfox, Gxss	dalfox file "$OUT/reflected.txt"	Reflection is an enrichment signal; validate context safely.
P2	split_params.txt	Parameter-based checks: open redirect, LFI/path, IDOR-style object reference, XSS, SSRF indicators	grep, gf, Burp Suite	grep -Ei 'redirect=|url=|next=|return=|file=|path=|id=|user=|account=' "$OUT/split_params.txt" | sort -u	This only groups interesting parameters for manual review.
P3	all_param_candidates.txt	General parameter inventory and coverage review	uro, qsreplace, httpx	qsreplace doctorjack_probe < "$OUT/all_param_candidates.txt" | httpx -silent -sc -cl -title	Useful for seeing whether parameter changes affect pages.
P3	alive.txt	HTTP status, title, technology, server/header review	httpx, nuclei	httpx -silent -sc -title -tech-detect -web-server -l "$OUT/alive.txt"	Good for baseline recon and tech fingerprinting.
P3	clean.txt	General template-based web exposure review	nuclei	nuclei -l "$OUT/clean.txt" -severity low,medium,high,critical	Run only approved templates and keep rate limits reasonable.
P4	final_review.tsv	Consolidated evidence review and report preparation	column, less, spreadsheet viewer	column -t -s $'\t' "$OUT/final_review.tsv" | less -S	Use this as the main readable review index.
EOF
}

build_testing_plan
PLAN_TOTAL=$(metric_tsv_count "$OUT/vulnerability_testing_plan.tsv")

# Structured JSON data for the offline HTML dashboard.
# The HTML dashboard reads this file instead of depending only on vulnerability_testing_plan.tsv.
build_html_report_data() {
    local json_file="$OUT/report_data.json"
    local signal_clean
    signal_clean="$(echo -e "$OVERALL_SIGNAL" | sed -r 's/\x1B\[[0-9;]*[mK]//g')"

    DOCTORJACK_REPORT_JSON="$json_file" \
    DOCTORJACK_RUN_ID="$RUN_ID" \
    DOCTORJACK_INPUT="$INPUT" \
    DOCTORJACK_OUT="$OUT" \
    DOCTORJACK_SIGNAL="$signal_clean" \
    DOCTORJACK_NEXT_ACTION="$NEXT_ACTION" \
    DOCTORJACK_DURATION="$DURATION" \
    DOCTORJACK_INPUT_TOTAL="$INPUT_TOTAL" \
    DOCTORJACK_PREPARED_TOTAL="$PREPARED_TOTAL" \
    DOCTORJACK_ALIVE_TOTAL="$ALIVE_TOTAL" \
    DOCTORJACK_CLEAN_TOTAL="$CLEAN_TOTAL" \
    DOCTORJACK_FULL_PARAM_TOTAL="$FULL_PARAM_TOTAL" \
    DOCTORJACK_SPLIT_TOTAL="$SPLIT_TOTAL" \
    DOCTORJACK_ALL_PARAM_TOTAL="$ALL_PARAM_TOTAL" \
    DOCTORJACK_SQLI_TOTAL="$SQLI_TOTAL" \
    DOCTORJACK_REFLECTED_TOTAL="$REFLECTED_TOTAL" \
    DOCTORJACK_NONREF_TOTAL="$NONREF_TOTAL" \
    DOCTORJACK_DYNAMIC_TOTAL="$DYNAMIC_TOTAL" \
    DOCTORJACK_PRIORITY_TOTAL="$PRIORITY_TOTAL" \
    DOCTORJACK_REVIEW_TOTAL="$REVIEW_TOTAL" \
    DOCTORJACK_PARAM_ANALYSIS_TOTAL="$PARAM_ANALYSIS_TOTAL" \
    DOCTORJACK_PLAN_TOTAL="$PLAN_TOTAL" \
    python3 <<'PYDATA'
import csv, json, os, re
from pathlib import Path

out_dir = Path(os.environ["DOCTORJACK_OUT"])
input_path = os.environ["DOCTORJACK_INPUT"]
json_path = Path(os.environ["DOCTORJACK_REPORT_JSON"])

def env_int(name):
    try:
        return int(os.environ.get(name, "0") or 0)
    except ValueError:
        return 0

def line_count(path):
    p = Path(path)
    if not p.exists() or p.is_dir():
        return 0
    try:
        with p.open("r", encoding="utf-8", errors="replace") as f:
            return sum(1 for _ in f)
    except Exception:
        return 0

def read_lines(path, limit=20):
    p = Path(path)
    if not p.exists() or p.is_dir() or p.stat().st_size == 0:
        return []
    rows = []
    try:
        with p.open("r", encoding="utf-8", errors="replace") as f:
            for i, line in enumerate(f):
                if i >= limit:
                    break
                rows.append(line.rstrip("\n"))
    except Exception as e:
        rows.append(f"[read error: {e}]")
    return rows

def sample_urls(path, limit=25):
    p = Path(path)
    if not p.exists() or p.is_dir() or p.stat().st_size == 0:
        return []
    urls = []
    url_re = re.compile(r"https?://[^\s\t\"'<>]+")
    try:
        with p.open("r", encoding="utf-8", errors="replace") as f:
            for line in f:
                for match in url_re.findall(line):
                    urls.append(match.rstrip(',);]'))
                    if len(urls) >= limit:
                        return urls
    except Exception:
        return urls
    return urls

def read_tsv(path):
    p = Path(path)
    if not p.exists() or p.stat().st_size == 0:
        return []
    try:
        with p.open("r", encoding="utf-8", errors="replace", newline="") as f:
            return list(csv.DictReader(f, delimiter="\t"))
    except Exception:
        return []

purpose_map = {
    "input file": "Original URL list supplied to Doctorjack.",
    "metadata.txt": "Run metadata, tool paths, tokens, and audit details.",
    "logs/": "Error and validation logs created during execution.",
    "input_prepared.txt": "Input normalized to one URL per line before probing and fallback analysis.",
    "alive.txt": "URLs that responded during alive probing.",
    "clean.txt": "Normalized and deduplicated alive URLs.",
    "full_params.txt": "Alive URLs containing query parameters.",
    "split_params.txt": "Parameter-expanded URLs for focused one-parameter review.",
    "all_param_candidates.txt": "Complete parameter candidate inventory.",
    "sqli_params.txt": "URLs matching SQLi-looking parameter patterns.",
    "parameter_type_analysis.tsv": "Parameter value-type classification and priority scoring for numeric, alpha, FUZZ, empty, and mixed values.",
    "reflected.txt": "Candidate URLs where test input reflected in the response.",
    "non_reflected_sqli_candidates.txt": "SQLi-looking candidates not reflected in response; useful for blind/non-reflected review.",
    "dynamic_candidates.txt": "Response comparison rows where status, length, or title changed.",
    "dynamic_only.txt": "URL-only list extracted from dynamic behavior candidates.",
    "manual_review_priority.txt": "Best practical manual-review shortlist; kept useful even when dynamic_only is empty.",
    "final_review.tsv": "Consolidated categorized review index.",
    "vulnerability_testing_plan.tsv": "CLI-friendly testing plan and tool suggestions.",
    "vulnerability_testing_plan.html": "Offline OSINT-style dashboard report.",
    "report_data.json": "Structured data used by the HTML dashboard.",
    "resp_a.jsonl": "Response metadata for first inert probe value.",
    "resp_b.jsonl": "Response metadata for second inert probe value.",
}

config = [
    ("Input & Metadata", "input file", input_path, "Metadata", "P4", "Keep original source for audit and repeatability.", "Recon, Audit", "cat, wc, less", "wc -l \"$INPUT\""),
    ("Input & Metadata", "metadata.txt", out_dir/"metadata.txt", "Metadata", "P4", "Use this to verify run settings and tool versions.", "Audit", "cat, less", f"cat \"{out_dir}/metadata.txt\""),
    ("Input & Metadata", "logs/", out_dir/"logs", "Logs", "P4", "Open when a stage fails or output looks empty.", "Debugging", "ls, cat, less", f"ls -la \"{out_dir}/logs\""),
    ("Recon Results", "alive.txt", out_dir/"alive.txt", "Recon", "P3", "Review responding URLs and baseline HTTP behavior.", "Headers, Tech, Exposure", "httpx, nuclei, curl", f"httpx -silent -sc -title -tech-detect -web-server -l \"{out_dir}/alive.txt\""),
    ("Recon Results", "clean.txt", out_dir/"clean.txt", "Recon", "P3", "Use as normalized baseline for safe template review.", "General Web Exposure", "nuclei, httpx", f"nuclei -l \"{out_dir}/clean.txt\" -severity low,medium,high,critical"),
    ("Recon Results", "full_params.txt", out_dir/"full_params.txt", "Recon", "P3", "Check original parameterized URLs before split context changes.", "Parameter Review", "Burp Suite, httpx", f"less -S \"{out_dir}/full_params.txt\""),
    ("Recon Results", "split_params.txt", out_dir/"split_params.txt", "Recon", "P2", "Review parameter names for redirect, path, IDOR, and SSRF-style indicators.", "Open Redirect, LFI, IDOR, SSRF, XSS", "grep, gf, Burp Suite", f"grep -Ei 'redirect=|url=|next=|return=|file=|path=|id=|user=|account=' \"{out_dir}/split_params.txt\" | sort -u"),
    ("Candidate Results", "all_param_candidates.txt", out_dir/"all_param_candidates.txt", "Candidate", "P3", "Use as full parameter inventory and coverage list.", "Input Handling", "qsreplace, httpx", f"qsreplace doctorjack_probe < \"{out_dir}/all_param_candidates.txt\" | httpx -silent -sc -cl -title"),
    ("Candidate Results", "sqli_params.txt", out_dir/"sqli_params.txt", "Candidate", "P1", "Start SQLi parameter review here when dynamic_only is empty.", "SQL Injection", "Burp Suite Repeater, sqlmap, curl", f"sqlmap -m \"{out_dir}/sqli_params.txt\" --batch --level 1 --risk 1 --random-agent"),
    ("Candidate Results", "parameter_type_analysis.tsv", out_dir/"parameter_type_analysis.tsv", "Candidate", "P1", "Use parameter value type and score to prioritize numeric, alpha, FUZZ marker, empty, and mixed values.", "SQL Injection, XSS, IDOR, Open Redirect, LFI", "Burp Suite Repeater, sqlmap, curl", f"column -t -s $'\t' \"{out_dir}/parameter_type_analysis.tsv\" | less -S"),
    ("Candidate Results", "reflected.txt", out_dir/"reflected.txt", "Candidate", "P2", "Review reflection context and output encoding safely.", "Reflected XSS, Input Encoding", "Burp Suite, Dalfox, Gxss", f"dalfox file \"{out_dir}/reflected.txt\""),
    ("Candidate Results", "non_reflected_sqli_candidates.txt", out_dir/"non_reflected_sqli_candidates.txt", "Candidate", "P1", "Review blind/non-reflected SQLi candidates manually.", "Blind SQL Injection", "Burp Suite Repeater, sqlmap", f"sqlmap -m \"{out_dir}/non_reflected_sqli_candidates.txt\" --batch --level 1 --risk 1 --random-agent"),
    ("Candidate Results", "dynamic_candidates.txt", out_dir/"dynamic_candidates.txt", "Candidate", "P1", "Inspect behavior-change reasons before manual testing.", "Injection, Logic, Backend Behavior", "Burp Comparer, curl, jq", f"column -t -s $'\\t' \"{out_dir}/dynamic_candidates.txt\" | less -S"),
    ("Candidate Results", "dynamic_only.txt", out_dir/"dynamic_only.txt", "Candidate", "P1", "Highest-priority list when response behavior changed.", "Injection, Logic, Backend Behavior", "Burp Suite Repeater, sqlmap, curl", f"sqlmap -m \"{out_dir}/dynamic_only.txt\" --batch --level 1 --risk 1 --random-agent"),
    ("Priority Review", "manual_review_priority.txt", out_dir/"manual_review_priority.txt", "Priority", "P1", "Primary manual review file recommended by Doctorjack.", "SQL Injection, Input Handling", "Burp Suite Repeater, sqlmap, curl", f"sqlmap -m \"{out_dir}/manual_review_priority.txt\" --batch --level 1 --risk 1 --random-agent"),
    ("Priority Review", "final_review.tsv", out_dir/"final_review.tsv", "Priority", "P4", "Readable categorized review index for reporting.", "Report Review", "column, less, spreadsheet viewer", f"column -t -s $'\\t' \"{out_dir}/final_review.tsv\" | less -S"),
    ("Testing Plan", "vulnerability_testing_plan.tsv", out_dir/"vulnerability_testing_plan.tsv", "Plan", "P4", "CLI-readable map of files to safe review workflows.", "Workflow Planning", "column, less", f"column -t -s $'\\t' \"{out_dir}/vulnerability_testing_plan.tsv\" | less -S"),
    ("Testing Plan", "vulnerability_testing_plan.html", out_dir/"vulnerability_testing_plan.html", "Plan", "P4", "Open this full OSINT-style dashboard in Firefox.", "Workflow Planning", "Firefox", f"firefox \"{out_dir}/vulnerability_testing_plan.html\""),
    ("Testing Plan", "report_data.json", out_dir/"report_data.json", "Plan", "P4", "Machine-readable data powering the HTML dashboard.", "Reporting, Automation", "python3, jq", f"python3 -m json.tool \"{out_dir}/report_data.json\" | less"),
    ("Raw Response Metadata", "resp_a.jsonl", out_dir/"resp_a.jsonl", "Candidate", "P4", "Metadata from first inert probe comparison.", "Behavior Diff", "jq, less", f"head -20 \"{out_dir}/resp_a.jsonl\""),
    ("Raw Response Metadata", "resp_b.jsonl", out_dir/"resp_b.jsonl", "Candidate", "P4", "Metadata from second inert probe comparison.", "Behavior Diff", "jq, less", f"head -20 \"{out_dir}/resp_b.jsonl\""),
]

output_files = []
for group, name, path, ftype, priority, action, vulns, tools, cmd in config:
    p = Path(path)
    exists = p.exists()
    is_dir = p.is_dir() if exists else False
    count = 0 if is_dir else line_count(p)
    status = "OK"
    if not exists:
        status = "MISSING"
    elif is_dir:
        status = "OK"
        try:
            count = len(list(p.iterdir()))
        except Exception:
            count = 0
    elif count == 0:
        status = "EMPTY"
    elif priority == "P1":
        status = "HIGH PRIORITY"
    elif priority == "P2":
        status = "REVIEW"
    output_files.append({
        "group": group,
        "name": name,
        "path": str(p),
        "type": ftype,
        "exists": exists,
        "is_dir": is_dir,
        "line_count": count,
        "purpose": purpose_map.get(name, "Generated Doctorjack output file."),
        "priority": priority,
        "recommended_next_action": action,
        "related_vulnerability_categories": [x.strip() for x in vulns.split(',') if x.strip()],
        "suggested_tools": [x.strip() for x in tools.split(',') if x.strip()],
        "safe_command_template": cmd,
        "status": status,
        "preview_lines": [] if is_dir else read_lines(p, 20),
        "sample_urls": [] if is_dir else sample_urls(p, 25),
        "more_available": False if is_dir else (count > 25),
    })

testing_plan = read_tsv(out_dir/"vulnerability_testing_plan.tsv")
final_review = read_tsv(out_dir/"final_review.tsv")

data = {
    "tool": "Doctorjack",
    "version": "7.4",
    "run_id": os.environ.get("DOCTORJACK_RUN_ID", ""),
    "input": input_path,
    "output_dir": str(out_dir),
    "signal": os.environ.get("DOCTORJACK_SIGNAL", ""),
    "next_action": os.environ.get("DOCTORJACK_NEXT_ACTION", ""),
    "duration_seconds": env_int("DOCTORJACK_DURATION"),
    "summary_counts": {
        "input_urls": env_int("DOCTORJACK_INPUT_TOTAL"),
        "alive": env_int("DOCTORJACK_ALIVE_TOTAL"),
        "clean": env_int("DOCTORJACK_CLEAN_TOTAL"),
        "full_params": env_int("DOCTORJACK_FULL_PARAM_TOTAL"),
        "split_params": env_int("DOCTORJACK_SPLIT_TOTAL"),
        "all_param_candidates": env_int("DOCTORJACK_ALL_PARAM_TOTAL"),
        "sqli_params": env_int("DOCTORJACK_SQLI_TOTAL"),
        "reflected": env_int("DOCTORJACK_REFLECTED_TOTAL"),
        "non_reflected": env_int("DOCTORJACK_NONREF_TOTAL"),
        "dynamic": env_int("DOCTORJACK_DYNAMIC_TOTAL"),
        "manual_priority": env_int("DOCTORJACK_PRIORITY_TOTAL"),
        "final_review_rows": env_int("DOCTORJACK_REVIEW_TOTAL"),
        "parameter_type_analysis": env_int("DOCTORJACK_PARAM_ANALYSIS_TOTAL"),
        "testing_plan_rows": env_int("DOCTORJACK_PLAN_TOTAL"),
    },
    "output_files": output_files,
    "testing_plan": testing_plan,
    "final_review_rows": final_review,
    "command_templates": {item[1]: item[8] for item in config},
    "safety_note": "Doctorjack is a pre-filter for authorized manual review. It does not prove vulnerabilities and does not run destructive tests.",
}
json_path.write_text(json.dumps(data, indent=2, ensure_ascii=False), encoding="utf-8")
PYDATA
}

build_html_report_data

# Full offline OSINT-style HTML dashboard.
build_testing_plan_html() {
    local html_file="$OUT/vulnerability_testing_plan.html"
    DOCTORJACK_REPORT_JSON="$OUT/report_data.json" \
    DOCTORJACK_PLAN_HTML="$html_file" \
    python3 <<'PYHTML'
import json, html, os
from pathlib import Path

json_path = Path(os.environ["DOCTORJACK_REPORT_JSON"])
out = Path(os.environ["DOCTORJACK_PLAN_HTML"])
data = json.loads(json_path.read_text(encoding="utf-8")) if json_path.exists() else {}

def esc(v):
    return html.escape(str(v if v is not None else ""), quote=True)

def badge(text):
    t = (text or "LOW").upper()
    cls = "ok"
    if "HIGH" in t or t == "P1": cls = "high"
    elif "REVIEW" in t or t in ("P2", "P3"): cls = "review"
    elif "EMPTY" in t or "LOW" in t: cls = "empty"
    elif "MISSING" in t: cls = "missing"
    return f'<span class="badge {cls}">{esc(text)}</span>'

def priority_badge(p):
    return f'<span class="priority {esc(p).lower()}">{esc(p)}</span>'

files = data.get("output_files", [])
counts = data.get("summary_counts", {})
groups = []
for f in files:
    if f.get("group") not in groups:
        groups.append(f.get("group"))

def metric(label, value, note=""):
    return f'<div class="metric"><span>{esc(label)}</span><strong>{esc(value)}</strong><small>{esc(note)}</small></div>'

metric_html = "".join([
    metric("Input URLs", counts.get("input_urls", 0), "source"),
    metric("Alive", counts.get("alive", 0), "responding"),
    metric("Param Candidates", counts.get("all_param_candidates", 0), "inventory"),
    metric("SQLi Patterns", counts.get("sqli_params", 0), "review"),
    metric("Manual Priority", counts.get("manual_priority", 0), "start here"),
    metric("Dynamic", counts.get("dynamic", 0), "behavior diff"),
])

sidebar_groups = []
for g in groups:
    children = ''.join(f'<a href="#file-{i}">├── {esc(f.get("name"))}</a>' for i, f in enumerate(files) if f.get("group") == g)
    sidebar_groups.append(f'<div class="tree-group"><a class="tree-title" href="#group-{esc(g).replace(" ", "-")}">▸ {esc(g)}</a>{children}</div>')
sidebar_html = ''.join(sidebar_groups)

file_cards = []
for i, f in enumerate(files):
    samples = f.get("sample_urls") or []
    preview = f.get("preview_lines") or []
    sample_html = ''.join(f'<li><code>{esc(u)}</code></li>' for u in samples[:25]) or '<li class="muted">No URL preview available.</li>'
    if f.get("more_available"):
        sample_html += '<li class="muted">More available in the file...</li>'
    preview_html = ''.join(f'<div class="preview-line">{esc(line)}</div>' for line in preview[:20]) or '<div class="muted">File is empty or preview is unavailable.</div>'
    tools_html = ''.join(f'<span class="tool">{esc(t)}</span>' for t in f.get("suggested_tools", []))
    vulns_html = ''.join(f'<span class="vuln">{esc(v)}</span>' for v in f.get("related_vulnerability_categories", []))
    group_anchor = ''
    if i == 0 or files[i-1].get("group") != f.get("group"):
        gid = esc(f.get("group")).replace(" ", "-")
        group_anchor = f'<div id="group-{gid}" class="group-anchor"><span>{esc(f.get("group"))}</span></div>'
    file_cards.append(f'''
{group_anchor}
<details class="file-card" id="file-{i}" open data-priority="{esc(f.get('priority'))}" data-type="{esc(f.get('type'))}" data-status="{esc(f.get('status'))}">
  <summary>
    <div class="file-title"><span class="tree-icon">├──</span><strong>{esc(f.get('name'))}</strong>{priority_badge(f.get('priority'))}{badge(f.get('status'))}</div>
    <div class="file-count">{esc(f.get('line_count'))} hits</div>
  </summary>
  <div class="file-body">
    <div class="info-grid">
      <div><label>Full local path</label><code class="path">{esc(f.get('path'))}</code></div>
      <div><label>Purpose</label><p>{esc(f.get('purpose'))}</p></div>
      <div><label>Recommended next action</label><p>{esc(f.get('recommended_next_action'))}</p></div>
      <div><label>Related vulnerability categories</label><div class="chips">{vulns_html}</div></div>
      <div><label>Suggested tools</label><div class="chips">{tools_html}</div></div>
      <div><label>Safe command template</label><pre class="cmd"><button class="copy" data-copy="{esc(f.get('safe_command_template'))}">Copy</button>{esc(f.get('safe_command_template'))}</pre></div>
    </div>
    <details class="nested" open><summary>Related URLs / Samples</summary><ul class="url-list">{sample_html}</ul></details>
    <details class="nested"><summary>First preview lines</summary><div class="preview">{preview_html}</div></details>
  </div>
</details>''')
file_cards_html = ''.join(file_cards)

plan_tree = []
for row in data.get("testing_plan", []):
    src = row.get("source_file", "")
    match = next((f for f in files if f.get("name") == src), {})
    urls = (match.get("sample_urls") or [])[:10]
    urls_html = ''.join(f'<li>{esc(u)}</li>' for u in urls) or '<li class="muted">No related URLs in preview.</li>'
    if match.get("more_available"):
        urls_html += '<li class="muted">more...</li>'
    plan_tree.append(f'''
<details class="plan-node" data-priority="{esc(row.get('priority'))}" open>
  <summary>{priority_badge(row.get('priority'))}<strong>{esc(src)}</strong></summary>
  <ul class="plan-list">
    <li><b>What to test:</b> {esc(row.get('what_to_test'))}</li>
    <li><b>Suggested tools:</b> {esc(row.get('suggested_tools'))}</li>
    <li><b>Command:</b><pre class="cmd"><button class="copy" data-copy="{esc(row.get('safe_command_or_script_template'))}">Copy</button>{esc(row.get('safe_command_or_script_template'))}</pre></li>
    <li><b>Notes:</b> {esc(row.get('note'))}</li>
    <li><b>Related URLs:</b><ul class="mini-urls">{urls_html}</ul></li>
  </ul>
</details>''')
plan_tree_html = ''.join(plan_tree) or '<div class="empty-state">No testing plan rows available.</div>'

review_rows = []
for row in data.get("final_review_rows", [])[:120]:
    review_rows.append('<tr>' + ''.join(f'<td>{esc(v)}</td>' for v in row.values()) + '</tr>')
review_header = ''
if data.get("final_review_rows"):
    keys = list(data["final_review_rows"][0].keys())
    review_header = '<tr>' + ''.join(f'<th>{esc(k)}</th>' for k in keys) + '</tr>'
review_html = f'<table class="review-table"><thead>{review_header}</thead><tbody>{"".join(review_rows)}</tbody></table>' if review_rows else '<div class="empty-state">No final review rows available.</div>'

html_doc = f'''<!doctype html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>Doctorjack OSINT Tree Dashboard</title>
<style>
:root{{--bg:#f8fbff;--panel:#ffffff;--panel2:#eef6ff;--line:#d7e7ff;--cyan:#0ea5e9;--green:#2563eb;--orange:#f97316;--red:#ea580c;--blue:#1d4ed8;--purple:#2563eb;--pink:#f97316;--text:#102033;--muted:#637083;--shadow:0 22px 70px rgba(29,78,216,.15)}}
*{{box-sizing:border-box}} body{{margin:0;background:linear-gradient(135deg,#fff 0,#f1f7ff 32%,#fff7ed 68%,#fff7ed 100%);color:var(--text);font-family:Inter,ui-sans-serif,system-ui,Segoe UI,Arial,sans-serif}} a{{color:inherit;text-decoration:none}} code,pre{{font-family:ui-monospace,SFMono-Regular,Consolas,monospace}}
.layout{{display:grid;grid-template-columns:310px 1fr;min-height:100vh}} .sidebar{{position:sticky;top:0;height:100vh;overflow:auto;background:rgba(255,255,255,.88);backdrop-filter:blur(18px);border-right:1px solid var(--line);padding:22px;box-shadow:12px 0 45px rgba(15,23,42,.06)}} .brand{{display:flex;gap:12px;align-items:center;margin-bottom:20px}} .logo{{width:45px;height:45px;border-radius:15px;background:linear-gradient(135deg,#0ea5e9,#2563eb,#f97316);display:grid;place-items:center;color:#fff;font-weight:1000;box-shadow:0 12px 30px rgba(29,78,216,.22)}} .brand h1{{font-size:20px;margin:0;background:linear-gradient(90deg,#0f172a,#1d4ed8,#f97316);-webkit-background-clip:text;background-clip:text;color:transparent}} .brand small{{display:block;color:var(--muted);margin-top:3px}}
.sidebar .search{{width:100%;background:#fff;border:1px solid #dbeafe;border-radius:14px;color:var(--text);padding:12px;margin:8px 0 16px;outline:none;box-shadow:0 8px 20px rgba(37,99,235,.06)}} .sidebar .search:focus{{border-color:#38bdf8;box-shadow:0 0 0 4px rgba(14,165,233,.12)}} .filters{{display:flex;flex-wrap:wrap;gap:7px;margin-bottom:18px}} button.filter{{border:1px solid #dbeafe;background:linear-gradient(180deg,#fff,#f8fbff);color:#334155;padding:8px 10px;border-radius:999px;font-weight:800;cursor:pointer;box-shadow:0 4px 12px rgba(15,23,42,.04)}} button.filter.active,button.filter:hover{{border-color:#38bdf8;background:linear-gradient(135deg,#e0f2fe,#fff7ed);box-shadow:0 0 0 3px rgba(14,165,233,.12)}} .tree-group{{border-left:3px solid #bfdbfe;padding-left:12px;margin:12px 0}} .tree-title{{display:block;color:#1d4ed8;font-weight:900;margin-bottom:7px}} .tree-group a:not(.tree-title){{display:block;color:var(--muted);padding:4px 0;font-size:13px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}} .tree-group a:hover{{color:#f97316}}
.main{{padding:26px;overflow:hidden}} .hero{{border:1px solid #dbeafe;background:linear-gradient(135deg,rgba(255,255,255,.96),rgba(239,246,255,.96));border-radius:24px;padding:24px;box-shadow:var(--shadow);position:relative;overflow:hidden}} .hero:before{{content:"";position:absolute;inset:-2px;background:linear-gradient(90deg,transparent,rgba(14,165,233,.22),rgba(249,115,22,.20),transparent);animation:sweep 7s infinite}} @keyframes sweep{{0%{{transform:translateX(-80%)}}60%,100%{{transform:translateX(80%)}}}} .hero>*{{position:relative}} .hero h2{{font-size:clamp(27px,4vw,48px);margin:0 0 8px;background:linear-gradient(90deg,#0f172a,#1d4ed8,#f97316);-webkit-background-clip:text;background-clip:text;color:transparent}} .subtitle{{color:var(--muted);line-height:1.6}} .meta-line{{margin-top:15px;color:#1e3a8a;word-break:break-word}} .metrics{{display:grid;grid-template-columns:repeat(6,minmax(0,1fr));gap:12px;margin-top:18px}} .metric{{background:linear-gradient(180deg,#fff,#f8fbff);border:1px solid #e0e7ff;border-radius:17px;padding:13px;box-shadow:0 10px 26px rgba(15,23,42,.06)}} .metric span{{display:block;color:var(--muted);font-size:11px;text-transform:uppercase;letter-spacing:.09em}} .metric strong{{display:block;font-size:24px;margin:6px 0;color:#0f172a}} .metric small{{color:var(--muted)}}
.section-title{{margin:28px 0 14px;font-size:22px;color:#0f172a}} .group-anchor{{margin:24px 0 10px;color:#2563eb;font-weight:1000;text-transform:uppercase;letter-spacing:.1em;font-size:12px}} .file-card,.plan-node{{border:1px solid #dbeafe;background:rgba(255,255,255,.94);border-radius:18px;margin:12px 0;overflow:hidden;box-shadow:0 14px 35px rgba(37,99,235,.08)}} summary{{cursor:pointer;list-style:none}} summary::-webkit-details-marker{{display:none}} .file-card>summary,.plan-node>summary{{display:flex;justify-content:space-between;gap:14px;align-items:center;padding:16px 18px;border-bottom:1px solid #eef2ff;background:linear-gradient(90deg,#ffffff,#f8fbff)}} .file-title{{display:flex;gap:10px;align-items:center;flex-wrap:wrap}} .tree-icon{{color:#2563eb}} .file-count{{color:var(--muted);font-weight:800;white-space:nowrap}} .file-body{{padding:18px}} .info-grid{{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:14px}} label{{display:block;color:var(--muted);font-size:11px;text-transform:uppercase;letter-spacing:.1em;margin-bottom:7px}} p{{margin:0;line-height:1.55;color:#334155}} .path{{display:block;padding:10px;border:1px solid #dbeafe;border-radius:12px;background:#f8fbff;color:#1d4ed8;white-space:pre-wrap;word-break:break-word}} .chips{{display:flex;flex-wrap:wrap;gap:7px}} .tool,.vuln{{display:inline-flex;background:#e0f2fe;border:1px solid #bae6fd;color:#0369a1;border-radius:999px;padding:6px 9px;font-size:12px;font-weight:800}} .vuln{{background:#fff7ed;border-color:#fed7aa;color:#c2410c}}
.badge,.priority{{display:inline-flex;align-items:center;border-radius:999px;padding:6px 9px;font-size:11px;font-weight:1000;letter-spacing:.04em}} .high,.p1{{background:#fff7ed;color:#c2410c;border:1px solid #fed7aa}} .review,.p2,.p3{{background:#fff7ed;color:#c2410c;border:1px solid #fed7aa}} .ok,.p4{{background:#e0f2fe;color:#1d4ed8;border:1px solid #bfdbfe}} .empty{{background:#e0f2fe;color:#0369a1;border:1px solid #bae6fd}} .missing{{background:#fff7ed;color:#c2410c;border:1px solid #fed7aa}}
.cmd{{position:relative;margin:0;background:#0f172a;border:1px solid #1e293b;border-radius:12px;padding:38px 12px 12px;white-space:pre-wrap;word-break:break-word;color:#e0f2fe;box-shadow:inset 0 0 0 1px rgba(255,255,255,.04)}} .copy{{position:absolute;right:8px;top:8px;border:1px solid #bfdbfe;background:#eff6ff;color:#1d4ed8;border-radius:999px;padding:6px 9px;cursor:pointer;font-size:12px;font-weight:900}} .copy:hover{{background:#dbeafe}} .nested{{margin-top:14px;background:#f8fbff;border:1px solid #e0e7ff;border-radius:14px;padding:12px}} .nested>summary{{font-weight:900;color:#1d4ed8}} .url-list,.mini-urls{{margin:10px 0 0;padding-left:20px}} .url-list li,.mini-urls li{{margin:7px 0;color:#334155;word-break:break-word}} .url-list code{{color:#2563eb}} .preview{{margin-top:10px;background:#f8fafc;border:1px solid #e2e8f0;border-radius:12px;padding:12px;overflow:auto}} .preview-line{{font-size:12px;line-height:1.6;color:#475569;white-space:pre-wrap;word-break:break-word}} .muted,.empty-state{{color:var(--muted)}}
.plan-list{{margin:0;padding:0 18px 18px 42px}} .plan-list li{{margin:10px 0;line-height:1.5;color:#334155}} .review-wrap{{overflow:auto;border:1px solid #dbeafe;border-radius:16px;background:#fff;box-shadow:0 14px 35px rgba(37,99,235,.08)}} .review-table{{width:100%;border-collapse:collapse;min-width:850px}} .review-table th,.review-table td{{padding:11px;border-bottom:1px solid #eef2ff;text-align:left;vertical-align:top;color:#334155}} .review-table th{{color:#1d4ed8;background:#eff6ff;position:sticky;top:0}}
.hidden{{display:none!important}} @media(max-width:1050px){{.layout{{grid-template-columns:1fr}}.sidebar{{position:relative;height:auto}}.metrics{{grid-template-columns:repeat(2,1fr)}}.info-grid{{grid-template-columns:1fr}}}} @media(max-width:560px){{.main{{padding:14px}}.metrics{{grid-template-columns:1fr}}.file-card>summary{{align-items:flex-start;flex-direction:column}}}}
</style></head><body><div class="layout"><aside class="sidebar"><div class="brand"><div class="logo">DJ</div><div><h1>Doctorjack</h1><small>OSINT Tree Dashboard</small></div></div><input id="search" class="search" placeholder="Search files, URLs, tools, commands..."><div class="filters"><button class="filter active" data-filter="ALL">All</button><button class="filter" data-filter="P1">P1</button><button class="filter" data-filter="P2">P2</button><button class="filter" data-filter="P3">P3</button><button class="filter" data-filter="P4">P4</button><button class="filter" data-type="Recon">Recon</button><button class="filter" data-type="Candidate">Candidate</button><button class="filter" data-type="Priority">Priority</button><button class="filter" data-type="Plan">Plan</button><button class="filter" data-type="Logs">Logs</button></div><nav>{sidebar_html}</nav></aside><main class="main"><section class="hero"><h2>Doctorjack Run</h2><div class="subtitle">Complete offline OSINT-style tree report. Doctorjack is a pre-filter for authorized manual review; this dashboard does not prove vulnerabilities.</div><div class="meta-line"><b>Target:</b> {esc(data.get('input'))}<br><b>Output:</b> {esc(data.get('output_dir'))}<br><b>Run ID:</b> {esc(data.get('run_id'))}<br><b>Signal:</b> {badge(data.get('signal'))}<br><b>Next action:</b> {esc(data.get('next_action'))}</div><div class="metrics">{metric_html}</div></section><h2 class="section-title">Output Files Tree</h2>{file_cards_html}<h2 class="section-title">Suggested Testing Plan Tree</h2>{plan_tree_html}<h2 class="section-title">Final Review Rows</h2><div class="review-wrap">{review_html}</div></main></div><script>
const search=document.getElementById('search');const buttons=[...document.querySelectorAll('.filter')];const cards=[...document.querySelectorAll('.file-card,.plan-node')];let activePriority='ALL';let activeType='ALL';function apply(){{const q=(search.value||'').toLowerCase();cards.forEach(c=>{{const p=c.dataset.priority||'';const t=c.dataset.type||'';const okP=activePriority==='ALL'||p===activePriority;const okT=activeType==='ALL'||t===activeType;const okS=c.innerText.toLowerCase().includes(q);c.classList.toggle('hidden',!(okP&&okT&&okS));}})}}buttons.forEach(b=>b.addEventListener('click',()=>{{buttons.forEach(x=>x.classList.remove('active'));b.classList.add('active');activePriority=b.dataset.filter||'ALL';activeType=b.dataset.type||'ALL';apply();}}));search.addEventListener('input',apply);document.querySelectorAll('.copy').forEach(btn=>btn.addEventListener('click',()=>{{navigator.clipboard&&navigator.clipboard.writeText(btn.dataset.copy||'');const old=btn.textContent;btn.textContent='Copied';setTimeout(()=>btn.textContent=old,900);}}));
</script></body></html>'''
out.write_text(html_doc, encoding="utf-8")
PYHTML
}

build_testing_plan_html

MAX_FOR_BARS="$SPLIT_TOTAL"
if [[ "$MAX_FOR_BARS" -lt "$ALIVE_TOTAL" ]]; then MAX_FOR_BARS="$ALIVE_TOTAL"; fi
if [[ "$MAX_FOR_BARS" -le 0 ]]; then MAX_FOR_BARS=1; fi

# Compact single-table graphical summary
# Designed to fit common 100-column terminals without wrapping.
BAR_WIDTH=16

status_plain() {
    local value="${1:-0}"
    local kind="${2:-normal}"
    if [[ "$value" -le 0 ]]; then
        echo "LOW"
    elif [[ "$kind" == "dynamic" ]]; then
        echo "HIGH"
    elif [[ "$kind" == "review" ]]; then
        echo "REVIEW"
    else
        echo "OK"
    fi
}

status_color_compact() {
    local status="${1:-LOW}"
    case "$status" in
        HIGH) printf "${RED}${BOLD}%-6s${NC}" "HIGH" ;;
        REVIEW) printf "${YELLOW}${BOLD}%-6s${NC}" "REVIEW" ;;
        OK) printf "${GREEN}${BOLD}%-6s${NC}" "OK" ;;
        *) printf "${BLUE}${BOLD}%-6s${NC}" "LOW" ;;
    esac
}

shorten() {
    local s="$1"
    local max="$2"
    if (( ${#s} <= max )); then
        printf "%s" "$s"
    else
        printf "%s…" "${s:0:$((max-1))}"
    fi
}

summary_row() {
    local phase="$1"
    local hits="$2"
    local base="$3"
    local file="$4"
    local status="$5"
    local bar pct phase_s file_s
    phase_s="$(shorten "$phase" 22)"
    file_s="$(shorten "$file" 24)"
    bar="$(mini_bar "$hits" "$base" "$BAR_WIDTH")"
    pct="$(pct_of "$hits" "$base")"
    printf "${CYAN}│${NC} %-22s ${CYAN}│${NC} %6s ${CYAN}│${NC} %-16s ${CYAN}│${NC} %7s ${CYAN}│${NC} %-24s ${CYAN}│${NC} " \
        "$phase_s" "$hits" "$bar" "$pct" "$file_s"
    status_color_compact "$status"
    printf " ${CYAN}│${NC}\n"
}

summary_note_line() {
    local label="$1"
    local value="$2"
    local value_s
    value_s="$(shorten "$value" 75)"
    printf "${CYAN}│${NC} ${BOLD}%-10s${NC} %-75s ${CYAN}│${NC}\n" "$label" "$value_s"
}

printf "\n${BOLD}${WHITE}┌──────────────────────────────────────────────────────────────────────────────────────────────┐${NC}\n"
printf "${CYAN}│${NC} ${CYAN}${BOLD}DOCTORJACK ANALYSIS SUMMARY${NC} ${WHITE}single-table graphical view${NC}                                      ${CYAN}│${NC}\n"
printf "${BOLD}${WHITE}├──────────────────────────────────────────────────────────────────────────────────────────────┤${NC}\n"
summary_note_line "Target" "$INPUT"
summary_note_line "Output" "$OUT"
summary_note_line "Runtime" "${DURATION}s"
summary_note_line "Signal" "$(echo -e "$OVERALL_SIGNAL" | sed -r 's/\x1B\[[0-9;]*[mK]//g')"
printf "${BOLD}${WHITE}├────────────────────────┬────────┬──────────────────┬─────────┬──────────────────────────┬────────┤${NC}\n"
printf "${CYAN}│${NC} %-22s ${CYAN}│${NC} %-6s ${CYAN}│${NC} %-16s ${CYAN}│${NC} %-7s ${CYAN}│${NC} %-24s ${CYAN}│${NC} %-6s ${CYAN}│${NC}\n" \
    "Phase" "Hits" "Graph" "Rate" "Output File" "Signal"
printf "${BOLD}${WHITE}├────────────────────────┼────────┼──────────────────┼─────────┼──────────────────────────┼────────┤${NC}\n"
summary_row "Input URLs" "$INPUT_TOTAL" "$INPUT_TOTAL" "source file" "OK"
summary_row "Prepared URLs" "$PREPARED_TOTAL" "$INPUT_TOTAL" "input_prepared.txt" "$(status_plain "$PREPARED_TOTAL")"
summary_row "Alive URLs" "$ALIVE_TOTAL" "$INPUT_TOTAL" "alive.txt" "$(status_plain "$ALIVE_TOTAL")"
summary_row "Normalized" "$CLEAN_TOTAL" "$ALIVE_TOTAL" "clean.txt" "$(status_plain "$CLEAN_TOTAL")"
summary_row "Full Param URLs" "$FULL_PARAM_TOTAL" "$ALIVE_TOTAL" "full_params.txt" "$(status_plain "$FULL_PARAM_TOTAL")"
summary_row "Split Params" "$SPLIT_TOTAL" "$FULL_PARAM_TOTAL" "split_params.txt" "$(status_plain "$SPLIT_TOTAL")"
summary_row "All Param Candidates" "$ALL_PARAM_TOTAL" "$SPLIT_TOTAL" "all_param_candidates.txt" "$(status_plain "$ALL_PARAM_TOTAL")"
summary_row "SQLi Pattern Candidates" "$SQLI_TOTAL" "$SPLIT_TOTAL" "sqli_params.txt" "$(status_plain "$SQLI_TOTAL" review)"
summary_row "Reflected Candidates" "$REFLECTED_TOTAL" "$SPLIT_TOTAL" "reflected.txt" "$(status_plain "$REFLECTED_TOTAL" review)"
summary_row "Non-reflected SQLi" "$NONREF_TOTAL" "$SPLIT_TOTAL" "non_reflected_sqli_candidates.txt" "$(status_plain "$NONREF_TOTAL" review)"
summary_row "Dynamic Behavior" "$DYNAMIC_TOTAL" "$SPLIT_TOTAL" "dynamic_only.txt" "$(status_plain "$DYNAMIC_TOTAL" dynamic)"
summary_row "Manual Priority" "$PRIORITY_TOTAL" "$SPLIT_TOTAL" "manual_review_priority.txt" "$(status_plain "$PRIORITY_TOTAL" review)"
summary_row "Final Review Rows" "$REVIEW_TOTAL" "$PRIORITY_TOTAL" "final_review.tsv" "$(status_plain "$REVIEW_TOTAL" review)"
summary_row "Param Type Score" "$PARAM_ANALYSIS_TOTAL" "$SPLIT_TOTAL" "parameter_type_analysis.tsv" "$(status_plain "$PARAM_ANALYSIS_TOTAL" review)"
summary_row "Testing Plan TSV" "$PLAN_TOTAL" "$PLAN_TOTAL" "vulnerability_testing_plan.tsv" "$(status_plain "$PLAN_TOTAL" review)"
summary_row "Report JSON" "1" "1" "report_data.json" "OK"
summary_row "Testing Plan HTML" "$PLAN_TOTAL" "$PLAN_TOTAL" "vulnerability_testing_plan.html" "$(status_plain "$PLAN_TOTAL" review)"
printf "${BOLD}${WHITE}├────────────────────────┴────────┴──────────────────┴─────────┴──────────────────────────┴────────┤${NC}\n"
summary_note_line "Next step" "$NEXT_ACTION"
summary_note_line "Open" "$OUT/manual_review_priority.txt"
summary_note_line "Details" "$OUT/final_review.tsv"
summary_note_line "Param Score" "$OUT/parameter_type_analysis.tsv"
summary_note_line "Plan TSV" "$OUT/vulnerability_testing_plan.tsv"
summary_note_line "Report JSON" "$OUT/report_data.json"
summary_note_line "HTML Dash" "$OUT/vulnerability_testing_plan.html"
printf "${BOLD}${WHITE}└──────────────────────────────────────────────────────────────────────────────────────────────┘${NC}\n"

echo -e "\n${GREEN}${BOLD}DOCTORJACK COMPLETE IN ${DURATION} SECONDS.${NC}"
echo -e "${YELLOW}Note:${NC} This is a pre-filter for authorized manual review, not proof of SQL injection."
echo -e "${YELLOW}HTML Dashboard:${NC} $OUT/vulnerability_testing_plan.html"
echo -e "${YELLOW}Open command:${NC} firefox \"$OUT/vulnerability_testing_plan.html\""
