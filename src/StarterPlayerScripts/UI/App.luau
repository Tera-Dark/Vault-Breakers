--!nonstrict
local UI=require(script.Parent.Components)
local Locale=require(script.Parent.Locale)
local Lobby=require(script.Parent.LobbyView)
local Run=require(script.Parent.RunView)
local Result=require(script.Parent.ResultView)
local Overlay=require(script.Parent.OverlayView)
local Numbers=require(game:GetService("ReplicatedStorage").VaultBreakers.Config.RewardPool)
local C=UI.colors
local App={}
App.__index=App
function App.new(playerGui,model,actions)
	local self=setmetatable({model=model,actions=actions,overlayMode=nil,toastToken=0},App)
	self.gui=UI.new("ScreenGui",playerGui,{Name="VaultBreakersUI",ResetOnSpawn=false,ZIndexBehavior=Enum.ZIndexBehavior.Sibling,IgnoreGuiInset=false})
	self.root=UI.frame(self.gui,"SafeArea",C.Ink);self.root.BackgroundTransparency=1;self.root.Size=UDim2.fromScale(1,1)
	self.lobbyScroll=UI.new("ScrollingFrame",self.root,{Name="LoungePage",Size=UDim2.fromScale(1,1),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=3,ScrollBarImageColor3=C.Line,CanvasSize=UDim2.new(),ScrollingDirection=Enum.ScrollingDirection.Y})
	self.lobby=Lobby.new(self.lobbyScroll,actions)
	self.run=Run.new(self.root,actions)
	self.waiting=UI.card(self.root,"WaitingForStage",C.Ink);self.waiting.Visible=false;self.waiting.ZIndex=25
	self.waitingTitle=UI.text(self.waiting,"Heading","",20,C.Ivory,true)
	self.waitingBody=UI.text(self.waiting,"Description","",13,C.Muted)
	self.result=Result.new(self.root,actions)
	self.header=UI.card(self.root,"BroadcastHeader",C.Ink);self.header.ZIndex=20
	self.mark=UI.mark(self.header,"BrandMark",C.Amber)
	self.wordmark=UI.text(self.header,"Wordmark","VAULT\nBREAKERS",13,C.Ivory,true)
	self.status=UI.text(self.header,"StudioStatus","",11,C.Amber,true)
	self.wallet=UI.text(self.header,"Credits","",13,C.Ivory,true);self.wallet.TextXAlignment=Enum.TextXAlignment.Right
	self.population=UI.text(self.header,"Population","",10,C.Muted);self.population.TextXAlignment=Enum.TextXAlignment.Right
	self.helpButton=UI.button(self.header,"HowToPlay","?","secondary",function()
		if model.touch and model.directory and (model.directory.myArena or model.directory.view)~="LOBBY" then actions.leave() else actions.overlay("HOW") end
	end)
	self.boardButton=UI.button(self.header,"StudioRecords","","secondary",function()actions.overlay("BOARD")end)
	for i=1,3 do local bar=UI.frame(self.boardButton,"ChartBar",C.Muted);UI.place(bar,10+(i-1)*9,30-i*5,5,6+i*5) end
	self.settingsButton=UI.button(self.header,"Preferences","","secondary",function()actions.overlay("SETTINGS")end)
	for i=1,3 do
		local line=UI.frame(self.settingsButton,"Slider",C.Muted);UI.place(line,11,10+i*6,22,1)
		local knob=UI.frame(self.settingsButton,"Knob",C.Muted);UI.place(knob,if i==2 then 24 else 15,8+i*6,3,5)
	end
	self.banner=UI.card(self.root,"PersistenceNotice",C.Ink);self.banner.ZIndex=22;self.banner.Visible=false
	self.bannerText=UI.text(self.banner,"Notice","",11,C.Amber)
	self.toast=UI.card(self.root,"Toast",C.Panel);self.toast.ZIndex=120;self.toast.Visible=false
	self.toastText=UI.text(self.toast,"Message","",14,C.Ivory)
	self.overlay=Overlay.new(self.root,actions)
	self.root:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()self:resize()end)
	task.defer(function()self:resize();self:render()end)
	return self
