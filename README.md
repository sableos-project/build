# SableOS build tooling

Host-side source assembly, trusted Android build orchestration, reproducibility checks, product-wiring proof and evidence tooling for SableOS.

This repository answers **how SableOS source/artifacts are assembled, integrated, built and validated**. Application implementation belongs in application-owned source/workspaces; exact OS source composition belongs in `platform_manifest`.

## Current R8 execution split

SableOS now separates two processes deliberately:

```text
PROCESS A — standalone application qualification
  GitHub/local Cargo + Gradle + upstream app workflows
  tests / static / security / APK/native build / artifact seal

PROCESS B — trusted SableOS integration
  exact frozen application artifacts + trusted Sable source
  product import/wiring proof
  Android/Soong integration
  Panther image build
  device evidence
```

This repository primarily owns **Process B** and the reproducibility/evidence rules joining the two processes. It may also provide generic gate helpers used by Process A, but the Panther tree is not the everyday compiler for R8 applications.

## Current host transition

The next R8 Panther image is intended to build on **`ai-g732`** after its expanded-storage environment and transferred source/tool/output state pass a migration seal.

```text
GitHub hosted     = disposable application/static/security qualification
ai-g732           = intended sable-builder-01 for R8 trusted Android/product builds
thinkpad-p50      = legacy/reference builder and historical evidence source
Pixel 7 / panther = sable-device-01
OptiPlex          = sable-signer-01
```

Do not copy ThinkPad-specific absolute paths into generic orchestration. Host/profile configuration must bind the actual `ai-g732` storage/workspace layout after migration.

## Build-tooling goals

- explicit authorization for network, source mutation, build, device contact, Git mutation and destructive operations;
- stable profile-driven entry points instead of milestone-specific shell fragments;
- source/artifact identities sealed before build execution;
- product-selection/PRODUCT_OUT/target-files/image/runtime claims kept separate;
- exact qualified APK/native artifact inputs tracked when the image consumes standalone-built applications;
- build outputs and evidence stored outside canonical source;
- no implicit clean/clobber/delete on failure;
- storage preflight/monitoring for long Android builds;
- clean reconstruction without workspace-only source or opaque local APKs;
- CI trust separation between disposable app runners, trusted image builder, device lab and signer.

## Recommended layout

Exact roots are host/profile-specific. Conceptually keep:

```text
source repos / manifest checkouts
upstream Android substrate
qualified external application artifacts
build output / OUT_DIR
evidence / logs / seals
pinned host tools
```

See [`docs/BUILD_LAYOUT.md`](docs/BUILD_LAYOUT.md).

## Product-build rule

Before a full image build:

1. app/source qualification required for the tranche is green;
2. exact application inputs are frozen;
3. the selected Android 17/GrapheneOS prebuilt/import mechanism is proven;
4. target product/release/variant/Build ID is resolved;
5. source/artifact/host identities are sealed;
6. storage has sufficient margin and a monitoring/abort policy;
7. mutation/network/device boundaries are explicit.

Then build once and preserve evidence.

A broad target such as `target-files-package` must not be assumed cheap; inspect graph/dry-run behavior before treating it as a low-cost gate.

## Core documentation

- [`docs/ANDROID_PRODUCT_BUILD_PLAYBOOK.md`](docs/ANDROID_PRODUCT_BUILD_PLAYBOOK.md) — target resolution, product-wiring ladder, qualified APK integration and long-build procedure.
- [`docs/CI_EXECUTION_MODEL.md`](docs/CI_EXECUTION_MODEL.md) — disposable app CI vs trusted product build/device/signing execution.
- [`docs/MILESTONE_EVIDENCE_GATES.md`](docs/MILESTONE_EVIDENCE_GATES.md) — bounded claim/evidence gates including current R8 Process A/B closure.
- [`docs/BUILD_LAYOUT.md`](docs/BUILD_LAYOUT.md) — source/output/evidence/tool separation.
- [`docs/REPRODUCIBILITY.md`](docs/REPRODUCIBILITY.md) — source plus sealed external artifact reproducibility.
- [`docs/AUTHORIZATION_MODEL.md`](docs/AUTHORIZATION_MODEL.md) — operation-class authorization.
- [`docs/CI_STATUS_20260911.md`](docs/CI_STATUS_20260911.md) — **historical dated CI snapshot**, not current status.

Historical Panther/ThinkPad observations remain useful reference evidence in the playbook. They must not be mistaken for a requirement to keep future image builds on the old host.

## Ownership boundary

```text
platform_manifest
    exact OS source composition + external artifact provenance references

application source/workspaces
    standalone source/build/dependency/test authority

platform_sable
    shared semantic/design/application contracts

vendor_sable
    common product integration/selection of qualified apps

device_sable_<target>
    bounded target adapter/runtime qualification

build
    orchestration, reconstruction, product-wiring proof and evidence
```

Build tooling enforces documented architecture. It does not invent product semantics, application permissions, default-app choices or device-specific policy.