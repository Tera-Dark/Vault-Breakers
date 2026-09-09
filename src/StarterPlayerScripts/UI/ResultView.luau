--!nonstrict
local UI = require(script.Parent.Components)
local Numbers = require(game:GetService("ReplicatedStorage").VaultBreakers.Config.RewardPool)
local C = UI.colors
local Result = {}
Result.__index = Result
function Result.new(parent,actions)
	local self=setmetatable({},Result)
	self.root=UI.frame(parent,"Result",C.Ink);self.root.Size=UDim2.fromScale(1,1);self.root.BackgroundTransparency=0.28;self.root.ZIndex=30;self.root.Visible=false
	self.panel=UI.card(self.root,"ResultSheet",C.Ink)
	self.heading=UI.text(self.panel,"Heading","",11,C.Amber,true)
	self.mark=UI.mark(self.panel,"Seal",C.Amber)
	self.body=UI.new("ScrollingFrame",self.panel,{Name="RecapScroll",BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=3,ScrollBarImageColor3=C.Line,CanvasSize=UDim2.fromOffset(0,560),ScrollingDirection=Enum.ScrollingDirection.Y,ClipsDescendants=true})
	self.title=UI.text(self.body,"Outcome","",27,C.Ivory,true)
	self.amount=UI.text(self.body,"SecuredCredits","",55,C.Ivory,true)
	self.amountTag=UI.text(self.body,"AmountLegend","",11,C.Muted,true)
	self.stats={}
	for i=1,3 do
		local frame=UI.card(self.body,"ResultStat"..i,C.Panel)
		self.stats[i]={frame=frame,label=UI.text(frame,"Label","",10,C.Muted,true),value=UI.text(frame,"Value","",19,C.Ivory,true)}
	end
	self.rep=UI.text(self.body,"Reputation","",12,C.Teal,true)
	self.recap=UI.text(self.body,"RecapHeader","",11,C.Muted,true)
	self.rows={}
	for i=1,4 do
		local row=UI.frame(self.body,"Decision"..i,C.Panel);UI.corner(row,6)
		self.rows[i]={frame=row,grade=UI.text(row,"Grade","",12,C.Ivory,true),explanation=UI.text(row,"Explanation","",12,C.Muted)}
	end
	self.primary=UI.button(self.panel,"Replay","","primary",actions.replay)
	self.secondary=UI.button(self.panel,"Return","","secondary",actions.returnLobby)
	self.timer=UI.text(self.panel,"ReturnTimer","",10,C.Muted)
	return self
end
function Result:resize(w,h)
	local panelW=math.min(680,w-32)
	local panelH=math.min(620,h-(if h<560 then 20 else 100))
	UI.place(self.panel,(w-panelW)/2,(h-panelH)/2,panelW,panelH)
	UI.place(self.heading,24,16,panelW-95,24);UI.place(self.mark,panelW-54,17,26,26)
	UI.place(self.body,24,54,panelW-48,panelH-132)
	local inner=panelW-52
	UI.place(self.title,0,0,inner,40);self.title.TextSize=if w<600 then 23 else 27
	UI.place(self.amount,0,48,inner,66);self.amount.TextSize=if w<600 then 46 else 55
	UI.place(self.amountTag,0,117,inner,18)
	for i,stat in self.stats do
		local width=(inner-20)/3
		UI.place(stat.frame,(i-1)*(width+10),150,width,72)
		UI.place(stat.label,10,9,width-20,22)
		UI.place(stat.value,10,38,width-20,26);stat.value.TextSize=if w<600 then 15 else 19
	end
	UI.place(self.rep,0,236,inner,23);UI.place(self.recap,0,279,inner,20)
	for i,row in self.rows do
		UI.place(row.frame,0,310+(i-1)*81,inner,71)
		UI.place(row.grade,12,8,inner-24,20)
		UI.place(row.explanation,12,30,inner-24,32)
	end
	local buttonW=(panelW-60)/2
	UI.place(self.primary,24,panelH-66,buttonW,44);UI.place(self.secondary,36+buttonW,panelH-66,buttonW,44)
	UI.place(self.timer,24,panelH-21,panelW-48,16)
end
function Result:render(model,t)
	local s=if model.showRecap then model.recap elseif model.snapshot and model.snapshot.breakerId~=model.userId then model.snapshot else nil
	local r=s and s.result
	self.root.Visible=s~=nil and s.state=="RESULT" and r~=nil
	if not self.root.Visible then return end
	self.s,self.t=s,t
	self.inArena=model.directory and model.directory.myArena==s.arenaId and model.snapshot and model.snapshot.runId==s.runId
	local own=r.breakerId==model.userId
	self.heading.Text=t("complete").."  /  "..r.breakerName
	self.title.Text=if own then (if r.extracted then t("result_extract") else t("result_final")) else (if r.extracted then t("result_watch_extract") else t("result_watch_final"))
	self.amount.Text=Numbers.formatNumber(r.credits).." CR"
	self.amountTag.Text=t("banked")..string.format("   /   HEAT ×%.1f",r.heat)
	self.stats[1].label.Text,self.stats[1].value.Text=t("base"),Numbers.formatNumber(r.baseCredits)
	self.stats[2].label.Text,self.stats[2].value.Text=t("original"),Numbers.formatNumber(r.claimValue)
	self.stats[3].label.Text=t("next_heat")
	self.stats[3].value.Text=string.format("×%.1f",r.nextHeat or (if own then model.profile.heat else r.heat) or r.heat)
	local gain=2
	for _,decision in r.decisions do if decision.score>0 then gain+=2 end end
	self.rep.Text=t(if own then "earned_rep" else "breaker_rep",{n=r.reputationGain or gain})
	self.recap.Text=t("recap")
	for i,row in self.rows do
		local decision=r.decisions[i]
		row.frame.Visible=decision~=nil
		if decision then
			row.grade.Text=string.format("%02d  /  ",i)..t(decision.grade).."    ·    "..Numbers.formatNumber(decision.offer).." CR"
			row.grade.TextColor3=if decision.score>0 then C.Teal elseif decision.score<0 then C.Red else C.Ivory
			row.explanation.Text=t(decision.explanation)
		end
	end
	self.body.CanvasSize=UDim2.fromOffset(0,310+#r.decisions*81)
	self.primary.Text=if own then t("replay").."  →" else t("play").."  →"
	self.secondary.Text=t("return_lobby")
	local key=s.arenaId..s.runId
	if self.key~=key then self.key=key;self.body.CanvasPosition=Vector2.zero end
end
function Result:tick(now)
	if self.root.Visible and self.s then self.timer.Text=if not self.inArena or now>=self.s.deadline then self.t("recap_released") else self.t("return_time",{n=math.max(0,math.ceil(self.s.deadline-now))}) end
end
return Result
