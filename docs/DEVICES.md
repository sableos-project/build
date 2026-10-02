# Device and release support matrix

Status: **current public foundation**

| Device | Release | Status | Artifact kind | Public build | Public flash |
| --- | --- | --- | --- | --- | --- |
| panther | R9 | REFERENCE_FROZEN | target-files | FAIL_CLOSED | PLAN_ONLY |
| titan2 | N1D/C3B canonical private; public release record pending | ACTIVE_ENGINEERING / PUBLIC_FAIL_CLOSED | systemimage engineering candidate | FAIL_CLOSED | NO |
| titan2-elite | N0 | RESEARCH_UNQUALIFIED | UNQUALIFIED | FAIL_CLOSED | NO |
| q27 | N0 | RESEARCH_UNQUALIFIED | UNQUALIFIED | FAIL_CLOSED | NO |

## Panther

Panther R9 is the frozen accepted touch-first reference. Public build tooling may
document the source/build/sign/verify path, but must not claim production
reproducibility until all inputs and signing boundaries are complete.

## Titan 2

Titan 2 uses the Treble portability lane. Current canonical engineering is
N1D/C3B, while the public build repository intentionally has no enabled N1D
build-image record yet:

```text
DEVICE=titan2
CANONICAL_RELEASE=N1D_C3B
ANDROID_RELEASE=16
PLATFORM_SDK=36
CANONICAL_ARTIFACT_KIND=systemimage
PUBLIC_RELEASE_RECORD=PENDING
PUBLIC_BUILD_IMAGE=FAIL_CLOSED
PUBLIC_FLASH=NO
```

The old public `N0_A16` record is historical precursor strategy and remains
useful only for understanding the earlier fail-closed portability plan.

Titan 2 is not required to track the latest Pixel Android release before the
stock vendor/kernel/firmware compatibility boundary is proven. Successful source
bootstrap or image build does not authorize package, sign or flash.

## Titan-family and Q devices

Titan 2 Elite and q27 remain portability/research targets. They must remain
fail-closed until physical evidence proves the partition model, restore path,
firmware/vendor basis, AVB boundary and safe artifact kind. Titan 2 PASS results
must not be copied to Titan 2 Elite.
