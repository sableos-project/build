# Development milestone evidence gates

Status: **normative validation/evidence guidance for the current SableOS development train.**

A gate proves a bounded claim. It must not collapse source identity, compilation, trusted artifact identity, product selection, image membership and runtime behavior into one reassuring `PASS`.

## 1. Universal claim ladder

```text
requirements/source identity
 -> A1 disposable qualification
 -> A2 trusted standalone artifact
 -> B1 import/module processing
 -> product selection
 -> PRODUCT_OUT install
 -> target-files membership
 -> filesystem image membership
 -> runtime package/component/JNI state
 -> user-visible behavior
 -> portability/reconstruction/release provenance
```

Never infer a later layer solely from an earlier one.

## 2. Evidence status vocabulary

```text
PASS       claim proven within stated boundary
FAIL       tested claim contradicted
BLOCKED    prerequisite/environment prevents evaluation
NOT_TESTED intentionally not executed
UNPROVEN   evidence exists but does not establish the claim
UNKNOWN    evidence ambiguous
```

## 3. Authorization

Every state-changing gate declares separate authorization for source mutation, build-output mutation, network/fetch, build execution, Git mutation, device contact, package install/uninstall, reboot, roles/defaults, flash/update/sign, root/remount/slot/wipe and clean/clobber/delete.

Authorization for one class never implies another.

## 4. Historical R5/R6 and R7 baseline

Preserve original R5/R6 migration/launcher requirements and R7 Panther daily-driver/product evidence. Current architecture may mark them historical/current baseline, but must not rewrite their original results.

R7 reinforced:

```text
source/prebuilt
 -> graph edge
 -> product selection
 -> PRODUCT_OUT
 -> target-files/image
 -> runtime
```

Unexecuted R7 runtime cases remain unproven.

## 5. R8-A1 — disposable source/application qualification

A1 runs without a full Android product build.

### Rust

As applicable:

```text
cargo fmt --all -- --check
cargo clippy --workspace --all-targets --all-features -- -D warnings
cargo test --workspace --all-targets
selected property/fuzz tests
unsafe/FFI review
RustSec/dependency/provenance review
```

### Android/Kotlin

```text
JVM/unit tests
Compose/emulator/instrumentation tests where useful
Android Lint/static analysis
standalone APK assembly
package/version inspection
manifest permission/component inspection
```

### Reader/Text Reader

Bind exact upstream revisions and deterministic Sable adaptation. Publication and text/accessibility capabilities may be qualified separately but must ultimately compose into one accepted Sable Reader identity.

A1 artifacts are qualification evidence, not automatically trusted product binaries.

## 6. R8-A2 — trusted standalone application artifact

A2 runs on `ai-g732` after host migration/preflight closure.

For every accepted app record at least:

```text
source/upstream commit(s)
Gradle/JDK/SDK/NDK/Rust identities
lockfile/dependency provenance
trusted APK SHA-256
package/version
permissions/exported components
classes*.dex extracted-content SHA-256
lib/<abi>/*.so extracted-content SHA-256
native ABI inventory
16 KiB ELF compatibility
APK native-library ZIP alignment
accepted feature-policy boundary
known limitations
```

If A1 and A2 artifacts differ, document why. Unexplained divergence blocks the trusted freeze.

### JNI boundary

For Rust-backed apps prove:

```text
Rust core tests PASS
Android native build PASS
arm64-v8a library identity PASS
Kotlin/JNI signature contract PASS
panic/error boundary reviewed
APK expected .so inventory PASS
representative Kotlin -> JNI -> Rust execution at app/device layer
```

A Rust core PASS plus Kotlin shell PASS without binding proof is `JNI_RUNTIME_INTEGRATION=UNPROVEN`.

## 7. Native 16 KiB compatibility gate

Every accepted native R8 APK must pass verified 16 KiB compatibility.

Evidence includes:

```text
ELF PT_LOAD alignment >= 0x4000
APK ZIP alignment suitable for uncompressed native libraries
runtime page size measured on accepted devices
representative JNI execution
```

Do not infer page size solely from SoC identity. The exact linker/toolchain mechanism follows the pinned NDK/toolchain.

## 8. R8 integration freeze

Before B1:

