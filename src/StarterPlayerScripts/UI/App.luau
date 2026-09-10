--!nonstrict
local GuiService=game:GetService("GuiService")
local UI=require(script.Parent.Components)
local Locale=require(script.Parent.Locale)
local Menu=require(script.Parent.LobbyView)
local Run=require(script.Parent.RunView)
local Result=require(script.Parent.ResultView)
local Overlay=require(script.Parent.OverlayView)
local Social=require(script.Parent.SocialView)
local Numbers=require(game:GetService("ReplicatedStorage").VaultBreakers.Config.RewardPool)
local C=UI.colors
local App={}
App.__index=App
function App.new(playerGui,model,actions)
	local self=setmetatable({model=model,actions=actions,overlayMode=nil,toastToken=0},App)
	self.gui=UI.new("ScreenGui",playerGui,{Name="VaultBreakersUI",ResetOnSpawn=false,ZIndexBehavior=Enum.ZIndexBehavior.Sibling,IgnoreGuiInset=false})
	self.root=UI.frame(self.gui,"SafeArea",C.Ink);self.root.BackgroundTransparency=1;self.root.Size=UDim2.fromScale(1,1);self.root.Active=false
	self.lobbyScroll=UI.new("ScrollingFrame",self.root,{
		Name="GameMenu",Visible=false,BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=3,ScrollBarImageColor3=C.Amber,
		CanvasSize=UDim2.new(),ScrollingDirection=Enum.ScrollingDirection.Y,ClipsDescendants=true,ZIndex=40,
	})
	self.lobby=Menu.new(self.lobbyScroll,actions)
	self.run=Run.new(self.root,actions)
	self.waiting=UI.card(self.root,"WaitingForStage",C.Ink);self.waiting.Visible=false;self.waiting.ZIndex=25
	self.waitingTitle=UI.text(self.waiting,"Heading","",18,C.Ivory,true)
	self.waitingBody=UI.text(self.waiting,"Description","",12,C.Muted)
	self.result=Result.new(self.root,actions)
	-- A few small HUD controls, not an opaque header spanning the whole screen.
	self.header=UI.frame(self.root,"GameHUD",C.Ink);self.header.BackgroundTransparency=1;self.header.ZIndex=130
	self.walletBox=UI.card(self.header,"Wallet",C.Ink);self.walletBox.BackgroundTransparency=.18
	self.coin=UI.frame(self.walletBox,"CreditToken",C.Amber);UI.corner(self.coin,18)
	local coinLetter=UI.gameText(self.coin,"Letter","V",21,C.Ink);coinLetter.TextStrokeTransparency=1;coinLetter.TextXAlignment=Enum.TextXAlignment.Center;coinLetter.Size=UDim2.fromScale(1,1)
	self.wallet=UI.text(self.walletBox,"Credits","",21,C.Ivory,true);self.wallet.TextScaled=true
	UI.new("UITextSizeConstraint",self.wallet,{MaxTextSize=21,MinTextSize=11})
	self.population=UI.text(self.walletBox,"HeatAndReputation","",10,C.Muted,true)
	self.menuButton=UI.gameButton(self.header,"MenuToggle","","secondary",actions.toggleMenu)
	self.menuButton:SetAttribute("Accent",C.Amber)
	self.menuButton:FindFirstChildOfClass("UIStroke").Color=C.Amber
	self.returnButton=UI.gameButton(self.header,"ReturnToLounge","←","secondary",actions.leave)
	self.live=UI.card(self.header,"UnpausedRun",C.Ink);self.live.Visible=false
	self.liveTitle=UI.text(self.live,"Warning","",11,C.Amber,true)
	self.liveClock=UI.gameText(self.live,"LiveClock","",18,C.Ivory)
	self.queue=UI.card(self.root,"QueueHUD",C.Ink);self.queue.Visible=false;self.queue.ZIndex=30
	self.queueTitle=UI.text(self.queue,"Position","",14,C.Amber,true)
	self.queueBody=UI.text(self.queue,"ExploreHint","",11,C.Muted)
	self.queueCancel=UI.gameButton(self.queue,"LeaveQueue","×","secondary",actions.cancelQueue)
	self.banner=UI.card(self.root,"PersistenceNotice",C.Ink);self.banner.ZIndex=22;self.banner.Visible=false
	self.bannerText=UI.text(self.banner,"Notice","",11,C.Amber)
	self.toast=UI.card(self.root,"Toast",C.Panel);self.toast.ZIndex=150;self.toast.Visible=false
	self.toastText=UI.text(self.toast,"Message","",14,C.Ivory)
	self.overlay=Overlay.new(self.root,actions)
	self.social=Social.new(self.root,actions)
	self.root:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()self:resize()end)
	task.defer(function()self:resize();self:render()end)
	return self
