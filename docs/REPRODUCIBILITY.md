# Reproducibility policy

> **Current execution overlay — 2026-09-20:** a successful target request against a warmed OUT is incremental evidence, not fresh-build proof. R9 release qualification requires an initially absent source-bound OUT, independently checked by the outer runner and inner build, plus target-files mtime/freshness evidence proving creation after the build start.


Status: **normative reproducibility/provenance policy.**

SableOS distinguishes related but different claims:

```text
source composition reproducibility
A1 standalone qualification reproducibility
A2 trusted application artifact reproducibility
product integration reproducibility
artifact byte reproducibility
runtime/portability reproducibility
later signed-release reproducibility
```

Do not use one as a substitute for another.

## 1. OS source composition

A reproducible Android build starts from explicit upstream/substrate identity plus exact Sable-owned revisions. `platform_manifest` is authoritative. A clean reconstruction must not depend on manual source copies, untracked local manifests, host-only symlinks, uncommitted source, unresolved branch tips or historical workspace-only modules.

## 2. A1 disposable application qualification

A1 may run on GitHub/developer machines and records exact source/upstream pins, lock/dependency state, workflow/tool identity, package/manifest state and qualification artifact hashes.

A1 proves the declared standalone qualification only; it is not automatically the artifact consumed by the product.

## 3. A2 trusted standalone application reproducibility

`ai-g732` rebuilds exact accepted source with pinned/recorded toolchains and produces the artifact eligible for the R8 freeze.

For each accepted A2 artifact record:

```text
source/upstream commit(s)
Gradle wrapper/version
JDK
Android SDK/NDK
Rust toolchain + lockfile hashes
build commands/variant
package/application ID + version
permissions/components
trusted APK SHA-256
classes*.dex extracted-content SHA-256
JNI .so extracted-content SHA-256
native ABI inventory
16 KiB compatibility
dependency/provenance inventory
```

Where reproducible, compare A1 and A2 outputs. Unexplained differences block the trusted freeze until understood.

## 4. External-source adaptation

For Vaachak or other pinned sources:

```text
exact upstream commit
+ exact Sable adaptation
+ exact trusted build/dependency environment
= accepted trusted source/artifact identity
```

Branch names alone are never sufficient provenance.

## 5. Product integration reproducibility

A reproducible SableOS development image records both exact source composition and exact trusted A2 application inputs.

For each imported app additionally record:

```text
A2 freeze record
module/import declaration
certificate/signing behavior
JNI/dexpreopt/uses-library behavior
product selection owner
install partition/path
PRODUCT_OUT identity
target-files/image identity when generated
```

Do not claim reconstruction solely from the Android source manifest when trusted external APKs are also required.

## 6. Whole-APK versus inner-code identity

Source reproducibility does not guarantee outer APK byte identity when signing, zip alignment, compression/layout or generated metadata changes.

Therefore track separately:

```text
whole APK SHA-256
classes*.dex extracted-content SHA-256
lib/<abi>/*.so extracted-content SHA-256
```

Intentional Soong/signing transformations must be documented rather than treated as unexplained code drift.

## 7. Native 16 KiB reproducibility

R8 native artifacts must be reproducibly compatible with 16 KiB page-size systems using the pinned toolchain. Record ELF program-header alignment and APK native-library ZIP alignment. Runtime page size/JNI behavior are device evidence, not inferred from SoC name alone.

## 8. Build host / target isolation

The first R8 `ai-g732` build after storage migration records host/OS, filesystem/storage, workspace/output/evidence roots, toolchains, source identities, free-space/network policy and isolated OUT_DIR per target/materially different variant.

Panther and Titan 2 should use the same trusted common app artifacts where compatible while keeping target output state separate.

## 9. Caches/network

Caches are performance inputs, not provenance authorities. Disposable caches are untrusted convenience data; trusted caches are isolated from arbitrary PR code; clean/reconstruction claims can bypass/invalidate caches. Offline/no-fetch claims require actual dependency pre-acquisition and an honestly enforced/reported boundary.

## 10. Evidence package

A strong evidence set records:

```text
platform_manifest/source identity
trusted_external_artifact_inputs
host/build environment
resolved target product/release/variant/Build ID
build commands/result
artifact inventory
product/package install evidence
target-files/image identities
SHA256SUMS
known transformations/nondeterminism
final gate report + seal
```

## 11. Production signing — later

Development/test signing identity is separate from production release signing.

Production app keys, AVB, OTA, `sign_target_files_apks`, signing-host hardening/key custody and signed-output provenance are deliberately deferred until Panther and Titan 2 development qualification is satisfactory.

The ThinkPad P50 is only a future signing-host candidate and is not yet `sable-signer-01`.

## 12. Closure vocabulary

```text
SOURCE_RECONSTRUCTION=PASS/UNPROVEN
A1_QUALIFICATION_REPRODUCIBILITY=PASS/UNPROVEN
A2_TRUSTED_APP_REPRODUCIBILITY=PASS/UNPROVEN
EXTERNAL_ARTIFACT_INPUT_BINDING=PASS/UNPROVEN
PRODUCT_INTEGRATION_RECONSTRUCTION=PASS/UNPROVEN
BYTE_REPRODUCIBILITY=PASS/UNPROVEN
PORTABILITY_REPRODUCIBILITY=PASS/UNPROVEN
SIGNED_RELEASE_REPRODUCIBILITY=PASS/UNPROVEN
```

Only claim the layers actually demonstrated.
