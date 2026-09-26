# Treble portability build policy

Status: **strategy accepted / build-image fail-closed**

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

## Titan 2 N0_A16

```text
DEVICE=titan2
RELEASE=N0_A16
ANDROID_RELEASE=16
PLATFORM_SDK=36
ARTIFACT_KIND=gsi-system-image
PRIMARY_OUTPUT=system.img
FIRST_SUBSTRATE=AOSP16_CLEAN_GSI
RESTLESSOS_ROLE=REFERENCE_AND_FUTURE_FORK
PUBLIC_BUILD_IMAGE=FAIL_CLOSED
PUBLIC_FLASH=NO
```

## RestlessOS use

RestlessOS is used as a compatibility reference and possible future fork for
common Treble work. It is not the first Titan 2 N0 boot dependency.

The planned fork is tracked by `sableos-project/platform_manifest#8`:

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
