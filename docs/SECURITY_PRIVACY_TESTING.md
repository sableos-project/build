# SableOS security and privacy testing toolchain

Status: **normative testing/tool-selection guidance; activation of any tool still requires a pinned implementation and evidence-producing gate.**

SableOS treats security and privacy requirements as properties of the source, dependency graph, build artifacts, runtime behavior, and release process. No single scanner is accepted as proof that an application or OS component is secure.

The required pattern is:

```text
source policy
    -> language/static analysis
    -> dependency/supply-chain review
    -> deterministic unit/component tests
    -> trusted build
    -> post-build artifact analysis
    -> device/runtime validation
    -> evidence seal
```

Tools may overlap, but each tool must have a defined claim boundary. A scanner result must not be generalized beyond what that scanner actually inspected.

## 1. Core principles

All security/privacy tooling should follow these rules:

- pin tool and third-party Action versions; do not use mutable `latest`, `main`, or floating tags for blocking gates;
- prefer official/native tooling before adding an external dependency;
- run untrusted PR source analysis on disposable GitHub-hosted runners, not on the trusted Android builder;
- do not give PR scanning jobs production secrets, device access, signing material, or access to persistent AOSP workspaces;
- keep networked acquisition/install phases separate from trusted offline build phases;
- emit machine-readable output such as SARIF/JSON where supported and preserve human-readable logs;
- distinguish blocking policy from advisory findings and document every accepted suppression/exception;
- never auto-fix production source in a security gate;
- retain exact source identity, tool versions/configuration, result artifacts, and hashes with accepted evidence;
- treat privacy regressions such as unexpected permissions, exported components, trackers, logging, or network behavior as security-relevant defects.

## 2. Android/Kotlin testing matrix

| Tool / layer | Primary purpose | Input | Normal stage | Initial policy |
| --- | --- | --- | --- | --- |
| **mobsfscan** | Android source SAST: insecure Java/Kotlin/XML patterns and mobile-security rules | Java, Kotlin, Android XML/source tree | C1 fast PR CI | Blocking for high-confidence ERROR findings; SARIF retained |
| **Android Lint** | Android API, correctness, security, privacy, performance, accessibility and manifest/resource checks | Android module source/resources | C1 when runnable without trusted AOSP state; otherwise C2 trusted component build | Blocking for configured fatal/error classes |
| **detekt** | Kotlin correctness, complexity, maintainability and policy enforcement | Kotlin source | C1 fast PR CI | Blocking on agreed correctness/complexity policy; baselines reviewed, not silently regenerated |
| **CodeQL** | Cross-file vulnerability/data-flow analysis for supported languages | Java/Kotlin, Rust, C/C++, workflows and other supported languages | C1 GitHub code scanning | Blocking policy based on severity/confidence after baseline triage |
| **Gitleaks** | Repository/history secret detection | Git history / working tree | C1 fast PR CI and pre-release | Blocking for unapproved secrets/keys/tokens |
| **Compose UI Test** | Deterministic first-party Compose behavior/semantics | Test APK + application code | C2 component test stage | Primary in-app Android UI test framework |
| **AndroidX UIAutomator** | Cross-application/system interaction and runtime assertions | Test APK/device | C4 device lab | Primary boundary-crossing Android UI automation |
| **shell evidence gates** | Artifact binding, package state, permissions/AppOps, logs, screenshots and evidence seals | Built artifacts + bounded device state | C2/C4 | Authoritative outer evidence/control-plane layer |
| **MobSF** | Post-build mobile artifact security assessment; static analysis and, when separately authorized, dynamic assessment | APK/AAB/ZIP as applicable | C2 post-build security stage; dynamic analysis in isolated lab | Artifact scanner, not source-build authority |

### 2.1 mobsfscan

Use `mobsfscan` as the default Android-focused source scanner because it understands Java, Kotlin and Android XML and can emit SARIF. Keep its configuration in version control.

Policy:

```text
source scan only
no source mutation
pinned scanner version
SARIF + text/JSON evidence
suppression requires rule id + justification
```

`mobsfscan` is powered by Semgrep/libsast rules. Do not add a second broad Semgrep pass merely to duplicate the same rule coverage. Add standalone Semgrep only when SableOS needs project-specific privacy/security rules that are not represented by mobsfscan, CodeQL, Android Lint or another native tool.

