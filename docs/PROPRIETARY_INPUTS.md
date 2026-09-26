# Proprietary and external inputs

Status: **inventory boundary**

A public build process must distinguish source that is openly synced from inputs
that are externally acquired, proprietary, device-specific or not yet publicly
reproducible.

## Input classes

```text
AOSP / Google source
    synced through documented manifests and public refs

GrapheneOS-derived source
    synced through documented manifests/refs where applicable

Sable-owned source
    hosted under sableos-project or explicitly documented private/public source

kernel / device / vendor source
    device-specific; exact repo/ref must be documented per target

factory images / OTA payloads / firmware
    proprietary or externally acquired; never silently implied

signing keys / credentials
    never committed; production material is not public
```

## Current public claim

The public repository set is useful for source publication and build-foundation
work. It does not yet independently reproduce the accepted Panther R9 image.

## Required before production reproducibility claims

- exact manifest refs;
- exact kernel/vendor/firmware source or payload inventory;
- proprietary download instructions where redistribution is not allowed;
- artifact hash registry;
- signing model and key boundary;
- verification commands.
