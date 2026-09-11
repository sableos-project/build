# Development milestone evidence gates

Status: **normative validation/evidence guidance for the R5–R10+ development train.**

This repository owns host-side build/reconstruction/validation tooling. The job of a gate is to prove a bounded claim, not to produce a reassuring `PASS` string around an ambiguous process.

The organization-wide product scope is in `sableos-project/.github/docs/DEVELOPMENT_RELEASE_PLAN.md`. Component repositories own feature-specific requirements. This document describes the evidence structure that should close those requirements.

## 1. General evidence principles

### 1.1 Claims must match evidence

Use explicit layers:

```text
source identity
  -> build input identity
  -> build result
  -> package/artifact identity
  -> install/integration identity
  -> runtime state
  -> user-visible behavior
  -> complete source reconstruction
```

Do not infer a later layer from an earlier one.

Examples:

- successful compilation does not prove runtime behavior;
- an APK existing does not prove it contains the intended source result;
- an installed package does not prove the tested HOME/default-role state;
- a screenshot does not prove package inventory completeness by itself;
- a historical workspace build does not prove clean reconstruction from organization repositories.

### 1.2 Authorization boundaries

Every state-changing gate should print explicit authorization at the top.

Use separate flags/concepts for at least:

- source mutation;
- workspace build-output mutation;
- build execution;
- network access/fetch;
- device contact;
- package install/uninstall;
- reboot;
- root/remount;
- slot change;
- userdata/metadata wipe;
- clean/clobber/delete;
- Git commit/push/history rewrite.

Do not treat permission for one class as permission for another.

### 1.3 Failure must stop the claim

A script must not print a final `PASS` merely because a shell pipeline returned an unexpected success code or because an intermediate diagnostic command failed harmlessly.

Known historical example: `pipefail` plus `unzip | grep -q` can make the producer receive SIGPIPE after `grep` finds a match. Gates that use early-exit consumers must distinguish this from a real package-validation failure.

When possible, use structured parsers or inspect command exit semantics explicitly.

### 1.4 Evidence directories

Prefer a unique run directory such as:

```text
/tmp/SABLE_<MILESTONE>_<PURPOSE>_<timestamp>
```

Store:

- gate report;
- focused command outputs;
- manifests/inventories;
- source/build/artifact hashes;
- relevant logs/screenshots references;
- a final `SHA256SUMS.txt` and seal hash.

Do not delete older evidence automatically unless a separate cleanup policy authorizes it.

## 2. R5 — migrated-source build and reconstruction

### 2.1 Claim

The canonical organization repository can supply the exact validated Sable Start source to the Android build, and the multi-repository source composition can ultimately reconstruct that path without the historical workspace copy.

### 2.2 Required source binding

Record:

```text
repository=sableos-project/packages_apps_SableStart
commit=059d5d23e4186bbd3119180433a5e6206b7d95bd
tree=c00fd741c401fdd1421e8971bfb82f01c4b7c7da
```

until a later accepted source revision supersedes the migration baseline.

Verify repository clean state before the build.

### 2.3 Build-input proof

A strong R5 gate must prove the build system actually saw the migrated checkout at `packages/apps/SableStart`.

Acceptable mechanisms may differ by host capability, but evidence must show identity rather than merely copying equivalent bytes and assuming Soong used them.

Where a temporary path swap or mount overlay is used, record pre/build/post identity and guarantee restoration on failure.

### 2.4 Host capability failures

If a sandbox mechanism fails before build execution, classify it as a host-isolation limitation, not a source compile failure.

Examples already observed on the ThinkPad include bubblewrap user/network namespace policy failures. Do not respond by silently weakening network/source boundaries or changing host security policy unless separately authorized.

### 2.5 Build output isolation

For a migration proof, a fresh isolated `OUT_DIR` is preferable when practical because it reduces ambiguity from historical Sable Start outputs.

A clean/clobber of the main workspace is not required and should not be used merely to obtain isolation if a new output directory can provide the needed evidence.

### 2.6 R5 artifact proof

Record:

- module build result;
- APK path;
- APK SHA-256;
- file/ZIP validity;
- exact AndroidManifest presence;
- dex presence;
- parsed package/version/min/target SDK if tools are available;
- source/worktree post-build integrity.

