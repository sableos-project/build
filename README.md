# SableOS build tooling

Status: **current build/artifact/deployment architecture — 2026-09-25**

## Canonical engineering interface

```text
build/sable.sh <device> <release> <function> [options]
```

Canonical device IDs:

```text
panther
titan2
titan2-elite
q27
```

Panther is a frozen accepted R9 Hub V1 reference. K1/K2 multi-device foundation
is implemented and host-qualified.

```text
R9_PANTHER_ACCEPTED_SOURCE=edf62e5bb08372a1395841d6cc5d78d3148a7695
R9_PANTHER_TARGET_FILES_SHA256=a0b359613c4f30e9a834fba212e0b044a97d63ed0537c59471c31b99b627d285
R9_PANTHER_PHYSICAL_ACCEPTANCE=PASS_WITH_PRESERVED_PLAY_STATE
```

## K1 — artifact registry v2

Registry identity remains:

```text
device + release + build source
```

Schema v2 adds explicit:

```text
artifact_kind
primary_artifact
named artifact paths/hashes/sizes
tool source
metadata
```

Supported artifact kinds:

```text
target-files
full-device-images
gsi-system-image
system-product-bundle
boot-recovery-bundle
```

Legacy Panther schema-1/target-files records remain readable/verifiable.

Release artifact registration is separately capability-gated by each device
adapter. Generic schema support does not make an unqualified device releasable.

## Serial rule

A physical serial is not build/image/artifact identity.

Serial is required only for device-contact operations. Every ADB/fastboot
mutation must bind the selected serial exactly; tooling must never fall back to
the first globally attached device.

## K2 — deployment boundary

Common deployment orchestration owns:

- explicit authorization;
- registered-artifact verification;
- artifact-kind support checks;
- exact selected-serial binding;
- evidence collection/sealing;
- preserved/destructive-data policy;
- baseline capture where applicable;
- bounded failure recovery;
- post-boot return and callback dispatch.

Device adapter owns:

- supported artifact kinds;
- expected product identity;
- partition/slot model;
- fastboot/fastbootd/vendor transport;
- AVB/vbmeta prerequisites;
- writable images;
- restore strategy;
- target-specific post-boot acceptance.

## Current adapter state

| Device | Register | Flash plan | Flash | Qualified artifact/transport |
| --- | --- | --- | --- | --- |
| panther | YES | YES | YES | target-files / A-B fastboot |
| titan2 | NO | NO | NO | UNQUALIFIED |
| titan2-elite | NO | NO | NO | UNQUALIFIED |
| q27 | NO | NO | NO | UNQUALIFIED |

Titan-family support remains fail-closed until research proves exact
restore/partition/AVB/transport contracts.

## CI / evidence

The authoritative release-critical pipeline is local-direct on the controlled
build host. A source-bound full-CI attestation is required before a release image
build where the release contract demands it.

GitHub remains source/review/issues/documentation infrastructure.

## Current next work

Build/deployment foundation is not the current blocker. Active work moves to
keyboard-first product design and Titan adapter-input research.

When Titan N0 deployment begins, first decide from physical evidence whether the
artifact should be a system GSI, generated super image, or bounded
system/product/system_ext bundle and whether data preservation is feasible.

Remaining open issues are intentionally kept open until the Titan 2 SableOS
install path proves or supersedes them.
