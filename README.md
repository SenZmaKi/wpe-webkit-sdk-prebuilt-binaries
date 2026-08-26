# WPE WebKit SDK prebuilt binaries

Versioned Linux SDK/runtime archives for Flutter apps using
[`flutter_inappwebview_linux`](https://pub.dev/packages/flutter_inappwebview_linux).

Each prerelease contains native `x86_64` and `aarch64` archives with the WPE
WebKit shared library, libwpe, WPE Platform metadata, headers, pkg-config files,
and the WPE inspector resource. Extract an archive at `/` before running
`flutter build linux`:

```sh
sudo tar -xJf Senpwai-WPE-SDK-<version>-linux-<architecture>.tar.xz -C /
sudo ldconfig
flutter build linux --release
```

The Flutter plugin copies the required WPE shared libraries into the resulting
application bundle, so end users do not install this SDK.

## Supported baseline

The defaults intentionally follow the current upstream Linux backend build
instructions: **WPE WebKit 2.50.4** and **libwpe 1.16.3**, using the modern
WPE Platform headless backend. The workflow exposes both version inputs so a
new upstream-supported pair can be rebuilt and published without changing this
repository.

## Publishing

Run **Build WPE WebKit SDK** from Actions. It builds natively on
`ubuntu-24.04` (`x86_64`) and `ubuntu-24.04-arm` (`aarch64`), produces checksums
and machine-readable metadata, and publishes/replaces the assets on the chosen
prerelease tag. Start with two compilation jobs per architecture; WPE WebKit is
memory intensive.

The `wpe-sdk-2.53.3-local` release is a migrated, locally validated Senpwai
build for compatibility testing. It is not the documented plugin baseline.
