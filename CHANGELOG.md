# Changelog

All notable changes to this project.
Format loosely follows [Keep a Changelog](https://keepachangelog.com/).

## [2.1.4] — 2026-11-12

### Added
- **About dialog** (toolbar button / `--about`): shows the upstream project
  (spinningbanana / dvd-rtr-vmg0-splitter) and this fork (NingbingHG /
  dvdvr-splitter) with their GitHub avatars (circular crop) and clickable
  links, plus the GPL-3.0 note and the DZ-GX20 test device.

## [2.1.3] — 2026-11-12

### Changed
- Default output folder is now the Windows **Videos** known folder
  (`SHGetKnownFolderPath(FOLDERID_Videos)`; honours OneDrive redirection)
  instead of the disc folder / `Videos\DVD_OUT`.

### Added
- Warning when the output folder is on the **same drive as the input** (usually
  the optical drive, which is read-only): a Yes/No dialog before exporting, and
  an immediate heads-up when picking such a folder with `Browse…`.

## [2.1.2] — 2026-11-12

### Fixed
- Reading the VRO no longer dies with a raw `OSError: [Errno 22] Invalid argument`
  traceback when the source device disconnects mid-export. Reads are now done in
  64 KB chunks with 3 retries (re-seeking each time).
- The error message now names the real-world causes explicitly:
  **camcorder battery ran out / device powered off**, **loose or unplugged USB
  cable**, scratched disc, virtual drive dropped, incomplete image.
  (Observed on a Hitachi DZ-GX20 connected over USB: battery died at ~76 %.)

### Added
- `--skip-errors` / GUI checkbox「读取错误时跳过」: skip unreadable blocks and
  continue, logging each skipped offset.

## [2.1.1] — 2026-11-12

### Fixed
- Choosing an output folder on an optical/virtual drive raised
  `Traceback … OSError: [WinError 685]`. `os.access()` mis-reports such volumes
  as writable; the app now performs a real write test and shows a readable
  message ("output folder is not writable, pick a local disk folder").
- Output-directory validation also happens before an export starts, and in CLI
  mode, so no work is wasted.

## [2.1.0] — 2026-11-12

### Added
- Chinese / Japanese / English UI, switchable at runtime and persisted in
  `%APPDATA%\DVDVRSplitter\config.json`; `--lang zh|ja|en` and `DVDVR_LANG`.
- Output files are named after the **recording date/time stored in the IFO**
  (`2026-11-11_17-36-20.mpg`), with `program_NN.mpg` fallback and `_2` suffixes
  on collisions.
- System-language detection on first run (`GetUserDefaultUILanguage`).

## [2.0.0] — 2026-11-11

### Fixed
- **IFO parsing**: the upstream splitter treats offset `0x100` as a clip table.
  It is `pgit_sa`, the *Program Information Table*; `0x130` is `def_psi_sa`
  (title text). Scanning those bytes with the `0x6540`/`0x32A0` marker
  heuristic produced dozens of fake clips with 0 or 1-tick durations, so ffmpeg
  wrote empty `.mpg` files (27 of 30 on the test disc).
- Replaced time-based ffmpeg cutting with **contiguous byte-range extraction**
  using `vvob.vobu_map` (`vob_off`, `vobu_size[]`): lossless, VOBU-exact, and
  no ffmpeg dependency.

### Added
- Program list (recorded time, duration, size, VRO offset) with checkboxes.
- Worker-thread export with progress bar and Cancel.
- Explicit validation: wrong IFO type, damaged IFO, IFO/VRO mismatch, CPRM flag.
- Optional `--remux` (ffmpeg `-c copy`) for a cleaner MPEG-PS.
- CLI: `--list`, `--programs 1,2`, `-o`, `--remux`, `--ffmpeg`.

### Tested
- Hitachi DZ-GX20 (DVD-RAM, VR mode): 2 programs, 66.6 MB / 92.59 s;
  exports 1875 frames / 900 frames, byte-exact.