end
function App:t(key,args)return Locale.text(self.model.settings.language,key,args)end
function App:isMenuVisible()
	return self.model.menuOpen==true or self.overlayMode~=nil or self.model.showRecap==true
end
function App:blocksActions()return self:isMenuVisible()or self.model.syncing==true or(self.social and self.social.open)==true end
function App:releaseFocus()
	local selected=GuiService.SelectedObject
	while selected do
		if selected==self.gui then GuiService.SelectedObject=nil;return end
		selected=selected.Parent
	end
end
function App:focusMenu(setting)
	if not self.model.gamepad or not self:isMenuVisible()then return end
	local target=self.menuButton
	if self.overlayMode then target=self.overlay:focusTarget(setting)
	elseif self.model.showRecap then target=self.result.primary
	elseif self.model.menuOpen and self.lobby.play.Active then target=self.lobby.play end
	GuiService.SelectedObject=target or self.menuButton
end
function App:resize()
	local size=self.root.AbsoluteSize
	local w,h=math.max(320,size.X),math.max(260,size.Y)
	self.w,self.h=w,h
	local menuW=math.min(970,w-32)
	local short=h<520 and w>=h
	local menuTop=if short then 76 else 88
	local menuH=h-menuTop-12
	self.menuW,self.menuH,self.menuShort=menuW,menuH,short
	UI.place(self.lobbyScroll,(w-menuW)/2,menuTop,menuW,menuH)
	self.lobby:resize(menuW-8,menuH,short)
	self.lobbyScroll.CanvasSize=UDim2.fromOffset(0,math.max(menuH,self.lobby.contentHeight))
	self.lobbyScroll.ScrollingEnabled=self.lobby.contentHeight>menuH
	self.run.touch=self.model.touch;self.run:resize(w,h);self.result:resize(w,h);self.overlay:resize(w,h);self.social:resize(w,h)
	local waitingW=math.min(400,w-32)
	UI.place(self.waiting,(w-waitingW)/2,90,waitingW,80)
	UI.place(self.waitingTitle,16,9,waitingW-32,27);UI.place(self.waitingBody,16,38,waitingW-32,33)
	local queueW=math.min(420,w-28)
	UI.place(self.queue,(w-queueW)/2,if w>=1000 then 14 else 80,queueW,54)
	UI.place(self.queueTitle,12,6,queueW-74,23);UI.place(self.queueBody,12,29,queueW-74,19);UI.place(self.queueCancel,queueW-50,5,44,44)
	local bannerW=math.min(480,w-40)
	UI.place(self.banner,(w-bannerW)/2,h-33,bannerW,27);UI.place(self.bannerText,10,0,bannerW-20,27)
	local toastW=math.min(560,w-40)
	UI.place(self.toast,(w-toastW)/2,if w>=850 then 82 else 142,toastW,62);UI.place(self.toastText,16,8,toastW-32,46)
	if self.model then self:render()end
end
function App:layoutHUD(inRun)
	local w=self.w or 800
	local headerW=w-24
	local buttonW=if w<540 then 118 else 150
	UI.place(self.header,12,12,headerW,55)
	UI.place(self.menuButton,headerW-buttonW,0,buttonW,50)
	local uiOpen=self:isMenuVisible()
	self.returnButton.Visible=inRun and not uiOpen
	UI.place(self.returnButton,headerW-buttonW-54,0,44,50)
	local walletW=math.min(222,headerW-buttonW-(if self.returnButton.Visible then 65 else 12))
	UI.place(self.walletBox,0,0,walletW,54)
	self.coin.Visible=walletW>=172
	UI.place(self.coin,10,10,33,33)
	local textX=if self.coin.Visible then 52 else 10
	UI.place(self.wallet,textX,5,walletW-textX-10,27);UI.place(self.population,textX,32,walletW-textX-10,16)
	local snapshot=self.model.snapshot
	self.live.Visible=uiOpen and snapshot~=nil and snapshot.breakerId==self.model.userId and snapshot.state~="RESULT"
	if w>=850 then UI.place(self.live,(headerW-350)/2,0,350,54)
	else UI.place(self.live,0,0,headerW-buttonW-12,54)end
	self.walletBox.Visible=not self.live.Visible or w>=850
	local liveW=self.live.AbsoluteSize.X
	UI.place(self.liveTitle,10,4,liveW-20,20);UI.place(self.liveClock,10,23,liveW-20,26)
	self.menuButton.Modal=uiOpen -- releases a first-person mouse only while our UI is visible
	self.menuButton.Text=if uiOpen then "×  "..self:t("menu_resume")else self:t("menu")..(if self.model.gamepad then "  [↑]"elseif self.model.touch then ""else "  [M]")
	self.menuButton.TextSize=if w<540 then 15 else 18
	self.menuButton.NextSelectionDown=if self.model.menuOpen and not self.overlayMode then self.lobby.play else nil
	for _,button in {self.lobby.stagesButton,self.lobby.play,self.lobby.watchButton}do button.NextSelectionUp=self.menuButton end
