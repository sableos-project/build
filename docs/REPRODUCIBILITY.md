# Reproducibility policy

Status: **current normative reproducibility/provenance policy — 2026-09-24**

## Layers

Distinguish reproducibility of:

```text
source composition
application qualification
trusted artifact
product integration
full image/artifact
artifact registration
deployment
runtime/portability
future signed release
```

## Source identity

Validated builds start from explicit upstream/substrate identity plus exact
Sable revisions. Do not depend on manual copies, untracked manifests, host-only
symlinks, uncommitted source or unresolved branch tips.

## Artifact identity — K1

Registry schema v2 records exact artifact class, primary artifact, named hashes,
tool source and metadata.

Legacy Panther records remain readable.

Artifact byte identity is separate from source identity; signing/zip/container
metadata may affect outer bytes and must be explained rather than ignored.

## Build-output freshness

A warmed OUT may be valid incremental evidence but is not fresh-build proof when
the claim requires reconstruction.

Historical successful OUT directories are evidence, not hidden inputs.

## Target isolation

Build/output state is isolated by device/release/source as appropriate.
Physical device serial is not build identity.

## Deployment reproducibility — K2

Repeatable deployment requires the same registered artifact plus the qualified
device adapter/transport contract and explicit selected serial.

Panther's A/B target-files semantics are not universal.

## Device evidence

Panther is frozen reference. Titan 2 and Titan 2 Elite have independent runtime
and hardware evidence. Do not infer page size, camera, keyboard, telephony,
display or power behavior across targets.

## Production signing

Development/test signing identity is separate from production release signing.
Future signed-release reproducibility must additionally bind production keys,
AVB/OTA process and signing-host provenance.
