#!/usr/bin/env python3
"""Generate broadcast game show cues and background music using Google DeepMind Lyria models.

Prerequisites:
  pip install google-genai soundfile numpy
  Set GEMINI_API_KEY environment variable or pass --api-key <YOUR_KEY>

Usage:
  # Check prompts and available cues
  python scripts/generate-lyria-audio.py --list

  # Generate a specific cue with Lyria
  python scripts/generate-lyria-audio.py --cue Music --api-key YOUR_API_KEY

  # Generate all cues to art/audio/lyria/
  python scripts/generate-lyria-audio.py --all --api-key YOUR_API_KEY

  # Generate and replace production WAVs + update manifest.json
  python scripts/generate-lyria-audio.py --all --replace-cues --api-key YOUR_API_KEY
"""

import argparse
import base64
import hashlib
import io
import json
import os
import sys
import wave
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DEFAULT_OUT = ROOT / 'art/audio/lyria'
PRODUCTION_OUT = ROOT / 'art/audio'
SAMPLE_RATE = 44100

LYRIA_PROMPTS = {
    'Music': {
        'file': 'low-drone-pulse.wav',
        'duration': 8.0,
        'model': 'lyria-3-clip-preview',
        'prompt': (
            'Low ambient tension drone loop, 80 BPM subtle rhythmic sub-bass pulse, '
            'dark industrial broadcast game show background atmosphere, subdued analog synth pad, '
            'clean seamless loop boundaries, no vocals, no drums.'
        ),
        'description': 'Original low drone pulse for suspenseful rounds, loopable.',
    },
    'Showtime': {
        'file': 'showtime-sting.wav',
        'duration': 2.0,
        'model': 'lyria-3-clip-preview',
        'prompt': (
            'Cinematic television broadcast game show intro sting, punchy brass accent followed by '
            'warm synthesizer swell, dramatic entrance fanfare, spotlight reveal audio cue, no vocals.'
        ),
        'description': 'Contestant entrance sting as lights come up.',
    },
    'Impact': {
        'file': 'vault-impact.wav',
        'duration': 1.0,
        'model': 'lyria-3-clip-preview',
        'prompt': (
            'Heavy sub-bass impact boom, dramatic metallic thud, game show loss stinger, '
            'deep damped bass drop expressing disappointment, cinematic impact.'
        ),
        'description': 'High value vault elimination impact.',
    },
    'Offer': {
        'file': 'curator-offer.wav',
        'duration': 1.5,
        'model': 'lyria-3-clip-preview',
        'prompt': (
            'Suspenseful television game show electronic offer tone, three-tone ascending modern chime, '
            'crisp digital synth sparkle, tension lock-in signal.'
        ),
        'description': 'Curator quote reveal and counter lock-in signal.',
    },
    'Heartbeat': {
        'file': 'pressure-heartbeat.wav',
        'duration': 1.0,
        'model': 'lyria-3-clip-preview',
        'prompt': (
            'Deep biological double heartbeat pulse, lub-dub low frequency vibration, '
            'intense countdown pressure sound effect, loop-friendly, 100 BPM.'
        ),
        'description': 'Critical 5-second countdown heartbeat.',
    },
    'Tick': {
        'file': 'pressure-tick.wav',
        'duration': 0.25,
        'model': 'lyria-3-clip-preview',
        'prompt': (
            'Single crisp mechanical chronometer tick, metallic clock escapement click, high precision audio accent.'
        ),
        'description': 'Second-by-second countdown clock tick.',
    },
    'Reveal': {
        'file': 'final-reveal.wav',
        'duration': 2.5,
        'model': 'lyria-3-clip-preview',
        'prompt': (
            'Climactic game show finale reveal sting, building cymbal swell into radiant electronic chord, '
            'triumphant suspense resolution, cinematic broadcast finish.'
        ),
        'description': 'Final vault opening and prize reveal sting.',
    },
    'Claim': {
        'file': 'claim-lock.wav',
        'duration': 0.5,
        'model': 'lyria-3-clip-preview',
        'prompt': (
            'Heavy vault door pneumatic lock engaging, double metal click and magnetic lock latching shut, mechanical.'
        ),
        'description': 'Initial vault selection latch.',
    },
    'Breach': {
        'file': 'vault-breach.wav',
        'duration': 2.0,
        'model': 'lyria-3-clip-preview',
        'prompt': (
            'Heavy bank vault wheel turning, pressurized air release hiss, mechanical gears sliding and heavy door creak.'
        ),
        'description': 'Vault opening sequence sound.',
    },
}

def convert_to_standard_wav(raw_bytes: bytes, target_path: Path, target_seconds: float = None):
    target_path.parent.mkdir(parents=True, exist_ok=True)
    try:
        import soundfile as sf
        import numpy as np

        data, sr = sf.read(io.BytesIO(raw_bytes))
        if len(data.shape) > 1:
            data = data.mean(axis=1)

        if sr != SAMPLE_RATE:
            import scipy.signal
            num_samples = round(len(data) * float(SAMPLE_RATE) / sr)
            data = scipy.signal.resample(data, num_samples)

        if target_seconds:
            target_samples = round(target_seconds * SAMPLE_RATE)
            if len(data) > target_samples:
                data = data[:target_samples]
            elif len(data) < target_samples:
                data = np.pad(data, (0, target_samples - len(data)))

        peak = np.max(np.abs(data))
        if peak > 0:
            data = (data / peak) * 0.70

        sf.write(str(target_path), data, SAMPLE_RATE, subtype='PCM_16')
    except Exception as exc:
        print(f"  Note: soundfile conversion ({exc}), writing raw stream...")
        target_path.write_bytes(raw_bytes)

