# Lidless (publik fork)

[![Downloads](https://img.shields.io/github/downloads/Blueturboguy07/Lidless/total)](https://github.com/Blueturboguy07/Lidless/releases)
[![Ko-fi](https://img.shields.io/badge/Ko--fi-Support%20the%20original%20author-FF5E5B?logo=ko-fi&logoColor=white)](https://ko-fi.com/nghialuong)

A tiny macOS menu-bar app that keeps your Mac running **even with the lid closed** —
so coding agents (Claude Code, Codex, etc.) keep working while you move around.

> Open source under the [MIT License](LICENSE). Lidless is by
> [Nghia Luong](https://github.com/nghialuong/Lidless); this fork is maintained for
> [publik](https://publikhq.com/lidless) and ships its own signed, notarized builds.

## What this fork fixes

**"I installed Lidless and the menu never opens."** On a MacBook with a crowded
menu bar, macOS puts the *newest* status item leftmost — which on notched
MacBooks is *behind the camera housing*. The icon exists (accessibility can press
it) but no click can reach it, and the first-run Welcome window opened *behind*
whatever you had in front, so the app looked dead. Reproduced on a fresh 0.1.3
install with 12 other menu-bar items: the Lidless item sat at x 754–790 on a bar
whose notch spans x 663–848.

- **Notch detection.** Lidless now checks where its status item actually landed
  (`MenuBarIconMonitor`, pure geometry in `MenuBarIconVisibility`) and says so —
  at the end of onboarding, in Settings, and inside the menu itself.
- **⌃⌥L opens the menu from anywhere.** A global shortcut (Carbon hotkey, no
  Accessibility permission needed) so the menu is reachable even when the icon
  isn't. Onboarding and Settings also get an *Open the Lidless menu* button.
- **The Welcome window shows up in front.** Since macOS 14 an accessory app
  can't force activation; the window is now ordered front regardless.
- **No app-modal alert from a timer.** "Restart to finish connecting the helper"
  could pop up to 30 s after approval as an app-modal alert, freezing the
  menu-bar icon (possibly behind another app). It's a sheet on our own window now.

Everything else — the root helper, watchdog, safety guards, timer, Sparkle — is
upstream Lidless, unchanged. Bundle id is `com.publikhq.lidless` (helper
`com.publikhq.lidless.helper`), signed with publik's Developer ID, updates from
this repo's own appcast.

<p align="center">
  <img src="docs/menu-popover.png" alt="Lidless menu bar popover — keep-awake toggle, helper status, battery, and safety controls" width="420">
</p>

## Features

- One-click **keep awake with the lid closed** (menu bar toggle).
- Privileged background **helper** (`SMAppService`) so toggling never asks for a password.
- **Watchdog**: if the app crashes or is force-quit, the helper auto-restores normal sleep — the Mac can't get stuck awake.
- **Safety guards**: pause when running hot, only-while-charging, and a low-battery cutoff.
- **Auto-off timer**: optionally turn keep-awake off after 15 min – 4 hours, with a live countdown.
- **Automatic updates** via [Sparkle](https://sparkle-project.org) — EdDSA-signed appcast, notarized DMGs.
- **Launch at login**, and a clean menu with battery/power status.

## How it works

macOS sleeps when you close the lid. The reliable way to override that on Apple Silicon
is the `SleepDisabled` flag in `IOPMrootDomain` (what `sudo pmset -a disablesleep 1` sets).
`caffeinate` does **not** prevent lid-close sleep — only this flag does.

The app talks to a root helper over XPC; the helper flips the flag with no admin prompt and
runs a heartbeat watchdog. If the app stops checking in (>90s), the helper restores sleep.

## Architecture

- **`Lidless`** — SwiftUI `MenuBarExtra` app (macOS 13+), not sandboxed, `LSUIElement`.
- **`LidlessHelper`** — root LaunchDaemon, registered via `SMAppService`, serves `LidlessHelperProtocol` over XPC. Embedded at `Contents/MacOS/LidlessHelper` with its plist in `Contents/Library/LaunchDaemons/`.
- **`Sources/Shared`** — pure, unit-tested logic: pmset parsers, watchdog, safety evaluator, settings.

## Build (no Xcode GUI needed)

Requires the Xcode command-line tools + [XcodeGen](https://github.com/yonaskolb/XcodeGen).

```bash
xcodegen generate
xcodebuild test -scheme Lidless-CI -destination 'platform=macOS' | xcbeautify
```

The `.xcodeproj` is gitignored — `project.yml` is the source of truth.

## App icon

The app icon and the menu-bar glyphs are committed assets under
`Resources/Assets.xcassets/` (`AppIcon.appiconset` plus the `MenubarLaptop` /
`MenubarLaptopActive` template imagesets that mark keep-awake off / on).

`scripts/make_iconset.sh` is kept as a helper for regenerating an icon set from a
single master if you want to swap the artwork:

```bash
bash scripts/make_iconset.sh   # renders icon + emits Assets.xcassets/AppIcon.appiconset
```

## Release

Signed + notarized DMG plus the EdDSA-signed Sparkle appcast (needs a Developer ID
cert, a notarytool keychain profile, and the Sparkle signing key in the keychain):

```bash
./scripts/release.sh   # archive → export → notarize → staple → DMG → appcast → publish
```

Publishes the DMG to a GitHub Release and writes the feed to `docs/appcast.xml`
(served at the `SUFeedURL` in `project.yml`).

## Milestones

- **M0** — spike, verified lid-closed on real Apple Silicon (`scripts/lidless.sh`). ✅
- **M1 / M1.5** — menu-bar app + privileged helper + XPC + watchdog. ✅
- **M2** — safety preferences (thermal / charging / battery) + persistence. ✅
- **App complete** — icon, launch-at-login, onboarding, About, release pipeline. ✅
- **Auto-update** — Sparkle with an EdDSA-signed appcast, shipped from `release.sh`. ✅
- **Later** — signed runtime verification on device.
- **publik fork** — hidden-icon detection, ⌃⌥L, front Welcome window, non-blocking helper prompt. ✅

## Safety

Running with the lid closed under heavy load can heat the machine and drain the battery.
Keep it plugged in and ventilated. The safety guards auto-pause on heat / low battery,
and a reboot always resets the underlying flag.

To report a security issue, see [SECURITY.md](SECURITY.md).

## Sign in with publik

Lidless opens with Sign in with publik, before the Welcome window. The publik
module (`Sources/Lidless/Publik.swift`, from
<https://publikhq.com/skills/setup.md>) holds the gate. At the first start on a
Mac it provisions an install key with the build's app token
(`POST /api/v1/installs`), opens the claim link in the browser, and polls
`GET /api/v1/wallet` every 3 seconds, up to 10 minutes, until the install is
claimed by a publik account. Without a connection it says "publik is not
reachable. Check your connection." and offers Retry. Until the sign-in is done
the menu bar popover offers only Sign in with publik and Quit. Lidless uses no
AI, so there is no plan screen and no key to choose.

The same module sends usage counts: `app_opened` at launch and `active_session`
every 30 minutes while it runs, with the install key as the bearer. Each event
holds the app name, the app version, the operating system, the CPU type and a
random install ID. Nothing else is sent: no settings, no power or battery data.
To turn it off, set `DO_NOT_TRACK=1` in the environment that starts Lidless.
Details and the other ways to opt out: <https://publikhq.com/skills/telemetry.md>

A built app proves the gate is on its start-up path with the self-test:
`PUBLIK_SELF_TEST=1 Lidless.app/Contents/MacOS/Lidless` prints
`publik self-test: ok lidless <version>` after one real `GET /api/v1/wallet`,
then exits. `scripts/release.sh` runs it on the exported app before it
notarizes.

## Support

Lidless is free and open source. If it saves you some hassle, you can
[buy me a coffee on Ko-fi](https://ko-fi.com/nghialuong) ☕ — completely optional,
and much appreciated.

## License

[MIT](LICENSE) © 2026 Nghia Luong. Fork changes © 2026 publik, same license.
