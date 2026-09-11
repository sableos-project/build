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

## Device profiles

Build tooling should accept a target/substrate profile such as Panther + GrapheneOS 2026081300 rather than hard-coding every command for one workspace. Future Bramble or MediaTek profiles should reuse the same orchestration framework where possible.
