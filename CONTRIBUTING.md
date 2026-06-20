# Contributing to Doctorjack

Thank you for helping improve Doctorjack.

## Before opening a pull request

1. Create a branch from the latest main branch.
2. Keep changes focused and easy to review.
3. Do not add credentials, private targets, scan results, or collected data.
4. Preserve the permission-only and non-destructive purpose of the project.
5. Validate both Bash scripts:

```bash
bash -n Doctorjack_v7_7.sh
bash -n Doctorjack_install_v7_7.sh
```

6. Run ShellCheck when available:

```bash
shellcheck Doctorjack_v7_7.sh Doctorjack_install_v7_7.sh
```

## Pull-request description

Explain:

- What changed
- Why it is needed
- How it was tested
- Whether installation, output formats, or existing commands are affected

## Scope

Helpful contributions include:

- Reliability improvements
- Clearer errors and logs
- Compatibility fixes
- Documentation corrections
- Safer input validation
- Report quality improvements

Changes that encourage unauthorized access, destructive testing, stealth, credential theft, or evasion will not be accepted.
