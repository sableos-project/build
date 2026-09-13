# Reproducibility policy

SableOS distinguishes source reproducibility from byte-for-byte artifact reproducibility.

## Source reproducibility

A validated source composition must be reconstructible from:

- a revision-pinned platform manifest;
- exact Sable repository commits;
- documented upstream release/tag identity;
- documented vendor/BSP acquisition steps and hashes when inputs cannot be redistributed;
- pinned build configuration.

A successful build from a workspace with manually supplied source is evidence about that workspace, not by itself proof of complete source reconstruction.

## Build-target reproducibility

For Android product builds, record target configuration as an explicit tuple rather than only a product name or a historical two-part lunch string.

Record at least:

```text
exact lunch invocation
TARGET_PRODUCT
release configuration supplied to lunch, when applicable
TARGET_BUILD_VARIANT
resolved BUILD_ID
upstream/substrate release identity
```

Android 17 supports product/release/variant lunch selection. Do not assume `<product>-<variant>` remains valid.

Do not use `get_build_var TARGET_RELEASE` as the sole proof of release selection. A tree may accept a release-qualified lunch invocation while that variable is empty. Preserve the exact lunch command and verify the resulting product, variant, release-dependent inputs, and build ID.

If the substrate supplies product-specific values such as `BUILD_ID_<product>`, record how those values enter the environment. Do not manually override `BUILD_ID` merely to bypass a product guard. A derived Sable product must have an intentional, documented build-ID/release mapping before it can be treated as reproducible.

## Generated vendor/substrate inputs

When vendor/device inputs are generated, record:

- generator/tool repository and exact revision;
- source/vendor specification identity;
- generated target/product identity;
- required external factory/vendor input identity and hashes where applicable;
- whether the generated tree is expected to be byte-stable;
- proof that Sable changes were not hidden inside generated substrate output.

Generated product files should be reproducible inputs, not canonical locations for common Sable product semantics.

## Host reproducibility

Build tooling should record host OS, tool versions, container/base-image identity when used, Node/Rust/Java/Clang inputs that materially affect the build, and build number/date policy.

Moving `latest` downloads or unrecorded branch heads are not acceptable release definitions.

## Build-output and failure preservation

A retained `OUT_DIR` is generated state, not source, but it can be important evidence. When a long product build succeeds and a later composition/artifact closure gate fails, preserve the output unless cleanup is separately authorized.

Do not convert a post-build integration failure into a clean rebuild automatically. First classify whether the failure is source, compile, product-selection, install, image-composition, or runtime related. Incremental continuation may be preferable after a bounded configuration repair, but it does not replace a later clean reconstruction gate when that stronger claim is required.

Record initial and final free-space observations for large builds when storage exhaustion is a realistic failure mode.

## Artifact reproducibility

Exact artifact hashes are valuable reference evidence, but a different host may introduce semantically irrelevant metadata differences. When exact hashes diverge, classify the delta rather than silently accepting it or assuming corruption.

A full Android build success does not by itself prove that a required Sable package is selected into the product. Artifact closure must distinguish:

```text
module known to build system
module compile success
generated install rules
product selection
installed PRODUCT_OUT artifact
image incorporation
runtime package state
```

Each later layer requires its own evidence.

## Release rule

A release candidate should bind source composition, build-target identity, build-environment identity, signing identity, resulting target-files/images, and validation evidence. Any change to those inputs creates a new release identity.
