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
- [ ] Define canonical app states: empty / editing / output
- [ ] Define action ownership: import / capture / export / share
- [ ] Define per-platform layout rules for macOS / iPad / iPhone
- [ ] Create new root screens for desktop/tablet/phone
- [ ] Remove legacy page composition assumptions from `ContentView`

### Exit criteria
- Three platform shells exist even if internals are temporary
- Each platform has a stable top-level layout strategy

## Phase 2 — State and service split
### Tasks
- [ ] Introduce `EditorDocument`
- [ ] Introduce `CanvasStyleState`
- [ ] Introduce `ExportState`
- [ ] Introduce `ImportCaptureState`
- [ ] Introduce `AppShellState`
- [ ] Move import/capture/share logic behind platform services
- [ ] Reduce `AppState` to a composition root or remove it entirely

### Exit criteria
- No single state object owns unrelated platform + UI + document concerns
- Root screens depend on focused state models

## Phase 3 — Rebuild the editor screens
### Tasks
- [ ] Rebuild macOS screen around preview + fixed inspector
- [ ] Rebuild iPad screen around preview-first adaptive split
- [ ] Rebuild iPhone screen as full-screen editor with phone-native tool areas
- [ ] Unify empty-state and editing-state transitions
- [ ] Rework action bars and toolbars around the new shell structure

### Exit criteria
- iPhone no longer looks like compressed desktop UI
- iPad no longer depends on ad-hoc compact desktop controls

## Phase 4 — Design system and tokens
### Tasks
- [ ] Add spacing tokens
- [ ] Add typography tokens
- [ ] Add control sizing tokens
- [ ] Add toolbar/panel sizing rules by device class
- [ ] Replace magic numbers in primary screens/components

### Exit criteria
- Major screens no longer define one-off sizing values inline
- Compact/regular/desktop sizing is consistent

## Phase 5 — Tests and regression hardening
### Tasks
- [ ] Add unit tests for render/state combinations
- [ ] Add UI tests for import → edit → export/share flows
- [ ] Add device-specific regression coverage for iPhone/iPad/macOS
- [ ] Run full build verification on all supported platforms

### Exit criteria
- Main workflow is covered by automated checks
- Refactor can continue without visual regressions going unnoticed
