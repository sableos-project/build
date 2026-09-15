# ThinkPad P50 4 TB storage migration and bring-up runbook

Status: **normative non-destructive migration and post-migration bring-up guidance for `sable-builder-01`.**

This document defines how to migrate the current SableOS Android workspace from the existing `/srv/data` filesystem to a new 4 TB drive while preserving absolute paths, source identity, Git/repo state, known-good R6 build artifacts, and rollback capability.

The migration is intentionally conservative. The existing disk is not deleted, reformatted, repurposed, or treated as disposable during initial cutover. The new drive must prove that it reproduces the existing `/srv/data` state before the old storage may be considered for later reclamation.

The same runbook also defines the order for resuming native Android testing and security/privacy tooling after the migration.

## 1. Why this migration is required

The current P50 storage baseline showed the existing `/srv/data` filesystem near capacity:

```text
filesystem: /dev/sdb1
filesystem type: ext4
size: 1.1T
used: 955G
available: 68G
utilization: 94%
mountpoint: /srv/data
```

The current Panther workspace is approximately:

```text
/srv/data/sableos_panther_graphene_2026081300_workspace  373G
```

and the known-good R6 output alone is approximately:

```text
out_r6_5d_graph  120G
```

with major subtrees including:

```text
soong/.intermediates  ~76G
soong                 ~86G
target                ~27G
```

At this utilization level SableOS must not treat the remaining free space as sufficient headroom for new full Android configuration/build cycles, clean reconstruction output trees, native instrumentation-test integration, large security-analysis artifacts, or fuzzing corpora.

Until the migration completes:

```text
NEW_FULL_BUILD=NO
SOONG_REGEN_FOR_TEST_DISCOVERY=NO
NEW_OUT_DIR=NO
CLEAN=NO
CLOBBER=NO
DELETE=NO
MAESTRO_INSTALL=NO
COMPOSE_TEST_BUILD=NO
UIAUTOMATOR_TEST_BUILD=NO

READ_ONLY_ANALYSIS=YES
GITHUB_DOCUMENTATION_WORK=YES
SOURCE_DESIGN_REVIEW=YES
```

These are project operating rules, not statements that ordinary small files cannot technically be written. The purpose is to preserve the validated build state and avoid a storage-induced failure during expensive Android work.

## 2. Migration goals

The migration must satisfy all of the following:

- preserve `/srv/data` as the canonical mountpoint;
- preserve current absolute workspace and repository paths;
- preserve file ownership, permissions, timestamps, symlinks, hardlinks where present, sparse-file semantics, ACLs, and extended attributes where applicable;
- preserve Git object stores, `.repo` metadata, worktrees, generated build state, and known-good R6 artifacts;
- make no production-source mutation as part of migration;
- perform no Android build during migration verification;
- contact no Android device during storage migration;
- keep the old disk unchanged and available as rollback until the new drive has passed post-cutover verification;
- produce evidence proving the new mounted `/srv/data` is the expected copy;
- retain enough free space for later clean reconstruction, native test builds, security tooling and future device targets.

The desired final topology is conceptually:

```text
new 4 TB filesystem
    mounted as /srv/data

/srv/data/sableos_panther_graphene_2026081300_workspace
/srv/data/sableos/repos
/srv/data/sableos/holds
/srv/data/sableos/evidence       # future durable evidence archive
```

Do not permanently relocate the active SableOS workspace to an unrelated path such as `/mnt/4tb/...` unless a separately reviewed architecture explicitly changes the canonical layout.

## 3. Authorization boundaries

Migration actions must remain separated by authorization scope.

A complete migration normally requires separate authorization for at least:

```text
read-only pre-migration inventory
new-disk partition/filesystem creation
new-disk mount configuration
metadata-preserving copy
post-copy verification
mount cutover
fstab or equivalent persistent mount mutation
host reboot, if used
post-reboot verification
old-disk cleanup/reformat/reuse
```

The final item is deliberately separate. Successful migration does **not** authorize deletion or reformatting of the old disk.

At no point does storage migration implicitly authorize:

```text
Android source mutation
Soong/Kati regeneration
Ninja execution
clean/clobber
network source fetch
ADB/fastboot
flash/reboot of Device1
Device2 contact
bootloader operations
userdata/metadata wipe
release signing
```

## 4. Known-good R6 identity anchors

The migration must preserve and revalidate the following current R6 identities.

### 4.1 SableStart source

```text
workspace path:
/srv/data/sableos_panther_graphene_2026081300_workspace/packages/apps/SableStart

source commit:
f705e875b3339ac1019429cac6df157257746660
```

