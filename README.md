# SBOMit Pipeline Runner

A GitHub Action that runs your build under [witness](https://github.com/in-toto/witness)
eBPF tracing and generates an SBOM from the resulting attestation with
[sbomit](https://github.com/sbomit/sbomit).

> **Status: skeleton.** Input validation (Stage 0) works. Stages 1 to 4 are
> placeholders and do not produce an attestation or SBOM yet.

## Usage

```yaml
jobs:
  sbom:
    runs-on: ubuntu-24.04
    steps:
      - uses: actions/checkout@v4          # required, and must come right before this action
        with:
          persist-credentials: false
      - uses: Uk-jake/sbomit-pipeline-runner@main
        with:
          build-command: go build -trimpath ./...
          language: go
```

## Inputs

| Input | Default | Values |
|---|---|---|
| `build-command` | (required) | Command that builds your project. Multi-line allowed. |
| `language` | `none` | `none`, `go`, `rust`, `node`, `python` |
| `network-trace` | `false` | `true`, `false` |
| `sbom-format` | `spdx23` | `spdx23`, `cdx14`, `cdx15` |
| `use-syft` | `true` | `true`, `false` (`cdx15` requires `false`) |

## Outputs

| Output | Description |
|---|---|
| `attestation-path` | Signed witness attestation |
| `sbom-path` | Generated SBOM |
| `metadata-path` | Run metadata (environment, tool versions, inputs) |

## Requirements

- Linux x86_64 runner with passwordless `sudo`
- A kernel where witness eBPF tracing works. The action checks this and fails if
  eBPF tracing is not available. There is no ptrace fallback.

## Pipeline

| Stage | Step | Script |
|---|---|---|
| 0 Validate | inputs, workspace | `scripts/validate/` |
| 1 Prepare | runner check, tool install, eBPF check, toolchain setup | `scripts/prepare/`, `scripts/install/` |
| 2 Run witness | signing key, network CA, traced build | `scripts/witness/` |
| 3 Run sbomit | generate, check | `scripts/sbomit/` |
| 4 Report | metadata, summary, upload | `scripts/report/` |

## Running scripts locally

Every script reads `SBOMIT_*` environment variables and can run without GitHub Actions:

```bash
SBOMIT_BUILD_COMMAND="go build ./..." SBOMIT_LANGUAGE=go SBOMIT_NETWORK_TRACE=false \
SBOMIT_SBOM_FORMAT=spdx23 SBOMIT_USE_SYFT=true \
  bash scripts/validate/inputs.sh
```