```text
selected A1 lanes PASS or explicitly deferred
A2 trusted artifact PASS
exact app/source/toolchain freeze produced
R8-A shared contract aligned
permissions/policy reviewed
external dependency/provenance recorded
trusted builder activation PASS
```

Changing a frozen artifact reopens downstream evidence for that artifact.

## 9. R8-B1 — pre-image Android integration

Read `R8_PREIMAGE_GATE.md`.

For each frozen app prove separately:

```text
trusted APK hash/input path
 -> Soong import/module declaration
 -> certificate/signing behavior
 -> JNI processing
 -> dexpreopt / uses-library configuration
 -> minimum import build
 -> processed APK DEX/JNI content identity
 -> product selection
 -> PRODUCT_OUT concrete path/hash
```

`android_app_import` is the preferred candidate until exact Android 17/GrapheneOS behavior is observed.

Outer APK hashes may legitimately change. Record whole-file and inner DEX/JNI identities separately.

## 10. R8-B2 — Panther development image

Before the broad Panther image build prove:

```text
A1/A2/freeze/B1 closure for selected tranche
ai-g732 host/storage/source/tool identity
target product/release/variant/Build ID
isolated Panther OUT_DIR
free-space floor/monitoring
network/build authorization
existing build-process state
```

Record separately:

```text
FULL_ANDROID_BUILD
REQUIRED_IMAGES
REQUIRED_SABLE_PRODUCT_SELECTION
REQUIRED_SABLE_PRODUCT_INSTALL
TARGET_FILES_MEMBERSHIP
IMAGE_MEMBERSHIP
R8_PANTHER_PRODUCT_CLOSURE
```

Image inspection must detect the actual filesystem format before choosing tools; do not assume ext4/debugfs for every image.

## 11. Panther device campaign

Consume exact hash-identified image/app artifacts. Validate package/component identity, launcher behavior, R8-A design behavior, Calculator/Convert/Games, one Reader product/capability set, Media local/network boundaries, permissions/AppOps/roles/system intents, native JNI execution and required R7 regressions.

Reboot-dependent claims require separate reboot authorization.

## 12. R8-B3 — Titan 2 portability gate

After Panther acceptance, build Titan 2 with an isolated OUT_DIR and the same frozen common R8 app artifacts/common `vendor_sable` integration wherever compatible.

Required portability claims include:

```text
same common application source/artifacts
same common product composition
bounded Titan-specific device adapter
16 KiB native compatibility
runtime page-size measurement
physical-keyboard navigation/focus/text input
square-display layout/readability
Reader OCR/TTS capability
Media3/audio behavior
no common application source fork
```

Titan-specific secondary-display/program-key/FM features are not common R8 requirements unless separately approved.

`R8_COMMON_APP_PORTABILITY=PASS` requires both common-artifact reuse and target-specific runtime acceptance.

## 13. Production signing — later release gate

Production signing is not part of R8 development closure.

After Panther and Titan 2 development qualification is satisfactory, a separate signing program may define:

```text
production app keys
AVB hierarchy
OTA signing
sign_target_files_apks
key custody/backup/recovery/rotation
approved artifact handoff
signing-host hardening/offline policy
signed-output provenance
```

The ThinkPad P50 is only a future signing-host candidate. It is not yet `sable-signer-01`.

## 14. Failure preservation

For trusted build/product failures:

```text
DO_NOT_CLEAN_AUTOMATICALLY
DO_NOT_CLOBBER_AUTOMATICALLY
DO_NOT_DELETE_OUT_AUTOMATICALLY
DO_NOT_RERUN_AUTOMATICALLY
```

Classify first:

```text
REQUIREMENTS
A1_SOURCE_TEST
A2_TRUSTED_APP_BUILD
A2_NATIVE_16K
B1_SOONG_IMPORT
B1_PRODUCT_SELECTION
B1_PRODUCT_INSTALL
B2/B3_IMAGE_COMPOSITION
HOST_ENVIRONMENT
STORAGE
RUNTIME
```

Fix the root cause and rerun the narrowest valid target while preserving useful evidence.

## 15. Documentation after closure

When a gate closes, update current status/README, record exact commit/artifact/evidence identity, preserve historical requirement/evidence files and do not rewrite requirements after the fact to make implementation appear correct.
