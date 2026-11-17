---
name: goodnight
description: >-
  Overnight improvement run driven by a Firstmate home: review the owner's 3 most recently pushed repos, file deduplicated GitHub issues, fix them with Firstmate workers, auto-merge only behaviour-preserving low-risk fixes, leave every other PR open, stop gracefully at a deadline or on the owner's return, and render a Lavish morning report.
  Use whenever the user types /goodnight (with or without focus instructions), says they are going to bed, signing off for the night, or want their repos worked on while they sleep, or asks for an overnight improvement run or nightly code review.
  Also use on the owner's first message after a goodnight run, to render the morning report.
---

# goodnight

`/goodnight [focus instructions] [until <time>]`, typed by the owner to the first mate of a Firstmate home before bed.

This skill is a plan, not machinery.
It runs entirely on Firstmate's own mechanisms: its project intake, backlog, brief and spawn path, away mode (`/afk`), validation pipeline, guarded merge script, and return brief.
It adds no supervision loop, lock, merge guard, or scheduler, and where it names a Firstmate script, that script's help and Firstmate's `AGENTS.md` and skills own the exact mechanics.
It only ever narrows Firstmate's authority; nothing here widens it.

## 1. Preconditions

- Run only as the first mate of a primary Firstmate home: the working directory (or `$FM_HOME`) holds an `AGENTS.md` whose first line is `# Firstmate`, plus `bin/fm-spawn.sh` and `bin/fm-afk-launch.sh`.
  Anywhere else, including a worker launched by Firstmate, a secondmate home, or a plain repo, reply that `/goodnight` runs only from a Firstmate home's first mate session and stop.
  List no repos, file nothing, spawn nothing.
- The session-start digest must be present and the session lock held.
  A lock-refused, read-only session reports that diagnostic and stops.
- Never ask the owner a question during setup: they are going to bed.
  When something is ambiguous, take the default below and say so in the read-back.

## 2. Parse the invocation

- **Deadline**: `until HH:MM` (local) or `until <ISO 8601 datetime>` anywhere in the text; otherwise the next 07:00 local.
  A time already past today means tomorrow.
  Compute both the local time and its UTC ISO 8601 form with `date`.
- **Focus**: the rest of the text, verbatim.
  Empty means a general code review only.
- **Run date** `<date>` is today's local `YYYY-MM-DD`; `<tag>` is `gn` plus its `MMDD` (for example `gn1117`).

## 3. Pick the repos

1. List the owner's repos most recently pushed first with gh-axi, for example `gh-axi api 'user/repos?affiliation=owner&sort=pushed&direction=desc&per_page=30'`.
2. Drop archived repos, forks, and the repository this Firstmate home itself runs from.
3. Take the first 3.
4. For each one not already a project in `data/projects.md`, load `project-management` and add it with that skill's resolved defaults (clone into `projects/`, register, initialize).
   The `/goodnight` invocation is the owner's consent to clone and register exactly these repos.
   If that skill routes the repo to a secondmate, or the clone or initialization fails, skip the repo, do not take a 4th in its place, and record why for the read-back and the morning report.

## 4. Record the run

Write `data/goodnight/<date>/run.md` (private operational state): start time, deadline (local and UTC), focus verbatim, the repos and why any were skipped, and the task ids below.
Every goodnight task id starts with `<tag>-`:

- review: `<tag>-<repo>-review`
- fix: `<tag>-<repo>-<issue number>`

## 5. Dispatch one review scout per repo

For each repo, through the normal path in `AGENTS.md` sections 4, 7, 10 and 11: add a scout backlog item (`bin/fm-tasks-axi.sh add <id> "<title>" --kind scout --repo <repo>`), scaffold with `bin/fm-brief.sh <id> <repo> --scout`, fill both subsections, run `bin/fm-dispatch-resolve.sh` on the brief, and spawn with `bin/fm-spawn.sh`.

`## Captain's intent`: the owner's ask for this review, "find improvement areas in my top recent repos, code review etc. The agents will raise issues", plus the focus verbatim, or "no focus given".

`## Firstmate spec` (copy, then substitute):

```text
Review <owner>/<repo> on its default branch: the focus first (<focus or "none">), then a general code review
(bugs, correctness, missing or weak tests, docs that disagree with the code, lint and typing errors, dead code,
maintainability, security smells). Read-only on code: no branch, commit, push or PR.
File findings as GitHub issues with gh-axi:
- Before filing, search open AND closed issues (gh-axi issue list --state all, plus a keyword search) and skip
  any finding an existing issue already covers.
- At most 5 new issues, highest value first.
- Each issue: a clear title; the problem with file:line evidence; the proposed fix; how to verify it.
  No direct address to anyone and no exploit detail for security findings.
- Labels (create any that are missing with gh-axi label create): `goodnight`; exactly one of
  `behaviour-preserving` / `behaviour-changing`; exactly one of `risk:low` / `risk:medium` / `risk:high`.
- `behaviour-preserving` only when the fix changes no runtime behaviour, output, API, configuration meaning,
  or deploy effect. `risk:low` only when the fix is docs, comments, tests, lint or typing fixes, dead code
  removal, or a refactor with tests unchanged, and touches nothing destructive, security-sensitive or
  access-related. When unsure, pick behaviour-changing and the higher risk.
Report in data/<id>/report.md: a table of the issues filed (URL, class, risk, one-line fix scope), the
findings skipped as duplicates (with the existing issue URL), and findings left unfiled by the cap.
```

