# WPE WebKit SDK prebuilt binaries

Versioned Linux SDK/runtime archives for Flutter apps using
[`flutter_inappwebview_linux`](https://pub.dev/packages/flutter_inappwebview_linux).

Each release contains separate native `x86_64` and `aarch64` artifacts:

- The SDK contains headers, pkg-config metadata, and linkable libraries used by
  `flutter build linux`.
- The stripped runtime contains shared libraries, WebKit subprocesses,
  resources, and the recursive non-host dependency closure bundled with the
  resulting application. Core system, graphics, display, audio, and driver
  libraries remain supplied by the target Linux installation.

Extract the SDK at `/` before running a Flutter build:

```sh
sudo tar -xJf Senpwai-WPE-SDK-<version>-linux-<architecture>.tar.xz -C /
sudo ldconfig
flutter build linux --release
```

The SDK is not distributed to end users. Packaging workflows bundle the
matching `Senpwai-WPE-Runtime-*` archive with the application.

Runtime packaging uses `lddtree` to follow every installed WPE library and
subprocess recursively. Non-host dependencies such as ICU and libxml2 are
copied into the archive with their package copyright files. The build fails if
any dependency outside the explicit AppImage-compatible host library policy is
not represented in the runtime archive. The GLib/GTK/libsecret/Pango/Cairo
desktop stack is explicitly host-provided so the runtime cannot override a
newer distribution's internally consistent desktop libraries. Every archive
includes `bundled-libraries.txt` and `host-libraries.txt` audit manifests.
The WPE source is patched so release builds honor `WEBKIT_EXEC_PATH`; packaged
applications can therefore launch `WPEWebProcess` and `WPENetworkProcess`
from their private runtime rather than the compile-time `/usr/local` prefix.

## Supported baseline

The defaults intentionally follow the current upstream Linux backend build
instructions: **WPE WebKit 2.50.4** and **libwpe 1.16.3**, using the modern
WPE Platform headless backend. It deliberately disables DRM/Wayland platform
backends, GPU/WebGL, video/media, speech synthesis, web audio, and optional
image/font features. Disabling WebGL alongside video avoids the ANGLE
dependency on video frame types encountered when video alone was disabled. The
workflow exposes both version inputs so a new upstream-supported pair can be
rebuilt and published without changing this repository.

## Publishing

Run **Build WPE WebKit SDK** from Actions. It builds natively on
`ubuntu-24.04` (`x86_64`) and `ubuntu-24.04-arm` (`aarch64`), produces checksums
and machine-readable metadata, and publishes/replaces the assets on the chosen
release tag. Start with two compilation jobs per architecture; WPE WebKit is
memory intensive.