### 2.7 Reconstruction closure

Final R5 closure should include a separate `platform_manifest` reconstruction proof that does not depend on manual source copying/symlinking from the historical workspace.

Record resolved project revisions before building.

## 3. R6 — Sable Start All Apps + greeting

Feature requirements live in `packages_apps_SableStart/docs/R6_ALL_APPS_AND_GREETING.md`.

### 3.1 Build gate

Bind the R6 Sable Start source commit and complete source composition; build the module; validate APK/package identity.

### 3.2 Independent launcher inventory

The runtime gate should collect an expected launcher-visible activity inventory independently from the rendered Compose UI where practical.

Normalize expected and observed entries using stable identities such as:

```text
profile/user | package | component
```

Labels are presentation data and should not be the sole comparison key.

Required closure:

```text
missing=0
unexpected=0
UI_count=logical_inventory_count
```

If adb/shell visibility differs from the app's permitted `LauncherApps` view, document and account for that API boundary instead of forcing a false equality.

### 3.3 Search proof

Prove Search is driven by the same live inventory. A practical gate can:

- capture an app in All Apps;
- search by label;
- search by package name where required;
- prove same component/profile identity;
- remove/change a test app and prove both All Apps and Search update consistently.

### 3.4 Dynamic package change

Keep at least one expendable third-party fixture installed for the initial inventory. Maps/Weather currently serve this role if still present.

A normal uninstall/remove test requires explicit package-mutation authorization.

If authorized, capture:

1. before count/inventory;
2. fixture visible/searchable/launchable;
3. package removal;
4. Sable process identity before/after if proving no process restart;
5. callback/refresh evidence;
6. after count/inventory;
7. zero unrelated differences.

### 3.5 Greeting proof

Prefer deterministic unit tests for all time-bucket boundaries. Runtime evidence only needs to prove the active greeting matches the actual device-local time bucket.

Do not change global device time merely to force all buckets unless separately authorized.

### 3.6 HOME/default-role boundary

R6 launcher feature validation does not automatically authorize changing default HOME.

Always record current HOME/default launcher state before/after if the test can plausibly affect it.

## 4. R7 — Panther daily-driver qualification

Detailed device matrix: `device_sable_panther/docs/R7_DAILY_DRIVER_VALIDATION.md`.

R7 is primarily a device/runtime evidence program.

### 4.1 Build identity

Every R7 run must bind to an exact device image/build identity. Record at least:

- fingerprint;
- Android/API;
- SPL;
- build type;
- product/device;
- Sable manifest/component identity where available;
- baseband/carrier context for telephony claims.

### 4.2 Capability reports

Do not hide all daily-driver testing inside one huge log. Produce capability-scoped results for:

- voice calls;
- contacts;
- SMS;
- MMS;
- Wi-Fi;
- cellular data;
- browser/Internet;
- notifications;
- Settings;
- camera/photos;
- files;
- clock/alarm;
- calculator;
- Sable Start integration.

Each should record prerequisites, actions, observed result, focused evidence, status, and claim boundary.

### 4.3 Private data

Do not publish raw:

- phone numbers;
- SMS/MMS content;
- Wi-Fi passphrases;
- private SSIDs if sensitive;
- account identifiers;
- carrier account data;
- contact contents.

Store/redact evidence accordingly.

### 4.4 Calls/SMS/MMS

Automation can collect state/log evidence, but a successful real call/message often requires a second endpoint and user observation. Record the human-observed part explicitly rather than manufacturing machine proof that cannot exist.

### 4.5 Network tests

Distinguish Wi-Fi and cellular data. A browser page loading while Wi-Fi is connected does not prove mobile data.

For cellular tests, verify Wi-Fi state and active transport.

For Wi-Fi tests, verify association/IP/DNS rather than relying only on the Settings icon.

### 4.6 Reboot-dependent claims

Reboot is separately authorized. If not authorized, mark persistence-after-reboot cases untested.

Do not reboot merely because an alarm/Wi-Fi/default-app test commonly includes reboot.

## 5. R8 — design/theme/customization

Requirements: `platform_sable/docs/R8_DESIGN_SYSTEM_AND_CUSTOMIZATION.md`.

### 5.1 Logic tests

Test appearance mode resolution and preference behavior without a device where possible.

