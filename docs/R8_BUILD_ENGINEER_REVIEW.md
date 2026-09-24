# R8 consolidated build-plan review brief

> **HISTORICAL R8 ENGINEERING RECORD — 2026-09-24 classification:** retained for build/integration provenance. The R8 execution sequence is closed; Panther R9 is accepted/frozen and K1/K2 is merged. Do not use this document as current project status or current Titan deployment authorization.


Status: **HISTORICAL_EVIDENCE / SUPERSEDED CURRENT EXECUTION.**

This brief summarizes the post-R7 R8 build architecture for experienced Android build review.

## Execution model

```text
A1 — disposable qualification
GitHub-hosted CI
  Rust/Kotlin/Gradle tests, lint, static/security checks
        |
        v
A2 — trusted standalone app build
ai-g732
  pinned JDK/SDK/NDK/Rust/Gradle
  arm64 JNI + standalone APK build
  16 KiB compatibility validation
  provenance seal
        |
        v
R8 application freeze
        |
        v
B1 — pre-image Android integration gate
ai-g732
  Soong graph generation/query
  android_app_import processing proof
  signing/JNI/dexpreopt/uses-library inspection
  product-selection proof
  PRODUCT_OUT proof
        |
        v
B2 — Panther development image + Panther qualification
        |
        v
B3 — Titan 2 development integration/image + portability qualification
        |
        v
later release-signing workstream
ThinkPad P50 is only a future signing-host candidate after development qualification
```

Production AVB, OTA and production APK signing are deliberately deferred until development builds are satisfactory on both Panther and Titan 2.

## Core policies

- The AOSP tree is an integration environment, not the everyday Rust/Kotlin compiler.
- GitHub runners do not enter the release binary trust chain.
- `ai-g732` produces the trusted standalone application artifacts and Android development images.
- `android_app_import` is the preferred candidate for standalone Gradle APK integration, but its exact Android 17 / GrapheneOS behavior is empirically proved before normalization.
- Common application import definitions and `PRODUCT_PACKAGES` composition belong in `vendor_sable`; device repositories contain only genuine target-specific adaptation.
- Module build success, product selection, PRODUCT_OUT, target-files, image membership and runtime state remain separate claims.
- No automatic clean/clobber/delete after a failure; classify and retry the narrowest valid target.
- Panther and Titan 2 use isolated OUT_DIRs.
- Where compatible, both devices consume the same frozen common R8 app artifacts.
- Native R8 libraries must be verified compatible with 16 KiB page-size systems; the exact linker mechanism follows the pinned toolchain rather than being hard-coded unnecessarily.
- Outer APK container hashes may legitimately change during Soong processing/signing; extracted DEX/JNI code identities are tracked separately.
- Image inspection must detect the actual filesystem format before choosing ext4/EROFS tooling.

## R8 application tranche

- R8-A: shared design — Follow system / Light / Dark / bounded accent / reset.
- R8-B: Calculator + Convert.
- R8-C: Games — Sudoku / Minesweeper / 2048.
- R8-D: Reader publication path — Vaachak Mobile / Readium.
- R8-D2: Reader text/accessibility — TXT / share/process-text / TTS / OCR.
- R8-E: Media — local Music + Internet Radio.

## Dual-target compatibility

| Dimension | Panther | Titan 2 |
| --- | --- | --- |
| ABI | arm64-v8a | arm64-v8a |
| Rust target | aarch64-linux-android | aarch64-linux-android |
| common app artifacts | frozen/common | same frozen/common where compatible |
| common product integration | vendor_sable | vendor_sable |
| device adapter | Panther-specific | Titan-specific |
| OUT_DIR | isolated | isolated |
| 16 KiB native compatibility | required | required |
| runtime page size | measured | measured |
| touch | validate | validate |
| physical keyboard | baseline | explicit gate |
| square display | baseline | explicit gate |
| Reader OCR/TTS | capability gate | capability gate |
| Media3/audio | capability gate | capability gate |
| production signing | deferred | deferred |

Titan-specific secondary-display/program-key/FM features are not common R8 requirements unless separately approved.

## Questions for second-eye review

1. Is the A1 -> A2 -> B1 -> B2/B3 separation sound for Android 17/GrapheneOS development?
2. Which additional Soong intermediates or graph queries should B1 capture for `android_app_import`?
3. Is the proposed DEX/JNI inner-content provenance sufficient to distinguish legitimate APK-container transformations from code changes?
4. Are there additional 16 KiB ELF/APK checks needed beyond program-header and ZIP alignment verification?
5. What narrow target(s) provide the best product-selection/PRODUCT_OUT proof before broad target-files/image work?
6. Are there dexpreopt/uses-library/certificate/partition edge cases we should explicitly test for imported apps?
7. For dual-target reuse, what build-system state should be kept common versus target-isolated besides OUT_DIR?
8. Are there additional failure classes where incremental continuation is unsafe and a fresh output should be required?

The objective is to make the full Panther/Titan image build the final integration proof, not the first place ordinary application or product-wiring defects are discovered.
