# apac-decode

Decode the **spatial audio** track of iPhone recordings — Apple Positional
Audio Codec (APAC) — into ordinary 4-channel first-order-ambisonics WAV/CAF,
**without needing a Mac**. The decoding runs on a GitHub-hosted macOS runner.

iPhones (16 and later) that record "spatial audio" write two audio tracks
into every video: a stereo AAC everyone can read, and a 4-channel APAC track
holding the full ambisonic sound field (ambiX / ACN-SN3D, W-Y-Z-X). Nothing
outside Apple's ecosystem can decode APAC — FFmpeg reports `unknown codec` —
so the spatial track is unreachable on Linux/Windows. This repo makes GitHub
do the Apple part.

## Browser-only usage (no tools needed)

1. Go to **Releases → Draft a new release** in this repo.
2. Give it any tag (e.g. `convert-2026-07-25`), and **attach your `.mov` /
   `.m4a` files** as release assets (up to 2 GB each).
3. **Publish** the release. The *Decode APAC to FOA* action starts
   automatically (watch it under the Actions tab, ~1–3 min).
4. Reload the release page: `*_foa.wav` (24-bit) and `*_foa.caf` (float32)
   are attached next to your originals. Download and delete the release if
   you don't want to keep it.

> **Privacy: this is a public repository.** Anything you attach to a release
> is publicly visible. Do not upload recordings with sensitive content or
> identifiable bystander speech — publish features, not audio. For private
> material, fork this repo as *private* (macOS Actions minutes are metered
> there, but occasional conversions are cheap) or use a Mac directly.

## With a Mac (no repo needed)

macOS 15+ decodes APAC natively:

```bash
afconvert -f WAVE -d LEI24@48000 IMG_1234.MOV IMG_1234_foa.wav
```

If `afconvert` refuses the container, `decode-apac.swift` in this repo does
the same via AVFoundation: `swift decode-apac.swift in.mov out.caf`.

## What you get, and what to do with it

A 4-channel first-order ambisonics file (ambiX, W-Y-Z-X). Use it for:

- **Soundscape analysis** with [ambiscape](https://github.com/fourMs/ambiscape)
  (4-channel input switches on the spatial layer: diffuseness, azimuth,
  elevation, per-event direction of arrival);
- **Joint audio-visual analysis** with
  [MGT-python](https://github.com/fourMs/MGT-python)
  (see [Working with ambiscape](https://github.com/fourMs/MGT-python/wiki/13-%E2%80%90-Working-with-ambiscape));
- **Binaural monitoring / rotation** in any ambisonics toolchain (e.g.
  Reaper + IEM plugins).

Keep the original `.mov` too — it is the only copy of the encoded sound
field, and the APAC track survives only transfers that preserve originals
(AirDrop, Files, USB; *not* chat apps or "compatible" exports).

## Notes

- Runner: `macos-15` (APAC needs macOS 15+). Public-repo Actions are free.
- The workflow also fires manually (Actions → *Decode APAC to FOA* → Run
  workflow) on any `.mov`/`.m4a` committed to the repo root — handy for
  small files (<100 MB via git, <25 MB via web upload).
- Background: [Apple's APAC overview (PDF)](https://developer.apple.com/av-foundation/Apple-Positional-Audio-Codec.pdf);
  the format's history and workflows are written up on
  [arj.no](https://www.arj.no).

---
A tool from the [fourMs Lab](https://github.com/fourMs), RITMO / University of Oslo.