### 2.2 Android Lint

Android Lint remains mandatory because it understands Android-specific APIs/resources and checks correctness, security, performance, usability, accessibility and related platform concerns.

For AOSP/Soong-owned applications, prefer the tree's native lint integration when available. Do not introduce a parallel Gradle dependency graph solely to run lint. If a module can only be linted during trusted Android configuration, run that gate in C2 and preserve its exact Soong/source identity.

### 2.3 detekt

Use detekt for Kotlin source health and enforceable code-policy checks. It is not a memory profiler and must not be described as one.

Use detekt for:

- potential defects/code smells;
- complexity limits;
- coroutine/API misuse rules where configured;
- maintainability and consistency rules;
- selected formatting/ktlint-wrapper rules if explicitly adopted.

Memory/performance behavior should be measured separately with runtime profiling/benchmarks when required.

### 2.4 MobSF

Run MobSF only after an exact build artifact has been produced and hashed. The scan input hash must be recorded with the MobSF report.

A MobSF PASS/clean report does not replace:

- source SAST;
- product/image inclusion proof;
- exact-device runtime tests;
- permission/AppOps checks;
- manual security review of high-risk features.

Dynamic MobSF analysis is a separate lab capability and must never silently gain access to the production signing environment or trusted developer data.

## 3. Native Android UI automation policy

Primary SableOS Android UI testing is:

```text
Compose UI Test
    first-party Compose semantics and deterministic in-app behavior

AndroidX UIAutomator
    cross-package/system UI boundaries

shell evidence gate
    outer artifact/device binding and evidence sealing
```

This stack is preferred over making a third-party black-box UI framework gate-critical because SableOS owns its Compose application source and can test the semantics tree directly.

Maestro may remain useful for exploratory or black-box compatibility testing, but it is optional and non-authoritative unless separately promoted after version/API/device validation. It must not replace native Compose tests or the shell evidence gate.

## 4. Rust security and quality matrix

Rust policy must distinguish **Soong-only Android Rust** from **Cargo-managed Rust**. Do not create a second Cargo dependency graph solely to make Cargo scanners happy if the production module is owned and built by Soong.

| Tool / layer | Primary purpose | Applicable to | Normal stage | Initial policy |
| --- | --- | --- | --- | --- |
| **rustfmt** | Deterministic Rust formatting | Soong and Cargo Rust | C1/source gate | Blocking formatting check |
| **Clippy** | Correctness, suspicious patterns, idioms and selected security-relevant linting | Cargo projects and Soong modules where the pinned tree/toolchain exposes a compatible Clippy path | C1/C2 | Blocking for correctness and agreed lint set; do not enable all restriction/pedantic lints blindly |
| **CodeQL Rust** | Cross-file security analysis | Rust repositories/builds supported by CodeQL | C1 | Security scanning, subject to exact build/extraction viability |
| **cargo test** | Unit/integration behavior | Cargo-managed Rust/test harnesses | C1/C2 | Blocking when Cargo is canonical for that component |
| **cargo-audit / RustSec** | Known-vulnerability advisory scan for crate lockfiles | Cargo-managed dependency graphs | C1 + scheduled | Blocking on unaccepted vulnerabilities; advisory DB identity retained |
| **cargo-deny** | Dependency advisories, license policy, banned/duplicate crates and source provenance | Cargo-managed dependency graphs | C1 | Blocking policy after configuration is reviewed |
| **cargo-vet** | Human-audit provenance for third-party Rust dependencies | Security-critical Cargo dependency graphs | Supply-chain review / C1 | Recommended for dependency trust, introduced incrementally with explicit exemptions |
| **cargo-fuzz** | Coverage-guided fuzzing with libFuzzer | Parsers, protocol/state-machine code, unsafe/FFI boundaries | Trusted CI / scheduled | Required for selected high-risk targets, not every crate |
| **Miri** | Undefined-behavior/interpreter checks | Suitable pure-Rust/unsafe code using a compatible nightly toolchain | Scheduled/specialized | Supplemental; not a universal blocking PR gate |
| **unsafe-code inventory** | Track/review `unsafe` usage and unsafe FFI boundaries | All Rust | C1 review metric | Every unsafe block/interface requires justification and review ownership |