Required deterministic cases include:

- missing preference -> documented default;
- Follow system -> both light and dark platform input;
- forced Light;
- forced Dark;
- each supported accent mapping;
- invalid/corrupt stored value fallback;
- schema migration when introduced.

### 5.2 Runtime proof

Capture representative Sable screens in:

- Follow system;
- Light;
- Dark;
- at least one non-default accent.

Where Sable Calculator exists, prove the same shared contract affects both Start and Calculator.

### 5.3 Accessibility

Validation should include practical font scale and contrast review. Automated contrast checks can support but not fully substitute for runtime layout inspection.

### 5.4 No privilege creep

Audit manifest permissions before/after R8. Basic appearance customization should not introduce location/network/phone/media/privileged permissions.

## 6. R9 — Sable Calculator / utility application

Requirements: `platform_sable/docs/R9_SABLE_UTILITY_APP_MODEL.md` plus the future Calculator repository's app-specific requirements.

### 6.1 Logic-first testing

Calculator arithmetic semantics should be covered heavily by deterministic host/unit tests.

Test results must bind to the exact Calculator source revision.

### 6.2 Permission audit

The first Calculator should have no network or sensitive permissions unless requirements explicitly change.

Record parsed manifest permissions as an acceptance artifact.

### 6.3 Package/build proof

Record:

- canonical repo commit/tree;
- Soong module;
- package name/version;
- APK SHA-256;
- manifest/dex structure;
- signing identity appropriate to the development/release context;
- product/manifest integration revision.

### 6.4 Runtime interaction

Prove representative operations, clear/error behavior, theme integration, accessibility semantics, and any persisted state.

Do not claim scientific/programmer/conversion behavior if it is not in the requirements.

## 7. R10+ — inherited application replacement

A replacement gate must compare old and new product state.

At minimum record:

- old/new package/component;
- roles/default handlers;
- permissions/allowlists;
- product package lists;
- data migration state;
- rollback plan;
- compatibility/runtime matrix;
- exact old/new source composition.

Do not validate only that the new app launches while leaving stale privileged grants/roles from the old app.

## 8. Gate design requirements

### 8.1 Fail closed

If a precondition cannot be proven, stop before the state-changing operation.

### 8.2 Verify before and after

For temporary mutations, record both prestate and restoration/poststate.

### 8.3 Idempotence where practical

A read-only audit should be safe to rerun. A state-changing gate should detect an already-completed/ambiguous state rather than blindly repeating a mutation.

### 8.4 No hidden network fetch

When `NETWORK_ACCESS_AUTHORIZED=NO`, build/test tooling must not silently download dependencies.

Prefer an explicit network-isolation/probe mechanism where the claim requires it. If the host cannot provide the desired namespace sandbox, document the limitation and choose a separately reviewed method; do not silently drop the boundary.

### 8.5 No hidden clean

Never run `m clean`, `clobber`, delete output trees, or reset source merely because a build failed unless cleanup is explicitly authorized.

Fresh isolated output directories are preferred for proof isolation when feasible.

## 9. Evidence status vocabulary

Use consistent results:

```text
PASS       claim proven within stated boundary
FAIL       tested claim contradicted / gate failed
BLOCKED    prerequisite/environment prevents test; claim not evaluated
NOT_TESTED intentionally not executed
UNKNOWN    evidence ambiguous; do not promote to PASS
```

Do not convert `BLOCKED` into `PASS` because source looked correct.

## 10. Documentation after a gate

Once a gate closes, update the owning repository documentation with:

- exact result;
- commit/artifact identities;
- evidence seal;
- exceptions/warnings;
- what remains open;
- next gate.

Do not rewrite historical evidence to make later architecture look inevitable. Record corrections explicitly.

## 11. Anti-invention rule for tooling

A validation script must implement the documented acceptance criteria. If the requirement is unclear, do not encode a new product semantic in the test script and then treat the test as authoritative.

Examples:

- build tooling must not decide which apps count as All Apps; R6 requirements define that semantic;
- an R7 test script must not choose a default Messaging app; product composition policy defines it;
- theme tests must not invent accent colors; R8 requirements define allowed choices;
- Calculator tests must not invent percentage/operator semantics before the Calculator requirements choose them.

Tests enforce decisions; they do not replace product decisions.