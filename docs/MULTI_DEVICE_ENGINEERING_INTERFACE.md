# Multi-device engineering interface

Status: **normative direction**

## Operator contract

```text
sable <device> <release> <function> [options]
```

The interface must remain stable while device-specific implementation lives
behind adapters.

## Parameter ownership

```text
device
    selects product/device adapter

release
    selects release contract/policy

source
    binds reproducible source/artifact identity

serial
    selects one physical device only when contacting hardware
```

Do not key build caches, artifact registries or image names by serial.

## Required functions

```text
ci
qualify
build
register-artifact
show-artifact
flash-plan
flash
accept
```

Future read-only functions may include `probe` and `capture`, also requiring
an explicit serial.

## Adapter capability schema

A future structured device descriptor should expose at least:

```text
canonical_name
aliases
support_level
interaction_profile
expected_product
android_baseline
build_supported
qualification_supported
artifact_kinds
flash_supported
preserve_data_supported
partition_model
flash_transport
fastbootd_required
stock_vendor_preserved
restore_strategy
acceptance_suites
```

## Flash callback split

Common orchestration:

```text
resolve registered artifact
verify source/hash
bind selected serial
capture baseline
call adapter preflight
call adapter deployment
wait for boot
run common smoke
run target acceptance
seal evidence
```

Adapter callbacks:

```text
device_preflight
device_enter_flash_mode
device_validate_flash_mode
device_deploy_artifact
device_reboot
device_postboot_checks
```

Panther's current A/B fastboot implementation can become one adapter
implementation of these callbacks.

## N0 GSI devices

For Titan-family N0 work, artifact registration may bind:

```text
Sable system/GSI image
exact stock firmware/vendor basis
vbmeta/AVB handling
dynamic-partition evidence
restore package identity
```

The standard tool must refuse mutation if the target's stock restore path or
partition assumptions are not qualified.

## Multi-device host safety

Every ADB/fastboot mutation must use the selected serial. Additional attached
devices are permitted, but the requested serial must resolve exactly once in the
expected transport before mutation.

Never fall back from a missing selected device to the first globally attached
device.
