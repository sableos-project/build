# Public build process

Status: **foundation-only — 2026-09-26**

This document defines the public SableOS build process shape. It intentionally
does not claim that public users can reproduce the accepted Panther R9 image yet.

## Canonical command

```text
build/sable.sh <device> <release> <function> [options]
```

When working inside this repository directly, use:

```bash
bash sable.sh <device> <release> <function>
```

## Required first command

Run the host prerequisite check before source sync or build work:

```bash
bash sable.sh panther R9 env-check
```

The report is both human-readable and machine-greppable. It emits `PASS`,
`FAIL`, `FAIL_CLOSED` and key/value records.

## Foundation self-test

Run the public build foundation self-test before claiming that the command layer
is healthy on a given host:

```bash
bash sable.sh panther R9 self-test
```

To capture evidence in a deterministic directory:

```bash
bash sable.sh panther R9 self-test \
  --evidence-dir out/panther/R9/evidence/public-build-self-test
```

To make missing host prerequisites fail the self-test on a qualified build host:

```bash
bash sable.sh panther R9 self-test --strict-env
```

The self-test is dry-run/fail-closed. It checks shell syntax, captures env-check
output, verifies Panther R9 source-sync/source-verify/flash-plan dry-run paths,
and confirms that Titan-family build-image, signing, unknown device, unknown
release, unknown function and missing-artifact verify paths fail closed.

See `docs/HOST_VALIDATION.md` for the evidence layout and markers.

## Source sync boundary

```bash
bash sable.sh panther R9 source-sync
bash sable.sh panther R9 source-verify
```

The first public foundation PR documents this boundary. Exact executable manifest
sync becomes publication-ready only after `platform_manifest` pins all public
source inputs and the proprietary-input inventory is complete.

## Image build boundary

`build-image` exists so scripts and docs converge on a stable interface, but it
fails closed until a device/release has a qualified public source, proprietary
input and signing boundary.

```bash
bash sable.sh panther R9 build-image
```

Expected current result:

```text
SABLE_BUILD_IMAGE=FAIL_CLOSED
```

Titan-family devices are more restrictive. They are research targets and do not
have public image build claims:

```bash
bash sable.sh titan2 N0 build-image
bash sable.sh titan2-elite N0 build-image
bash sable.sh q27 N0 build-image
```

## App build boundary

`build-apps` is reserved for Sable-owned app module builds. It fails closed until
app repositories, dependency locks and output identity are publicly wired.

## Output paths

No output path is publication-ready until `package` and `verify` are qualified.
Future public builds should emit:

```text
out/<device>/<release>/
out/<device>/<release>/artifacts/
out/<device>/<release>/evidence/
out/<device>/<release>/artifact-manifest.json
```

The public build foundation self-test currently writes host-validation evidence
under either the caller-provided `--evidence-dir` path or:

```text
out/sable-public-build-evidence/<device>-<release>-<utc-stamp>/
```

## Non-goals in this phase

- No production signing material is published.
- No accepted release image reproducibility claim is made.
- No Titan-family image build or flash path is enabled.
- No device contact is required for host/source/build validation.
