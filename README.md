# SableOS build tooling

Host-side bootstrap, source assembly, build orchestration, reproducibility checks, and validation tooling for SableOS.

This repository answers **how** SableOS source is obtained, assembled, built, and validated. Exact multi-repository source composition belongs in `platform_manifest`; product/application code belongs in its owning repository.

## Goals

- stable entry points instead of milestone-specific shell fragments;
- explicit authorization for network, source mutation, build, device contact, and destructive operations;
- reproducible/pinned host inputs where practical;
- evidence capture separated from source and build outputs;
- support for multiple device/substrate profiles without copying common tooling.

## Planned layout

```text
config/
    pinned build/substrate profiles

bootstrap/
    upstream acquisition and verification

assemble/
    source synchronization/composition helpers

build/
    module and product build entry points

gates/
    pre-build, compile, artifact, and validation gates

docs/
    build architecture and reproducibility policy
```

The current validated ThinkPad workspace remains authoritative until the existing R3B gate closes and the new organization layout reproduces the same source/build state.

See `docs/BUILD_LAYOUT.md`, `docs/REPRODUCIBILITY.md`, and `docs/AUTHORIZATION_MODEL.md`.