### 4.1 Clippy policy

Use the same pinned Rust toolchain as the component build whenever practical. Treat `clippy::correctness` findings as build-blocking. Add selected additional lints intentionally; do not turn the entire `restriction`, `pedantic`, or `nursery` groups into global errors without a reviewed policy.

Any `#[allow(...)]` used for a security/correctness lint should carry a nearby justification when the reason is not self-evident.

### 4.2 Rust dependency policy

For Cargo-managed software, use both classes of checks:

```text
cargo-audit / RustSec
    known-vulnerability intelligence

cargo-deny
    advisories + licenses + bans/duplicates + source provenance
```

For higher assurance repositories, add `cargo-vet` so a dependency is not considered trustworthy merely because no public CVE/advisory exists. `cargo-vet` records human audit provenance and should be introduced with explicit, shrinking exemptions rather than a fictional instant full-audit claim.

### 4.3 Unsafe Rust and FFI

SableOS should minimize `unsafe` code and keep it concentrated at reviewed boundaries. For every new unsafe block, unsafe function, raw-pointer manipulation, or FFI boundary, reviewers should be able to answer:

```text
Why is unsafe required?
What invariants make it sound?
Who owns those invariants?
What tests exercise the boundary?
Can fuzzing or Miri cover it?
What happens on malformed/untrusted input?
```

An unsafe-line counter is useful as a trend/review signal but is not a vulnerability detector. Do not treat a low unsafe count as proof of safety.

### 4.4 Fuzzing

Use `cargo-fuzz`/libFuzzer for selected Rust components that parse or transform attacker-controlled data, cross an FFI boundary, implement protocol/state machines, or perform complex serialization/deserialization.

For scalable CI fuzzing, ClusterFuzzLite is a later option. It supports Rust through cargo-fuzz but requires container/tooling resources and can consume substantial disk. It belongs on dedicated CI capacity, not on a storage-constrained developer workstation by default.

## 5. Repository-agnostic supporting tools

The following tools fill gaps not covered by the mobile-specific scanners:

### Gitleaks

Use Gitleaks for committed-secret/history scanning across every SableOS repository. mobsfscan can identify some hard-coded secrets in mobile source, but it is not a substitute for repository-wide secret detection.

### ShellCheck and action/workflow validation

All build/gate shell scripts should pass ShellCheck with reviewed suppressions. GitHub Actions should be syntax/policy checked, use least-privilege permissions, and pin third-party Actions by full commit SHA.

### OSV-Scanner / dependency vulnerability scanning

Use OSV-Scanner where lockfiles, SBOMs, vendored dependency metadata, or other supported dependency identities exist. It complements ecosystem-native scanners and is particularly useful for non-Rust host/tool dependencies and SBOM-driven validation.

Do not infer complete AOSP vulnerability coverage from an OSV lockfile scan; Android source composition is manifest/source-revision based and needs separate upstream/security-patch provenance.

## 6. Security/privacy build gate sequence

Every application or component should converge on the following sequence. Not every tool runs on every repository, but every omitted stage requires a reason.

### S0 — source identity and policy

```text
exact commit/revision
clean source state
workflow/action pinning
secret scan
license/provenance policy
no generated-production-source mutation
```

### S1 — static source analysis

Android/Kotlin:

```text
mobsfscan
Android Lint
Detekt
CodeQL java-kotlin
```

Rust:

```text
rustfmt --check (or tree-equivalent)
Clippy where supported
CodeQL rust where supported
cargo-audit/cargo-deny for canonical Cargo graphs
```

### S2 — deterministic tests

```text
pure unit tests
Compose UI Test for first-party Compose UI
Rust unit/integration tests
property/fuzz tests for security-critical parsers/boundaries
```

No device is required for S0-S2 unless the repository cannot be meaningfully tested without the trusted Android tree; such exceptions move to C2 and must be documented.

### S3 — trusted component/product build

Build only an exact trusted source identity on `sable-builder-01` or equivalent trusted infrastructure. Preserve build logs, environment identity, artifact inventory and SHA-256 hashes.

