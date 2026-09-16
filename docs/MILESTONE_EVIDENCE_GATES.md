# Development milestone evidence gates

Status: **normative validation/evidence guidance for the current SableOS development train.**

A gate proves a bounded claim. It must not collapse source identity, compilation, product selection, image membership and runtime behavior into one reassuring `PASS`.

Historical Git history preserves the earlier long-form R5–R10 gate document. This revision keeps the earlier claim boundaries while making the current R8 Process A / Process B architecture explicit.

## 1. Universal claim ladder

Use explicit layers:

```text
requirements/source identity
 -> build input identity
 -> module/application compile
 -> standalone artifact identity
 -> product import/module declaration
 -> product selection
 -> PRODUCT_OUT install
 -> installed-files / target-files
 -> image membership
 -> runtime package/component state
 -> user-visible behavior
 -> clean reconstruction/release provenance
```

Never infer a later layer solely from an earlier one.

Examples:

- Cargo/Gradle PASS != Android product integration PASS.
- `module-info.json` != product selection.
- generated install rules != concrete PRODUCT_OUT output.
- target-files membership != runtime/default-role behavior.
- a successful Android build != complete SableOS product closure.
- one Panther runtime PASS != qualification of another device/carrier.

## 2. Evidence status vocabulary

Use consistently:

```text
PASS       claim proven within stated boundary
FAIL       tested claim contradicted / gate failed
BLOCKED    prerequisite/environment prevents evaluation
NOT_TESTED intentionally not executed
UNPROVEN   evidence exists but does not establish the claim
```

Do not convert `BLOCKED` or `UNPROVEN` to PASS because source looked reasonable.

## 3. Authorization

Every state-changing gate declares separate authorization for relevant classes, including:

- source mutation;
- workspace/build-output mutation;
- network/fetch;
- build execution;
- Git mutation;
- device contact;
- install/uninstall;
- reboot;
- roles/default apps;
- flash/update/sign;
- root/remount/slot/wipe;
- clean/clobber/delete.

Authorization for one class does not imply another.

## 4. Evidence storage

Prefer a unique evidence directory. Record focused outputs, manifests/inventories, hashes, source/build/artifact identity, result markers and a final evidence checksum/seal when the gate completes.

An interrupted evidence directory is preserved/unsealed, not silently promoted to a completed seal.

## 5. R5/R6 historical foundation

R5/R6 evidence remains historically important for:

- canonical Sable Start source migration;
- direct migrated-checkout build identity;
- manifest/reconstruction ownership;
- real launcher inventory/search/greeting requirements;
- distinction between module compile and product inclusion.

Do not rewrite old R5/R6 PASS/FAIL artifacts to match current R8 architecture. Current README/status documents may mark these gates historical/superseded as the next work item.

## 6. R7 Panther baseline

R7 remains the daily-driver/product-wiring evidence baseline.

Runtime requirements are in `device_sable_panther/docs/R7_DAILY_DRIVER_VALIDATION.md`.

Product/build forensics must continue to distinguish:

```text
source/prebuilt identity
 -> graph edge
 -> product selection
 -> PRODUCT_OUT
 -> target-files/image
 -> runtime
```

Recent Panther firmware work established direct graph/source/product/target-files provenance for standalone ABL, aggregate bootloader and radio artifacts, including byte identity through the final target-files RADIO staging. The standalone ABL build path is a direct vendor-prebuilt copy; the bootloader aggregate independently contains the same ABL payload. This is product/firmware evidence, not a substitute for application/runtime testing.

Any remaining unexecuted R7 calls/SMS/MMS/network/default-app/device cases stay explicit.

## 7. R8 — consolidated application foundation

R8 has two separate gate families.

### 7.1 Process A — standalone source/application qualification

Process A must be able to run without a full Panther image build.

#### Rust correctness

As applicable:

