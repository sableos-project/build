# SableOS CI execution model

Status: **normative implementation guidance for CI/build/device/signing execution.**

This document implements `sableos-project/.github/docs/CI_TRUST_ARCHITECTURE.md`.

## Infrastructure roles during the R8 transition

```text
GitHub hosted     = disposable/untrusted application/static/security CI
ai-g732           = intended sable-builder-01 for trusted Android/product builds
thinkpad-p50      = legacy/reference builder and historical evidence source
Pixel 7 / panther = sable-device-01
OptiPlex          = sable-signer-01
```

`ai-g732` becomes the active trusted builder only after its new storage/source/tool/output environment passes the migration preflight. The role name is stable; the physical host transition must be explicit in evidence.

## C0 — repository/policy checks

Fast disposable checks may validate:

- repository/workflow structure;
- pinned/least-privilege workflow policy;
- syntax/configuration;
- secret/private-key heuristics;
- documentation/reference consistency where practical.

No trusted AOSP workspace/device/signing access.

## C1 — standalone R8 application qualification

C1 runs on GitHub-hosted disposable runners and is the normal feedback loop for independently developed R8 applications.

Current lanes should remain separately diagnosable:

```text
Rust correctness
Rust dependency/security
Android compile/tests
Android static analysis
Reader compile/tests
Reader policy/static
Text Reader compile/tests
Text Reader policy/static
APK artifact seal
```

C1 may use public dependency networks as the app workflow declares, but it must not possess production signing material, persistent trusted build state or device authority.

Expected outputs include as applicable:

```text
source_commit.txt
upstream_pin.txt
qualification_result.txt
dependency_inventory.txt
manifest_permissions.txt
package_components.txt
native_abi_inventory.txt
APK_SHA256SUMS.txt
qualification APK artifact
workflow/run identity
```

A green C1 application build does not prove SableOS product/image integration.

### Reader/upstream qualification

External reuse sources are checked out at exact commits. Deterministic Sable flavor/overlay/patch logic is version-controlled in the qualification source.

Initial R8 upstreams include:

```text
vaachak-mobile      5393503ec0695e87e0a9bc4567fec0fea110ea4d
vaachak-textreader  50fca365baae9869264716569830690fb62029a7
```

A branch name is not an accepted freeze identity.

## C1.5 — integration-freeze aggregation

Before trusted product integration, aggregate the selected green application lanes into an exact freeze manifest.

For every accepted input record:

```text
source/upstream commit(s)
workflow/run
package ID + version
APK/native artifact SHA-256
permissions/exported components
native ABIs/libraries
third-party dependency/provenance inventory
accepted feature-policy boundary
known limitations
```

A source workstream may be explicitly deferred instead of weakening the gate.

Changing a frozen application artifact reopens downstream integration evidence for that artifact.

## C2 — trusted product-wiring / narrow Android integration

C2 runs only on the trusted builder and only against explicitly approved exact input identities.

Use C2 for Android properties that standalone Gradle/Cargo cannot prove, including:

- exact prebuilt/import module semantics;
- signing/partition/native-library behavior of the selected module type;
- product package selection;
- PRODUCT_OUT install path;
- installed-files/target-files wiring;
- framework/platform API/resource integration;
- JNI installation/linkage when Android product packaging matters;
- bounded Soong/module builds required by the product architecture.

`android_app_import` is a candidate mechanism until C2 proves the exact Android 17/GrapheneOS behavior required by SableOS.

Do not use C2 to discover ordinary Kotlin/Rust compile failures already covered by C1.

## C3 — trusted Panther image / clean reconstruction

C3 performs the normal Android product build or clean reconstruction claim.

Before execution record:

```text
host/storage identity
workspace/source/manifest identity
frozen external application-input identity
target product/release/variant/lunch invocation
expected/resolved Build ID
OUT/evidence roots
network/fetch authorization
free-space floor/monitoring policy
existing build-process state
clean/clobber/delete authorization
```

Expected evidence includes:

```text
source_identity.txt
external_artifact_inputs.txt
build_environment.txt
build.log
build_result.txt
artifact_inventory.txt
installed/product package evidence
target-files/image inventory
SHA256SUMS.txt
gate_report.txt
```

### ai-g732 activation

For the first R8 build after moving to the new 4 TB storage, C3 must additionally prove the migration itself did not introduce:

- source revision drift;
- incomplete repository transfer;
- stale absolute-path assumptions;
- missing host tools;
- unexpected dependency on old ThinkPad-only local state;
- inadequate free-space margin;
- ambiguous OUT/evidence ownership.

Do not clean the historical ThinkPad workspace merely because migration succeeded unless cleanup is separately authorized.

## C4 — Panther device lab

C4 consumes an exact hash-identified C3 image/artifact and requires independent device authorization.

Automatable evidence may include:

- build fingerprint/product/API/SPL;
- installed package/component identity;
- launcher inventory/launch;
- permissions/AppOps;
- role/default-handler state;
- focused logs;
- screenshots/semantic UI tests;
- cross-app storage/media behavior;
- theme/design integration;
- reboot persistence when reboot is authorized.

Calls/SMS/MMS/carrier behaviors may require human observation or a second endpoint; record those boundaries honestly.

## C5 — release/signing

`sable-signer-01` is never a general CI/build host.

It accepts only an approved release candidate plus expected source/manifest/external-artifact/image hashes, verifies identity locally, signs, and emits signing provenance/checksums.

Production signing material is not present on C1/C2/C3 infrastructure.

## Workflow supply-chain rules

Trusted/release-critical workflows should converge on:

- immutable third-party Action pins;
- least-privilege permissions;
- explicit timeouts;
- concurrency cancellation for replaceable PR jobs;
- no secrets exposed to untrusted fork code;
- diagnostic artifacts where useful;
- explicit tool/dependency versions;
- no mutable cross-repository workflow refs in trusted paths;
- explicit network/offline behavior.

## Cache rules

- C1 caches are untrusted convenience data.
- A C1 artifact becomes a product candidate only by exact sealed identity, not because it came from a cache.
- C2/C3 trusted caches are isolated from untrusted PR runners.
- clean/reconstruction gates can invalidate/bypass caches when the claim requires it.
- C5 trusts verified hashes/provenance, not build caches.

## Failure handling

A failure in one lane must not be hidden by success in another.

Examples:

```text
RUST_TEST=PASS
ANDROID_APK_BUILD=FAIL
=> application qualification FAIL

APP_QUALIFICATION=PASS
PRODUCT_IMPORT=FAIL
=> application source remains qualified; product integration FAIL

ANDROID_BUILD=PASS
REQUIRED_SABLE_APP_IN_IMAGE=FAIL
=> Android build PASS; Sable product closure FAIL
```

Preserve the strongest bounded claim without promoting it beyond the evidence.