# Multi-device engineering interface

Status: **implemented foundation / normative interface — 2026-09-24**

## Operator contract

```text
build/sable.sh <device> <release> <function> [options]
```

The interface remains stable while device-specific implementation lives behind
adapters.

## Parameter ownership

```text
device
    selects product/device adapter

release
    selects release policy

source
    binds reproducible source/artifact identity

serial
    selects one physical device only for device-contact operations
```

Never key build caches, artifact registries or image names by serial.

## Artifact contract — implemented K1

Schema v2 supports:

```text
target-files
full-device-images
gsi-system-image
system-product-bundle
boot-recovery-bundle
```

Each record includes exact build source, tool source, primary artifact and named
artifact hashes/sizes plus optional metadata/build evidence.

Schema-1 Panther target-files records remain compatible.

## Deployment contract — implemented K2

Common orchestration:

```text
resolve registered artifact
verify artifact hashes/kind
bind selected serial
capture common evidence/baseline
call adapter preflight
call adapter deployment
wait for Android/CE return
call target post-boot acceptance
seal evidence
```

Adapter callbacks own:

```text
artifact preparation / flash plan
device preflight
flash-mode transition/validation
actual deployment
bounded pre-write recovery
target post-boot smoke
```

Panther's A/B target-files fastboot implementation is the first qualified
adapter.

## Capability gate

An adapter explicitly declares whether build, qualification, artifact
registration, flash planning and flashing are supported.

Titan 2, Titan 2 Elite and Q27 currently declare those release/deployment
capabilities blocked.

## N0 Titan direction

Future Titan-family N0 records may bind a Sable system/GSI artifact plus exact
stock kernel/vendor/ODM/firmware basis.

Before enabling mutation prove:

- exact restore source/hashes;
- bootloader + fastbootd identity;
- dynamic partition/super layout;
- snapshot state;
- AVB strategy;
- artifact sizing;
- whether userdata preservation is actually possible.

If an experiment requires wipe, add a separate explicit destructive-data policy.
Do not silently reuse Panther's preserved-data contract.

## Multi-device host safety

Additional attached devices are allowed. The requested serial must resolve
exactly once in the expected transport before mutation.

Never fall back to an unqualified global `adb`/`fastboot` device.
