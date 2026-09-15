# SableOS CI execution model

Status: **normative implementation guidance for CI execution.**

This document implements the trust architecture in `sableos-project/.github/docs/CI_TRUST_ARCHITECTURE.md`.

Security/privacy tool selection and claim boundaries are defined in [`SECURITY_PRIVACY_TESTING.md`](SECURITY_PRIVACY_TESTING.md). CI stages below decide **where** those checks may run; the security/privacy document decides **what each check proves**.

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
- ShellCheck for committed shell/build-gate scripts;
- XML/JSON/YAML syntax checks where applicable;
- Gitleaks repository/history secret scanning;
- CodeQL for supported languages where source is present;
- mobsfscan for Android Java/Kotlin/XML repositories;
- Android Lint when it can run reproducibly without trusted persistent AOSP state;
- detekt for Kotlin repositories using a pinned standalone/CI configuration;
- Rust formatting/Clippy checks where the repository/toolchain makes those checks canonical and reproducible;
- RustSec/cargo-audit and cargo-deny for repositories that actually own a Cargo dependency graph;
- pure deterministic unit tests as component code is structured to support them;
- failure artifacts, scanner configuration identity and SARIF/JSON where supported.

C1 jobs must not rely on production secrets, a persistent AOSP checkout, ADB, or a self-hosted machine.

C1 must not auto-fix production source. Baseline/suppression changes are normal reviewed source changes and must not be regenerated automatically to make CI green.

### C1 tool-overlap policy

Avoid redundant scanner count as a goal. Initial division of responsibility is:

```text
Gitleaks
    repository/history secret detection

mobsfscan
    Android-focused Java/Kotlin/XML SAST

Android Lint
    Android API/resource/manifest correctness + security/privacy/platform checks

detekt
    Kotlin correctness/complexity/maintainability policy

CodeQL
    deeper cross-file data-flow/security analysis where supported

Rustfmt + Clippy
    Rust formatting/correctness/idiom checks

cargo-audit / cargo-deny
    Cargo dependency advisory/provenance/license policy
```

Because mobsfscan already uses Semgrep-based Android rules, broad standalone Semgrep is not mandatory by default. Add Semgrep when Sable-specific security/privacy rules require it rather than duplicating existing coverage.

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
tool_identity.txt
artifact_inventory.txt
build.log
SHA256SUMS.txt
```

For APK/module work, additionally record package metadata, SDK levels, manifest/DEX structure, exact artifact SHA-256, and applicable post-build security reports.

### C2 security/privacy responsibilities

Checks that require the trusted Android tree or exact built artifact belong here rather than being approximated on C1:

- Soong/AOSP-native Android Lint when the module cannot be linted meaningfully in disposable CI;
- native Compose UI Test modules that require the Android build graph;
- AndroidX UIAutomator test APK build/install preparation, without device execution until C4 authorization;
- exact APK/target-files/image artifact binding;
- manifest/component/permission inspection of the built artifact;
- MobSF static scanning of the exact hashed APK/AAB/ZIP where applicable;
- Rust checks that depend on the pinned AOSP/Soong Rust toolchain;
- build-time sanitizer/fuzz target construction when separately authorized.

Do not perform opportunistic `pip`, `cargo install`, curl-pipe-shell, or mutable scanner downloads inside an offline trusted Android build. Security tools used in C2 must be pre-provisioned/pinned/checksum-verified or supplied through a separately authorized acquisition phase.

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
8. run the C2 artifact-security checks that are part of the reconstruction acceptance profile;
9. seal evidence;
10. retain the exact manifest/source/build/tool identity with artifacts.

No local manifest override or manual copied module may be treated as successful reconstruction evidence.

A security scanner that needs network access must not silently reopen network access during step 6. Use a pre-provisioned database/cache/tool artifact or run that scanner in a separately identified post-build networked analysis stage against the already-hashed artifact.

## C4 — device lab

C4 targets `sable-device-01` only.

The device stage consumes an exact artifact hash from C2/C3 and requires a separate authorization boundary for install/update, reboot, role/default-app changes, wipe, or other device mutation.

Automatable evidence includes package/artifact binding, launcher inventory, exact component launch, permissions/AppOps, focused logs, screenshots, and semantic UI tests.

Primary Android UI automation is:

```text
Compose UI Test
    deterministic first-party Compose behavior

