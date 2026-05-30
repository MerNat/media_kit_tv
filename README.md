This library extends the [media_kit](https://pub.dev/packages/media_kit) library with widgets designed to enhance the TV experience.

## Contributing and Maintenance

For now, I have adapted the Material video controls from the base package and optimized them for TV. I am using this `material_tv` widget myself in [Open Media Station](https://github.com/OpenMediaStation), and I will continue to add any features that I find useful.

Additionally, I welcome any PRs from the community that include fixes or new features.

---

## Features

- `material_tv` widget optimized for TV

---

## Usage

### Material TV Controls

You can use the `material_tv` widgets similarly to the original widgets from `media_kit`. For further documentation, refer to [media_kit's video controls documentation](https://github.com/media-kit/media-kit/blob/main/README.md#video-controls).

To see my implementation in action, check out the [Open Media Station video frontend repository](https://github.com/OpenMediaStation/OpenMediaStation.FE.MovieTV/blob/ea3de04f1cd73e6ca401b37c3585756d0b5f931c/lib/views/player.dart).

```dart
var tvThemeData = MaterialTvVideoControlsThemeData(
    topButtonBar: topButtonBar,
    bottomButtonBar: bottomButtonBar,
    visibleOnMount: true,
    seekBarThumbColor: seekBarColor,
    seekBarPositionColor: seekBarColor,
    seekBarSeekDuration: Duration(seconds: 10), // base seek step per arrow press
    primaryButtonBar: [
      const MaterialTvPlayOrPauseButton(
          iconSize: 124,
      ),
    ],
);

return MaterialTvVideoControlsTheme(
    normal: tvThemeData,
    fullscreen: tvThemeData,
    child: Scaffold(
        body: Video(
            controller: controller,
            controls: (state) {
                return MaterialTvVideoControls(state);
            },
        ),
    ),
);
```

### Seek bar behavior

The seek bar uses **duration-based** seeking instead of percentage-based:

- **Tap** arrow key: seeks by `seekBarSeekDuration` (default: 10 seconds)
- **Hold** arrow key: accelerates progressively — 1x → 2x → 3x → 4x → 5x → 6x (every 4 repeats)
- **Release**: resets acceleration

This gives consistent seek UX regardless of content length (unlike percentage-based seeking where 1% of a 3-hour movie is 108 seconds).

### TV remote behavior

The controls handle three TV-specific keys at the top-level `FocusScope`:

- **OK / Select / dedicated media play-pause keys**: toggle play/pause from anywhere on the player. Catches `LogicalKeyboardKey.select` (the OK button on Fire TV / Android TV remotes), `mediaPlayPause`, `mediaPlay`, and `mediaPause`. `enter` and `space` are intentionally NOT intercepted so the default `IconButton` `ActivateIntent` still fires Skip Prev/Next, Fullscreen, and Volume buttons when those have focus.
- **Back / Escape**: first press hides the controls, second press (controls already hidden) bubbles up so the consumer's parent route can exit. Matches YouTube / Netflix / Plex.

#### Coordinating Back with `PopScope` on Android

On Android the hardware Back button fires through two parallel platform channels: `KeyEvent` (consumed by this widget's `FocusScope.onKeyEvent`) AND `popRoute` (which goes straight to `PopScope.onPopInvokedWithResult` regardless of the `KeyEvent` being consumed). Returning `KeyEventResult.handled` from a `Focus` widget does **not** stop the route from popping.

If your player route uses `PopScope` and you want "first Back hides controls, second Back exits" to work end-to-end, gate the pop on visibility via the `onControlsVisibilityChanged` callback:

```dart
class _PlayerScreenState extends State<PlayerScreen> {
  bool _controlsVisible = true; // matches `visibleOnMount: true`
  bool _controlsVisibleAtLastBackPress = false;

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_captureBackPressVisibility);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_captureBackPressVisibility);
    super.dispose();
  }

  // Captures visibility synchronously BEFORE Flutter's focus dispatch
  // hides the controls, so PopScope below can read the pre-press state.
  bool _captureBackPressVisibility(KeyEvent event) {
    if (event is KeyDownEvent &&
        (event.logicalKey == LogicalKeyboardKey.goBack ||
            event.logicalKey == LogicalKeyboardKey.escape)) {
      _controlsVisibleAtLastBackPress = _controlsVisible;
    }
    return false; // don't consume — let normal dispatch continue
  }

  @override
  Widget build(BuildContext context) {
    final tvTheme = MaterialTvVideoControlsThemeData(
      visibleOnMount: true,
      onControlsVisibilityChanged: (v) => _controlsVisible = v,
      // ... your usual button bars, seek bar styling, etc.
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (_controlsVisibleAtLastBackPress) {
          // Controls are being hidden by this widget — don't pop.
          _controlsVisibleAtLastBackPress = false;
          return;
        }
        // Real exit intent: do your save / cleanup, then pop.
        Navigator.of(context).pop();
      },
      child: MaterialTvVideoControlsTheme(
        normal: tvTheme,
        fullscreen: tvTheme,
        child: Video(/* ... */),
      ),
    );
  }
}
```

`HardwareKeyboard.handler` runs **before** the focus tree dispatches, so the snapshot is always taken pre-hide. The `popRoute` platform message arrives after, and `PopScope` reads the snapshot to decide.