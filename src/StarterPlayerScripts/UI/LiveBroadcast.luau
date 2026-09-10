--!nonstrict
-- A real in-world scoreboard, not a second full stage render. Public feed only.
local UI=require(script.Parent.Components)
local Locale=require(script.Parent.Locale)
local Pool=require(game:GetService("ReplicatedStorage").VaultBreakers.Config.RewardPool)
local Show=require(game:GetService("ReplicatedStorage").VaultBreakers.Shared.ShowRules)
local C=UI.colors
local TV={};TV.__index=TV
local PHASE={IDLE="standby",SHOWTIME="showtime_title",CLAIM="claim_title",BREACH="breach_title",OPENING="opening_title",BREACH_REACT="reaction_title",OFFER_ROLL="rolling_title",OFFER="curator",LIFELINE="lifeline_title",TRANSITION="transition_title",FINAL_CHOICE="final_title",REVEAL="reveal_title",RESULT="complete"}
function TV.new(playerGui)return setmetatable({parent=playerGui},TV)end
function TV:bind()
	local world=workspace:FindFirstChild("VaultWorld");local screen=world and world:FindFirstChild("LiveTelevision",true)
	if not screen then return false end
	if self.screen==screen and self.gui then return true end
	if self.gui then self.gui:Destroy()end
	self.screen=screen
	self.gui=UI.new("SurfaceGui",self.parent,{Name="VaultLiveTelevision",Adornee=screen,Face=Enum.NormalId.Front,CanvasSize=Vector2.new(1280,560),LightInfluence=0,AlwaysOnTop=false,MaxDistance=130})
	local old=screen:FindFirstChild("Graphics");if old then old.Enabled=false end
	self.root=UI.frame(self.gui,"Broadcast",C.Ink);self.root.Size=UDim2.fromScale(1,1)
	self.brand=UI.gameText(self.root,"LiveBrand","VAULT BREAKERS / LIVE",27,C.Amber);UI.place(self.brand,34,22,880,39)
	self.avatar=UI.new("ImageLabel",self.root,{Name="ContestantPortrait",BackgroundColor3=C.Panel,BorderSizePixel=0});UI.place(self.avatar,36,82,110,110);UI.corner(self.avatar,12)
	self.name=UI.text(self.root,"Contestant","",30,C.Ivory,true);UI.place(self.name,170,76,1010,50);self.name.TextTruncate=Enum.TextTruncate.AtEnd;self.name.TextWrapped=false
	self.phase=UI.text(self.root,"Phase","",22,C.Muted,true);UI.place(self.phase,170,132,1010,50)
	self.amount=UI.gameText(self.root,"Amount","",72,C.Ivory);UI.place(self.amount,36,204,890,100)
	self.timer=UI.gameText(self.root,"Clock","",44,C.Amber);UI.place(self.timer,970,220,260,72);self.timer.TextXAlignment=Enum.TextXAlignment.Right
	self.detail=UI.text(self.root,"Detail","",23,C.Muted);UI.place(self.detail,36,318,1200,45)
	self.cells={}
	for i,value in Pool.VALUES do
		local cell=UI.card(self.root,"Reward"..value,C.Panel);UI.place(cell,36+(i-1)*100,381,91,57)
		local text=UI.text(cell,"Value",Pool.formatNumber(value),20,C.Ivory,true);text.Size=UDim2.fromScale(1,1);text.TextXAlignment=Enum.TextXAlignment.Center
		self.cells[i]={frame=cell,text=text,value=value}
	end
	self.quick=UI.text(self.root,"QuickStudio","",21,C.Teal,true);UI.place(self.quick,36,473,1200,39)
	return true
end
function TV:update(feeds,settings)
	self.feeds=feeds or{};self.settings=settings
	if not self:bind()then return end
	local s=self.feeds.MAIN;local t=function(key,args)return Locale.text(settings.language,key,args)end
	self.t=t
	if not s then self.name.Text=t("loading");return end
	self.name.Text=if s.breakerId then s.breakerName else t("tv_waiting")
	self.avatar.Visible=s.breakerId~=nil
	if s.breakerId then self.avatar.Image="rbxthumb://type=AvatarHeadShot&id="..s.breakerId.."&w=150&h=150"end
	self.phase.Text=t(PHASE[s.state]or"standby",{n=math.max(0,(s.quota or 0)-(s.breached or 0))})..(if s.round>0 then "  /  "..t("round",{n=s.round})else"")
	local remaining={};for _,v in s.remaining do remaining[v]=true end
	for _,cell in self.cells do local exists=remaining[cell.value]or s.state=="IDLE";cell.text.TextColor3=if exists then C.Ivory else C.Line;cell.frame.BackgroundTransparency=if exists then 0 else .65 end
	self.detail.Text=if s.lastBreach then t("opened",{n=Pool.formatNumber(s.lastBreach.value)})else t("tv_public")
	local q=self.feeds.QUICK
	self.quick.Text=t("quick").."  /  "..(if q and q.state~="IDLE"then q.breakerName.." · "..t("round",{n=q.round})else t("available"))
	self:tick(workspace:GetServerTimeNow())
end
function TV:tick(now)
	if not self.gui or not self.feeds.MAIN then return end
	local s=self.feeds.MAIN;local text=""
	if s.state=="OFFER_ROLL"then text=Pool.formatNumber(Show.counter(s.offer,s.phaseStartedAt,s.deadline,now,self.settings.reducedMotion)).." CR"
	elseif s.state=="OFFER"or s.state=="LIFELINE"then text=Pool.formatNumber(s.offer).." CR"
	elseif s.state=="FINAL_CHOICE"then text=string.format("%02d  /  %02d",s.claimId or 0,s.finalId or 0)
	elseif s.state=="RESULT"and s.result then text=Pool.formatNumber(s.result.credits).." CR"
	elseif s.lastBreach and(s.state=="BREACH_REACT"or s.state=="BREACH")then text="− "..Pool.formatNumber(s.lastBreach.value).." CR"
	else text=self.t(if s.state=="IDLE"then "tv_next"else"tv_sealed")end
	self.amount.Text=text
	self.timer.Text=if s.deadline>0 then (if s.state=="OFFER_ROLL"then "…"else math.max(0,math.ceil(s.deadline-now)).."s")else""
end
function TV:destroy()if self.gui then self.gui:Destroy()end end
return TV
