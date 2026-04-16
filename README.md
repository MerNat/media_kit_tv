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