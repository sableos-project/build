# GrapheneOS product-specific envsetup discovery

Status: **build-mechanics note derived from the Panther R6 investigation. Revalidate against each future substrate revision.**

GrapheneOS product builds can provide product-specific environment values through `cmds-for-envsetup.sh`. For the Android 17 build tree inspected during Panther R6, `build/envsetup.sh` resolves the selected product and searches only this pattern before product configuration:

```text
vendor/*/<product>/cmds-for-envsetup.sh
```

The relevant control flow is:

```text
lunch / _lunch_meat
    -> maybe_source_extra_commands <product>
    -> source vendor/*/<product>/cmds-for-envsetup.sh when exactly one match exists
    -> build product configuration
```

This matters for derived Sable products whose Build ID differs in variable name from the substrate product. A product makefile inheriting `panther.mk` does not automatically make `BUILD_ID_panther` satisfy a build configured with `TARGET_PRODUCT=sable_panther`; Android resolves the product-specific variable for the selected product before the inherited product makefile is evaluated.

## Panther R6 mapping

For the GrapheneOS `2026091000` Panther substrate, the validated base product exports:

```text
BUILD_ID_panther=CP2A.260705.006
```

The Sable derivative therefore uses:

```text
TARGET_PRODUCT=sable_panther
BUILD_ID_sable_panther=CP2A.260705.006
```

and the Panther-specific Sable adapter is intended to be checked out at:

```text
vendor/sable_devices/sable_panther
```

so that its repository-root `cmds-for-envsetup.sh` resolves to:

```text
vendor/sable_devices/sable_panther/cmds-for-envsetup.sh
```

which matches the GrapheneOS discovery pattern for product `sable_panther`.

This checkout-path requirement is build mechanics, not an ownership transfer: the repository remains the bounded `device_sable_panther` adapter. Common Sable package composition remains in `vendor_sable` at `vendor/sable`.

## Rules for future devices

Do not assume this exact discovery pattern is stable across Android or GrapheneOS revisions. Before introducing a new derived product:

1. inspect the active `build/envsetup.sh` product-specific command discovery;
2. record the exact pattern it searches;
3. ensure the target-specific adapter can supply its Build-ID/release environment through that normal mechanism;
4. keep target-specific Build-ID state out of common `vendor_sable` product configuration;
5. prove the resolved Build ID before compilation;
6. do not use an ad hoc shell `BUILD_ID` override to bypass a generated device guard.

If the upstream mechanism changes, update the device profile/adapter rather than embedding one substrate's discovery assumption in generic build tooling.
