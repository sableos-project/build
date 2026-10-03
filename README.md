# SableOS build tooling

Status: **public build foundation — 2026-10-02**

This repository is the public command and documentation entrypoint for SableOS
source sync, host validation, artifact build, signing-boundary documentation,
artifact verification and packaging.

The canonical interface is:

```text
build/sable.sh <device> <release> <function> [options]
```

When this repository is cloned as `build` inside a larger SableOS source tree,
that command is literally `build/sable.sh`. When working from this repository
alone, run `./sable.sh` or `bash sable.sh`.

## Current support posture

This repository now provides a fail-closed public build foundation. It does not
yet claim that a public user can reproduce the accepted Panther R9 image.

```text
panther / R9
    REFERENCE_FROZEN
    source/build/signing docs are being established
    accepted-image reproducibility is not yet claimed publicly

titan2 / N1D_C3B
    ACTIVE_CANONICAL_ENGINEERING_PRIVATE
    current artifact class: Sable-composed systemimage engineering build
    E3 private build is running; public build and flash paths remain fail closed
    legacy N0_A16 public placeholder is historical

titan2-elite / N0
    RESEARCH_UNQUALIFIED
    build and flash paths fail closed

q27 / N0
    RESEARCH_UNQUALIFIED
    build and flash paths fail closed
```

## Current private engineering checkpoint

The canonical private lane is Titan 2 N1D/C3B:

```text
C3B_E1_SYSTEMIMAGE=PASS
C3B_E2_SOURCE_ADMISSION=PASS
C3B_E3_BUILD_SOURCE=caf98dde723d07a071d95aaa1ef27d578d3208d8
C3B_E3_STATUS=BUILD_RUNNING_NOT_YET_SEALED
C3B_RUNTIME_PATCH_ALLOWLIST_COUNT=0
DEVICE_CONTACT_AUTHORIZED=NO
FLASH_AUTHORIZED=NO
TARGET_FILES_AUTHORIZED=NO
OTA_AUTHORIZED=NO
PRODUCTION_SIGNING_AUTHORIZED=NO
```

The public tool remains fail-closed until a separately reviewed public
composition, artifact and deployment contract is qualified. The private E3
build does not authorize a public `build-image` or flash path.

## Functions

```text
env-check        validate host tools and print a host prerequisite report
source-sync      print the exact source-sync boundary for the selected target
source-verify    print the expected source verification boundary
build-image      fail closed unless a device/release is explicitly build-qualified
build-apps       fail closed until app build wiring is public and qualified
sign             fail closed unless an explicit public signing mode is qualified
verify           print artifact-verification requirements and fail without inputs
package          fail closed until artifact registry packaging is public
flash-plan       print the current flash/deployment support boundary
self-test        run local dry-run/fail-closed checks and write evidence
```

Unknown devices, releases and functions fail closed.

## Quick start

```bash
bash sable.sh panther R9 env-check
bash sable.sh panther R9 source-sync
bash sable.sh panther R9 flash-plan
bash sable.sh panther R9 self-test

# Public Titan build paths intentionally fail closed today.
# The old N0 command remains a fail-closed compatibility/example path, not
# current N1D/C3B execution authority:
bash sable.sh titan2 N0 build-image
```

For a qualified build host, run self-test with strict environment enforcement:

```bash
bash sable.sh panther R9 self-test --strict-env
```

## Treble portability boundary

Titan-family and future Unihertz/MediaTek builds use the Treble portability lane.
For current Titan 2 engineering that means:

- preserve the qualified stock vendor/kernel/firmware boundary;
- use the canonical N1D/C3B Graphene/AOSP-derived Android 16 base plus a minimal
  Treble scaffold;
- admit compatibility changes through the C3B compatibility-peel process;
- treat RestlessOS/TrebleDroid as a known-fix compatibility reference, not the
  Sable runtime/security baseline;
- require local artifact evidence before enabling any public build-image path;
- keep signing, package and flash paths closed until their gates are explicit.

See `docs/TREBLE_PORTABILITY.md`.

## Documentation

```text
docs/BUILD.md
    host setup, source sync, build commands and output boundaries

docs/HOST_VALIDATION.md
    self-test, evidence directory layout and host-validation evidence contract

docs/TREBLE_PORTABILITY.md
    Titan-family / Unihertz / MediaTek build-lane policy

docs/SIGNING.md
    DEV_SIGNED / RELEASE_CANDIDATE_SIGNED / PRODUCTION_SIGNED /
    UNSIGNED_OR_NOT_REPRODUCIBLE_PUBLICLY boundary

docs/VERIFY.md
    artifact manifest, checksum and image-identity verification requirements

docs/DEVICES.md
    device/release/artifact support matrix

docs/PROPRIETARY_INPUTS.md
    Google/AOSP, GrapheneOS, kernel/vendor/blob and private-input boundaries
```

## Release-critical boundary

GitHub is source/review/issues/documentation infrastructure. A release-critical
image still requires local evidence from a qualified build host and must not be
claimed as production reproducible until the exact source, proprietary input,
signing and verification boundaries are published and validated.

Production signing material must never be committed to public or private source
repositories.
