# SableOS source storage and history policy

Status: **normative source-storage, history-retention, and trusted-workspace guidance.**

This document defines how SableOS should store Android/GrapheneOS-derived source on trusted builders, how much Git history a build workspace needs, and how storage reduction may be introduced without weakening reproducibility or the evidence chain.

The objective is not to minimize disk usage at any cost. The objective is to keep enough source and metadata to reproduce exact accepted revisions while avoiding unnecessary historical data in new build workspaces.

## 1. Core rule

SableOS uses **revision-pinned, history-light build workspaces**, not history-free or provenance-free workspaces.

A trusted build workspace must be able to prove:

```text
which manifest/revisions were selected
which exact project commits were checked out
which Sable repositories supplied product source
which build/toolchain inputs were used
which artifacts were produced
```

Complete upstream Git history is not required merely to compile an exact accepted revision. Exact source identity is required.

## 2. Existing validated workspaces are evidence-bearing state

Do not convert an already validated Android workspace in place to a shallow clone, delete `.repo/project-objects`, aggressively prune repositories, remove arbitrary projects, or run destructive Git maintenance solely to recover space.

For an evidence-bearing workspace:

```text
IN_PLACE_HISTORY_TRIM=NO
AD_HOC_PROJECT_DELETION=NO
AUTOMATIC_GIT_GC_FOR_SPACE=NO
DELETE_OLD_OUT_FOR_SPACE=NO
```

unless a separately authorized maintenance operation has first recorded the source/build state and established that the affected historical state is no longer needed.

The current `sable-builder-01` Panther workspace is therefore preserved through the 4 TB migration. Storage optimization belongs in the new workspace strategy, not in destructive surgery on the known-good workspace.

## 3. New trusted workspace policy

For a new trusted Android workspace, prefer the smallest source history that still supports the exact revision-pinned build and offline validation model.

The desired sequence is:

```text
networked acquisition
    -> resolve exact manifest and project revisions
    -> acquire all objects required by those revisions
    -> record source identity
    -> verify checkout completeness
    -> end networked acquisition phase
    -> trusted offline build/test phase
```

The build phase must not depend on lazy object downloads or an unplanned network fetch to complete a checkout.

### 3.1 Preferred characteristics

New production build workspaces should prefer, where compatible with the selected upstream tooling:

- an exact revision-pinned manifest;
- branch/history depth limited to what the accepted revisions and tooling require;
- no unnecessary tags or unrelated historical refs;
- no local-manifest source overrides for accepted reconstruction evidence;
- no mutable dependency on an upstream moving branch after revision resolution;
- complete local availability of every blob/tree/commit required for the selected build before the offline build phase begins.

History-light does **not** mean "use whatever happens to be at the branch tip." The manifest/revision record remains authoritative.

## 4. Shallow history versus partial/lazy clones

These mechanisms have different trust implications.

### 4.1 Shallow history

A shallow checkout may be acceptable for a build workspace when:

- the exact required commit is present;
- the manifest can resolve every project without reaching beyond the retained boundary;
- build/generator tooling does not require omitted ancestry;
- source identity can still be recorded exactly;
- clean reconstruction has been demonstrated from the same acquisition profile.

If an accepted Sable revision or required upstream revision falls outside the shallow boundary, increase the depth or fetch that exact revision during the authorized acquisition phase. Do not silently change the intended source revision to fit the shallow checkout.

### 4.2 Partial/lazy clones

Do not make blobless or other on-demand partial-clone behavior the default for a trusted offline Android build workspace.

A checkout that can lazily retrieve missing objects during normal file access weakens the network-phase boundary and makes offline reproducibility harder to reason about.

Partial clones may be evaluated for disposable development/research environments, but a trusted build profile must prove all required objects are local before the build and must be able to build with network access denied.

## 5. Do not guess a minimal Android manifest by deletion

Android/GrapheneOS-derived source composition contains build-time host tools, generated API/configuration inputs, test/support projects, prebuilts, and transitive Soong dependencies that may not be obvious from application source.

Therefore:

```text
rm -rf project until build succeeds/fails
```

is not a valid source-reduction method.

If SableOS later introduces a reduced production manifest, derive it as a separate manifest/profile and prove it through reconstruction rather than mutating a full workspace in place.

A reduced-manifest candidate is acceptable only after it proves:

1. exact manifest/revision resolution;
2. successful trusted clean build for the intended product;
3. required host-tool and generator closure;
4. required product/package/image closure;
5. artifact and runtime claims equivalent to the milestone boundary being asserted;
6. no hidden fetch during the offline build phase.

Until that proof exists, the full validated upstream composition remains the reference source profile.

## 6. Source storage classes

Treat storage as separate classes with different retention rules.

