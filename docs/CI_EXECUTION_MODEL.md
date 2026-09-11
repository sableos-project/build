# SableOS CI execution model

Status: **normative implementation guidance for CI execution.**

This document implements the trust architecture in `sableos-project/.github/docs/CI_TRUST_ARCHITECTURE.md`.

## Infrastructure roles

```text
thinkpad-p50      = sable-builder-01
optiPlex          = sable-signer-01
Pixel 7 / panther = sable-device-01
GitHub hosted     = untrusted/disposable CI
```

## C1 — fast PR CI

C1 runs only on GitHub-hosted runners and may execute untrusted pull-request code.

Required baseline checks:

- repository policy and workflow validation;
- third-party Action references pinned to full commit SHA;
- shell syntax checks;
- XML/JSON syntax checks;
- simple committed-secret/private-key heuristics;
- CodeQL for supported languages where source is present;
- Android/source-oriented security scanning where applicable;
- pure deterministic unit tests as component code is structured to support them;
- failure artifacts and SARIF where supported.

C1 jobs must not rely on production secrets, a persistent AOSP checkout, ADB, or a self-hosted machine.

## C2 — trusted component/AOSP build

C2 runs on `sable-builder-01` only after the source identity is explicitly trusted.

Initial policy: do not run arbitrary pull-request heads on the ThinkPad. Until a reviewed merge-candidate mechanism is implemented, automated C2 should consume only exact trusted commits already accepted to the trusted development line or a separately approved exact identity.

Future self-hosted runner labels should be specific, for example:

```text
self-hosted
linux
x64
sable-builder-01
trusted-aosp
```

Do not use a generic `self-hosted` selector by itself for Sable build jobs.

The runner should operate under a dedicated `sable-ci` account and isolated workspace rooted under `/srv/data/sable-ci/`, not the developer/reference Android workspace.

C2 output should include:

```text
gate_report.txt
source_identity.txt
build_environment.txt
artifact_inventory.txt
build.log
SHA256SUMS.txt
```

For APK/module work, additionally record package metadata, SDK levels, manifest/DEX structure, and exact artifact SHA-256.

## C3 — clean reconstruction

C3 proves that the documented multi-repository composition can reconstruct without workspace-only source.

Required sequence:

1. create a new CI workspace;
2. acquire exact `platform_manifest` and referenced revisions;
3. verify all expected Sable/upstream revisions;
4. seal source identity;
5. end the networked acquisition phase;
6. perform the build with network access denied;
7. inspect and hash outputs;
8. seal evidence;
9. retain the exact manifest/source/build identity with artifacts.

No local manifest override or manual copied module may be treated as successful reconstruction evidence.

## C4 — device lab

C4 targets `sable-device-01` only.

The device stage consumes an exact artifact hash from C2/C3 and requires a separate authorization boundary for install/update, reboot, role/default-app changes, wipe, or other device mutation.

Automatable evidence includes package/artifact binding, launcher inventory, exact component launch, permissions/AppOps, focused logs, screenshots, and semantic UI tests.

Carrier-dependent call/SMS/MMS validation remains semi-automated until a dedicated second endpoint/test harness exists.

## C5 — release/signing

C5 targets `sable-signer-01` only.

The signer is never registered as a general GitHub Actions runner. It consumes only an approved artifact plus its expected source/manifest identity and hash, verifies them locally, signs, then emits signed-output checksums and signing provenance.

Production signing material must not be present on `sable-builder-01` or GitHub-hosted runners.

## Workflow supply-chain rules

All repository workflows must:

- pin third-party Actions by full commit SHA;
- use explicit least-privilege permissions;
- set timeouts;
- use concurrency cancellation for replaceable PR jobs;
- upload diagnostic artifacts on failure;
- avoid exposing secrets to fork PR code;
- avoid mutable cross-repository workflow references.

The initial reusable policy workflow is owned by `sableos-project/.github` and caller repositories should reference the exact `.github` repository commit containing that workflow.

## Vaachak reference

`vaachak-platform/vaachak-mobile` is the implementation reference for several patterns: SHA-pinned Actions, concurrency, bounded permissions, CodeQL, MobSF/SARIF, failure artifacts, Dependabot, checksums, and semantic UI identifiers. Do not copy its Gradle-specific build/release/signing assumptions into SableOS.

## Cache rules

- GitHub-hosted PR caches are untrusted convenience data.
- T0 caches never become trusted AOSP/release inputs.
- trusted build caches are isolated from PR runners and should be scoped by exact source/toolchain/substrate identity.
- clean/reproducibility gates must be able to run without mutable caches.

## Activation order

1. activate C1 reusable policy CI and SableStart security scanning;
2. add pure R6 tests as product logic is extracted;
3. provision the dedicated `sable-ci` account/workspace on `sable-builder-01`;
4. add C2 manual/trusted-SHA component builds;
5. add C3 clean reconstruction;
6. add bounded C4 Panther runtime automation;
7. commission `sable-signer-01` separately before enabling C5 release signing.