AndroidX UIAutomator
    cross-package/system UI boundaries

shell evidence gates
    artifact/device binding, logs, screenshots, permissions/AppOps and evidence sealing
```

Maestro may be used as an optional black-box/exploratory layer after compatibility is proven, but it is not the authoritative SableOS Android test framework.

Privacy-oriented runtime gates should additionally validate the component's declared policy where applicable, including unexpected permissions, exported behavior, AppOps, sensitive logging, and network behavior. Absence of a crash is not sufficient privacy evidence.

Carrier-dependent call/SMS/MMS validation remains semi-automated until a dedicated second endpoint/test harness exists.

## C5 — release/signing

C5 targets `sable-signer-01` only.

The signer is never registered as a general GitHub Actions runner. It consumes only an approved artifact plus its expected source/manifest identity and hash, verifies them locally, signs, then emits signed-output checksums and signing provenance.

Production signing material must not be present on `sable-builder-01` or GitHub-hosted runners.

Release approval should require the security/privacy evidence profile applicable to the component/product, including documented exceptions. C5 must never download or update scanners as part of signing.

## Workflow supply-chain rules

All repository workflows must:

- pin third-party Actions by full commit SHA;
- use explicit least-privilege permissions;
- set timeouts;
- use concurrency cancellation for replaceable PR jobs;
- upload diagnostic artifacts on failure;
- avoid exposing secrets to fork PR code;
- avoid mutable cross-repository workflow references;
- record exact scanner/tool versions for security-significant jobs;
- avoid mutable installer channels in trusted build/signing jobs.

The initial reusable policy workflow is owned by `sableos-project/.github` and caller repositories should reference the exact `.github` repository commit containing that workflow.

## Rust-specific CI policy

Rust repositories/components must first identify whether the production dependency graph is Cargo-owned or Soong-owned.

For Cargo-owned components, the normal C1 stack is:

```text
rustfmt --check
cargo clippy with reviewed lint policy
cargo test
cargo audit
cargo deny check
CodeQL Rust where extraction/build support is valid
```

For security-critical Cargo dependency graphs, add `cargo-vet` so third-party dependency trust is based on explicit audits rather than only the absence of a known advisory.

For Soong-only Android Rust, do not introduce a parallel Cargo dependency graph solely for scanning. Use the pinned AOSP/Soong Rust toolchain and only add Cargo-specific checks when Cargo is a real canonical test/dependency representation.

Targeted `cargo-fuzz`/libFuzzer coverage should be added for parsers, protocol/state-machine code, unsafe code and FFI boundaries. High-volume ClusterFuzzLite-style fuzzing belongs on dedicated CI capacity, not on a storage-constrained developer workstation by default.

## Vaachak reference

`vaachak-platform/vaachak-mobile` is the implementation reference for several patterns: SHA-pinned Actions, concurrency, bounded permissions, CodeQL, MobSF/SARIF, failure artifacts, Dependabot, checksums, and semantic UI identifiers. Do not copy its Gradle-specific build/release/signing assumptions into SableOS.

## Cache rules

- GitHub-hosted PR caches are untrusted convenience data.
- T0 caches never become trusted AOSP/release inputs.
- trusted build caches are isolated from PR runners and should be scoped by exact source/toolchain/substrate identity.
- clean/reproducibility gates must be able to run without mutable caches.
- vulnerability/advisory databases and scanner caches are inputs whose identity/freshness should be recorded when their contents affect a security decision.

## Activation order

1. activate C1 reusable policy CI plus Gitleaks, workflow/ShellCheck, CodeQL and SableStart mobsfscan;
2. add Android Lint and detekt using pinned/reproducible execution paths;
3. add Rust rustfmt/Clippy and Cargo advisory/provenance checks to repositories where they are canonical;
4. add pure R6 tests and native Compose UI Test as product logic is structured to support them;
5. provision the dedicated `sable-ci` account/workspace on `sable-builder-01`;
6. add C2 manual/trusted-SHA component builds and exact-artifact MobSF scanning;
7. add C3 clean reconstruction with security/artifact checks preserved;
8. add bounded C4 Panther runtime automation with Compose UI Test + AndroidX UIAutomator + shell evidence seals;
9. add cargo-vet and targeted Rust fuzzing for security-critical dependency/input boundaries;
10. commission `sable-signer-01` separately before enabling C5 release signing.
