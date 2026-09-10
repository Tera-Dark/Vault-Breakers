--!nonstrict
local UI=require(script.Parent.Components)
local Rules=require(game:GetService("ReplicatedStorage").VaultBreakers.Shared.ReactionRules)
local C=UI.colors
local Social={};Social.__index=Social
function Social.new(parent,actions)
	local self=setmetatable({open=false,actions=actions},Social)
	self.root=UI.frame(parent,"AudienceDock",C.Ink);self.root.BackgroundTransparency=1;self.root.Size=UDim2.fromScale(1,1);self.root.ZIndex=55
	self.toggle=UI.gameButton(self.root,"OpenReactions","…","secondary",actions.toggleSocial)
	self.panel=UI.card(self.root,"ReactionPanel",C.Ink);self.panel.Visible=false
	self.heading=UI.text(self.panel,"Heading","",13,C.Teal,true)
	self.close=UI.gameButton(self.panel,"CloseReactions","×","secondary",actions.toggleSocial)
	self.buttons={}
	for i,key in Rules.ORDER do self.buttons[i]=UI.gameButton(self.panel,key,"","secondary",function()actions.react(key)end)end
	for i,button in self.buttons do button.NextSelectionDown=self.buttons[i%#self.buttons+1];button.NextSelectionUp=self.buttons[(i-2)%#self.buttons+1]end
	self.buttons[1].NextSelectionUp=self.close;self.close.NextSelectionDown=self.buttons[1];self.buttons[#self.buttons].NextSelectionDown=self.close
	self.stand=UI.gameButton(self.root,"StandUp","","secondary",actions.stand)
	return self
end
function Social:resize(w,h)
	UI.place(self.toggle,w-60,math.max(84,math.floor(h*.38)),44,44)
	UI.place(self.stand,(w-200)/2,h-70,200,44)
	local width=math.min(240,w-28)
	local short=h<390;local height=if short then 160 else 252
	UI.place(self.panel,w-width-16,math.max(78,math.min(h-height-20,h*.3)),width,height)
	UI.place(self.heading,12,6,width-74,36);UI.place(self.close,width-52,4,44,44)
	for i,button in self.buttons do
		if short then UI.place(button,12+(i-1)%2*((width-30)/2+6),52+math.floor((i-1)/2)*51,(width-30)/2,44)
		else UI.place(button,12,52+(i-1)*48,width-24,44)end
		button.TextSize=if short then 13 else 16
	end
end
function Social:render(model,t,blocked)
	local d=model.directory;local s=d and d.broadcast and d.broadcast.MAIN
	self.eligible=not blocked and d~=nil and not d.myArena and(d.view=="MAIN"or d.view=="LOBBY")and s~=nil and s.state~="IDLE"and s.state~="RESULT"
	if not self.eligible then self.open=false end
	self.toggle.Visible=self.eligible==true;self.panel.Visible=self.open and self.eligible==true
	self.heading.Text=t("quick_reactions")
	local left=math.max(0,(model.reactionReadyAt or 0)-os.clock())
	for i,key in Rules.ORDER do self.buttons[i].Text=t("reaction_"..key);UI.enabled(self.buttons[i],left<=0)end
	if left>0 then self.heading.Text=t("reaction_cooldown",{n=math.ceil(left)})end
	self.stand.Visible=model.seated==true and not blocked
	self.stand.Text=t("stand_up")
end
return Social
