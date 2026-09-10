#!/usr/bin/env python3
"""Professional slice, crossfade, and mastering script for Lyria-generated game audio cues.
Outputs 44.1kHz, 16-bit PCM WAV with equal-power crossfades and safe peak headroom.
"""

import math
from pathlib import Path
import numpy as np
import soundfile as sf

ROOT = Path(__file__).resolve().parents[1]
UPLOAD_DIR = Path(r"C:\Users\wjx19\.gemini\antigravity\brain\d2a6620a-4fd6-40fc-88af-adfdc8d6a13c\.user_uploaded")
OUT_DIR = ROOT / "art/audio/lyria_processed"
OUT_DIR.mkdir(parents=True, exist_ok=True)

SR = 44100

SRC_0 = UPLOAD_DIR / "uploaded_media_0_1789010068114.mp3"  # The Sterile Hour (Stage Tension)
SRC_1 = UPLOAD_DIR / "uploaded_media_1_1789010068114.mp3"  # Before The Lock (Final Two / Climax)
SRC_2 = UPLOAD_DIR / "uploaded_media_2_1789010068114.mp3"  # Green Room (Lounge / Lobby)
SRC_3 = UPLOAD_DIR / "uploaded_media_3_1789010068114.mp3"  # The Midnight Verdict (Showtime / Grand Reveal)


def load_audio(path: Path):
    data, sr = sf.read(str(path))
    if sr != SR:
        import scipy.signal
        num_samples = round(len(data) * float(SR) / sr)
        data = scipy.signal.resample(data, num_samples)
    return data


def equal_power_crossfade(data: np.ndarray, crossfade_sec: float = 2.0) -> np.ndarray:
    """Create a seamless loop by taking the tail and crossfading it into the head with equal-power curve."""
    fade_len = int(crossfade_sec * SR)
    if len(data) <= fade_len * 2:
        return data

    t = np.linspace(0, math.pi / 2, fade_len)
    fade_out = np.cos(t) ** 2
    fade_in = np.sin(t) ** 2

    if data.ndim > 1:
        fade_out = fade_out[:, np.newaxis]
        fade_in = fade_in[:, np.newaxis]

    tail = data[-fade_len:]
    head = data[:fade_len]

    blended_head = head * fade_in + tail * fade_out
    body = data[fade_len:-fade_len]

    return np.concatenate([blended_head, body], axis=0)


def normalize(data: np.ndarray, target_peak: float = 0.82) -> np.ndarray:
    peak = np.max(np.abs(data))
    if peak > 0:
        return (data / peak) * target_peak
    return data


def save_wav(data: np.ndarray, out_path: Path, mono: bool = False):
    if mono and data.ndim > 1:
        data = data.mean(axis=1)
    data = normalize(data)
    sf.write(str(out_path), data, SR, subtype="PCM_16")
    dur = len(data) / SR
    print(f"  -> Saved: {out_path.name} ({dur:.2f}s, {'Mono' if mono or data.ndim==1 else 'Stereo'}, {out_path.stat().st_size} bytes)")


def main():
    print("=== Processing Lyria Master Audio Cues ===")

    # ----------------------------------------------------
    # Cue 1: Stage Underscore BGM (The Sterile Hour)
    # ----------------------------------------------------
    print("\n1. Processing The Sterile Hour (Main Stage Tension BGM)...")
    d0 = load_audio(SRC_0)
    # Trim lead-in sub-100ms silence, take from 0.2s to 56.0s
    seg0 = d0[int(0.2 * SR) : int(56.0 * SR)]
    loop0 = equal_power_crossfade(seg0, crossfade_sec=2.0)
    save_wav(loop0, OUT_DIR / "bgm_stage_sterile_hour_loop.wav")

    # ----------------------------------------------------
    # Cue 2: Final Two / Climax BGM (Before The Lock)
    # ----------------------------------------------------
    print("\n2. Processing Before The Lock (Final Two & Countdown Climax)...")
    d1 = load_audio(SRC_1)
    # High-tension build section between 6.0s and 54.0s
    seg1 = d1[int(6.0 * SR) : int(54.0 * SR)]
    loop1 = equal_power_crossfade(seg1, crossfade_sec=2.0)
    save_wav(loop1, OUT_DIR / "bgm_final_two_lock_loop.wav")

    # Extract clean Heartbeat double-pulse from 1.0s to 1.96s
    hb = d1[int(0.6 * SR) : int(1.56 * SR)]
    # Soft linear fade-in and exponential fade-out
    fade_len = int(0.04 * SR)
    fi = np.linspace(0, 1, fade_len)
    fo = np.linspace(1, 0, int(0.12 * SR)) ** 2
    if hb.ndim > 1:
        fi = fi[:, np.newaxis]
        fo = fo[:, np.newaxis]
    hb[:fade_len] *= fi
    hb[-len(fo):] *= fo
    save_wav(hb, OUT_DIR / "pressure_heartbeat.wav", mono=True)

    # ----------------------------------------------------
    # Cue 3: Lounge / Green Room Chill BGM (Green Room)
    # ----------------------------------------------------
    print("\n3. Processing Green Room (Lounge / Waiting Area BGM)...")
    d2 = load_audio(SRC_2)
    # Start after warm intro (1.5s) to 175.0s
    seg2 = d2[int(1.5 * SR) : int(175.0 * SR)]
    loop2 = equal_power_crossfade(seg2, crossfade_sec=3.0)
    save_wav(loop2, OUT_DIR / "bgm_green_room_lounge_loop.wav")

    # ----------------------------------------------------
    # Cue 4: Showtime Fanfare & Grand Victory (The Midnight Verdict)
    # ----------------------------------------------------
    print("\n4. Processing The Midnight Verdict (Showtime Sting & Grand Victory)...")
    d3 = load_audio(SRC_3)

    # 4a: Showtime Sting (2.0s entrance punch)
    st = d3[int(0.0 * SR) : int(2.2 * SR)].copy()
    tail_len = int(0.4 * SR)
    exp_tail = (np.linspace(1, 0, tail_len) ** 2.5)
    if st.ndim > 1:
        exp_tail = exp_tail[:, np.newaxis]
    st[-tail_len:] *= exp_tail
    save_wav(st, OUT_DIR / "showtime_fanfare_sting.wav", mono=True)

    # 4b: Final Reveal / Climax Sting (from peak energy ~62.5s to 65.5s)
    rev = d3[int(62.6 * SR) : int(65.6 * SR)].copy()
    rev_tail = int(0.5 * SR)
    exp_rev = (np.linspace(1, 0, rev_tail) ** 2)
    if rev.ndim > 1:
        exp_rev = exp_rev[:, np.newaxis]
    rev[-rev_tail:] *= exp_rev
    save_wav(rev, OUT_DIR / "final_reveal_resolution.wav", mono=True)

    # 4c: Grand Victory Full Theme (14.5s celebratory crescendo from 115.0s to 129.5s)
    vic = d3[int(115.0 * SR) : int(129.5 * SR)].copy()
    vic_tail = int(1.2 * SR)
    vic_head = int(0.05 * SR)
    if vic.ndim > 1:
        vic[:vic_head] *= np.linspace(0, 1, vic_head)[:, np.newaxis]
        vic[-vic_tail:] *= (np.linspace(1, 0, vic_tail) ** 2)[:, np.newaxis]
    save_wav(vic, OUT_DIR / "grand_victory_theme.wav")

    print("\nAll master cues processed and mastered successfully!")


if __name__ == "__main__":
    main()
