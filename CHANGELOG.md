# Changelog

All notable changes to `novatip-contracts` are documented here.

## [Unreleased]

### Added
- `get_jar_ids()` view function for indexer discovery of all registered jar slugs
- Edge case tests for single recipient tip, max recipients rejection, and jar ID tracking
- `JarIds` storage key to track registered slugs at the instance level
- Tests covering zero-bps rejection on `create_jar` (leading, trailing, and sole entry) and on `update_splits`
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
- `validate_splits()` now rejects any split with `bps == 0` (`InvalidSplits`).
  Such a recipient could never be paid but still consumed one of the 20
  recipient slots and appeared in clients as a collaborator. This applies to
  both `create_jar` and `update_splits`; jars written before this change are
  unaffected on read but must drop zero-bps entries before their next
  `update_splits` call.
- `validate_splits()` now rejects any split with `bps > 10_000` and accumulates
  the total with `checked_add`, both failing with `InvalidSplits`. `bps` is
  caller-supplied and unbounded, so a set of shares could previously sum past
  `u32::MAX`. That was caught by `overflow-checks = true` in the release
  profile, so no invalid jar was ever created — but it surfaced as an opaque
  wasm trap instead of error code 4, and the guarantee lived in `Cargo.toml`
  rather than in the validator. Correctness no longer depends on that profile
  setting.

### Fixed
- `validate_splits()` added each entry's `bps` to the running total twice, so
  a correct set summing to `10_000` computed as `20_000` and every
  `create_jar` and `update_splits` call was rejected with `InvalidSplits`.

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
- `TipReceived` event emission on every successful tip
- Full test coverage for all contract functions
- Deploy scripts for testnet and mainnet (`scripts/deploy.sh`, `scripts/create-jar.sh`)
- GitHub Actions CI pipeline (fmt, clippy, test)
