--!strict
-- Creator Store partner defaults; metadata checked, native playback still needs Studio QA.
-- Fill OriginalUploads with WAV IDs owned/authorized by your experience. Keep partner defaults as fallback.
-- Sources, publishers and limitations are recorded in art/audio/library-manifest.json.
return table.freeze({
	Sounds={
		Click="rbxasset://sounds/switch.wav", Tick="rbxasset://sounds/switch.wav",
		Claim="rbxassetid://9116324156", Breach="rbxassetid://9116604303",
		Offer="rbxassetid://9119882039", Impact="rbxassetid://9119882039",
		Heartbeat="rbxassetid://9119882039", -- low synth pulse; original double heartbeat is an upload override
		Cheer="rbxassetid://9112766176", Gasp="rbxassetid://9125572450",
		Music="rbxassetid://1837835644", Reveal="rbxassetid://1844584698",Showtime="rbxassetid://1844584698",
	},
	OriginalUploads={Claim="",Breach="",Offer="",Heartbeat="",Tick="",Reveal="",Showtime="",Impact="",Music=""},
	Volume=.45,
	Mix={UI=.55,SFX=.75,CROWD=.40,MUSIC=.20},
	ClipSeconds={Claim=1.4,Breach=1.2,Offer=.7,Impact=.9,Cheer=1.7,Gasp=1.5,Reveal=3,Showtime=1.2,Tick=.12},
})
