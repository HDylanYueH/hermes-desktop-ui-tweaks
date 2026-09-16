> 🌐 Language: English | [中文版](README.zh-CN.md)

# hermes-desktop-ui-tweaks

Local UI patches for [Hermes Agent](https://github.com/NousResearch/hermes-agent) Desktop, plus the script that re-applies them after every `hermes update`.

## The problem

Hermes Desktop is a release build: you patch the source, run `npm run pack`, and the change is live. But `hermes update` resets the git checkout to `origin/main` (local commits on `main` are discarded with `reset --hard`) and silently rebuilds the app — every local tweak vanishes on the next update.

## What this pack contains

Two patches against `apps/desktop/src/`, developed and verified on Hermes v2026.7.x (Sep 2026):

| Patch | What it does |
|---|---|
| `0001-collapse-sessions-section-shell.patch` | Collapses the Sessions section shell when folded, so the Messaging and Cron sections in the left sidebar reflow up instead of leaving dead space. |
| `0002-cron-jobs-tab-right-sidebar.patch` | Adds a **CRON tab** to the right sidebar (`FILES \| CRON`). Lists scheduled jobs with state dots and next-run countdowns; hover to trigger/manage, right-click to pause/resume/delete, click a row to peek at recent runs and jump into a run's session. Reuses the same shared `$cronJobs` atom and row component as the left sidebar section — no duplicated logic. |

Plus `scripts/apply-and-repack.sh`, which re-applies both patches, runs the sidebar test suite, and repacks the app.

## Usage

**Prerequisites:** a working Hermes source checkout with dependencies installed (the default location is `~/.hermes/hermes-agent`; set `HERMES_REPO=/path/to/hermes-agent` if yours differs).

After every `hermes update`, run it one of two ways:

```bash
# 1. Command line
scripts/apply-and-repack.sh

# 2. Or double-click apply-and-repack.command in Finder — it opens Terminal
#    and runs the same script. Nothing is installed on your Desktop.
```

Expected output:

```
→ applying: desktop: cron jobs tab in the right sidebar (FILES | CRON)   # or: ✓ already applied, skipping
→ running sidebar tests...   # ✓ passed (skipped if node_modules is missing)
→ packing the desktop app (~2 min, the app may stay open)...
✅ Done. Quit Hermes (⌘Q) and relaunch — changes load on restart.
```

**Result:** after relaunching Hermes, the right sidebar shows two tabs — `FILES | CRON` — and the folded Sessions section no longer blocks the Messaging/Cron sections below it.

The script is idempotent: patches already in the tree are detected (reverse-apply check) and skipped. If upstream changed the same lines, `git am --3way` stops with a conflict message instead of forcing anything.

## How the cron tab was built (dev notes)

The desktop's right sidebar is not a bespoke widget — it's a pane system (`components/pane-shell/tree/`). Panes register with a `placement` and an optional `dock: { pane, pos }` hint; a pane not yet in the layout tree gets adopted via `insertAtGroup`, and `pos: 'center'` stacks it as a tab onto the anchor pane's group.

So the whole feature is:

1. A new pane contribution (`id: 'cron'`, `placement: 'right'`, `dock: { pane: 'files', pos: 'center' }`) rendering a thin list component.
2. A `bindPaneVisibility('cron', …)` call riding the same atoms as the file browser, bound *before* it so the files tab stays the default active tab when the rail opens (the last unhide fronts its pane).
3. Reuse, not duplication: the row component, state dots, job-title logic, trigger controller, and the shared `$cronJobs` atom all come from the existing left-sidebar cron section and cron page.

~30 lines of new glue in `controller.tsx`, one new pane component, three `export` keywords on existing components. No new dependencies.

## Caveats

- Patches are anchored to the upstream revision they were written against (v2026.7.x, Sep 2026). On later versions `git am --3way` usually still lands them; if it conflicts, resolve by hand — the dev notes above explain the intent of each hunk.
- This is a personal tweak pack, not affiliated with or endorsed by Nous Research. Updating Hermes without re-running the script loses the tweaks (but never breaks the app — it just reverts to stock).

## Acknowledgements

- [Hermes Agent](https://github.com/NousResearch/hermes-agent) — Nous Research, MIT License. The patches modify its desktop app source locally; nothing from upstream is redistributed here beyond the patch context lines.

## License

MIT — see [LICENSE](LICENSE).
