# Reproducibility policy

SableOS distinguishes source reproducibility from byte-for-byte artifact reproducibility.

## Source reproducibility

A validated source composition must be reconstructible from:

- a revision-pinned platform manifest;
- exact Sable repository commits;
- documented upstream release/tag identity;
- documented vendor/BSP acquisition steps and hashes when inputs cannot be redistributed;
- pinned build configuration.

## Host reproducibility

Build tooling should record host OS, tool versions, container/base-image identity when used, Node/Rust/Java/Clang inputs that materially affect the build, and build number/date policy.

Moving `latest` downloads or unrecorded branch heads are not acceptable release definitions.

## Artifact reproducibility

Exact artifact hashes are valuable reference evidence, but a different host may introduce semantically irrelevant metadata differences. When exact hashes diverge, classify the delta rather than silently accepting it or assuming corruption.

## Release rule

A release candidate should bind source composition, build-environment identity, signing identity, resulting target-files/images, and validation evidence. Any change to those inputs creates a new release identity.
