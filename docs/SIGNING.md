# Signing policy

Status: **public boundary — production signing deferred**

SableOS public tooling distinguishes signing modes but does not publish private
keys or production signing material.

## Terms

```text
DEV_SIGNED
    locally reproducible development/test signing only

RELEASE_CANDIDATE_SIGNED
    release-candidate process exists, but production signing is still separate

PRODUCTION_SIGNED
    production keys/process have been established and documented

UNSIGNED_OR_NOT_REPRODUCIBLE_PUBLICLY
    source is useful, but the published repository set cannot independently
    reproduce the accepted image
```

## Current public state

```text
panther / R9
    SOURCE_AVAILABLE_BUT_NOT_FULLY_PUBLIC_REPRODUCIBLE
    public production signing is not available

titan2 / N0
titan2-elite / N0
q27 / N0
    UNSIGNED_OR_NOT_REPRODUCIBLE_PUBLICLY
```

## Command boundary

```bash
bash sable.sh panther R9 sign --mode dev
bash sable.sh panther R9 sign --mode release-candidate
bash sable.sh panther R9 sign --mode production
```

All signing modes currently fail closed. That is intentional.

## Key boundary

Production keys, release keys, credentials, passphrases and signing service
configuration must never be committed to public or private source repositories.

A future public dev-signing path must document:

- key-generation command;
- key storage path outside git;
- supported artifact kind;
- exact signing command;
- verification command;
- what the result does and does not prove.
