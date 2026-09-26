# Host validation and public build self-test

Status: **foundation-only — 2026-09-26**

This document defines how to generate local evidence for the public build
foundation without claiming that public users can reproduce a production SableOS
image.

## Command

Run from the public `build` repository:

```bash
bash sable.sh panther R9 self-test
```

To choose an explicit evidence directory:

```bash
bash sable.sh panther R9 self-test \
  --evidence-dir out/panther/R9/evidence/public-build-self-test
```

To require the host prerequisite check to pass as part of the self-test:

```bash
bash sable.sh panther R9 self-test --strict-env
```

`--strict-env` is appropriate for a qualified build host. Without `--strict-env`,
`self-test` records the environment result but does not fail merely because a
casual checkout lacks Android build prerequisites such as `repo`.

## Evidence layout

The self-test creates:

```text
<EVIDENCE_DIR>/
  self-test.log
  env-check.txt
  summary.json
  samples/
    sample_source_sync.txt
    sample_source_verify.txt
    sample_flash_plan.txt
    sample_titan2_build_image_fail_closed.txt
    sample_sign_dev_fail_closed.txt
    sample_unknown_device_fail_closed.txt
    sample_unknown_release_fail_closed.txt
    sample_unknown_function_fail_closed.txt
    sample_verify_missing_artifact_fail_closed.txt
```

## What is validated

The foundation self-test validates:

```text
- shell syntax for the public build scripts
- env-check execution and report capture
- Panther R9 source-sync dry-run boundary
- Panther R9 source-verify dry-run boundary
- Panther R9 flash-plan information path
- Titan-family image build fail-closed behavior
- public signing fail-closed behavior
- unknown device/release/function fail-closed behavior
- verify without artifact fail-closed behavior
```

## What is not validated yet

The self-test does not validate:

```text
- production signing
- accepted Panther R9 image reproducibility
- real source checkout completeness
- private/proprietary input acquisition
- image compilation
- device flashing
- Titan-family deployment safety
```

Those remain separate release-critical gates.

## Expected foundation markers

A successful foundation self-test emits:

```text
SABLE_SELF_TEST=PASS
sample_source_sync=PASS
sample_source_verify=PASS
sample_flash_plan=PASS
sample_titan2_build_image_fail_closed=PASS
sample_sign_dev_fail_closed=PASS
sample_unknown_device_fail_closed=PASS
sample_unknown_release_fail_closed=PASS
sample_unknown_function_fail_closed=PASS
sample_verify_missing_artifact_fail_closed=PASS
```

`summary.json` uses schema `sable-public-build-self-test-v1` so future tooling can
parse it without scraping the text log.
