#!/usr/bin/env python3
"""Original, sample-free industrial show cues. Python standard library only.
No speech or third-party recordings. Includes an original loop-friendly drone and broadcast stings. Mono PCM WAV, 44.1 kHz / 16 bit.
Use --check to validate the delivered files and their manifest without regenerating.
"""
from pathlib import Path
import argparse
import array
import hashlib
import json
import math
import random
import sys
import wave

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'art/audio'
RATE=44100
TAU=math.tau

def pulse(t,at,freq,decay=28,amplitude=1):
    x=t-at
    if x<0:return 0.0
    return amplitude*(1-math.exp(-x*600))*math.exp(-x*decay)*math.sin(TAU*(freq*x+2.8*(1-math.exp(-x*24))))

def render(kind,duration):
    rng=random.Random(93013+len(kind));low=0.0;values=[]
    for i in range(round(duration*RATE)):
        t=i/RATE;n=rng.uniform(-1,1);low=.975*low+.025*n
        if kind=='Claim':
            y=pulse(t,0,310,38,.48)+pulse(t,.09,173,32,.6)+(n-low)*math.exp(-t*58)*.09
        elif kind=='Breach':
            y=low*.48*math.sin(math.pi*t/duration)**2
            for at in [0,.045,.10,.16,.24,.34]:y+=pulse(t,at,128+at*110,52,.36)
            y+=pulse(t,.40,62,5,.14)+pulse(t,1.06,71,20,.45)
            y+=(n-low)*.025*math.exp(-((t-.73)/.32)**2)
        elif kind=='Offer':
            y=pulse(t,0,220,8,.5)+pulse(t,.14,330,9,.24)+pulse(t,.29,440,12,.13)
        elif kind=='Heartbeat':
            y=pulse(t,.05,59,26,.7)+pulse(t,.24,66,32,.39)
        elif kind=='Tick':
            y=pulse(t,0,840,79,.42)+pulse(t,.009,1230,91,.08)+n*.035*math.exp(-t*90)
        elif kind in ('Reveal','Showtime'):
            y=pulse(t,0,130.81,4,.30)+pulse(t,.16,196,5,.25)+pulse(t,.32,261.63,4,.23)+pulse(t,.48,329.63,4,.17)
            y+=pulse(t,.62,523.25,6,.12)+pulse(t,.64,65.41,5,.28)+low*.08*math.exp(-t*4)
        elif kind=='Impact':
            y=pulse(t,0,48,8,.8)+pulse(t,.025,73,12,.3)+low*.5*math.exp(-t*18)
        elif kind=='Music':
            envelope=.75+.20*math.sin(TAU*t/duration)
            y=(math.sin(TAU*55*t)*.11+math.sin(TAU*82.5*t)*.065+math.sin(TAU*110*t)*.028)*envelope
            for beat in range(int(duration)):y+=pulse(t,beat+.02,55,15,.075)
            y+=low*.015
        else:raise ValueError(kind)
        fade=min(1,t/.004,max(0,(duration-t)/.018))
        values.append(y*fade)
    peak=max(abs(v) for v in values)
    pcm=array.array('h',(round(max(-1,min(1,v/peak*.64))*32767) for v in values))
    if sys.byteorder!='little':pcm.byteswap()
    return pcm.tobytes()

CUES=[
    ('Claim','claim-lock.wav',.34,'Claim latches shut; two small mechanical contacts.'),
    ('Breach','vault-breach.wav',1.35,'Lock retraction, subdued rotation, then a damped stop.'),
    ('Offer','curator-offer.wav',.82,'A restrained three-part broadcast signal, not a jackpot flourish.'),
    ('Heartbeat','pressure-heartbeat.wav',.96,'Low double pulse with clean silent loop boundaries.'),
    ('Tick','pressure-tick.wav',.13,'Short, softened clock contact.'),
    ('Reveal','final-reveal.wav',1.65,'Short original broadcast resolution sting; completion, not a luck-based decision grade.'),
    ('Showtime','showtime-sting.wav',1.2,'Skippable entrance sting with no spoken voice.'),
    ('Impact','vault-impact.wav',.7,'One low, damped impact; no piercing alarm or strobe.'),
    ('Music','low-drone-pulse.wav',8,'Original low drone pulse with silent loop boundaries; keep below speech and important cues.'),
]

def check():
    manifest=json.loads((OUT/'manifest.json').read_text())
    for item in manifest['cues']:
        path=OUT/item['file']
        assert hashlib.sha256(path.read_bytes()).hexdigest()==item['sha256'],path
        with wave.open(str(path),'rb') as f:
            assert (f.getnchannels(),f.getsampwidth(),f.getframerate())==(1,2,RATE),path
            assert abs(f.getnframes()/RATE-item['seconds'])<1/RATE,path
            samples=array.array('h',f.readframes(f.getnframes()))
        assert max(abs(s) for s in samples)<24000,path
    print(f"PASS: {len(manifest['cues'])} original WAV cues, format/duration/headroom/SHA-256 verified.")

def main():
    parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('--check',action='store_true');args=parser.parse_args()
    if args.check:check();return
    OUT.mkdir(parents=True,exist_ok=True)
    cues=[]
    for kind,name,duration,description in CUES:
        path=OUT/name
        with wave.open(str(path),'wb') as f:
            f.setnchannels(1);f.setsampwidth(2);f.setframerate(RATE);f.writeframes(render(kind,duration))
        cues.append({'key':kind,'file':name,'seconds':duration,'description':description,'sha256':hashlib.sha256(path.read_bytes()).hexdigest()})
    manifest={'origin':'Procedural original synthesis; no third-party samples','generator':'scripts/generate-audio.py','sampleRate':RATE,'channels':1,'bitsPerSample':16,'cues':cues}
    (OUT/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
    check()
if __name__=='__main__':main()
