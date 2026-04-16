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