```text
cargo fmt --all -- --check
cargo clippy --workspace --all-targets --all-features -- -D warnings
cargo test --workspace --all-targets
property/fuzz tests for selected parsers/state machines
unsafe/FFI review where present
```

#### Rust dependency/security

Where Cargo is canonical:

```text
lock/dependency inventory
RustSec/cargo-audit
license/provenance review
```

Do not invent a parallel Cargo graph for a canonically Soong-owned component just to run Cargo tools.

#### Android/Kotlin

For each standalone app:

```text
JVM/unit tests
Compose/instrumentation tests as appropriate
Android lint/static analysis
standalone APK assembly
package/version inspection
manifest permission/component inspection
```

#### Rust-backed Android JNI

Before a Rust-backed app can freeze:

```text
Rust core tests PASS
Android native build PASS
arm64-v8a library identity PASS
x86_64/emulator library identity when supported
Kotlin/JNI signature contract PASS
panic/error boundary reviewed
APK expected .so inventory PASS
representative Kotlin -> JNI -> Rust call PASS
```

A Rust core PASS plus a Kotlin shell PASS without the binding is `JNI_RUNTIME_INTEGRATION=UNPROVEN`.

#### Vaachak Reader publication path

Bind exact Vaachak Mobile source revision, deterministic Sable adaptation, relevant upstream/core tests, Sable flavor build/lint/policy and APK identity.

Initial qualification pin currently used by the R8 staging work:

```text
5393503ec0695e87e0a9bc4567fec0fea110ea4d
```

Do not claim TXT solely from this path unless the source/tests/runtime prove it.

#### Vaachak Text Reader capability

Bind exact Vaachak Text Reader revision, tests, build, lint and capability-policy evidence.

Initial pin:

```text
50fca365baae9869264716569830690fb62029a7
```

Capability gates include:

- `text/plain` local ingestion;
- `ACTION_SEND`;
- `ACTION_PROCESS_TEXT`;
- TTS/audio export;
- CameraX/gallery OCR;
- Latin/Devanagari recognition.

Network policy must independently inspect the upstream Internet permission and ML Kit model-download/translation behavior. `ON_DEVICE_PROCESSING=PASS` does not imply `STRICT_NETWORK_FREE=PASS`.

### 7.2 R8 artifact seal

Every accepted Process A artifact records at least:

```text
source repository + commit
upstream/reuse commit(s)
workflow/run identity
package/application ID
versionCode/versionName
APK SHA-256
permissions
exported components/intent filters
native ABI/library inventory
third-party dependency/provenance inventory
accepted feature-policy boundary
known limitations
```

The freeze manifest lists the exact selected R8 inputs. A later rebuild with another hash is a different integration input.

### 7.3 R8-A design gate

Shared design contract:

```text
Follow system
Light
Dark
bounded accent
reset/default
```

Test preference resolution, invalid/corrupt fallback, persistence/schema migration as applicable, representative UI rendering and accessibility/contrast/font-scale behavior.

Basic appearance work must not introduce unrelated network/location/phone/media/privileged authority.

### 7.4 R8-B Calculator/Convert

Host/domain tests may implement exact arithmetic primitives before unresolved user-interaction semantics are chosen.

Do not write tests that silently make precedence, percent, repeated-equals, history or display-rounding behavior normative while those remain requirements TBDs.

Core Calculator/Convert permission inventory should remain low privilege/offline.

### 7.5 R8-C Games

Prove deterministic rules/state for Sudoku, Minesweeper and 2048 and Android rendering/input/accessibility separately. No Lua runtime is part of the gate.

### 7.6 R8-D / D2 Reader composition

Separate qualification of publication and text/accessibility capabilities is allowed. Product integration must eventually prove one accepted Sable Reader identity rather than two competing branded Reader apps.

### 7.7 R8-E Media

Separate local-Music storage policy from Internet-Radio network authority. Prove Media3/MediaSession/background/audio-focus behavior at the appropriate app/device layer. Do not import ESP FreeRTOS/I2S/HELIX/PSRAM playback architecture.

