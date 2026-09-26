# Artifact verification

Status: **foundation-only**

Verification must prove what was built, from which source composition, for which
device/release, with which artifact kind and hash.

## Current command shape

```bash
bash sable.sh panther R9 verify --artifact <path>
```

Today this computes a checksum for a provided file and reminds the caller that
release-manifest comparison is not yet public-qualified.

## Required verification records

Future publication-ready artifacts must include:

```text
device
release
artifact_kind
primary_artifact
artifact_sha256
artifact_size
source_manifest_revision
tool_source_revision
signing_mode
proprietary_input_inventory_revision
build_host_report
```

## Panther R9 boundary

The accepted Panther R9 reference image exists, but public verification does not
yet claim independent reproduction of that image. Public docs must continue to
distinguish:

```text
accepted physical reference image
publicly rebuildable source state
publicly reproducible signed image
```

Those are different claims.
