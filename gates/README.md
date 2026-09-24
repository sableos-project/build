# Build/evidence gates

Status: **current gate index — 2026-09-24**

Gates prove bounded claims. A source/build PASS does not imply product selection,
image membership, artifact registration, deployment or runtime acceptance.

## Current common gate principles

- explicit mutation authorization;
- source-bound qualification where required;
- no automatic clean/clobber;
- exact artifact hashes;
- explicit artifact kind;
- selected-serial exact binding for device contact;
- common safety/evidence vs adapter-owned transport;
- fail-closed unqualified devices.

## K1/K2

The current private integration pipeline includes self/static contracts for:

- artifact registry schema v2 + legacy Panther compatibility;
- generic GSI-style artifact representation;
- registered artifact verification;
- device capability-gated registration;
- common flash driver free of Panther slot/flashall semantics;
- Panther adapter callback ownership;
- Titan 2 / Titan 2 Elite / Q27 blocked deployment capabilities;
- multi-device serial scope.

## Historical R8 gates

Older `r8_*` gate names remain useful provenance and may still exist where
their bounded artifact/JNI/product checks remain applicable. They are not the
active project milestone by name.

Every state-changing gate must print its authorization boundary before mutation.
