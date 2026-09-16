# R8 pre-image application integration gate

Status: **normative execution guidance for the trusted R8 application-build and pre-image integration stages.**

This gate exists to catch application-artifact, JNI, Soong-import, dexpreopt, product-selection and packaging defects before authorizing a broad Panther or Titan 2 image build.

## Pipeline position

```text
A1 disposable GitHub qualification
  -> A2 trusted standalone app build on ai-g732
  -> exact application freeze
  -> B1 pre-image Android integration gate
  -> B2 Panther development image
  -> Panther runtime qualification
  -> B3 Titan 2 development integration/image
  -> Titan 2 portability qualification
```

Production AVB/OTA/release signing is deliberately outside this gate and remains deferred until Panther and Titan 2 development qualification are satisfactory.

## Claim layers

Keep these separate:

```text
source/app qualification
  -> trusted standalone artifact
  -> Soong import/module processing
  -> product selection
  -> PRODUCT_OUT install
  -> target-files membership
  -> filesystem image membership
  -> runtime package/JNI behavior
```

No earlier layer proves a later layer.

## Required A2 trusted application evidence

For each accepted APK containing native code, record at least:

```text
source repository + exact commit
upstream/reuse commit where applicable
Gradle wrapper/version
JDK version
Android SDK/NDK identity
Rust toolchain + Cargo.lock hash
APK SHA-256
package/version
manifest permissions/components
classes*.dex extracted-content SHA-256
lib/<abi>/*.so extracted-content SHA-256
native ABI inventory
ELF PT_LOAD alignment
APK ZIP alignment for uncompressed native libraries
native DT_NEEDED inventory
native undefined-symbol inventory
```

R8 native libraries must be compatible with 16 KiB page-size systems. The gate requires verified compatibility, not a hard-coded linker flag when the pinned NDK/toolchain already produces compliant binaries.

Source/dependency review must also look for hard-coded page-size assumptions in native code actually built. A `Cargo.lock` text grep alone is not proof. Runtime execution on a 16 KiB-capable/16 KiB-running target remains the decisive behavioral evidence.

## B1 pre-image sequence

1. Bind exact target product/release/variant and isolated OUT_DIR.
2. Generate the Soong graph without broad compilation where supported.
3. Discover the exact generated Ninja/Soong outputs for the imported module.
4. Query the module/target edge and, where supported, Ninja `-t inputs` to prove the frozen A2 APK is a hard graph input.
5. Inspect `module_bp_java_deps.json` when the target tree generates it; use it as dependency evidence, not as product-selection proof.
6. Record signing/certificate configuration and whether the module is presigned, resigned or otherwise processed.
7. Record JNI processing and dexpreopt/uses-library configuration, including `uses_libs`, `optional_uses_libs`, enforcement state and `dexpreopt.config` where generated.
8. Audit SELinux implications. Ordinary `/system/app` placement does not by itself require a custom `file_contexts` rule. If a Sable app requires a custom process domain, privileged/system semantics or signer-based seinfo, inspect the relevant `mac_permissions.xml`, `seapp_contexts`, policy and file/property contexts explicitly.
9. Build only the imported module / minimum required dependencies.
10. Inspect the actual Soong intermediate APK discovered from the graph.
11. Compare extracted classes*.dex and native .so hashes against the frozen artifact.
12. Verify native libraries are stored/compressed consistently with the APK manifest/runtime extraction model and satisfy required ZIP/page alignment.
13. Validate ELF 16 KiB compatibility and capture DT_NEEDED / unresolved-symbol inventory. Do not claim host `dlopen` execution of an ARM64 Android library on an unrelated x86 host.
14. Prove product selection independently from module-build success.
15. Prove concrete PRODUCT_OUT installation.
16. When target-files are produced, prove target-files membership and content identity.
17. Inspect the filesystem image with a filesystem-appropriate tool (for example ext4 vs EROFS); do not assume debugfs is universally valid.
18. After device deployment, record runtime package path/certificate/JNI execution and page-size evidence separately.

## Page-size runtime evidence

Record the actual runtime page size; do not infer it from SoC identity.

Useful evidence includes:

```text
getconf PAGE_SIZE or getconf PAGESIZE
ro.boot.hardware.cpu.pagesize              when present
ro.product.cpu.pagesize.max
ro.product.page_size                       where defined
ro.product.build.16k_page.enabled           only as the developer-option capability flag
```

`ro.product.build.16k_page.enabled` does not itself prove the kernel is currently running at 16 KiB.

## `snod` policy

`snod` / `systemimage-nodeps` may be used only as a bounded repackaging experiment after the required PRODUCT_OUT inputs are already known current.

It is **not** dependency-closure proof because it deliberately ignores normal dependency checking. With dexpreopt enabled, the build system itself warns that a full rebuild may be required. Therefore:

```text
SNOD_PACKAGING_EXPERIMENT=PASS
!= DEPENDENCY_REBUILD_CLOSURE=PASS
```

## Shared-user-ID policy

R8 applications must not introduce new `android:sharedUserId` use. Existing Sable-owned applications do not currently require it, including Sable Start. Any future exception requires an explicit architecture/security decision rather than a build convenience.

## Fresh-output escalation

Do not automatically clean/clobber after failures.

Reassess whether a fresh OUT_DIR is required when changes materially alter build-system/toolchain/schema assumptions, for example substantial Soong/Go build-logic changes, compiler/toolchain transitions, or source/policy changes with demonstrated stale-output inconsistency.

A repo sync, SEPolicy edit or product-metadata edit alone is not automatic proof that incremental continuation is unsafe. Preserve the old OUT_DIR/evidence unless destructive cleanup is separately authorized.

## Evidence vocabulary

```text
PASS        claim proven within its stated boundary
FAIL        claim contradicted
BLOCKED     prerequisite/environment prevents evaluation
NOT_TESTED  intentionally not executed
UNKNOWN     evidence ambiguous
```

## Dual-target portability rule

Where platform compatibility permits, Panther and Titan 2 should consume the same frozen common application artifacts and the same common `vendor_sable` product integration.

```text
R8_COMMON_APP_PORTABILITY=PASS

iff

same qualified common app source/artifacts
+ same common product integration
+ isolated per-target OUT_DIR
+ bounded device-specific adapters
+ target-specific runtime acceptance
+ no common application source fork
```

## Titan 2 compatibility matrix

| Dimension | Panther | Titan 2 |
| --- | --- | --- |
| Android ABI | `arm64-v8a` | `arm64-v8a` |
| Rust target | `aarch64-linux-android` | `aarch64-linux-android` |
| 16 KiB native compatibility | required | required |
| frozen common app artifact | same where compatible | same where compatible |
| common product composition | `vendor_sable` | `vendor_sable` |
| device adapter | Panther-specific | Titan-specific |
| OUT_DIR | isolated | isolated |
| runtime page size | measured | measured |
| touch | validate | validate |
| physical keyboard | baseline | explicit navigation/focus/input gate |
| square-display layout | baseline | explicit layout gate |
| Reader OCR/TTS | capability gate | capability gate |
| Media3/audio | capability gate | capability gate |
| production signing | deferred | deferred |

The secondary display, programmable-key extensions, FM radio and other Titan-specific features are not R8 common-application requirements unless separately documented.
