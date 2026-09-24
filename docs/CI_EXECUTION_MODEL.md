# SableOS CI execution model

Status: **current normative implementation guidance — 2026-09-24**

## Current authority

Release-critical qualification runs directly on the controlled local build
machine. GitHub is source/review/issues/documentation infrastructure and may run
disposable source-policy workflows, but it is not the release Android builder.

## Source qualification

Ordinary app/source defects should be caught before broad Android image work.

A full local-CI PASS is bound to an exact source commit. When a release build
requires that attestation, source drift invalidates it.

## Build layers

Keep separate:

```text
source/static/unit/lint
trusted standalone app artifact
Android module/product integration
full image/artifact build
artifact registration
device deployment
physical runtime acceptance
```

## Artifact registration

K1 schema v2 supports multiple artifact classes and verifies stored hashes.
Device adapters separately gate release artifact registration.

## Deployment

K2 common deployment code owns safety/evidence; device adapters own
transport/partition/restore semantics.

Panther is the qualified target-files/A-B reference. Titan 2, Titan 2 Elite and
Q27 remain blocked.

## Device roles

```text
Panther        REFERENCE_FROZEN
Titan 2        N0 portability research
Titan 2 Elite  independent N0 candidate
Q27            research
```

No new Panther image should be built merely because host tooling/documentation
changed. Rebuild/flash only when the claim actually changes image inputs/runtime.

## Failure handling

Preserve evidence and partial OUT state. Do not automatically clean/clobber or
restart a long build after failure.

## Production signing

Production signing/update infrastructure remains separate and deferred.
Production secrets do not belong on disposable CI or the ordinary development
builder.
