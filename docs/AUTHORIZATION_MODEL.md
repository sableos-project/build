# Build and mutation authorization model

> **Current multi-device note — 2026-09-24:** device-contact operations must also bind an explicit selected serial. Artifact registration/build identity does not contain a physical serial. Titan-family/Q27 mutation remains blocked by adapter capability until qualified.


SableOS validation tooling should make mutation boundaries explicit rather than relying on operator assumptions.

Typical independent authorization classes include:

- network fetch;
- source mutation;
- build-output mutation;
- module/full-product build;
- clean/clobber/delete;
- device contact;
- install/flash/reboot/slot changes;
- userdata/metadata mutation;
- signing/key generation/release operations.

A script should request only the authority it needs. Read-only evidence capture must not silently perform source/build/device mutation. A module build must not imply clean/clobber authority. A successful build must not imply device deployment authority.

## Fail-closed behavior

If required authorization is absent, scripts should stop before the first mutation and report the blocked boundary. They should not reinterpret a missing authorization as consent.

## Evidence

Each gate should record its authorization boundary in its report so later review can distinguish what was actually permitted and executed.