def call_lyria(client, prompt: str, model: str = 'lyria-3-clip-preview') -> bytes:
    try:
        if hasattr(client, 'interactions') and hasattr(client.interactions, 'create'):
            res = client.interactions.create(model=model, input=prompt)
            if hasattr(res, 'output_audio') and res.output_audio:
                audio_data = res.output_audio.data
                if isinstance(audio_data, str):
                    return base64.b64decode(audio_data)
                return audio_data
    except Exception as err:
        print(f"  [interactions.create note]: {err}")

    try:
        from google.genai import types
        res = client.models.generate_content(
            model=model if 'gemini' in model else 'gemini-2.5-flash',
            contents=prompt,
            config=types.GenerateContentConfig(response_modalities=['AUDIO'])
        )
        for part in res.candidates[0].content.parts:
            if hasattr(part, 'inline_data') and part.inline_data:
                return base64.b64decode(part.inline_data.data)
    except Exception as err:
        print(f"  [models.generate_content note]: {err}")

    raise RuntimeError(
        f"Unable to generate audio with model '{model}'. Please verify that your API Key "
        f"has access to the Lyria preview or Gemini Audio generation API."
    )

def update_production_manifest():
    manifest_path = PRODUCTION_OUT / 'manifest.json'
    if not manifest_path.exists():
        return

    data = json.loads(manifest_path.read_text(encoding='utf-8'))
    for item in data.get('cues', []):
        file_path = PRODUCTION_OUT / item['file']
        if file_path.exists():
            content = file_path.read_bytes()
            item['sha256'] = hashlib.sha256(content).hexdigest()
            with wave.open(str(file_path), 'rb') as wf:
                item['seconds'] = round(wf.getnframes() / wf.getframerate(), 2)

    manifest_path.write_text(json.dumps(data, indent=2) + '\n', encoding='utf-8')
    print("Updated art/audio/manifest.json with new hashes and durations.")

def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('--list', action='store_true', help='List all available cues and their prompts')
    parser.add_argument('--cue', type=str, choices=list(LYRIA_PROMPTS.keys()), help='Specific cue to generate')
    parser.add_argument('--all', action='store_true', help='Generate all audio cues')
    parser.add_argument('--api-key', type=str, default=os.getenv('GEMINI_API_KEY', ''), help='Google AI / Gemini API Key')
    parser.add_argument('--out-dir', type=Path, default=DEFAULT_OUT, help='Output directory (default: art/audio/lyria)')
    parser.add_argument('--replace-cues', action='store_true', help='Directly overwrite art/audio/*.wav and update manifest')

    args = parser.parse_args()

    if args.list:
        print("=== Vault Breakers Lyria Audio Prompts ===")
        for key, info in LYRIA_PROMPTS.items():
            print(f"[{key}] -> {info['file']} ({info['duration']}s)")
            print(f"  Prompt: {info['prompt']}\n")
        return

    if not args.cue and not args.all:
        parser.print_help()
        print("\n[Tip] Run with --list to see all cues, or --cue Music --api-key YOUR_KEY to test.")
        return

    api_key = args.api_key.strip()
    if not api_key:
        print("=" * 60)
        print("ERROR: Missing API Key.")
        print("To generate music and cues with Google DeepMind Lyria:")
        print("  1. Get an API key from Google AI Studio: https://aistudio.google.com/")
        print("  2. Run the script with --api-key:")
        print("     python scripts/generate-lyria-audio.py --cue Music --api-key AIzaSy...")
        print("  Or set the environment variable:")
        print("     $env:GEMINI_API_KEY = 'AIzaSy...'")
        print("=" * 60)
        sys.exit(1)

    try:
        from google import genai
        client = genai.Client(api_key=api_key)
    except Exception as exc:
        print(f"Failed to initialize google-genai Client: {exc}")
        sys.exit(1)

    cues_to_generate = list(LYRIA_PROMPTS.keys()) if args.all else [args.cue]
    dest_dir = PRODUCTION_OUT if args.replace_cues else args.out_dir
    dest_dir.mkdir(parents=True, exist_ok=True)

    print(f"Starting Lyria generation for {len(cues_to_generate)} cue(s)... Target directory: {dest_dir}")

    for cue_key in cues_to_generate:
        info = LYRIA_PROMPTS[cue_key]
        out_file = dest_dir / info['file']
        print(f"\n[Generating] {cue_key} -> {info['file']}...")
        print(f"  Prompt: {info['prompt']}")
        try:
            raw_audio = call_lyria(client, info['prompt'], model=info['model'])
            convert_to_standard_wav(raw_audio, out_file, target_seconds=info['duration'])
            print(f"  [Success] Saved to {out_file} ({out_file.stat().st_size} bytes)")
        except Exception as exc:
            print(f"  [Failed] {cue_key}: {exc}")

    if args.replace_cues:
        update_production_manifest()

    print("\nDone!")

if __name__ == '__main__':
    main()
