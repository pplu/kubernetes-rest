# Kubernetes::REST House Rules

The shared house rules come from skilletor — bundle `getty-cpan-dist@getty`: engineering
discipline, the delegation lock, the publish gate, karr coordination, CPAN release. They load
as `.claude/rules/.local.*.md`; if they are missing, run `skilletor sync` and publish nothing
until they load. This file adds what is true only here, and wins where it differs.

## What this repo is

A Perl REST client for the Kubernetes API. Read first: the pipeline in
`lib/Kubernetes/REST.pm` (`_prepare_request` → `io->call` → `_check_response`/`_inflate_*`)
and `Role/IO.pm`. Request building, transport and inflation are one mechanism; "looks
orthogonal" is dangerous here.

## Agent team

| Task | Agent |
|---|---|
| Implement / refactor / debug anything under `lib/` or `bin/` | `kubernetes-rest-worker` (default) |
| Write or extend tests in `t/` | `kubernetes-rest-test-writer` |
| POD, on the core, the backends or the CLI | `kubernetes-rest-doc-writer` |
| Commits, `Changes`, card → done, pre-release audit | `kubernetes-rest-release-manager` |
| Read-only research, audit, gap analysis | `kubernetes-rest-worker` ("read-only, change nothing") |

Behavior-relevant = everything under `lib/` and `bin/`, the request/response pipeline, the IO
backends, path building, the resource map, kubeconfig parsing, the CLI, and the tests. Prose in
`README.md` and `Changes` bullets are not.

A defect that turns out to live in the object model belongs on **`../io-k8s-p5`**'s board, not
this one — `cd` there and create it, then note the pointer here.

## Release

The dist is **co-maintained**: `authority = cpan:JLMARTIN`, the remote is
`github.com/pplu/kubernetes-rest`, Getty is a co-author. Releasing is not a unilateral call.

## Deviations from the house rules

- **Public tracker on someone else's repository:** `github.com/pplu/kubernetes-rest` — never
  act on an issue or PR there on your own initiative, not even to read it. No listing, viewing,
  commenting, editing, closing or creating unless explicitly told to handle a specific item.
  Every write publishes under the maintainer's account.

## Hazards specific to this distribution

Short form — the mechanisms and the reasons live in skill `kubernetes-rest-core` and in the
agents' own lane notes. The prohibitions stay here.

- **A test that only checks the return value** cannot fail when path building or encoding
  breaks, which is the failure that actually reaches the cluster.
- **`prove -l t/` is not recursive** and silently skips subdirectory tests, exiting 0 — use
  `dzil test` or `prove -lr t/`; reserve non-`-r` for a single named file.
- **An untracked file does not exist as far as dzil is concerned** — `Git::GatherDir` leaves
  `include_untracked` off, so a new test that was never `git add`ed is absent from `dzil build`,
  from the release test gate and from the CPAN tarball while `prove -lr t/` runs it and passes.
  `git add` a new file as soon as it exists, and make `git status` the last check before any
  release.
- **Bytes on the wire, characters in objects** — the internal JSON encoder uses `utf8 => 1` and
  IO backends must return undecoded bodies (`decoded_content(charset => 'none')` under LWP):
  decoding in a backend causes silent mojibake, not an error, and dropping `utf8 => 1` makes
  every non-ASCII request body die in `HTTP::Message`. Both directions are pinned by
  `t/24_encoding.t` — run it after touching JSON, a backend or response handling.
- **One `package` per file, `$VERSION` in every file, all identical** —
  `RewriteVersion`/`BumpVersionAfterRelease` rewrite only the *first* `our $VERSION` per file,
  so a second package silently keeps a stale version while the metadata reports the release
  version (five packages sat at 1.003 until 1.106); `t/25_one_package_per_file.t` keeps it
  removed. The `$VERSION`-everywhere part is also correct and must not be "cleaned up" to the
  main module — the bundle narrows `version_finder` to `:MainModule` only for `no_cpan` dists.
- **Nine methods are published API for async clients such as `Net::Async::Kubernetes`** — the
  pipeline seam `build_path`, `prepare_request`, `check_response`, `inflate_object`,
  `inflate_list`, `process_watch_chunk`, `process_log_chunk`, and the discovery seam
  `prepare_discovery_requests`, `absorb_discovery`. Additive changes only, plus a `Changes`
  bullet. The `_`-prefixed originals behind them may move freely.
- **The object model belongs to `IO::K8s`** (`../io-k8s-p5`) — wrong field names or types are
  bugs there; do not paper over them here.
- **Removing public API is a breaking change with a protocol** — the tombstone goes into the
  separate `Kubernetes-REST-Deprecated` distribution (its own CPAN dist, not a module in this
  repo), and `Changes` states the changed failure mode. See the 1.105 removal of the 1002
  `Call::*` classes.
- **Tests never touch a real cluster** — the mock harness is the only path; the live path is
  gated behind `TEST_KUBERNETES_REST_KUBECONFIG`, deliberately named so nobody points the suite
  at production by accident. Never set it, never widen a test to depend on it.

## Perl conventions — reference, don't restate

Module loading, Moo patterns, dependency pinning and house style live in skills
`getty-perl-core`, `getty-perl-moo`, `kubernetes-rest-core`, `perl-kubernetes-rest` and
`getty-perl-release-author-getty` (force-loaded per lane via `briefing.skills` —
`.claude/agents/` defines which agent briefs which). Do not duplicate that content here.