The source worktree was clean at the accepted R6 package-visibility build/runtime closure.

### 4.2 R6 SableStart APK

```text
path:
/srv/data/sableos_panther_graphene_2026081300_workspace/out_r6_5d_graph/target/product/panther/system/app/SableStart/SableStart.apk

sha256:
d5ba8e1abdbbd8f32f513df149487ee1c6b80164d1fd4076e5a2dd97ff66b0a7
```

### 4.3 R6 target-files archive

```text
path:
/srv/data/sableos_panther_graphene_2026081300_workspace/out_r6_5d_graph/target/product/panther/obj/PACKAGING/target_files_intermediates/sable_panther-target_files.zip

sha256:
3a804061c7e83c3330d2d640d966832f12c7e5c3f3f4346dd67758f0969211fc
```

### 4.4 R6 system image

```text
path:
/srv/data/sableos_panther_graphene_2026081300_workspace/out_r6_5d_graph/target/product/panther/obj/PACKAGING/target_files_intermediates/sable_panther-target_files/IMAGES/system.img

sha256:
31eb027ce20fa7e300e73483ce8b4096cc144e4084de2c7cbcc2f72a130950ac
```

The same system image identity was proven in staging, target-files, and fastboot ZIP.

### 4.5 R6 fastboot image ZIP

```text
path:
/srv/data/sableos_panther_graphene_2026081300_workspace/out_r6_5d_graph/target/product/panther/sable_panther-img.zip

sha256:
5b8dd3dec4a562f96a46c9bed9b04916cedc76b212b061e1b008b6b407ae8ceb
```

### 4.6 Combined Ninja graph

```text
path:
/srv/data/sableos_panther_graphene_2026081300_workspace/out_r6_5d_graph/combined-sable_panther.ninja

sha256:
254769b70dc1c30764e7248b70615e6e7584e6aabcadabb8d3410e3f222248c4
```

These are migration acceptance anchors. A mismatch must be classified before any new build/test work begins.

## 5. Current storage inventory that must not be casually discarded

The current workspace contains large but legitimate state, including approximately:

```text
.repo                                  95G
prebuilts                              59G
out_r6_5d_graph                       120G
out_r5_migrated_20260911_142602        22G
out                                    20G
vendor                                 14G
external                               22G
```

Large file duplication inside Android packaging/build outputs is not by itself evidence that a file is safe to delete. Image copies, target-files contents and generated Ninja files may be part of expected graph/package state.

Do not manually deduplicate or remove current R6 outputs as part of migration.

Potential historical cleanup candidates such as older OUT trees or large `/tmp` evidence bundles must be evaluated separately after the new storage is stable.

## 6. Operational free-space policy after migration

The initial planning target for `sable-builder-01` is:

```text
TARGET_OPERATIONAL_FREE_SPACE_FLOOR=500GB
```

This is an operational reserve, not a guarantee that 500 GB is sufficient for every future build. Device profiles and build wrappers may require a larger start floor based on measured output growth.

Long-running build wrappers should continue to implement both:

```text
START_FREE_SPACE_FLOOR
RUNTIME_FREE_SPACE_MONITOR
```

and must preserve partial output/evidence rather than automatically cleaning when a floor is crossed.

## 7. Phase A — pre-migration evidence capture

Before connecting migration activity to the new disk, capture a read-only baseline of the old `/srv/data` state.

Record at minimum:

```text
host identity and date/time
lsblk -o NAME,SIZE,FSTYPE,UUID,PARTUUID,MOUNTPOINTS,MODEL,SERIAL
findmnt /srv/data
blkid for relevant source/new disks
df -hT /srv/data /
du summary for the primary workspace
mount options
/etc/fstab relevant entries
```

Also record exact source identities for:

```text
/srv/data/sableos/repos/*
/srv/data/sableos_panther_graphene_2026081300_workspace/packages/apps/SableStart
/srv/data/sableos_panther_graphene_2026081300_workspace/.repo/manifests
```

For each Git worktree, preserve at least:

```text
git rev-parse HEAD
git status --short --branch
git remote -v
```

For repo-managed composition preserve:

```text
active manifest pointer
manifest repository HEAD
local manifest inventory
repo manifest -r output if already available without broadening the approved boundary
```

The pre-migration evidence directory should be stored somewhere not dependent on the source `/srv/data` filesystem when practical, for example under the root filesystem's `/tmp` for the duration of migration, and then copied into durable evidence storage later.