end
function App:render()
	local model=self.model
	local t=function(key,args)return self:t(key,args)end
	UI.reducedMotion=model.settings.reducedMotion
	local directory=model.directory
	local view=directory and(directory.myArena or directory.view)or"LOBBY"
	local inRun=view~="LOBBY"and model.snapshot~=nil
	self.lobbyScroll.Visible=model.menuOpen==true and self.overlayMode==nil and not model.showRecap
	self.waiting.Visible=model.syncing==true and not self:isMenuVisible()
	self.waitingTitle.Text,self.waitingBody.Text=t("sync_stage"),t("sync_stage_body")
	self.run.root.Visible=inRun and model.snapshot.state~="RESULT"and not self:isMenuVisible()
	self.lobby:render(model,t)
	if self.menuW then
		self.lobby:resize(self.menuW-8,self.menuH,self.menuShort)
		self.lobbyScroll.CanvasSize=UDim2.fromOffset(0,math.max(self.menuH,self.lobby.contentHeight))
		self.lobbyScroll.ScrollingEnabled=self.lobby.contentHeight>self.menuH
	end
	if inRun then self.run:render(model,t)end
	self.result:render(model,t)
	if model.menuOpen or self.overlayMode or(not inRun and not model.showRecap)then self.result.root.Visible=false end
	local p=model.profile or{}
	self.wallet.Text=if p.status=="LOADING"then "…"else Numbers.formatNumber(p.credits or 0).." CR"
	self.population.Text=if(self.w or 800)>=540 then string.format("HEAT ×%.1f   ·   %s %s",p.heat or 1,Numbers.formatNumber(p.reputation or 0),t("rep"))else string.format("HEAT ×%.1f",p.heat or 1)
	self.liveTitle.Text=t("menu_live_short")
	self.queue.Visible=directory~=nil and(directory.queuePosition or 0)>0 and not self:isMenuVisible()
	self.queueTitle.Text=t("queue",{n=if directory then directory.queuePosition or 0 else 0});self.queueBody.Text=t("queue_explore")
	self.banner.Visible=(p.status=="SESSION_ONLY"or p.status=="SAVE_DELAYED")and not inRun and not self:isMenuVisible()
	self.bannerText.Text=t(if p.status=="SAVE_DELAYED"then"save_delayed"else"session_only")
	self:layoutHUD(inRun)
	self.social:render(model,t,self:isMenuVisible()or model.syncing==true)
end
function App:showOverlay(mode)
	self.overlayMode=mode
	if mode then self.model.menuOpen=true end
	self.overlay:render(mode,self.model,function(key,args)return self:t(key,args)end)
	self:render()
end
function App:refreshOverlay()
	if self.overlayMode then
		local scroll=self.overlay.body.CanvasPosition
		local selected=GuiService.SelectedObject
		local name=selected and selected.Name
		self:showOverlay(self.overlayMode)
		self.overlay.body.CanvasPosition=scroll
		if self.model.gamepad then GuiService.SelectedObject=(name and self.overlay.root:FindFirstChild(name,true))or self.overlay:focusTarget()end
	end
end
function App:notify(key,args)
	self.toastToken+=1
	local token=self.toastToken
	self.toastText.Text=self:t(key,args);self.toast.Visible=true
	task.delay(4.5,function()if token==self.toastToken then self.toast.Visible=false end end)
end
function App:tick(now)
	self.run:tick(now);self.result:tick(now)
	local s=self.model.snapshot
	if self.live.Visible and s then self.liveClock.Text=self:t("menu_seconds",{n=math.max(0,math.ceil(s.deadline-now))})end
end
return App
