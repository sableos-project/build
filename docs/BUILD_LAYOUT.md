# Build layout

SableOS development should separate canonical Sable source, upstream Android source, generated outputs, evidence, and host tools.

Recommended local root:

```text
/srv/data/sableos/
├── repo/ or repos/                 # SableOS organization checkouts
├── upstream/                       # GrapheneOS/AOSP/Lineage source trees
├── build-output/                   # OUT_DIR and generated artifacts
├── evidence/                       # logs, manifests, seals, reports
└── host-tools/                     # pinned host-side tools
```

The exact directory spelling may vary by host, but scripts should derive paths from configuration rather than embedding milestone-specific absolute workspace names.

## Separation rules

- Git repositories hold source and documentation.
- Upstream Android trees are disposable/reconstructible inputs.
- Build output is generated state and must not become canonical source.
- Evidence is append-oriented validation material, not source.
- Host tools are explicitly versioned inputs.
- Generated substrate/vendor product files are build inputs, not Sable product-customization owners.

## Device/substrate profiles

Build tooling should accept a target/substrate profile rather than hard-coding every command for one workspace. Future Panther revisions, Bramble, Titan-class research targets, or other devices should reuse the same orchestration framework where possible.

A profile should bind enough information to reproduce target configuration before build execution. At minimum record:

```text
SUBSTRATE=<AOSP/GrapheneOS/Lineage/etc.>
SUBSTRATE_RELEASE=<exact tag/revision/build>
ANDROID_PLATFORM=<major/release identity>

TARGET_DEVICE=<hardware target>
TARGET_PRODUCT=<Android product>
TARGET_RELEASE_CONFIG=<release name used by lunch, when applicable>
TARGET_BUILD_VARIANT=<user/userdebug/eng>
LUNCH_COMBO=<exact invocation>
EXPECTED_BUILD_ID=<resolved device build ID>

VENDOR_GENERATOR=<tool and exact revision, if generated inputs are used>
GENERATED_PRODUCT_PATH=<path, if applicable>
GENERATED_PRODUCT_MUTATION_ALLOWED=NO

SABLE_COMMON_PRODUCT_OWNER=<canonical common integration repository/path>
SABLE_DEVICE_ADAPTER_OWNER=<canonical target-specific repository/path>

OUT_DIR=<isolated or retained output location>
EVIDENCE_DIR=<append-oriented evidence location>
START_FREE_SPACE_FLOOR=<profile/gate-defined threshold>
NETWORK_DURING_BUILD=<authorized value>
CLEAN_CLOBBER_DEFAULT=NO
FAILURE_OUT_PRESERVATION=REQUIRED
```

`TARGET_RELEASE_CONFIG` is the release name supplied to Android 17 `lunch`; it must not be inferred solely from `get_build_var TARGET_RELEASE`. Some current Android 17 trees do not expose that variable after lunch even though the release-qualified lunch invocation is valid. Record the exact invocation and independently validate the resulting product/variant/build-ID state.

## Ownership boundary

Build profiles describe where product integration belongs; they do not move ownership into this repository.

```text
platform_manifest
    exact multi-repository source composition

vendor_sable
    common Sable product/package integration

device_sable_<target>
    bounded target-specific adapter/integration

upstream/generated substrate product
    substrate/device input; do not patch with Sable semantics

build
    orchestration, validation, evidence and reproducibility tooling
```

If a product build exposes a missing Sable package, first determine whether the module is built, selected by the product, installed into `PRODUCT_OUT`, and incorporated into an image. Do not fix a common Sable composition omission by editing a generated vendor/device product file.

See [`ANDROID_PRODUCT_BUILD_PLAYBOOK.md`](ANDROID_PRODUCT_BUILD_PLAYBOOK.md) for the build and evidence procedure.