Do not produce a giant hash of every Android source file unless needed. Use layered verification: metadata/copy verification for the whole filesystem plus exact hashes for high-value anchors.

## 8. Phase B — new-drive preparation

New-drive preparation is a host-storage mutation and requires explicit authorization.

Before partitioning or formatting:

- identify the new drive by stable hardware identity, not only `/dev/sdX` ordering;
- verify the selected drive is not the current `/srv/data` source disk or system/root disk;
- record model, serial, capacity and any existing partition table;
- require an explicit destructive confirmation bound to that exact device identity before creating a new partition table or filesystem.

Preferred filesystem policy for continuity is ext4 unless a separately reviewed storage design selects another filesystem.

If ext4 is used:

- assign a unique filesystem UUID;
- use a meaningful filesystem label if helpful;
- preserve default security-relevant mount semantics unless a documented need changes them;
- do not enable experimental filesystem behavior merely for migration.

Mount the new filesystem initially at a temporary staging mountpoint, for example:

```text
/mnt/sable-data-new
```

This staging path is temporary. The final active mountpoint remains `/srv/data`.

## 9. Phase C — metadata-preserving copy

The copy must preserve Android source/build semantics and normal Unix metadata.

A suitable implementation may use `rsync` or an equivalent tool with options that preserve:

```text
ownership
permissions
timestamps
symlinks
hardlinks
ACLs
extended attributes
sparse files
numeric uid/gid identity
```

The exact command must be reviewed against the host's installed rsync version before execution.

General requirements:

- copy `/srv/data/` contents into the new filesystem root so final absolute paths remain identical after mount cutover;
- do not follow symlinks into unrelated filesystems;
- avoid crossing unexpected mounted sub-filesystems;
- preserve Git object stores and `.repo` metadata exactly;
- preserve the old disk unchanged during the copy;
- avoid source/build activity during the final synchronization window so the copy does not race active mutation.

A two-pass strategy is acceptable:

```text
initial bulk copy while host is otherwise idle
final synchronization pass after confirming no relevant writers are active
```

Do not use delete-from-destination semantics during the first copy unless separately authorized and necessary. The destination is initially empty and safety is more important than aggressive mirroring.

## 10. Phase D — whole-tree verification before cutover

Before changing `/srv/data`, verify the staged destination.

Verification should include:

### 10.1 Capacity and filesystem

```text
expected new filesystem mounted at staging path
expected filesystem type
expected approximate capacity
sufficient free space after copy
```

### 10.2 Top-level inventory

Compare source and destination for:

```text
top-level names
file counts by broad subtree where practical
workspace sizes
repository presence
.repo presence
prebuilt/toolchain presence
OUT tree presence
```

Do not treat small `du` differences alone as corruption; sparse allocation, filesystem block accounting and metadata can differ. Investigate meaningful discrepancies using file-level metadata/hash checks.

### 10.3 Git/repo identity

Run equivalent read-only Git identity checks against the staged copy by substituting the staging mount prefix.

The staged SableStart path must resolve to:

```text
HEAD=f705e875b3339ac1019429cac6df157257746660
worktree clean
```

Canonical Sable repository identities and manifest state must match their pre-migration records.

### 10.4 Exact R6 artifact anchors

Recompute the hashes in section 4 directly from the staged destination and require all to match.

Required decisive markers should include:

```text
R6_SABLESTART_APK_MIGRATION_FIDELITY=PASS
R6_TARGET_FILES_MIGRATION_FIDELITY=PASS
R6_SYSTEM_IMG_MIGRATION_FIDELITY=PASS
R6_FASTBOOT_ZIP_MIGRATION_FIDELITY=PASS
R6_NINJA_GRAPH_MIGRATION_FIDELITY=PASS
```

A mismatch is a migration failure until explained. Do not repair it by rebuilding.

### 10.5 Read-only filesystem comparison

Where practical, use a metadata/content verification pass such as rsync checksum/dry-run or an equivalent controlled comparison after the main copy.

Because a checksum of hundreds of gigabytes can be expensive, the exact verification mode should balance assurance and duration. At minimum, all critical anchors, Git repositories, manifest metadata, and high-value build outputs must be directly verified.

## 11. Phase E — cutover to `/srv/data`

Cutover is permitted only after pre-cutover verification passes.

Required properties:

- no relevant Android build or repo synchronization process is active;
- current `/srv/data` source mount identity has been recorded;
- new filesystem identity has been recorded;
- old disk remains intact;
- mount configuration change is separately authorized;
- rollback steps are known before unmounting the old filesystem.

The intended cutover is conceptually:

