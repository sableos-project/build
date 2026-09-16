# Reproducibility policy

Status: **normative reproducibility/provenance policy.**

SableOS distinguishes several related but different claims:

```text
source composition reproducibility
standalone application reproducibility
product integration reproducibility
artifact byte reproducibility
runtime/release reproducibility
```

Do not use one as a substitute for another.

## 1. OS source composition

A reproducible Android build starts from an explicit upstream/substrate identity plus exact Sable-owned repository revisions.

The authoritative source-composition layer is `platform_manifest`.

A clean reconstruction must not depend on:

- manual source copies;
- untracked local manifests;
- host-only symlinks;
- uncommitted source;
- branch tips without resolved commit identity;
- historical workspace-only modules.

## 2. Standalone R8 application reproducibility

R8 applications may intentionally keep their canonical build/dependency graph in Cargo/Gradle/upstream application tooling rather than reproducing that whole graph in Soong.

For every accepted standalone application artifact record:

```text
source repository + exact commit
upstream/reuse repository + exact commit where applicable
lock/dependency state
compiler/JDK/Gradle/Rust/Android SDK identity as applicable
qualification workflow/run
build commands/variant
package/application ID + version
manifest permissions/components
native ABI/library inventory
APK SHA-256
third-party dependency/provenance inventory
```

An APK with the same package name but a different hash is a different product-integration input unless a documented deterministic transformation explains the difference.

## 3. Sable adaptation of external sources

For pinned sources such as Vaachak:

```text
exact upstream commit
+ exact Sable overlay/flavor/patch logic
+ exact build/dependency environment
= qualified source identity
```

Do not document a branch name as sufficient provenance.

If an upstream repository changes after the accepted pin, the new revision requires a new qualification run before it can replace the frozen input.

## 4. Product integration reproducibility

A reproducible SableOS image must record both:

1. exact source composition; and
2. exact qualified external application/artifact inputs when the build consumes prebuilts.

For each imported application additionally record:

```text
artifact source/freeze record
module/import declaration
product selection owner
install partition/path
signing or build-time transformation behavior
PRODUCT_OUT resulting hash
installed-files/target-files/image identity
```

Do not claim the product was reconstructed solely from the Android source manifest when external sealed APKs were required and not represented by that provenance record.

## 5. Source reproducibility versus byte reproducibility

A source-reproducible build does not automatically produce byte-identical outputs if the build contains timestamps, nondeterministic archive ordering, signing state, generated metadata or toolchain/environment variability.

Record byte reproducibility as a separate claim.

Where byte identity is expected, compare hashes under equivalent build inputs/toolchains. Where deterministic byte identity is not currently guaranteed, preserve enough provenance to explain and validate intentional transformations.

## 6. Build host identity

The host is part of build evidence even when it should not become a semantic product dependency.

The first R8 `ai-g732` build after storage migration must record:

```text
host/OS identity
filesystem/storage identity
workspace/output/evidence roots
host toolchain identity
source identities
free-space state/policy
network policy
```

This prevents accidental dependence on hidden ThinkPad-only state while avoiding hard-coding one host's absolute paths into generic scripts.

## 7. Trusted toolchain and network

Record the toolchain versions/configuration required by the claim.

When a gate declares an offline/no-fetch build phase, dependency acquisition must complete before that phase and the no-network boundary must be enforced or honestly reported as unproven.

A successful build that silently fetched an undeclared dependency does not satisfy an offline reconstruction claim.

## 8. Build caches

Caches are performance inputs, not provenance authorities.

- disposable CI caches are untrusted convenience data;
- trusted builder caches are isolated from arbitrary PR code;
- clean/reconstruction gates must be able to bypass/invalidate caches when necessary;
- an artifact's accepted identity comes from source/tool/input/output evidence, not cache presence.

## 9. Evidence package

A strong reconstruction/reproducibility evidence set records:

```text
platform_manifest/source identity
external_artifact_inputs.txt
host/build environment
resolved target product/release/variant/Build ID
build commands and result
artifact inventory
product/package install evidence
SHA256SUMS
known nondeterminism/transformations
final gate report + seal
```

## 10. Signing/release

Signing is a separate provenance stage. Reproducing an unsigned engineering image is not the same claim as reproducing a signed release package.

A release record binds the approved pre-sign candidate hashes to signed outputs and signing identity/channel without exposing private signing material.

## 11. Historical evidence

Older ThinkPad/Panther builds remain useful reference evidence even after the trusted build host moves. Preserve historical source/build/artifact seals; do not mutate old records to fit a new workspace layout.

## 12. Reproducibility closure rule

Use precise language:

```text
SOURCE_RECONSTRUCTION=PASS
STANDALONE_APP_REPRODUCIBILITY=PASS/UNPROVEN
EXTERNAL_ARTIFACT_INPUT_BINDING=PASS/UNPROVEN
PRODUCT_INTEGRATION_RECONSTRUCTION=PASS/UNPROVEN
BYTE_REPRODUCIBILITY=PASS/UNPROVEN
SIGNED_RELEASE_REPRODUCIBILITY=PASS/UNPROVEN
```

Only claim the layers actually demonstrated.