--!nonstrict
local UI = require(script.Parent.Components)
local Preview = require(script.Parent.VaultPreview)
local Numbers = require(game:GetService("ReplicatedStorage").VaultBreakers.Config.RewardPool)
local C = UI.colors
local Lobby = {}
Lobby.__index = Lobby
function Lobby.new(parent, actions)
	local self = setmetatable({actions=actions},Lobby)
	self.root = UI.frame(parent,"Lobby",C.Ink);self.root.BackgroundTransparency=1;self.root.Size=UDim2.fromScale(1,1)
	local scrim=UI.frame(self.root,"EditorialScrim",C.Ink);scrim.Size=UDim2.fromScale(0.75,1)
	UI.new("UIGradient",scrim,{Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0.10),NumberSequenceKeypoint.new(0.55,0.25),NumberSequenceKeypoint.new(1,1)})})
	self.kicker = UI.text(self.root,"Kicker","A SOCIAL RISK SHOW",11,C.Amber,true)
	self.hero = UI.text(self.root,"Hero","",62,C.Ivory,true)
	self.hero.TextYAlignment = Enum.TextYAlignment.Top
	self.body = UI.text(self.root,"Introduction","",17,C.Muted)
	self.play = UI.button(self.root,"Play","","primary",function()actions.play("AUTO")end)
	self.how = UI.button(self.root,"Guide","","secondary",function()actions.overlay("HOW")end)
	self.note = UI.text(self.root,"FreePlayNote","",10,C.Muted,true)
	self.main = UI.card(self.root,"MainStageCard")
	self.preview = Preview.new(self.main)
	self.mainTag = UI.text(self.main,"StudioNumber","STUDIO 01",11,C.Amber,true)
	self.mainTitle = UI.text(self.main,"MainTitle","",24,C.Ivory,true)
	self.mainStatus = UI.text(self.main,"MainStatus","",13,C.Muted)
	self.mainButton = UI.button(self.main,"MainAction","","secondary",function()
		if self.mainAvailable then actions.play("MAIN") else actions.watch("MAIN") end
	end)
	self.quick = UI.card(self.root,"QuickStageCard")
	self.quickTag = UI.text(self.quick,"StudioNumber","STUDIO 02",11,C.Teal,true)
	self.quickTitle = UI.text(self.quick,"QuickTitle","",20,C.Ivory,true)
	self.quickStatus = UI.text(self.quick,"QuickStatus","",12,C.Muted)
	self.quickButton = UI.button(self.quick,"QuickAction","","teal",function()actions.play("QUICK")end)
	self.stats = UI.card(self.root,"CareerStrip",C.Ink)
	self.values, self.tags = {},{}
	for i=1,3 do self.values[i]=UI.text(self.stats,"Value"..i,"0",24,C.Ivory,true);self.tags[i]=UI.text(self.stats,"Tag"..i,"",10,C.Muted,true) end
	self.queue = UI.card(self.root,"QueueStatus",C.Panel)
	self.queueTitle = UI.text(self.queue,"QueuePosition","",14,C.Amber,true)
	self.queueBody = UI.text(self.queue,"QueueHint","",12,C.Muted)
	self.queueCancel = UI.button(self.queue,"CancelQueue","","secondary",actions.cancelQueue)
	self.queue.Visible=false
	return self
