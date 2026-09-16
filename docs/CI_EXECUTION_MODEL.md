# SableOS CI execution model

Status: **normative implementation guidance for CI/build/device and later signing execution.**

This document implements `sableos-project/.github/docs/CI_TRUST_ARCHITECTURE.md`.

## Current infrastructure roles

```text
GitHub hosted     = disposable/untrusted A1 application/static/security CI
ai-g732           = intended trusted A2/B1/B2/B3 development builder
thinkpad-p50      = historical/reference builder during migration;
                    future production-signing-host candidate only
Pixel 7 / panther = primary R8 runtime target
Titan 2           = second R8 portability/runtime target
```

There is no active signing appliance yet. OptiPlex is removed from the current plan. Production signing is deferred until development qualification is satisfactory on Panther and Titan 2.

## C0 — repository/policy checks

Fast disposable checks may validate repository/workflow structure, immutable Action pins, least privilege, syntax/configuration, secret/private-key heuristics and documentation/reference consistency. No trusted AOSP workspace/device/signing access.

## C1 / A1 — disposable application qualification

C1 runs on GitHub-hosted disposable runners and is the normal feedback loop for independently developed R8 applications.

Keep lanes independently diagnosable:

```text
Rust correctness
Rust dependency/security
Android compile/tests
Android static analysis
Reader compile/tests
Reader policy/static
Text Reader compile/tests
Text Reader policy/static
qualification artifact seal
```

Expected outputs include exact source/upstream identities, dependency/provenance inventory, package/manifest/component state, native ABI inventory, APK hashes and workflow/run identity.

A1 success never proves trusted artifact identity or SableOS product integration.

## C1.5 / A2 — trusted standalone app build on ai-g732

A2 consumes exact accepted source and rebuilds outside the AOSP product graph using pinned/recorded toolchains.

Record:

```text
source/upstream commits
Gradle/JDK/SDK/NDK/Rust identities
lockfile hashes
trusted APK SHA-256
package/version/permissions/components
classes*.dex extracted-content hashes
JNI .so extracted-content hashes
native ABI inventory
16 KiB ELF compatibility
APK native-library ZIP alignment
```

Where reproducible, compare A1/A2 outputs. Unexplained divergence blocks the trusted freeze until understood.

A2 is allowed to repeat as accepted source changes. It is much cheaper than a broad Android image build.

## C2 / B1 — trusted pre-image Android integration

B1 runs on `ai-g732` only against exact frozen A2 inputs and trusted Sable source.

Use B1 for Android properties standalone Gradle/Cargo cannot prove:

- exact `android_app_import` or equivalent module behavior;
- input artifact identity;
- certificate/signing mode;
- JNI uncompression/layout/processing;
- dexpreopt and uses-library behavior;
- generated Soong/Ninja dependencies;
- product selection;
- concrete PRODUCT_OUT install path;
- bounded framework/resource/JNI integration.

Required high-level sequence:

```text
bind target + isolated OUT_DIR
 -> generate Soong graph without broad compile where supported
 -> discover/query exact module edges
 -> build minimum import dependencies
 -> inspect actual intermediate APK/output paths
 -> compare DEX/JNI inner-content hashes to A2 freeze
 -> prove product selection separately
 -> prove PRODUCT_OUT separately
```

Read `R8_PREIMAGE_GATE.md` for the detailed boundary.

Do not use B1 to discover ordinary Kotlin/Rust compile failures covered by A1/A2.

## C3 / B2 — Panther development image

After A1/A2/freeze/B1 close for the selected tranche, run the normal Panther development image build.

Before execution record host/storage/workspace/manifest identity, frozen application inputs, exact target/release/variant/lunch/Build ID, OUT/evidence roots, network/build authorization, free-space floor/monitoring and existing-build state.

Expected evidence includes build logs/result, product package evidence, target-files/image inventory, artifact hashes and gate report.

## C3P / B3 — Titan 2 portability development image

After Panther acceptance, repeat product integration/image work for Titan 2 with a separate OUT_DIR and the same common frozen application artifacts wherever compatible.

The portability claim must demonstrate:

```text
same common app source/artifacts
same common vendor_sable product integration
bounded Titan-specific adapter
no common application fork
runtime acceptance for Titan-specific input/layout/platform differences
```

Titan-specific secondary-display/program-key/FM features are outside current common R8 requirements unless separately approved.

## ai-g732 activation

Before using `ai-g732` as the trusted builder prove:

```text
host identity
filesystem/new-storage identity
source repository identities
workspace/output/evidence roots
isolated per-target OUT_DIR policy
toolchain prerequisites
free-space floor + monitoring
network/build authorization
expected target/release/variant/Build ID
exact frozen app inputs + hashes
absence of accidental ThinkPad-only path/local-state dependency
```

Do not clean the historical ThinkPad workspace merely because migration succeeds unless cleanup is separately authorized.

## Native 16 KiB gate

Every R8 APK containing native libraries must pass verified 16 KiB compatibility.

The trusted artifact/integration evidence should cover:

```text
ELF PT_LOAD alignment >= 0x4000
APK ZIP alignment suitable for uncompressed native libraries
runtime page size measured on accepted devices
representative JNI execution
```

The implementation mechanism follows the pinned NDK/toolchain; do not hard-code a linker flag when the selected toolchain already produces compliant output.

## Device campaigns

Device contact and mutation remain separately authorized.

### Panther

Validate exact accepted image/package identities, launcher/role behavior, R8-A appearance, Calculator/Convert/Games interactions, one Reader identity/capability set, Media local-vs-network boundaries, permissions/AppOps/system intents and required R7 regressions.

### Titan 2

In addition, explicitly validate physical-keyboard focus/navigation/text entry, square-display layout, runtime page size, Reader OCR/TTS capability and Media3/audio behavior.

## Production signing — deferred

Production signing is **not** a current C-stage in the R8 development critical path.

Only after Panther and Titan 2 development qualification is satisfactory should a separate release-signing program define production APK keys, AVB hierarchy, OTA signing, `sign_target_files_apks`, key custody/backup/recovery/rotation and sealed artifact handoff.

The ThinkPad P50 is a future signing-host candidate only. It must not be called `sable-signer-01` until commissioned.

Production signing material must not be present on C1/A1 or the ordinary trusted development builder.

## Workflow supply-chain rules

Trusted/release-critical workflows should converge on immutable third-party Action pins, least privilege, explicit timeouts, replaceable-job concurrency cancellation, no secrets to untrusted fork code, diagnostic artifacts where useful, explicit tool/dependency versions and declared network/offline policy.

## Cache rules

- A1 caches are untrusted convenience data.
- A2/B1/B2/B3 caches remain isolated from arbitrary PR execution.
- reconstruction gates can bypass/invalidate caches when required.
- cache presence never establishes artifact identity.

## Failure handling

Preserve bounded success and classify the failing layer:

```text
A1_SOURCE_TEST
A2_TRUSTED_APP_BUILD
A2_NATIVE_16K
B1_SOONG_IMPORT
B1_PRODUCT_SELECTION
B1_PRODUCT_INSTALL
B2/B3_IMAGE_PACKAGING
HOST_ENVIRONMENT
STORAGE
RUNTIME
```

Do not automatically clean/clobber/delete/rerun. Fix the root cause and rerun the narrowest valid target while preserving useful evidence.
