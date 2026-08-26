# Getting started — the plain-language guide

This page is for a reader who wants the system working without learning its internals first.
The README beside it is the technical reference; everything here is also true there, in more words.

## What this is

A four-specialist AI crew that runs inside [Claude Code](https://claude.com/claude-code) — the
smaller sibling of [psychic-crew](https://github.com/nathan-hayashi/psychic-crew). Fewer agents,
same discipline: it tests itself three different ways, writes everything to ledgers, and cannot
finish work without your written approval.

## What you need

- A Mac, Linux machine, or Windows with WSL2. Just `git` and `jq` — no Node, nothing to install.
- [Claude Code](https://claude.com/claude-code) installed and signed in.
- The parent repo cloned **beside** this one (this crew checks itself against it).

## Set it up once

```bash
cd ~/projects
git clone https://github.com/nathan-hayashi/psychic-crew.git
git clone https://github.com/nathan-hayashi/psychic-crew-lite.git

cd ~/projects/psychic-crew-lite && ./scripts/apply-models.sh && ./scripts/verify.sh
```

Success ends with **no signal**. There is deliberately no setup script here — `verify.sh` is the
front door, and the working folders create themselves on first use.

Keeping the repos somewhere other than `~/projects`? Tell this crew where its parent lives (add to
your shell profile) — for example if both live under `~/dev`:

```bash
export PSYCHIC_CREW_PARENT="$HOME/dev/psychic-crew"
```

Until the parent is found, one layer prints `check-sync: skipped` — announced and harmless; it
engages the moment the parent is reachable.

## Daily use

Identical to the parent's loop: open a terminal **in this folder**, type `claude`, say what you
want, and approve with the exact token it shows you when it stops. `pwd` tells you which crew
you're in; this one answers "how many agents?" with **4**.

## If something says FAIL

SKIPs explain themselves and are usually fine. A real FAIL names itself — paste it into a `claude`
session in this folder rather than editing by hand. The three-layer check (`./scripts/verify.sh`)
is always safe to run.