end
function Lobby:resize(w,h)
	local portrait=w<600
	local small=h<640
	local margin=if portrait then 20 else math.max(28,math.floor(w*0.055))
	local leftW=if portrait then w-40 else w*0.47
	local top=if small then 74 else if portrait then 92 else math.max(115,h*0.19)
	UI.place(self.kicker,margin,top,leftW,18)
	self.hero.TextSize=if portrait then 42 elseif small then 36 else math.min(66,math.floor(w/20))
	local titleH=if small then 88 elseif portrait then 108 else 156
	UI.place(self.hero,margin,top+28,leftW,titleH)
	self.body.Visible=not small
	UI.place(self.body,margin,top+titleH+32,leftW-12,52)
	local buttonY=top+titleH+(if small then 34 else 100)
	local playW=if portrait then math.floor(leftW*0.57) else math.min(220,leftW*0.55)
	UI.place(self.play,margin,buttonY,playW,48)
	UI.place(self.how,margin+playW+12,buttonY,math.min(leftW-playW-12,160),48)
	UI.place(self.note,margin,buttonY+59,leftW,26)
	local cardX=if portrait then margin else math.floor(w*0.60)
	local cardW=if portrait then leftW else w-cardX-margin
	local cardY=if portrait then buttonY+106 else top
	local mainH=if portrait or small then 122 else 226
	UI.place(self.main,cardX,cardY,cardW,mainH)
	self.preview.Visible=not portrait and not small
	UI.place(self.preview,cardW*0.33,12,cardW*0.67,mainH-65)
	UI.place(self.mainTag,18,16,cardW-36,16)
	UI.place(self.mainTitle,18,38,cardW-36,32)
	UI.place(self.mainStatus,18,if mainH==122 then 71 else 83,cardW-36,22)
	UI.place(self.mainButton,18,mainH-60,cardW-36,44)
	if portrait or small then
		UI.place(self.mainTitle,18,35,cardW-180,28);self.mainTitle.TextSize=18
		UI.place(self.mainStatus,18,72,cardW-180,32)
		UI.place(self.mainButton,cardW-155,53,137,46)
	else self.mainTitle.TextSize=24 end
	local quickY=cardY+mainH+14
	local quickH=if portrait or small then 106 else 160
	UI.place(self.quick,cardX,quickY,cardW,quickH)
	UI.place(self.quickTag,18,14,cardW-36,16)
	UI.place(self.quickTitle,18,34,cardW-36,27)
	UI.place(self.quickStatus,18,65,cardW-36,22)
	UI.place(self.quickButton,18,quickH-60,cardW-36,44)
	if portrait or small then
		UI.place(self.quickTitle,18,35,cardW-180,27);self.quickTitle.TextSize=18
		UI.place(self.quickStatus,18,67,cardW-180,30)
		UI.place(self.quickButton,cardW-155,42,137,46)
	end
	local statsY=if portrait then quickY+quickH+16 else h-(if small then 64 else 108)
	local statsH=if small then 54 else 76
	UI.place(self.stats,margin,statsY,w-margin*2,statsH)
	for i=1,3 do
		local column=(w-margin*2)/3
		UI.place(self.values[i],18+(i-1)*column,if small then 5 else 11,column-26,28)
		UI.place(self.tags[i],18+(i-1)*column,if small then 32 else 43,column-26,if small then 20 else 27)
	end
	UI.place(self.queue,margin,buttonY,leftW,112)
	UI.place(self.queueTitle,16,12,leftW-32,22)
	UI.place(self.queueBody,16,38,leftW-150,60)
	UI.place(self.queueCancel,leftW-133,51,117,44)
	-- On short portrait screens, scroll the whole lobby rather than shrinking touch targets.
	self.contentHeight=math.max(statsY+statsH+20,h)
end
function Lobby:render(model,t)
	self.hero.Text,self.body.Text=t("hero"),t("hero_body")
	self.play.Text,self.how.Text,self.note.Text=t("play").."  →",t("how"),t("free_note")
	local directory=model.directory
	local main,quick
	for _,arena in (directory and directory.arenas) or {} do if arena.id=="MAIN" then main=arena else quick=arena end end
	self.mainAvailable=main and main.available
	self.mainTitle.Text,self.quickTitle.Text=t("main"),t("quick")
	self.mainStatus.Text=if not main then t("loading") elseif main.available then t("available") else t("playing",{name=main.name})
	self.quickStatus.Text=if not quick then t("loading") elseif quick.available then t("available") else t("playing",{name=quick.name})
	self.mainButton.Text=if self.mainAvailable then t("enter") else t("watch")
	self.quickButton.Text=if quick and quick.available then t("join_quick") else t("queue_quick")
	local profile=model.profile or {}
	local loaded=profile.status and profile.status~="LOADING"
	local queuePosition=if directory then directory.queuePosition or 0 else 0
	for _,button in {self.play,self.mainButton,self.quickButton} do UI.enabled(button,loaded and directory~=nil and queuePosition==0) end
	-- Watching remains possible while queued.
	if main and not main.available then UI.enabled(self.mainButton,true) end
	self.values[1].Text=Numbers.formatNumber(profile.reputation or 0)
	self.values[2].Text=Numbers.formatNumber(math.max(profile.bestExtract or 0,profile.bestFinal or 0))
	self.values[3].Text=tostring(profile.runs or 0)
	self.tags[1].Text,self.tags[2].Text,self.tags[3].Text=t("rep"),t("best"),t("runs")
	self.queue.Visible=queuePosition>0
	self.queueTitle.Text=t("queue",{n=queuePosition})
	self.queueBody.Text,self.queueCancel.Text=t("queue_body"),t("cancel_queue")
	self.play.Visible,self.how.Visible,self.note.Visible=queuePosition==0,queuePosition==0,queuePosition==0
end
return Lobby
