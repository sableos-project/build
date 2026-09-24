# SableOS milestone evidence gates

Status: **current normative evidence model — 2026-09-24**

Historical R5-R9 evidence remains preserved. Current gates follow the same claim
discipline while using the K1/K2 multi-device architecture.

## Claim ladder

```text
source qualified
  -> trusted artifact
  -> product selected
  -> image/artifact membership
  -> registered artifact
  -> device deployment
  -> runtime acceptance
```

Never skip a claim boundary by implication.

## Authorization

State-changing tooling declares independent authorization for source mutation,
build/output mutation, network, device contact, install/remove, reboot, role
changes, flash, unlock, wipe and clean/clobber/delete.

Read-only evidence capture must not silently mutate the device.

## Source-bound CI

Where required, full CI produces an exact-source attestation. A different source
commit must requalify.

## Artifact gate — K1

Verify exact artifact kind and hashes through the registry. Generic schema
support is not a device support claim.

## Deployment gate — K2

Before mutation prove:

- adapter explicitly permits the operation;
- registered artifact kind is supported;
- selected serial resolves exactly;
- restore/preservation policy is explicit;
- target-specific preflight passes.

After deployment preserve exact transport logs, post-boot identity and target
acceptance evidence.

## Panther

Panther R9 is accepted/frozen. Its target-files/A-B path is regression reference
evidence, not the active product-design target.

## Titan family

Titan 2 / Titan 2 Elite require independent adapter evidence. Initial N0 work
must not inherit Panther slot/flashall assumptions or one another's hardware
claims.

## Production release

Production signing/update provenance is a later gate and is not implied by N0
functional portability.

## Closure rule

When a gate closes, update current status and preserve exact source/artifact/
evidence identities. Do not rewrite historical requirement documents to make
earlier execution appear different.
