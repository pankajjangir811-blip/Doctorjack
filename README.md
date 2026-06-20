# Doctorjack v7.7

**SQL injection candidate pre-filter and manual-review planning tool for authorized security assessments.**

Doctorjack accepts a file containing URLs, normalizes and deduplicates them, extracts parameters, identifies SQLi-looking candidates, enriches them with reflection and basic response-behavior signals, and generates text, TSV, JSON, and HTML review outputs.

> [!CAUTION]
> Use Doctorjack only on systems you own or have explicit written permission to test. A candidate reported by this tool is **not proof of SQL injection**. Follow the approved scope, rate limits, disclosure policy, and applicable law.

## What Doctorjack does

- prepares malformed, mixed, or whitespace-separated URL input;
- probes alive URLs using ProjectDiscovery `httpx`;
- normalizes and deduplicates URLs with `uro`;
- splits query parameters for focused review;
- filters SQLi-looking parameters using `gf sqli`;
- checks reflection using `Gxss`;
- compares basic response metadata using two inert probe values;
- ranks parameter candidates for manual review;
- generates a browser-readable HTML review dashboard;
- preserves metadata and logs for audit and troubleshooting.

Doctorjack does not automatically confirm exploitation and does not run destructive payloads.

## Supported environment

The installer is intended for Debian-based Linux systems using `apt`, including Kali Linux and Ubuntu. Run it as a normal user with `sudo` access—not from a root login—because Go tools and GF patterns are installed in the current user's home directory.

## Quick installation

```bash
git clone https://github.com/pankajjangir811-blip/Doctorjack.git
cd Doctorjack
chmod +x install.sh doctorjack uninstall.sh
./install.sh
source ~/.bashrc
```

For Zsh:

```bash
source ~/.zshrc
```

Verify the installation:

```bash
which doctorjack
which httpx
httpx -version
doctorjack -h
```

### Important installer behavior

The installer:

- installs Go, Python, Git, Curl, Wget, and build packages through `apt`;
- installs ProjectDiscovery `httpx`, `gf`, `Gxss`, and `qsreplace` using Go;
- installs `uro` using Python `pip`;
- downloads public GF pattern repositories;
- prioritizes `$HOME/go/bin` in your shell profile;
- removes a conflicting Debian/Python `httpx` CLI when detected;
- installs the global command at `/usr/local/bin/doctorjack`.

Review `install.sh` before running it, especially on a workstation that already uses the Python `httpx` package or another command named `httpx`.

## Manual use without global installation

After dependencies are available:

```bash
chmod +x doctorjack
./doctorjack -f examples/urls.example.txt
```

## Input format

Provide HTTP or HTTPS URLs containing parameters, preferably one URL per line:

```text
https://authorized.example/products.php?id=1
https://authorized.example/search.php?q=test
https://authorized.example/view.php?page=home
```

Comments are not treated as URLs. Input may also contain whitespace-separated URLs; Doctorjack prepares a normalized URL-per-line file internally.

## Usage

```text
Usage: doctorjack -f <url_file> [options]

Required:
  -f <file>        URL/input file

Options:
  -o <dir>         Base output directory; default: recon
  -c <codes>       HTTP status codes accepted by httpx
  -d <number>      Content-length delta threshold; default: 20
  -t <seconds>     HTTP timeout; default: 10
  -r <rate>        Optional httpx rate limit, such as 20
  --no-intro       Skip the animated intro
  -h               Show help
```

### Examples

Standard run:

```bash
doctorjack -f urls.txt
```

Use a custom output directory and conservative rate:

```bash
doctorjack -f urls.txt -o authorized_assessment -r 10 -t 15
```

Disable the animated intro:

```bash
doctorjack --no-intro -f urls.txt
```

## Output directory

A run creates a timestamped directory:

```text
recon/
└── run_YYYY-MM-DD_HH-MM-SS/
    ├── manual_review_priority.txt
    ├── final_review.tsv
    ├── parameter_type_analysis.tsv
    ├── vulnerability_testing_plan.tsv
    ├── vulnerability_testing_plan.html
    ├── report_data.json
    ├── metadata.txt
    └── logs/
```

Open the HTML dashboard locally:

```bash
xdg-open recon/run_YYYY-MM-DD_HH-MM-SS/vulnerability_testing_plan.html
```

See [docs/OUTPUTS.md](docs/OUTPUTS.md) for the complete output reference.

## Understanding results

Doctorjack produces **review signals**, not confirmed findings:

- `sqli_pattern` means the URL matched a configured GF SQLi pattern;
- `reflected_candidate` means a parameter value appeared in the response;
- `non_reflected_sqli_candidate` remains relevant because SQL injection does not require reflection;
- `dynamic_behavior` means basic response metadata changed between inert probes;
- priority scores are triage aids and must be validated manually.

False positives and false negatives are possible. Authentication, caching, redirects, WAF behavior, unstable content, and rate limiting may affect results.

## Safe testing checklist

- Obtain written authorization and a clearly defined target scope.
- Use a conservative `-r` value and respect program limits.
- Never put third-party targets in public issues or commits.
- Review candidates manually before making a vulnerability claim.
- Avoid destructive options, data extraction, or service disruption.
- Preserve logs and report findings through the approved channel.

## Updating

```bash
cd Doctorjack
git pull
chmod +x install.sh doctorjack uninstall.sh
./install.sh
```

The installer refreshes the global `/usr/local/bin/doctorjack` command.

## Uninstalling

```bash
./uninstall.sh
```

This removes only the Doctorjack global command. It intentionally leaves shared dependencies and generated assessment data untouched.

## Troubleshooting

### Wrong `httpx` command

Doctorjack requires the ProjectDiscovery Go binary:

```bash
which httpx
```

Expected path:

```text
/home/YOUR_USER/go/bin/httpx
```

Reload the shell profile when necessary:

```bash
source ~/.bashrc
hash -r
```

### Missing `gf sqli` pattern

Confirm that the pattern exists:

```bash
ls ~/.gf/*sqli*
echo 'https://example.com/item.php?id=1' | gf sqli
```

Re-run `./install.sh` if the pattern is unavailable.

### Empty reports

Check:

```bash
cat recon/run_*/metadata.txt
tail -n 100 recon/run_*/logs/*.err
```

Common causes include unreachable targets, authentication requirements, blocked probes, missing parameters, redirects, and overly restrictive status-code filters.

## Repository files

| Path | Description |
|---|---|
| `doctorjack` | Main v7.7 pipeline. |
| `install.sh` | Dependency and global-command installer. |
| `uninstall.sh` | Removes the global Doctorjack command. |
| `examples/urls.example.txt` | Safe example input. |
| `docs/OUTPUTS.md` | Output file reference. |
| `SECURITY.md` | Private vulnerability reporting and authorized-use policy. |
| `CONTRIBUTING.md` | Contribution requirements. |
| `CHANGELOG.md` | Release history. |

## License

Released under the [MIT License](LICENSE).

The license permits use and modification of the software; it does not grant permission to test systems you do not own or have authorization to assess.
