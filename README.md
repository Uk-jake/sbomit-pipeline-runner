# SBOMit Pipeline Runner

A GitHub Action that generate a SBOM file using [sbomit](https://github.com/sbomit/sbomit).
the action runs your build under [witness](https://github.com/in-toto/witness) and generates an SBOM.

> **Status:** the file-trace pipeline is complete: your build runs under witness
> eBPF file tracing, a signed attestation is produced, an SBOM is generated from
> it, and all results are uploaded with a summary. Network trace
> (`network-trace: true`) is not supported yet.

## How it fits into your workflow

This action is used **in place of the build step of your existing build job**.
Your job keeps doing what it already does: check out the source and prepare the
build environment (toolchains, environment variables, services). This action then
runs your build command under witness, and your later steps run as usual.

```yaml
jobs:
  build:
    runs-on: ubuntu-22.04
    steps:
      - uses: actions/checkout@v7
        with:
          persist-credentials: false
      - uses: actions/setup-go@v7
        with:
          go-version-file: go.mod
          cache: false                      # recommended, see "Accurate SBOMs" below
      - uses: Uk-jake/sbomit-pipeline-runner@main
        with:
          build-command: make build         # the command your build step runs
      - run: make test                      # later steps work as usual
```

What you provide and what the action does:

| Your job | This action |
|---|---|
| Checks out the source (before this action) | Installs witness, sbomit and syft |
| Sets up toolchains and environment | Runs `build-command` under witness eBPF tracing, with your environment |
| Runs any steps after the build | Returns files created by the build to the runner user |
| | Generates the SBOM and uploads the results as an artifact |

The action does not install or change any build toolchain. The Go version it
needs for building witness and sbomit is kept separate from your PATH and caches.

## Inputs

| Input | Default | Values |
|---|---|---|
| `build-command` | (required) | The command your build step runs. Multi-line allowed. |
| `network-trace` | `false` | `false` only for now (`true` is rejected until network trace is implemented) |
| `sbom-format` | `spdx23` | `spdx23`, `cdx14`, `cdx15` |
| `use-syft` | `true` | `true`, `false` (`cdx15` requires `false`) |

## Outputs

| Output | Description |
|---|---|
| `attestation-path` | Signed witness attestation |
| `sbom-path` | Generated SBOM |
| `metadata-path` | Run metadata (environment, tool versions, inputs) |

The SBOM document is named after your repository, and its version is the short
commit SHA of the checked-out source, so each SBOM identifies the build it describes.

## What you get

**An artifact** named `sbomit-<job>-<matrix index>-<sbom-format>` containing:

| File | What it is |
|---|---|
| `attestation.json` | Signed witness attestation of the build (DSSE envelope) |
| `sbom.spdx.json` or `sbom.cdx.json` | SBOM generated from the attestation |
| `signing.pub` | Public key to verify the attestation (the private key is never uploaded) |
| `witness-run.log` | witness output, for troubleshooting |
| `run-metadata.json` | Runner, kernel, tool versions and commits, inputs, and how far the run got |

**A summary** on the workflow run page with the SBOM result, what was traced,
a link to the artifact, and the environment and tool versions.

The artifact and the summary are produced even when the build or SBOM step
fails, so you can see how far the run got.

> Do not put secrets in `build-command`. The attestation records the command
> line. Pass secrets to the build through environment variables instead.

## Accurate SBOMs: turn off dependency caches

witness records what your build actually does. If dependencies are restored from
a cache (for example `actions/setup-go` caches by default), the build does not
download them, so that activity is not observed. For the most accurate SBOM,
disable dependency caching in the job that uses this action (for example
`cache: false` on `actions/setup-go`). Detailed guidance per ecosystem will be
added after testing how caches affect the results.

## Requirements

- Linux x86_64 runner with passwordless `sudo` (witness needs root for eBPF).
- A kernel where witness eBPF file tracing works. There is no ptrace fallback.
  - Tested: `ubuntu-22.04` (kernel 6.8).
  - Known issue: tracing fails on kernel 7.0 (`command-run eBPF trace missing pending open`),
    which affects `ubuntu-26.04` and newer `ubuntu-24.04` images. Tracked in go-witness.
  - Network trace (not yet supported here) will need kernel 6.12 or newer.
- Network access to github.com, dl.google.com and get.anchore.io (tools are installed at run time).

## What happens inside

| Stage | Step | Script |
|---|---|---|
| Validate | inputs, workspace (source checked out) | `scripts/validate/` |
| Prepare | runner check, tool install | `scripts/prepare/`, `scripts/install/` |
| Run witness | signing key, network CA (later), traced build, return file ownership | `scripts/witness/` |
| Run sbomit | generate, check | `scripts/sbomit/` |
| Report | metadata, upload, summary | `scripts/report/` |

## Tools

Each tool is installed by one script in `scripts/install/`. The install
commands are at the top of each script, so changing how a tool is installed
means editing that one file.

| Tool | Script | How |
|---|---|---|
| witness | `witness.sh` | Built from `in-toto/witness` + `in-toto/go-witness` (`main` by default) with `go work` |
| sbomit | `sbomit.sh` | `go install github.com/sbomit/sbomit@latest` |
| syft | `syft.sh` | Official installer script from `get.anchore.io` |
| Go (tools only) | `go.sh` | Official archive, sha256-verified; isolated from your PATH and caches |

The exact versions and commits used in a run are recorded for the run metadata.

## Running scripts locally

Every script reads `SBOMIT_*` environment variables and can run without GitHub Actions:

```bash
SBOMIT_BUILD_COMMAND="go build ./..." SBOMIT_NETWORK_TRACE=false \
SBOMIT_SBOM_FORMAT=spdx23 SBOMIT_USE_SYFT=true \
  bash scripts/validate/inputs.sh
```