```text
S1 canonical Sable Git repositories
    small, authoritative source; retain normal development history

S2 Android/upstream checkout working trees
    large, reconstructible from manifest/revisions

S3 .repo Git object store/history
    large, partly reconstructible; history may be reduced in new workspaces

S4 prebuilts/vendor acquisition inputs
    large; retain exact inputs needed for offline reconstruction where upstream policy permits

S5 build OUT directories
    very large; evidence-bearing while a milestone/build remains active

S6 sealed evidence
    logs, inventories, hashes, screenshots and reports; retain according to evidence policy
```

Do not apply one cleanup rule to all classes.

## 7. Canonical Sable repositories keep useful history

History-light policy applies primarily to very large upstream Android/GrapheneOS-derived workspaces.

Canonical Sable-owned repositories are comparatively small and are development/audit history. Do not shallow or rewrite them merely for disk savings.

Examples include:

```text
packages_apps_SableStart
platform_manifest
build
platform_sable
vendor_sable
device_sable_*
future Sable application repositories
```

Accepted source must continue to originate from canonical organization repositories and exact commits.

## 8. OUT directory retention and storage pressure

Build output is not source history, but storage decisions must consider both together.

For active milestone work:

- preserve the last known-good trusted OUT while debugging a bounded change;
- do not clean/clobber/delete automatically after compile or closure failure;
- prefer narrow incremental module builds when the existing graph/output is understood;
- create a fresh reconstruction OUT only when the milestone requires clean-build proof and adequate capacity exists;
- record free space before long builds and monitor it during execution.

For `sable-builder-01`, the post-migration operational target is to retain at least:

```text
TARGET_OPERATIONAL_FREE_SPACE_FLOOR=500GB
```

This is a planning floor, not permission to delete data automatically when the threshold is approached.

## 9. New 4 TB builder layout direction

The 4 TB migration should preserve canonical absolute paths, especially `/srv/data`, while providing enough capacity for independent build/evidence roles.

A practical capacity model is:

```text
current validated Android workspace
current primary OUT
fresh/reconstruction OUT capacity
security/test outputs and fuzz corpora
vendor/prebuilt acquisition inputs
sealed evidence archive
large operational free-space reserve
```

The old storage remains rollback media until the new `/srv/data` installation and source/build identities have been verified under `docs/P50_STORAGE_MIGRATION_AND_BRINGUP.md`.

## 10. Network and acquisition policy

Storage optimization must not create hidden network behavior.

Every trusted reconstruction/build should make the phase boundary explicit:

```text
NETWORK_ACQUISITION=AUTHORIZED
    repo/manifest/vendor/tool acquisition
    exact revision resolution
    required object completion

NETWORK_BUILD_PHASE=DENIED
    Soong/Kati/Ninja/component/product build
    deterministic tests that do not require external service access
    artifact inspection and evidence generation
```

If a required source object is missing after the boundary closes, classify the run as an acquisition/profile failure. Do not let Git silently fetch it during the trusted build and then claim an offline/reproducible build.

## 11. Reconstruction evidence for a history-light profile

Before promoting a history-light profile from experimental to trusted, capture:

```text
repo/tool version
manifest repository + exact commit
manifest file/hash
project count
project path -> exact revision inventory
shallow/clone-filter options actually used
network phase start/end
missing-object preflight result
source tree clean state
build target/release/variant
build result
artifact inventory + hashes
post-build source state
proof that no network fetch occurred during build
```

A successful incremental build in an existing full-history workspace does not prove the history-light reconstruction profile.

## 12. Cleanup and reclamation policy

Storage cleanup is a separate authorized operation.

Before removing a large source/history/output tree, determine:

- whether it is canonical source or reconstructible upstream state;
- exact path and size;
- whether current milestone evidence references it;
- whether unique commits/objects exist only there;
- whether a verified replacement copy exists;
- whether important artifacts/hashes have been sealed elsewhere;
- rollback consequences.

No build script or CI gate may automatically reclaim source history or delete OUT trees merely because disk space is low.

## 13. Security rationale

A smaller history footprint is useful, but security comes from controlled provenance rather than minimal byte count.

This policy prioritizes:

- exact revision identity over long local history;
- complete local build inputs over lazy network retrieval;
- canonical repositories over workspace-only source;
- reconstruction proof over ad-hoc pruning;
- explicit cleanup authorization over automatic disk-pressure deletion;
- preservation of known-good evidence while a migration or milestone remains open.

## 14. Adoption sequence

Use this order:

```text
1. preserve current validated P50 workspace
2. migrate to new 4 TB /srv/data without destructive cleanup
3. verify known-good source and R6/R7 precursor artifacts
4. define/test a history-light acquisition profile in a separate workspace
5. prove clean offline reconstruction
6. promote the profile only after evidence closure
7. consider old redundant history/output reclamation separately
```

The desired outcome is a builder that is **space-efficient without becoming provenance-light, network-dependent, or difficult to reconstruct**.