Spawn only while the home stays at 4 live workers or fewer (`bin/fm-afk-contract.sh live-workers`); leave the rest queued, and the away session dispatches them as slots free under the spend cap from section 6.

## 6. Enter away mode

Load `afk` and follow its entry exactly, as the last step of this turn:

```sh
bin/fm-afk-launch.sh enter --words-file data/goodnight/<date>/words.txt \
  --expected-return <deadline UTC> --spend 4
```

`--spend 4` is the "at most 4 workers at once" limit (the workers share one Claude usage limit); `bin/fm-spawn.sh` enforces it while away.
Then do the afk skill's per-harness step and announcement.

The words file is the whole away mandate, because the away session reads only the words.
Write it from this template, filled in, and add nothing that widens it:

```text
Goodnight run <date> (goodnight skill; run record data/goodnight/<date>/run.md).
Repos: <repo-a>, <repo-b>, <repo-c>. Focus: <focus verbatim, or "none, general review">.
Deadline: <HH:MM local> (<UTC ISO 8601>).

Until the deadline:
1. When a review scout <tag>-<repo>-review finishes, read its report. For every issue it filed labelled
   behaviour-preserving and risk:low, file and dispatch one fix ship through the normal brief, dispatch and
   spawn path, with id <tag>-<repo>-<issue number>, yolo off, the issue's substance as its intent, and a PR
   body that closes the issue.
2. From that repo's other new issues, pick at most 2 by value and risk and dispatch a fix ship for each the
   same way. Their PRs stay open for me; never merge them.
3. Merge a goodnight fix PR, only through bin/fm-pr-merge.sh, when ALL of these hold: its issue is labelled
   behaviour-preserving and risk:low; its diff only touches docs, comments, tests, lint or typing fixes, dead
   code, or a refactor that leaves every test file unchanged; all checks are green; it is nothing destructive,
   security-sensitive or access-related (auth, secrets, keys, permissions, CI permissions, infrastructure
   access, data deletion); and on homelab, none of its changed files matches a `paths` filter of a workflow
   that deploys, converges or applies on push to main, read from the repo at merge time (a homelab merge that
   touches a host redeploys it). Any doubt: leave the PR open for me.
4. Never more than 4 workers at once.

At and after the deadline: dispatch nothing new and merge nothing. Workers already running finish to their
PR or report and stop there.
On my return: no new goodnight work and no more merges; render the goodnight morning report.
```

## 7. Read-back, then goodnight

After entry, give the afk skill's read-back in plain sentences: the repos (and any added or skipped, with why), the focus, the deadline, exactly which fixes may merge on their own, that every other PR waits for the owner, and how to stop.
Stopping: any message from the owner ends the run gracefully; work in flight finishes to a PR, nothing more merges, and the morning report follows.
Do not wait for a reply.

## 8. Merge authority (do not widen)

- The only PRs that may merge without the owner are goodnight fix PRs meeting every condition in rule 3 of the words, merged by the away session through `bin/fm-pr-merge.sh` before the deadline and before the owner returns.
- Never merged by goodnight: behaviour-changing fixes, anything above risk:low, anything red or with an unreported required check, any homelab change touching host files, and anything destructive, irreversible, security-sensitive or access-related, whatever a label says.
- Goodnight ships spawn with yolo off, so after the run no goodnight PR merges without the owner's explicit word.
- Away mode's own limits stay in force: no red merges, no local-only landing, nothing from the never-set.

## 9. Morning report (on the owner's return)

The owner's first ordinary message after a goodnight run is the return, whether before or after the deadline.

1. Follow the afk skill's return first: run `bin/fm-afk-return.sh`, relay its return brief, and clear its catch-up gate.
2. Stop new goodnight work: hold every `<tag>-` backlog item that is still queued with `bin/fm-captain-hold.sh hold <id> --reason "goodnight run ended before dispatch"`.
   Workers still running keep going to their PR under normal supervision; their PRs wait for the owner.
3. Gather from durable records, never memory: `run.md`, each review report, `bin/fm-crew-state.sh` for each `<tag>-` task, and gh-axi for the live state of each goodnight issue and PR.
4. Load `lavish` and render `data/goodnight/<date>/report.html` with:
   - a summary line: repos reviewed, issues filed, PRs merged, PRs waiting, failures;
   - issues filed, per repo: link, class, risk, and whether a fix was attempted;
   - PRs merged: full URL and the issue it closed;
   - PRs waiting for the owner: full URL and why it did not merge (behaviour-changing, not low risk, red or pending checks, homelab host files, deadline, owner returned);
   - still running, held, failed, or skipped: what and why, with evidence.
   Open it with `lavish-axi`.
5. Reply in chat with the Lavish link and a short outcome summary in `AGENTS.md` section 9 language, every PR as its full `https://` URL.
6. Mark `run.md` ended, with the end time and the report path.
