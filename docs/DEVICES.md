# Device and release support matrix

Status: **current public foundation**

| Device | Release | Status | Artifact kind | Public build | Public flash |
| --- | --- | --- | --- | --- | --- |
| panther | R9 | REFERENCE_FROZEN | target-files | FAIL_CLOSED | PLAN_ONLY |
| titan2 | N0 | RESEARCH_UNQUALIFIED | UNQUALIFIED | FAIL_CLOSED | NO |
| titan2-elite | N0 | RESEARCH_UNQUALIFIED | UNQUALIFIED | FAIL_CLOSED | NO |
| q27 | N0 | RESEARCH_UNQUALIFIED | UNQUALIFIED | FAIL_CLOSED | NO |

## Panther

Panther R9 is the frozen accepted touch-first reference. Public build tooling may
document the source/build/sign/verify path, but must not claim production
reproducibility until all inputs and signing boundaries are complete.

## Titan-family and Q devices

Titan 2, Titan 2 Elite and q27 are portability/research targets. They must remain
fail-closed until physical evidence proves the partition model, restore path,
firmware/vendor basis, AVB boundary and safe artifact kind.