### S4 — post-build artifact security

For Android applications:

```text
exact APK/AAB hash binding
manifest/component/permission inspection
MobSF static artifact scan
signature/package metadata inspection
image/package inclusion proof when shipping in the OS
```

For native/Rust artifacts, add available binary metadata, dependency provenance and sanitizer/fuzz evidence appropriate to the component.

### S5 — device/runtime privacy and behavior

```text
exact installed artifact binding
HOME/default-role state where relevant
Compose/UIAutomator functional tests
permissions + AppOps
exported component/runtime launch behavior
focused crash/security logs
screenshots/semantic evidence
network/privacy behavior for components allowed network access
```

Device mutation requires its own explicit authorization boundary.

### S6 — evidence closure

A gate closes only when the evidence records:

```text
source identity
tool names + exact versions/config
build/artifact hashes
blocking/advisory findings
accepted exceptions with justification
runtime target identity where applicable
SHA256SUMS/evidence seal
claim boundary
```

## 7. Blocking versus advisory policy

Do not start by making every warning from every scanner fatal. That creates suppression pressure rather than security.

Initial policy:

- known exposed secrets/keys: **blocking**;
- confirmed high-confidence security defects: **blocking**;
- Rust Clippy correctness failures: **blocking**;
- known vulnerable dependencies without an approved exception: **blocking**;
- manifest/exported/permission regressions against SableOS policy: **blocking**;
- formatting/style-only issues: project-policy blocking where deterministic, but not security claims;
- new unsafe Rust: **review required**, not automatically accepted because tests pass;
- low-confidence/general scanner warnings: **triage required**, then either promote to blocking, fix, or record a bounded suppression.

Baselines are migration mechanisms, not permanent blind spots. A baseline update is itself a reviewed source/policy change.

## 8. Tool installation and pinning

Tool activation should use repository-owned version/config declarations. Installation is a networked supply-chain operation and must be separated from offline Android build execution.

Preferred model:

```text
GitHub-hosted C1
    pinned Action/container/binary/package version
    disposable environment

trusted builder C2
    pre-provisioned, checksum-verified tools
    no opportunistic network install during the Android build

security lab / C4
    dedicated scanner/device tooling
    isolated from signing infrastructure
```

When a tool itself has a dependency lockfile or release checksum/signature, preserve/verify it. Do not curl-and-execute mutable installer scripts in a trusted build gate.

## 9. Tool choices intentionally not made mandatory

### Broad standalone Semgrep

Not mandatory initially because mobsfscan already uses Semgrep-based Android rules and CodeQL covers deeper cross-file analysis. Add standalone Semgrep for Sable-specific policies, not duplicate scanning for its own sake.

### Maestro

Not mandatory. Native Compose UI Test + AndroidX UIAutomator is the primary SableOS Android automation stack. Maestro remains optional for black-box/exploratory tests after device/API compatibility is proven.

### cargo-geiger or similar unsafe counters

Useful as an advisory unsafe-code inventory, but not a security gate by itself. It measures use of unsafe constructs rather than proving soundness.

### heavy containerized fuzz infrastructure on developer workstations

Do not make ClusterFuzzLite/Docker a default local requirement. Run high-volume fuzzing on CI/dedicated storage/compute after basic cargo-fuzz targets are proven.

## 10. Recommended adoption order

1. document/pin configurations and activate C1 secret/workflow/SAST checks;
2. add Android Lint + detekt where they can run reproducibly;
3. add Rust rustfmt/Clippy and Cargo advisory/source/license checks to repositories that actually own Cargo graphs;
4. build native Compose UI Test + AndroidX UIAutomator suites beside application source;
5. add trusted C2 post-build MobSF scans bound to exact APK hashes;
6. add bounded C4 device privacy/runtime gates;
7. introduce cargo-vet for security-critical dependency graphs;
8. introduce targeted cargo-fuzz, then CI-scale fuzzing where risk/benefit justifies the resources;
9. continuously reduce baselines/exemptions and convert repeated advisory findings into blocking policy.

The security objective is not to maximize scanner count. It is to build a small, pinned, understandable set of complementary controls whose results are reproducible and whose failures lead to actionable ownership.