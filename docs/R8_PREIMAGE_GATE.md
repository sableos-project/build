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
ELF program-header alignment
APK ZIP alignment for uncompressed native libraries
```

R8 native libraries must be compatible with 16 KiB page-size systems. The gate requires verified compatibility, not a hard-coded linker flag when the pinned NDK/toolchain already produces compliant binaries.

## B1 pre-image sequence

1. Bind exact target product/release/variant and isolated OUT_DIR.
2. Generate the Soong graph without broad compilation where supported.
3. Discover the exact generated Ninja/Soong outputs for the imported module.
4. Verify the frozen input APK is the declared import input.
5. Record signing/certificate configuration and whether the module is presigned, resigned or otherwise processed.
6. Record JNI processing and dexpreopt/uses-library configuration.
7. Build only the imported module / minimum required dependencies.
8. Inspect the actual Soong intermediate APK discovered from the graph.
9. Compare extracted classes*.dex and native .so hashes against the frozen artifact.
10. Validate ELF 16 KiB compatibility and APK ZIP alignment.
11. Prove product selection independently from module-build success.
12. Prove concrete PRODUCT_OUT installation.
13. When target-files are produced, prove target-files membership and content identity.
14. Inspect the filesystem image with a filesystem-appropriate tool (for example ext4 vs EROFS); do not assume debugfs is universally valid.
15. After device deployment, record runtime package path/certificate/page-size/JNI execution separately.

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
