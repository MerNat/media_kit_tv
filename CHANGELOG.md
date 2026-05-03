## 0.0.5

- Fixed: pressing OK / Select on a TV remote now toggles play/pause anywhere on the player (was silently no-op — Fire TV / Android TV remotes send `LogicalKeyboardKey.select` which Flutter's default `ActivateIntent` does not map)
- Fixed: D-pad focus is now visible on every control button (the inner Theme override was setting `focusColor` and `hoverColor` to fully transparent, killing the inherited focus circle on every `IconButton`)
- Added: Back / Escape on a TV remote first hides the controls, second press bubbles up so the parent route can exit (matches YouTube / Netflix / Plex)
- Added: `onControlsVisibilityChanged` callback on `MaterialTvVideoControlsThemeData` so consumers can gate their own `PopScope.onPopInvokedWithResult` on whether the controls were visible at the moment of a back press (Android dispatches Back through `KeyEvent` AND `popRoute` in parallel, so a `Focus` consuming the KeyEvent does not stop the route from popping — consumers need the visibility signal to decide)
- Removed: leftover `print('Key pressed: ...')` that logged every keystroke to the platform log

## 0.0.4

- Fixed: holding arrow keys on seek bar now works (was frozen due to unhandled `KeyRepeatEvent`)
- Changed seek from percentage-based (1%/press) to duration-based (`seekBarSeekDuration`, default 10s)
- Added accelerating seek on sustained hold (1x → 6x, resets on release)
- Added `seekBarSeekDuration` to `MaterialTvVideoControlsThemeData` for configurable base seek step

## 0.0.3

- Updated README

## 0.0.2

- Updated README

## 0.0.1

- Initial release
