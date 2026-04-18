# ScreenshotEditor Refactor Execution Backlog

## Phase 0 — Audit and blueprint
### Deliverables
- [x] Audit document
- [x] Refactor backlog
- [ ] Finalized wireframe references
- [ ] Deletion/defer checklist confirmed in code

### Exit criteria
- Team has a single source of truth for the refactor goals
- No new feature work proceeds before the blueprint is accepted

## Phase 1 — Information architecture redesign
### Tasks
- [x] Define canonical app states: empty / editing / output
- [x] Define action ownership: import / capture / export / share
- [x] Define per-platform layout rules for macOS / iPad / iPhone
- [x] Create new root screens for desktop/tablet/phone
- [x] Remove legacy page composition assumptions from `ContentView`

### Exit criteria
- Three platform shells exist even if internals are temporary
- Each platform has a stable top-level layout strategy

## Phase 2 — State and service split
### Tasks
- [x] Introduce `EditorDocument`
- [x] Introduce `CanvasStyleState`
- [x] Introduce `ExportState`
- [x] Introduce `ImportCaptureState`
- [x] Introduce `AppShellState`
- [ ] Move import/capture/share logic behind platform services
- [x] Reduce `AppState` to a composition root or remove it entirely

### Exit criteria
- No single state object owns unrelated platform + UI + document concerns
- Root screens depend on focused state models

## Phase 3 — Rebuild the editor screens
### Tasks
- [x] Rebuild macOS screen around preview + fixed inspector
- [x] Rebuild iPad screen around preview-first adaptive split
- [x] Rebuild iPhone screen as full-screen editor with phone-native tool areas
- [x] Unify empty-state and editing-state transitions
- [x] Rework action bars and toolbars around the new shell structure

### Exit criteria
- iPhone no longer looks like compressed desktop UI
- iPad no longer depends on ad-hoc compact desktop controls

## Phase 4 — Design system and tokens
### Tasks
- [x] Add spacing tokens
- [x] Add typography tokens
- [x] Add control sizing tokens
- [x] Add toolbar/panel sizing rules by device class
- [x] Replace magic numbers in primary screens/components

### Exit criteria
- Major screens no longer define one-off sizing values inline
- Compact/regular/desktop sizing is consistent

## Phase 5 — Tests and regression hardening
### Tasks
- [x] Add unit tests for render/state combinations
- [x] Add workflow regression tests for import → edit → export/share flows
- [x] Add device-specific regression coverage for iPhone/iPad/macOS
- [x] Run full build verification on all supported platforms

### Notes
- Workflow coverage currently uses a harness-backed regression suite inside the shared test target; a dedicated XCUI bundle can still be added later if deeper UI automation becomes necessary.

### Exit criteria
- Main workflow is covered by automated checks
- Shared macOS and iOS builds are verified before the next refactor phase
