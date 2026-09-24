# SableOS build tooling

## Current direction — 2026-09-24

The canonical engineering interface is multi-device and release-neutral:

```text
build/sable.sh <device> <release> <function> [options]
```

Known canonical device IDs:

```text
panther
titan2
titan2-elite
q27
```

Pixel 7 / Panther R9 is now a frozen reference. Active build-tooling work is to
generalize the proven Panther pipeline for Titan 2 and Titan 2 Elite without
weakening its source/artifact/evidence discipline.

## Serial rule

A physical device serial is **not** part of build or image identity.

Build identity is:

```text
device class + release + source + toolchain + product inputs
```

Serial is mandatory only for device-contact operations:

```bash
build/sable.sh titan2 R10 flash --build-source <sha> --serial <serial> --preserve-data --authorize
build/sable.sh titan2 R10 accept --serial <serial> --suite keyboard
```

This permits multiple attached devices while keeping every mutation explicitly
bound to the selected unit.

## Device adapter contract

The common entry point dispatches through:

```text
build/devices/<device>.sh
```

A device adapter declares whether build, qualification, preserved-data flash and
acceptance are supported. Unknown or unqualified devices fail closed.

Adapters own:

- expected product/device identity;
- artifact kind supported by that target;
- partition/slot model;
- fastboot/fastbootd/vendor transport;
- stock/vendor partitions that must be preserved;
- bootloader/AVB prerequisites;
- restore strategy;
- target-specific acceptance suites.

Common tooling owns:

- authorization;
- selected-serial binding;
- source/artifact provenance;
- hash verification;
- evidence collection/sealing;
- no-wipe/default preservation policy;
- post-boot smoke framework.

## Artifact generalization

Panther currently proves a `target-files`-centric release path. Non-Pixel N0
targets may instead consume a GSI/system-image artifact while retaining stock
vendor/kernel/firmware.

The artifact registry should therefore represent:

```text
device
release
source_commit
tool_source_commit
artifact_kind
image/member hashes
stock/vendor basis where applicable
build evidence
required flash strategy
```

Supported artifact kinds may include:

```text
target-files
full-device-images
gsi-system-image
system/product bundle
device-specific boot/recovery bundle
```

Do not pretend every device can use Panther's A/B `fastboot flashall` path.

## Current device state

| Device | Build | Flash | Role |
| --- | --- | --- | --- |
| panther | qualified | qualified | frozen R9 reference |
| titan2 | blocked until N0 contract | blocked | active keyboard-first target |
| titan2-elite | blocked until independent proof | blocked | next keyboard-first target |
| q27 | blocked | blocked | research/future |

## CI / evidence model

The authoritative pipeline remains local-direct on the controlled build machine.
GitHub is source/review/documentation, not the release-critical Android builder.

Claims remain separated:

```text
source checks
 != trusted artifact
 != product selection
 != image membership
 != flash success
 != runtime acceptance
```

A source-bound full CI attestation is required before a release image build.
Historical successful OUT directories remain evidence, not hidden reconstruction
inputs.

## Next tooling sequence

```text
K1 generalized artifact descriptor
K2 common flash policy + device transport callbacks
K3 Titan 2 read-only preflight/restore model
K4 Titan 2 N0 build artifact
K5 Titan 2 flash/acceptance qualification
K6 Titan 2 Elite repeat independently
```

See [Multi-device engineering interface](docs/MULTI_DEVICE_ENGINEERING_INTERFACE.md).
