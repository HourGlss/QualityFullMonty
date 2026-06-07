# Local Tests

These tests are checked into GitHub but stay outside the `QualityFullMonty/` mod folder, so they are not packaged into the published Factorio mod.

Run from the repository root:

```sh
local-tests/run_local_checks.py
```

By default the test harness looks for Factorio headless at `../../factorio_headless` relative to this repository. Override it with `FACTORIO_ROOT=/path/to/factorio` or `FACTORIO_BIN=/path/to/factorio`.
