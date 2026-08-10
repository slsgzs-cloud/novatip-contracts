# Changelog

All notable changes to `novatip-contracts` are documented here.

## [Unreleased]

### Added
- `jar_crtd` event published on every successful `create_jar`, carrying the jar
  slug and owner, so indexers can discover jars from the event log
- `DuplicateRecipient` (code 7) error variant, raised when a split vector names the same address twice
- Edge case tests for single recipient tip and max recipients rejection
- Tests covering zero-bps rejection on `create_jar` (leading, trailing, and sole entry) and on `update_splits`
- Tests for duplicate recipients (adjacent and non-adjacent) on `create_jar` and `update_splits`, plus valid-case coverage for distinct recipients and a full 20-recipient jar
- Test that `tip` fails when the sender's balance is insufficient
- Tests covering a share above 100% and a `bps` set whose sum overflows `u32`,
  on both `create_jar` and `update_splits`
- `jar_exists(jar_id) -> bool` view function, so a slug-availability check no
  longer has to call `get_jar` and catch the `JarNotFound` panic. Reads one
  persistent key, matches slugs exactly, and is cheap enough for the debounced
  onboarding check. Not yet exposed from `@novatip/sdk`.
- Tests covering `jar_exists` before and after registration, against a rejected
  jar, and across `update_splits`
- `MAX_MESSAGE_LEN` (280 bytes) bound on the `tip` message, with a new
  `MessageTooLong` error (code 8, appended so existing codes are unchanged)
- Tests covering a message one byte over the limit and one at exactly the limit

### Changed
- Jar discovery moved from an on-chain list to the event log. The `get_jar_ids()`
  view and its `JarIds` instance-storage vector — both added and removed within
  this unreleased cycle, so never shipped in a release — are gone: the vector
  grew without bound and made each `create_jar` cost more than the last.
  Indexers reconstruct the jar list by scanning `jar_crtd` events; see
  [`docs/CONTRACT.md`](docs/CONTRACT.md) for the backfill procedure.
- `validate_splits()` now rejects any split with `bps == 0` (`InvalidSplits`).
  Such a recipient could never be paid but still consumed one of the 20
  recipient slots and appeared in clients as a collaborator. This applies to
  both `create_jar` and `update_splits`; jars written before this change are
  unaffected on read but must drop zero-bps entries before their next
  `update_splits` call.
- `validate_splits()` now rejects any split vector containing the same recipient
  address more than once, on both `create_jar` and `update_splits`. Duplicates
  were not a loss-of-funds bug, but they made `tip` issue several transfers to
  one destination in a single call and forced per-collaborator accounting to
  de-duplicate after the fact. Clients that allow entering a collaborator twice
  must sum the shares before submitting. Jars written before this change are
  unaffected on read, but must drop duplicates before their next `update_splits`
  call.
- `create_jar_rejects_bad_bps_sum` now uses two distinct recipients, so it still
  exercises the sum check rather than tripping the new duplicate check first

### Fixed
- `validate_splits()` added each entry's `bps` to the running total twice, so
  splits summing to the required `10_000` were rejected as `InvalidSplits` and
  no valid jar could be created or updated. The zero-bps and duplicate-recipient
  branches were merged with both sides of the accumulator line left in place.

## [0.1.0] - 2025-07-01

### Added
- `tip_splitter` Soroban contract (Rust) deployed on Stellar testnet
- `create_jar(owner, jar_id, splits)` - register a tip jar with basis-point splits
- `tip(from, jar_id, amount, message)` - atomic USDC split across all recipients
- `update_splits(jar_id, splits)` - replace a jar's collaborator splits
- `get_jar(jar_id)` - read a jar's on-chain configuration
- `get_token()` - return the configured USDC Stellar Asset Contract address
- Atomic payment routing with rounding dust sent to the last recipient
- Typed contract errors (`NotInitialized`, `JarExists`, `JarNotFound`, `InvalidSplits`, `InvalidAmount`, `TooManyRecipients`)
- `tip` event emission on every successful tip, with topics `(symbol "tip", jar_id)`
- Full test coverage for all contract functions
- Deploy scripts for testnet and mainnet (`scripts/deploy.sh`, `scripts/create-jar.sh`)
- GitHub Actions CI pipeline (fmt, clippy, test)
