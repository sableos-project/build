# Build/evidence gates

Gate scripts are designed to prove bounded claims and fail closed. A `PASS` from one gate must not be promoted into a later product/image/runtime claim.

## Current R8 gates

- `r8_app_artifact_audit.sh` — read-only audit of one trusted standalone APK. Records whole-APK and extracted DEX/JNI identities and can verify native 16 KiB ELF/APK alignment when the caller supplies the pinned `llvm-readelf` and `zipalign` tools. It does **not** prove Soong import, package manifest semantics, product selection, target-files/image membership or runtime behavior.

## Historical gates

- `r5_r3a_manifest_audit.sh` — read-only historical workspace/manifest/path audit used during SableStart migration and reconstruction work.

Every state-changing build/integration gate must print explicit authorization before mutation. Read-only gates may create only their declared evidence directory.
