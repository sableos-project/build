# SableOS build tooling

Host-side bootstrap, source assembly, build orchestration, reproducibility checks, and validation tooling for SableOS.

This repository answers **how** SableOS source is obtained, assembled, built, and validated. Exact multi-repository source composition belongs in `platform_manifest`; product/application code belongs in its owning repository.

## Goals

- stable entry points instead of one-off milestone shell fragments;
- explicit authorization for network, source mutation, build, device contact, Git mutation, and destructive operations;
- reproducible/pinned host inputs where practical;
- evidence capture separated from source and build outputs;
- support for multiple device/substrate profiles without copying common tooling;
- gates that fail closed and state exactly what they prove;
- clean reconstruction from organization repositories rather than dependence on historical workspace-only source;
- CI execution that preserves the trust boundary between disposable PR runners, trusted Android builds, device validation, and release signing.

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
    pre-build, compile, artifact, runtime and reconstruction gates

docs/
    build architecture, authorization, CI and reproducibility policy
```

## Current migration/build state

The current work is at the R5 boundary: the validated Sable Start source has been captured, sealed in the organization repository, pushed, and opened as PR #1, while the migrated-checkout build/reconstruction proof is still being closed.

The ThinkPad host has also demonstrated that some unprivileged bubblewrap namespace modes are blocked by host policy. Such a stop is an isolation-environment limitation, not a source compile failure. Build tooling must preserve the declared authorization/network/source boundary rather than silently weakening it to make a gate run.

## CI infrastructure identity

```text
thinkpad-p50      = sable-builder-01
optiPlex          = sable-signer-01
Pixel 7 / panther = sable-device-01
GitHub hosted     = untrusted/disposable CI
```

The normative trust model is in `sableos-project/.github/docs/CI_TRUST_ARCHITECTURE.md` and the execution model is in [`docs/CI_EXECUTION_MODEL.md`](docs/CI_EXECUTION_MODEL.md).

## Development milestone gates

Normative evidence guidance for the current development train is in:

- [`docs/MILESTONE_EVIDENCE_GATES.md`](docs/MILESTONE_EVIDENCE_GATES.md)

It covers:

- R5 migrated-source build/reconstruction;
- R6 All Apps/Search/greeting validation;
- R7 daily-driver device qualification;
- R8 design/theme/customization validation;
- R9 Sable Calculator/utility validation;
- R10+ inherited-application replacement evidence.

See also:

- [`docs/CI_EXECUTION_MODEL.md`](docs/CI_EXECUTION_MODEL.md)
- [`docs/BUILD_LAYOUT.md`](docs/BUILD_LAYOUT.md)
- [`docs/REPRODUCIBILITY.md`](docs/REPRODUCIBILITY.md)
- [`docs/AUTHORIZATION_MODEL.md`](docs/AUTHORIZATION_MODEL.md)

Product requirements remain in the owning product/component repository. Build/test tooling must enforce documented semantics, not invent them.