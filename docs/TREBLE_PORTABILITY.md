# Treble portability build policy

Status: **current portability policy / public build-image fail-closed — 2026-10-02**

This document defines public build-tool posture for Titan-family and future
Unihertz/MediaTek devices.

## Release lanes

```text
PIXEL_REFERENCE_LANE
  artifact classes: target-files, full-device-images
  release cadence: Pixel/Sable reference first

TREBLE_PORTABILITY_LANE
  artifact classes: gsi-system-image first
  release cadence: stock-vendor compatibility first
```

A Treble portability artifact is not a Pixel-equivalent release image. It is a
Sable userspace candidate bound to preserved stock vendor/kernel/firmware.

## Titan 2 N1D/C3B

```text
DEVICE=titan2
CANONICAL_RELEASE=N1D_C3B
ANDROID_RELEASE=16
PLATFORM_SDK=36
ARTIFACT_KIND=systemimage
PRIMARY_OUTPUT=system.img
FIRST_SUBSTRATE=GRAPHENE_AOSP_DERIVED_C3B_BASE
TREBLE_SCAFFOLD=MINIMAL
RESTLESSOS_ROLE=COMPATIBILITY_REFERENCE_ONLY
FULL_RESTLESS_RUNTIME_STACK=BLOCKED
PUBLIC_BUILD_IMAGE=FAIL_CLOSED
PUBLIC_FLASH=NO
```

The old N0/AOSP-first public strategy is historical precursor material. Current
C3B compatibility uses a fail-closed peel: audit known fixes, admit only the
safe build/Graphene-Treble compatibility subset, and keep runtime patch
admission separately controlled.

## RestlessOS use

RestlessOS/TrebleDroid is used as a compatibility reference and known-fix
inventory. The public fork now exists, but it is not the Sable product runtime
or security baseline and is not imported wholesale into C3B.

The compatibility/reference fork is:

```text
sableos-project/treble_restlessos
```

Build tooling must not treat prebuilt RestlessOS images as Sable release
artifacts. If Sable forks RestlessOS, manifest-pinned source commits and local
build evidence are still required.

## Build enablement gates

A Titan-family `build-image` path may become active only after:

```text
SOURCE_SUBSTRATE_QUALIFIED=YES
ARTIFACT_KIND_SELECTED=YES
STOCK_VENDOR_BASIS_BOUND=YES
OUTPUT_IDENTITY_RECORDED=YES
VERIFY_PATH_EXISTS=YES
FLASH_PATH_REMAINS_EXPLICITLY_GATED=YES
```

## Non-goals

- no production signing keys;
- no stock firmware/images/blobs in source;
- no device identifiers;
- no Pixel-equivalent security claim;
- no public flash enablement from a successful build alone;
- no inheritance of GrapheneOS or RestlessOS branding, support or endorsement.
