# SBOMit Pipeline Runner

A GitHub Action that runs your build under [witness](https://github.com/in-toto/witness)
eBPF tracing and generates an SBOM from the resulting attestation with
[sbomit](https://github.com/sbomit/sbomit).

> **Status: in progress.** Stages 0 to 2 are implemented: the build runs under
> witness eBPF file tracing and a signed attestation is produced. Network trace
> (`network-trace: true`) is not supported yet. SBOM generation (Stage 3) and
> reporting (Stage 4) are placeholders.

## Usage

```yaml
jobs:
  sbom:
    runs-on: ubuntu-24.04
    steps:
      - uses: actions/checkout@v7          # required, and must come right before this action
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
| `network-trace` | `false` | `false` only for now (`true` is rejected until network trace is implemented) |
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
- A runner where witness eBPF tracing works. If the eBPF tracer cannot be loaded,
  witness fails before your build starts. There is no ptrace fallback.
  Supported runners are the ones that pass this repository's E2E workflow.
- Network access to github.com, dl.google.com and get.anchore.io (tools are installed at run time).

## Tools

Each tool is installed by one script in `scripts/install/`. The install
commands are at the top of each script, so changing how a tool is installed
means editing that one file.

| Tool | Script | How |
|---|---|---|
| witness | `witness.sh` | Built from `in-toto/witness` + `in-toto/go-witness` (`main` by default) with `go work` |
| sbomit | `sbomit.sh` | `go install github.com/sbomit/sbomit@latest` |
| syft | `syft.sh` | Official installer script from `get.anchore.io` |
| Go (tools only) | `go.sh` | Official archive, sha256-verified; isolated from the user's PATH and caches |

The exact versions and commits used in a run are recorded for the run metadata.

## Pipeline

| Stage | Step | Script |
|---|---|---|
| 0 Validate | inputs, workspace | `scripts/validate/` |
| 1 Prepare | runner check, tool install, toolchain setup | `scripts/prepare/`, `scripts/install/` |
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