```text
old disk: unmount from /srv/data but retain unchanged
new disk: mount as /srv/data
```

Persistent mount configuration should use stable UUID/PARTUUID identity rather than `/dev/sdX` naming.

Do not overwrite the old filesystem, change its UUID, or reformat it during initial cutover.

## 12. Phase F — immediate post-cutover verification

After the new drive is mounted at `/srv/data`, repeat the high-value verification using the canonical paths, not the staging path.

Required checks:

```text
findmnt /srv/data reports expected new filesystem identity
df shows expected new capacity/free space
canonical workspace path exists
.repo exists
prebuilts exist
out_r6_5d_graph exists
SableStart source HEAD matches
SableStart worktree is clean
all section-4 hashes match
```

The migration gate should conclude with something equivalent to:

```text
P50_4TB_MOUNT_IDENTITY=PASS
P50_4TB_SOURCE_IDENTITY=PASS
P50_4TB_R6_ARTIFACT_FIDELITY=PASS
P50_4TB_OPERATIONAL_FREE_SPACE=PASS
P50_4TB_CUTOVER=PASS
```

No Android build is required to prove storage migration fidelity.

## 13. Phase G — reboot persistence verification

A reboot is optional for initial cutover but is the strongest proof that persistent mount configuration is correct. If used, host reboot requires explicit authorization.

After reboot verify:

```text
/srv/data mounted automatically from expected new UUID/PARTUUID
no duplicate/incorrect /srv/data mount
expected free-space capacity
canonical workspace paths
Git source identities
critical R6 hashes
```

Do not begin new test/build work until mount persistence is proven if the final design depends on automatic mounting.

## 14. Rollback policy

Rollback must remain possible throughout initial migration.

If cutover validation fails:

```text
stop new build/test work
preserve evidence
unmount the new /srv/data when safe
restore the original disk at /srv/data
verify original mount identity
verify critical anchors
classify the failure
```

Do not attempt a rebuild to compensate for a storage copy failure.

The old disk should remain physically/logically intact through at least one accepted post-cutover/reboot verification cycle and until a separately authorized retention period or cleanup decision is reached.

## 15. Old-disk cleanup is a separate project gate

Potential future reclamation candidates may include:

```text
out_r5_migrated_20260911_142602
historical out/
out_c2r32_sable_fresh
large sealed /tmp evidence bundles
```

None is declared safe to delete by this document.

Before deleting any historical output/evidence:

- identify whether it is referenced by accepted milestone documentation;
- identify available SHA/evidence seals;
- decide whether it needs durable archival storage;
- obtain explicit delete authorization bound to exact paths;
- never use broad wildcard deletion for mixed-value evidence directories.

The current R6 `out_r6_5d_graph`, `.repo`, prebuilts, target-files, image ZIP, system image and combined Ninja graph are specifically protected from cleanup during migration.

## 16. Durable evidence policy after the new drive is live

The current root filesystem has substantial historical `/tmp/SABLE*` and `/tmp/PANTHER*` evidence. `/tmp` should not remain the permanent archive location.

After storage migration, establish a durable evidence layout such as:

```text
/srv/data/sableos/evidence/
    accepted/
    current/
    archive/
```

Recommended policy:

```text
/tmp
    transient current-run evidence only

/srv/data/sableos/evidence/accepted
    milestone evidence that remains actively referenced

/srv/data/sableos/evidence/archive
    older sealed bundles retained for provenance/audit
```

Any migration from `/tmp` to durable evidence storage should itself preserve names, hashes and reference mapping. Do not silently move or delete historical evidence while documentation still points to its old path.

## 17. Post-migration bring-up order

Once storage migration has passed, resume engineering in this order.

### B0 — storage and source identity

```text
new /srv/data mount identity
free-space floor
Git/repo/manifest identities
R6 artifact anchors
```

### B1 — read-only native-test dependency discovery

Resolve the exact Android 17/Soong module names available for:

```text
Compose UI Test
AndroidX Test Runner/Core/Rules
AndroidX UIAutomator
JUnit/test support
```

Do not add guessed test dependencies to production repositories before the tree proves the available module identities.

### B2 — native Android test authoring

Primary stack:

```text
Compose UI Test
    deterministic first-party Compose semantics and in-app behavior

AndroidX UIAutomator
    cross-package/system UI behavior

shell evidence gates
    installed-artifact binding, runtime state, logs, screenshots and evidence sealing
```

Maestro remains optional/non-authoritative unless separately promoted after compatibility testing.

### B3 — narrow test-module build

