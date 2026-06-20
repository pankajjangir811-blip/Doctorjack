# Doctorjack v7.7

Doctorjack is an authorized-security-testing pre-filtering tool that prepares SQL injection candidates for manual review. It normalizes URLs, extracts parameters, applies SQLi-oriented patterns, checks reflection, compares basic response behavior, and generates review files and an HTML dashboard.

> Use this project only on systems you own or where you have explicit written permission to test.

## Repository contents

This repository intentionally keeps the original two-script layout:

```text
Doctorjack_v7_7.sh
Doctorjack_install_v7_7.sh
```

The documentation and GitHub support files do not change the original tool or installer logic.

## Supported systems

The installer is designed for Debian-based Linux distributions that use `apt`, including:

- Kali Linux
- Ubuntu
- Debian

Run the installer as a normal user with `sudo` access. Do not run it from a root login unless you understand that Go tools and GF patterns will be installed under the root home directory.

## Quick installation

Clone the public repository:

```bash
git clone https://github.com/pankajjangir811-blip/Doctorjack.git
cd Doctorjack
chmod +x Doctorjack_install_v7_7.sh Doctorjack_v7_7.sh
./Doctorjack_install_v7_7.sh
```

The password requested during installation is your local Linux `sudo` password, not your GitHub password.

Reload your shell after installation.

For Bash:

```bash
source ~/.bashrc
```

For Zsh:

```bash
source ~/.zshrc
```

Verify the global command:

```bash
which doctorjack
doctorjack -h
```

## Run without installing the global command

You can also run the main script directly:

```bash
chmod +x Doctorjack_v7_7.sh
./Doctorjack_v7_7.sh -f urls.txt
```

## Basic usage

```bash
doctorjack -f urls.txt
```

With optional settings:

```bash
doctorjack -f urls.txt -o custom_recon -r 20 -t 15
```

Skip the animated introduction:

```bash
doctorjack --no-intro -f urls.txt
```

## Input format

Provide a text file containing HTTP or HTTPS URLs. One URL per line is recommended.

Example:

```text
https://example.test/product.php?id=10
https://example.test/search.php?q=phone
https://example.test/view.php?page=about
```

## Options

| Option | Description |
|---|---|
| `-f <file>` | Required input URL file |
| `-o <dir>` | Base output directory; default is `recon` |
| `-c <codes>` | HTTP status codes accepted by httpx |
| `-d <number>` | Content-length change threshold |
| `-t <seconds>` | HTTP timeout |
| `-r <rate>` | Optional httpx rate limit |
| `--no-intro` | Skip animated introduction |
| `-h` | Display help |

## Main output files

Each run creates a timestamped directory such as:

```text
recon/run_YYYY-MM-DD_HH-MM-SS/
```

Important files include:

| File | Purpose |
|---|---|
| `manual_review_priority.txt` | Main manual-review shortlist |
| `final_review.tsv` | Categorized review results |
| `dynamic_only.txt` | URLs with changed response metadata |
| `non_reflected_sqli_candidates.txt` | SQLi candidates that were not reflected |
| `parameter_type_analysis.tsv` | Parameter classification and priority scoring |
| `vulnerability_testing_plan.tsv` | Structured testing plan |
| `vulnerability_testing_plan.html` | Browser-readable report/dashboard |
| `report_data.json` | Structured report data |
| `metadata.txt` | Audit details, settings, and tool paths |
| `logs/` | Tool and stage error logs |

## Installed dependencies

The installer configures and verifies:

- ProjectDiscovery `httpx`
- `gf`
- GF patterns including SQLi patterns
- `Gxss`
- `qsreplace`
- `uro`
- Go
- Python 3
- Git and basic build tools

The installer places Go tools first in `PATH` to avoid conflicts with unrelated packages also named `httpx`.

## Troubleshooting

### Git asks for a username or password while cloning

Use the exact public HTTPS URL:

```bash
git clone https://github.com/pankajjangir811-blip/Doctorjack.git
```

Do not use an old URL with a different GitHub username.

### Installation asks for a password

This is expected when the installer runs `sudo apt`. Enter the password of your local Linux user.

### `doctorjack: command not found`

Reload the correct shell profile:

```bash
source ~/.bashrc
```

or:

```bash
source ~/.zshrc
```

Then verify:

```bash
which doctorjack
```

### Wrong `httpx` is being used

Check:

```bash
which httpx
httpx -version
```

The expected path is normally:

```text
$HOME/go/bin/httpx
```

Run the installer again if another `/usr/bin/httpx` package is taking priority.

### Review logs

Every run stores logs in:

```text
recon/run_<timestamp>/logs/
```

## Safety and legal notice

Doctorjack is intended for authorized assessment, training labs, and defensive review. It does not itself prove that a SQL injection vulnerability exists. Candidate results require careful manual validation.

You are responsible for obtaining permission, defining scope, applying rate limits, protecting collected data, and complying with applicable law and program rules.

## Reporting security issues

Do not publish a vulnerability affecting Doctorjack users as a public GitHub issue. Follow the process in [SECURITY.md](SECURITY.md).

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

Released under the MIT License. See [LICENSE](LICENSE).
