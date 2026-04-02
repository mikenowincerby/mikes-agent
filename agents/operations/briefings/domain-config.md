# Briefings — Domain Config

## Purpose

Manages the briefing lifecycle: ingesting meeting transcripts into structured briefing files, recalling past decisions/context, and promoting ephemeral briefing facts to permanent knowledge.

## References

| Source | Content |
|--------|---------|
| `codespecs/briefings.md` | Full briefing protocol (extraction, naming, retention, KB promotion, index) |
| `knowledge.md` | Permanent institutional knowledge |
| `briefings/briefings.md` | Briefing index (one-line descriptions for search) |

## Operation Modes

| Mode | Trigger | Input | Output |
|------|---------|-------|--------|
| **ingest** | "process meeting/transcript/context", transcript link | Transcript URL or filename | Briefing file written, index updated, KB candidates surfaced |
| **recall** | "what did we decide about X", "recall X" | Topic query | Answer with source citations |
| **promote** | "add to knowledgebase", "promote to KB" | Fact or briefing reference | KB candidates listed for user approval |

## Stages

| Order | Stage | Instruction File | Dispatch File | Skip Conditions |
|-------|-------|-----------------|---------------|-----------------|
| 1 | briefings | 1-briefings.md | briefings | never |

## Context Inlining

| File | Scope |
|------|-------|
| `codespecs/briefings.md` | all operations |
| `knowledge.md` | recall, promote |
| `briefings/briefings.md` | all operations |

## Context Sources

| Source | Adapter | Params |
|--------|---------|--------|
| Google Drive transcripts | gws drive files list | folder: `1ZQ5iCAglMjcQrCJmP5OcejQ0qY2B5GYb`, delta: `last_drive_scan` from state file |
| Session Attachments | local file scan | path: `.context/attachments/`, delta: `ingested_files` from state file |