Build only the exact new test module(s) first. Do not launch a full product build merely to determine whether the test code compiles.

Preserve:

```text
source commit
module graph identity
build command
return code
artifact paths/hashes
source poststate
```

### B4 — Device1 instrumentation/runtime validation

Use fresh exact device authorization.

Validate:

```text
Start/Home semantics
All Apps inventory
Search inventory/filtering
exact app launches
return-to-HOME behavior
process/crash state
permissions/AppOps where relevant
real application icon requirement
```

### B5 — security/privacy tooling activation

Activate tooling incrementally rather than all at once.

Recommended initial order:

```text
1. Gitleaks
2. ShellCheck
3. CodeQL
4. mobsfscan
5. detekt
6. Android Lint
7. rustfmt / Clippy where supported
8. cargo-audit / cargo-deny where Cargo is canonical
9. MobSF exact-artifact scan
10. fuzz/Miri/cargo-vet for selected high-assurance Rust components
```

Tool versions/configurations must be pinned and evidence-producing before becoming blocking gates.

### B6 — clean reconstruction capacity

After the primary workspace/test toolchain is stable, establish a separate clean-reconstruction OUT/workspace strategy. Do not destroy the known-good R6 incremental OUT merely to obtain clean-build evidence.

### B7 — later storage cleanup

Only after migration, testing and evidence retention are stable should historical OUT/evidence cleanup be considered.

## 18. Security and privacy implications of storage migration

Storage migration is part of the SableOS trust boundary, not just an infrastructure convenience.

Preserve these properties:

- new storage must not broaden filesystem permissions on source/build trees;
- do not copy secrets into world-readable evidence bundles;
- do not move production signing material onto `sable-builder-01`;
- keep release-signing separation from the builder unchanged;
- preserve provenance of vendored/downloaded build inputs;
- use stable device/filesystem identifiers in mount policy;
- review persistent mount options rather than copying them blindly if the original configuration is insecure;
- preserve least-privilege ownership for future dedicated `sable-ci` workspaces;
- do not grant untrusted GitHub PR workloads access to the persistent Android tree merely because more storage is available.

More disk capacity must not weaken the CI trust architecture.

## 19. Migration evidence bundle

A completed migration should produce a sealed evidence directory containing at least:

```text
host_identity.txt
pre_lsblk.txt
pre_findmnt.txt
pre_df.txt
pre_fstab_relevant.txt
source_git_inventory.txt
manifest_identity.txt
pre_anchor_sha256.txt
new_disk_identity.txt
new_fs_identity.txt
copy_command.txt
copy_log.txt
pre_cutover_compare.txt
staged_anchor_sha256.txt
post_findmnt.txt
post_df.txt
post_git_inventory.txt
post_anchor_sha256.txt
results.env
SHA256SUMS.txt
SHA256SUMS.txt.sha256
migration.log
```

If a reboot persistence test is performed, also preserve:

```text
post_reboot_findmnt.txt
post_reboot_df.txt
post_reboot_anchor_sha256.txt
```

The evidence claim boundary should explicitly state that the migration proves storage/source/artifact fidelity and mount correctness. It does not prove that a new Android build would be reproducible or that runtime behavior is unchanged until those later gates run.

## 20. Acceptance criteria

The migration is accepted only when all of the following are true:

```text
new filesystem identity is known and expected
new filesystem is mounted at /srv/data
canonical absolute paths are preserved
SableStart source commit matches f705e875...
SableStart source worktree remains clean
canonical Sable Git repositories are present
.repo and prebuilts are present
R6 APK hash matches
target-files hash matches
system.img hash matches
fastboot ZIP hash matches
combined Ninja graph hash matches
operational free-space target is satisfied
old disk remains available for rollback
no unclassified copy/metadata error remains
```

If reboot persistence is part of the approved migration, successful automatic remount from the stable filesystem identity is also required.

Final gate marker:

```text
P50_4TB_STORAGE_MIGRATION_AND_BRINGUP=PASS
```

## 21. Non-goals

This migration does not by itself authorize or prove:

```text
Android build reproducibility
clean reconstruction
new test-module integration
Compose/UIAutomator runtime PASS
security-scanner PASS
MobSF PASS
Device1 reflash
Device2 qualification
release signing
old-disk deletion
historical evidence deletion
```

Those remain separate gates.

## 22. Summary operating rule

The migration strategy is:

**preserve paths, copy non-destructively, verify exact identities before cutover, keep the old disk intact as rollback, prove the new `/srv/data`, then resume testing/security work in narrow stages.**
