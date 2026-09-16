# SableOS build tooling

Host-side source assembly, trusted application builds, Android build orchestration, reproducibility checks, product-wiring proof and evidence tooling for SableOS.

This repository answers **how SableOS source/artifacts are qualified, frozen, integrated, built and validated**. Application implementation belongs in application-owned source/workspaces; exact OS source composition belongs in `platform_manifest`.

## Current R8 execution model

```text
A1 — disposable qualification
GitHub/local Rust + Kotlin + Gradle + static/security
        |
        v
A2 — trusted standalone app build
ai-g732, pinned toolchains, APK/JNI provenance + 16 KiB checks
        |
        v
exact trusted R8 app freeze
        |
        v
B1 — pre-image Soong/product integration proof
        |
        v
B2 — Panther development image + runtime campaign
        |
        v
B3 — Titan 2 portability image + runtime campaign
        |
        v
later production-signing workstream
```

The Android tree is not the everyday compiler for R8 applications.

## Current host transition

```text
GitHub hosted     = disposable/untrusted A1 CI
ai-g732           = intended trusted A2/B1/B2/B3 development builder
thinkpad-p50      = historical/reference builder during migration;
                    future production-signing-host candidate only
Pixel 7 / panther = primary R8 runtime target
Titan 2           = second R8 portability/runtime target
```

OptiPlex is no longer part of the signing plan. Production AVB/OTA/application signing is deferred until Panther and Titan 2 development qualification is satisfactory.

Do not copy ThinkPad-specific absolute paths into generic orchestration. `ai-g732` host/profile configuration must bind the actual storage/workspace layout after migration.

## Build-tooling goals

- explicit authorization for network, source mutation, build, device contact, Git mutation and destructive operations;
- fast A1 feedback separated from trusted A2 artifact production;
- trusted app artifacts sealed before Android integration;
- product-selection/PRODUCT_OUT/target-files/image/runtime claims kept separate;
- exact DEX/JNI inner-content identities tracked where APK containers can legitimately change;
- verified 16 KiB compatibility for native R8 libraries;
- isolated OUT_DIR per target/materially different variant;
- no implicit clean/clobber/delete on failure;
- storage preflight/monitoring for long Android builds;
- filesystem-aware image inspection (do not assume ext4/debugfs);
- clean reconstruction without workspace-only source or opaque local APKs.

## Recommended layout

Conceptually keep:

```text
source repos / manifest checkouts
upstream Android substrate
trusted standalone application artifacts
build output / isolated OUT_DIRs
evidence / logs / seals
pinned host tools
```

See [`docs/BUILD_LAYOUT.md`](docs/BUILD_LAYOUT.md).

## Pre-image gate

Before a full development image build:

1. A1 source/application qualification required for the tranche is green;
2. A2 trusted app build/seal passes on `ai-g732`;
3. exact app inputs are frozen;
4. selected Android 17/GrapheneOS import mechanism is proven;
5. signing/JNI/dexpreopt/uses-library processing is recorded;
6. product selection is proven separately;
7. PRODUCT_OUT installation is proven separately;
8. exact target product/release/variant/Build ID is resolved;
9. host/storage/source/tool identities are sealed;
10. storage has adequate margin and monitoring/abort policy.

Read [`docs/R8_PREIMAGE_GATE.md`](docs/R8_PREIMAGE_GATE.md).

A broad target such as target-files must not be assumed cheap; use graph/dry-run evidence first.

## R8 tooling

- [`gates/r8_app_artifact_audit.sh`](gates/r8_app_artifact_audit.sh) — read-only whole-APK/DEX/JNI/native-alignment audit.
- [`gates/r8_app_artifact_audit_selftest.sh`](gates/r8_app_artifact_audit_selftest.sh) — host-only fixture/self-test.
- [`docs/R8_BUILD_ENGINEER_REVIEW.md`](docs/R8_BUILD_ENGINEER_REVIEW.md) — concise second-eye review brief.
- [`docs/R8_PREIMAGE_GATE.md`](docs/R8_PREIMAGE_GATE.md) — normative trusted-artifact/pre-image boundary.

The artifact audit intentionally does **not** claim package-manifest semantics, Soong import, product selection, target-files/image or runtime proof.

## Core documentation

- [`docs/ANDROID_PRODUCT_BUILD_PLAYBOOK.md`](docs/ANDROID_PRODUCT_BUILD_PLAYBOOK.md)
- [`docs/CI_EXECUTION_MODEL.md`](docs/CI_EXECUTION_MODEL.md)
- [`docs/MILESTONE_EVIDENCE_GATES.md`](docs/MILESTONE_EVIDENCE_GATES.md)
- [`docs/REPRODUCIBILITY.md`](docs/REPRODUCIBILITY.md)
- [`docs/AUTHORIZATION_MODEL.md`](docs/AUTHORIZATION_MODEL.md)

Historical Panther/ThinkPad observations remain useful reference evidence but do not require future broad builds to stay on the old host.

## Ownership boundary

```text
platform_manifest
    exact OS source composition + external artifact provenance

application source/workspaces
    app source/dependency/test authority

platform_sable
    shared semantic/design/application contracts

vendor_sable
    common imported modules + common qualified app selection

device_sable_<target>
    bounded target adapter/runtime qualification

build
    trusted app build, Android build, product-wiring proof and evidence
```

Build tooling enforces documented architecture. It does not invent product semantics, privileges, default-app choices or device-specific policy.