end
function App:t(key,args) return Locale.text(self.model.settings.language,key,args) end
function App:resize()
	local size=self.root.AbsoluteSize
	local w,h=math.max(320,size.X),math.max(260,size.Y)
	self.w,self.h=w,h
	UI.place(self.header,16,12,w-32,54)
	UI.place(self.mark,14,13,28,28);UI.place(self.wordmark,54,9,89,36)
	local right=w-32
	UI.place(self.helpButton,right-152,5,44,44);UI.place(self.boardButton,right-102,5,44,44);UI.place(self.settingsButton,right-52,5,44,44)
	self.wallet.Visible,self.population.Visible=w>=650,w>=650
	UI.place(self.wallet,right-330,9,159,20);UI.place(self.population,right-330,31,159,15)
	self.status.Visible=w>=850;UI.place(self.status,163,12,math.max(110,w-540),30)
	self.lobby:resize(w,h)
	local height=self.lobby.contentHeight or h
	self.lobbyScroll.CanvasSize=UDim2.fromOffset(0,height);self.lobbyScroll.ScrollingEnabled=height>h
	self.lobby.root.Size=UDim2.new(1,0,0,height)
	self.run.touch=self.model.touch;self.run:resize(w,h);self.result:resize(w,h);self.overlay:resize(w,h)
	local waitingW=math.min(440,w-40)
	UI.place(self.waiting,(w-waitingW)/2,(h-112)/2,waitingW,112)
	UI.place(self.waitingTitle,20,16,waitingW-40,30);UI.place(self.waitingBody,20,51,waitingW-40,45)
	UI.place(self.banner,20,h-31,w-40,25);UI.place(self.bannerText,10,0,w-60,25)
	local toastW=math.min(560,w-40)
	UI.place(self.toast,(w-toastW)/2,76,toastW,62);UI.place(self.toastText,16,8,toastW-32,46)
	if self.model then self:render() end
end
function App:render()
	local model=self.model
	local t=function(key,args)return self:t(key,args)end
	UI.reducedMotion=model.settings.reducedMotion
	local directory=model.directory
	local view=directory and (directory.myArena or directory.view) or "LOBBY"
	local inRun=view~="LOBBY" and model.snapshot~=nil
	self.lobbyScroll.Visible=view=="LOBBY"
	self.waiting.Visible=model.syncing==true
	self.waitingTitle.Text,self.waitingBody.Text=t("sync_stage"),t("sync_stage_body")
	self.helpButton.Text=if model.touch and inRun then "←" else "?"
	self.run.root.Visible=inRun and model.snapshot.state~="RESULT" and not model.showRecap
	self.lobby:render(model,t)
	if inRun then self.run:render(model,t) end
	self.result:render(model,t)
	if not inRun and not model.showRecap then self.result.root.Visible=false end
	local p=model.profile or {}
	self.wallet.Text=Numbers.formatNumber(p.credits or 0).." CR     ×"..string.format("%.1f",p.heat or 1)
	self.population.Text=t("players",{n=if directory then directory.playerCount else 0})
	self.status.Text=if not directory then t("loading") elseif view=="LOBBY" then t("green_room") else (if model.snapshot and model.snapshot.state~="IDLE" then "●  "..t("on_air") else t("standby")).."  /  "..(if view=="MAIN" then "STUDIO 01" else "STUDIO 02")
	self.banner.Visible=(p.status=="SESSION_ONLY" or p.status=="SAVE_DELAYED") and not inRun and not model.showRecap and self.overlayMode==nil
	self.bannerText.Text=t(if p.status=="SAVE_DELAYED" then "save_delayed" else "session_only")
end
function App:showOverlay(mode)
	self.overlayMode=mode
	self.overlay:render(mode,self.model,function(key,args)return self:t(key,args)end)
	self:render()
end
function App:refreshOverlay()
	if self.overlayMode then self:showOverlay(self.overlayMode) end
end
function App:notify(key,args)
	self.toastToken+=1
	local token=self.toastToken
	self.toastText.Text=self:t(key,args);self.toast.Visible=true
	task.delay(4.5,function()if token==self.toastToken then self.toast.Visible=false end end)
end
function App:tick(now)
	self.run:tick(now);self.result:tick(now)
end
return App