## 8. R8 integration freeze gate

Before any full R8 Panther build:

```text
selected Process A lanes PASS or explicitly deferred
exact artifact/source freeze produced
shared R8-A contract aligned
permissions/policy reviewed
external dependency/provenance recorded
product integration mechanism selected for proof
trusted builder migration/preflight PASS
```

A workstream may be deferred rather than forcing a low-quality implementation into the image.

## 9. R8 Process B — product integration gate

### 9.1 Prebuilt/import mechanism

The Android 17/GrapheneOS behavior of the selected mechanism must be proven. `android_app_import` is a candidate, not an assumption.

For each sealed app prove:

```text
sealed APK hash
 -> module/import declaration
 -> product package selection
 -> PRODUCT_OUT concrete path/hash
 -> installed-files membership
 -> target-files membership
 -> image membership
```

If the installed bytes differ because signing/zipalign/transformation is intentionally performed, record the transformation and resulting identity rather than claiming byte identity falsely.

### 9.2 Trusted builder migration

The next R8 image is planned on `ai-g732`. Before treating it as `sable-builder-01`, prove:

- host/storage identity;
- source repository identities;
- workspace/output/evidence roots;
- toolchain prerequisites;
- target/release/variant/Build ID;
- free-space floor/monitoring;
- no accidental old-ThinkPad-only input;
- exact frozen R8 app inputs available and hash-verified.

### 9.3 Full image gate

Record independently:

```text
FULL_ANDROID_BUILD
REQUIRED_IMAGES
REQUIRED_SABLE_PRODUCT_SELECTION
REQUIRED_SABLE_PRODUCT_INSTALL
TARGET_FILES_MEMBERSHIP
IMAGE_MEMBERSHIP
R8_PRODUCT_CLOSURE
```

Do not collapse a successful Ninja result and a later missing application into one ambiguous result.

## 10. R8 device campaign

The Panther Device1 campaign consumes exact hash-identified image/application artifacts.

Prove as applicable:

- package/component identity;
- launcher visibility/launch;
- shared design behavior;
- Reader format/share/TTS/OCR flows;
- Media local/network boundaries;
- Calculator/Convert/Games interaction/accessibility;
- permissions/AppOps/roles;
- cross-app/system intents;
- reboot persistence only when authorized;
- R7 daily-driver regression cases required for the accepted image.

## 11. Full image-build budget

Normal R8 loop:

```text
Cargo/Gradle/static CI            repeat
standalone app/device test        repeat as needed
product-wiring proof              bounded
full Panther image                once per frozen integration tranche
Device1 campaign                  once per accepted image tranche
```

Use dry-run/graph evidence before assuming a target-files/packaging target is cheap.

## 12. R9+

R9 is the next coherent productivity/replacement tranche, not the first Calculator milestone. It follows the same Process A -> freeze -> Process B -> image -> device model.

## 13. Failure preservation

For trusted Android/product failures:

```text
DO_NOT_CLEAN_AUTOMATICALLY
DO_NOT_CLOBBER_AUTOMATICALLY
DO_NOT_DELETE_OUT_AUTOMATICALLY
DO_NOT_RERUN_AUTOMATICALLY
```

First classify:

```text
REQUIREMENTS
SOURCE_INPUT
APP_COMPILE
STATIC_SECURITY
JNI_NATIVE
ARTIFACT_SEAL
PRODUCT_IMPORT
PRODUCT_SELECTION
PRODUCT_INSTALL
IMAGE_COMPOSITION
RUNTIME
HOST_ENVIRONMENT
STORAGE
```

Preserve partial outputs/logs when they contain useful evidence.

## 14. Documentation after closure

When a gate closes:

- update the owning current status/README;
- record exact commit/artifact/evidence identity;
- keep original historical requirement/evidence files intact;
- update the organization documentation map if a file becomes historical/superseded;
- do not rewrite the requirement after the fact to make the implementation appear correct.