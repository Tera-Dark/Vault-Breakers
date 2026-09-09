--!nonstrict
local UI = require(script.Parent.Components)
local Numbers = require(game:GetService("ReplicatedStorage").VaultBreakers.Config.RewardPool)
local C = UI.colors
local Run = {}
Run.__index = Run
local TITLES = { CLAIM="claim", BREACH="breach", OPENING="opening", OFFER="offer", LIFELINE="lifeline", TRANSITION="transition", FINAL_CHOICE="final", REVEAL="reveal" }
function Run.new(parent,actions)
	local self=setmetatable({actions=actions},Run)
	self.root=UI.frame(parent,"Run",C.Ink);self.root.BackgroundTransparency=1;self.root.Size=UDim2.fromScale(1,1);self.root.Visible=false
	self.brief=UI.card(self.root,"PhaseBacking",C.Ink);self.brief.BackgroundTransparency=0.16
	self.round=UI.text(self.root,"Round","",11,C.Amber,true)
	self.title=UI.text(self.root,"PhaseTitle","",32,C.Ivory,true)
	self.title.TextScaled=true
	UI.new("UITextSizeConstraint",self.title,{MinTextSize=16,MaxTextSize=32})
	self.body=UI.text(self.root,"PhaseDescription","",14,C.Muted)
	self.steps={}
	for i=1,4 do
		local label=UI.text(self.root,"Step"..i,"",10,C.Muted,true)
		self.steps[i]={label=label,rule=UI.rule(self.root)}
	end
	self.board=UI.card(self.root,"RewardBoard",C.Ink)
	self.boardTitle=UI.text(self.board,"Remaining","",11,C.Muted,true)
	self.claim=UI.text(self.board,"Claim","",11,C.Amber,true)
	self.cells={}
	for i,value in Numbers.VALUES do
		local cell=UI.card(self.board,"Reward"..value,C.Panel)
		local text=UI.text(cell,"Value",Numbers.formatNumber(value),14,if i>6 then C.Amber else C.Text,true)
		text.TextXAlignment=Enum.TextXAlignment.Center;text.Size=UDim2.fromScale(1,1)
		local strike=UI.rule(cell);strike.AnchorPoint=Vector2.new(0.5,0.5);strike.Position=UDim2.fromScale(0.5,0.5);strike.Size=UDim2.fromScale(0.65,0.035);strike.Visible=false
		self.cells[i]={frame=cell,text=text,strike=strike,value=value}
	end
	self.card=UI.card(self.root,"DecisionCard",C.Ink)
	self.cardTitle=UI.text(self.card,"OfferTitle","",11,C.Muted,true)
	self.amount=UI.text(self.card,"OfferAmount","",48,C.Ivory,true)
	self.possible=UI.text(self.card,"PossibleRange","",12,C.Muted)
	self.clock=UI.text(self.card,"Clock","18",22,C.Amber,true);self.clock.TextXAlignment=Enum.TextXAlignment.Right
	self.track=UI.frame(self.card,"ClockTrack",C.Raised);self.fill=UI.frame(self.track,"ClockFill",C.Amber);self.fill.Size=UDim2.fromScale(1,1)
	self.sentiment=UI.text(self.card,"AudienceOpinion","",11,C.Muted)
	self.left=UI.button(self.card,"LeftChoice","","primary",function()actions.choice(1)end)
	self.right=UI.button(self.card,"RightChoice","","secondary",function()actions.choice(2)end)
	self.leftHint=UI.text(self.card,"LeftHint","",10,C.Muted);self.leftHint.TextXAlignment=Enum.TextXAlignment.Center
	self.rightHint=UI.text(self.card,"RightHint","",10,C.Muted);self.rightHint.TextXAlignment=Enum.TextXAlignment.Center
	self.feedback=UI.card(self.root,"EliminationFeedback",C.Panel)
	self.feedbackTitle=UI.text(self.feedback,"Eliminated","",12,C.Teal,true)
	self.feedbackBody=UI.text(self.feedback,"Meaning","",11,C.Muted)
	self.lifeline=UI.text(self.root,"PhysicalLifelineHint","",12,C.Amber,true)
	self.consensus=UI.text(self.root,"LifelineConsensus","",12,C.Amber,true)
	self.help=UI.text(self.root,"InputHint","",11,C.Muted)
	self.leave=UI.button(self.root,"Leave","","secondary",actions.leave)
	self.standby=UI.button(self.root,"StartEmptyStage","","primary",function()actions.play("AUTO")end)
	return self
end
function Run:resize(w,h)
	self.w,self.h=w,h
	local short,micro=h<560,h<380
	local touchShort=short and self.touch
	local stacked=w<900 and not short
	self.short,self.stacked,self.touchShort=short,stacked,touchShort
	local phaseX=if stacked or short then 20 else 260
	local phaseW=if stacked or short then w-40 else w-510
	local top=if short then 74 elseif stacked then 82 else 92
	local briefH=if touchShort and micro then 34 elseif short then 62 elseif stacked then 120 else 166
	UI.place(self.brief,phaseX-12,if short then top-4 else top-10,phaseW+24,briefH)
	UI.place(self.round,phaseX,top,phaseW,18)
	self.round.Visible=not (touchShort and micro)
	UI.place(self.title,phaseX,if touchShort and micro then top else top+24,phaseW,if short then 30 else 42)
	self.title.TextSize=if short then 22 elseif stacked then 25 else 32
	UI.place(self.body,phaseX,top+70,phaseW,38);self.body.Visible=not short
	for i,step in self.steps do
		local cell=math.min(phaseW/4,125)
		UI.place(step.label,phaseX+(i-1)*cell,top+122,cell-10,15)
		UI.place(step.rule,phaseX+(i-1)*cell,top+142,cell-12,2)
		step.label.Visible,step.rule.Visible=not short and not stacked,not short and not stacked
	end
	local compactBoard=stacked or (touchShort and h>=310)
	local tinyTouch=touchShort and h<310
	local boardW=if compactBoard then w-40 elseif short then 156 else 204
	local boardY=if tinyTouch then 104 elseif touchShort then (if micro then 104 else 138) elseif stacked then 199 elseif short then (if micro then 132 else 146) else 162
	local boardH=if tinyTouch then 132 elseif touchShort then (if micro then 70 else 78) elseif stacked then 104 elseif short then (if micro then 132 else 186) else 293
	UI.place(self.board,20,boardY,boardW,boardH)
	UI.place(self.boardTitle,12,if touchShort then 3 else 9,boardW-24,if touchShort then 14 else 18)
	UI.place(self.claim,12,boardH-(if short then 18 else 23),boardW-24,if short then 14 else 16)
	self.boardTitle.TextSize=if touchShort then 9 else 11
	self.claim.TextSize=if short then 9 else 11
	for i,cell in self.cells do
		local col,row,cellW,cellH,gap,cellTop
		if compactBoard then
			col=(i-1)%6;row=math.floor((i-1)/6);cellW=(boardW-34)/6
			cellH=if touchShort then (if micro then 14 else 17) else 23
			gap=2;cellTop=if touchShort then 21 else 32
		else
			col=math.floor((i-1)/6);row=(i-1)%6;cellW=(boardW-30)/2
			cellH=if short then (boardH-50)/6-2 else 33
			gap=if short then 2 else 3;cellTop=if short then 28 else 34
		end
		UI.place(cell.frame,12+col*(cellW+2),cellTop+row*(cellH+gap),cellW,cellH)
		cell.text.TextSize=if short then 10 elseif stacked then 11 else 14
	end
	local compact=short or (stacked and h<720)
	local cardW=if short then math.min(540,w-212) else math.min(584,w-32)
	local cardH=if touchShort then (if micro then 130 else 154) elseif micro then 180 elseif compact then 222 else 252
	local cardX=if short then w-cardW-20 else (w-cardW)/2
	local cardY=h-cardH-(if short then (if micro then 10 else 16) else 72)
	self.hideBoard=false
	UI.place(self.card,cardX,cardY,cardW,cardH)
	local titleY=if short then 7 else 14
	UI.place(self.cardTitle,20,titleY,cardW-108,18)
	UI.place(self.clock,cardW-86,titleY-2,64,26)
	local amountY=if touchShort then 22 elseif micro then 25 else 37
	local amountH=if touchShort or micro then 36 elseif compact then 47 else 62
	UI.place(self.amount,20,amountY,cardW-40,amountH)
	self.amount.TextSize=if touchShort or micro then 31 elseif compact then 37 else 48
	UI.place(self.possible,20,if micro then 63 elseif compact then 86 else 100,cardW-40,22)
	self.possible.Visible=not touchShort
	local trackY=if touchShort then (if micro then 72 else 94) elseif micro then 89 elseif compact then 114 else 133
	UI.place(self.track,20,trackY,cardW-40,2)
	local sentimentY=if touchShort then (if micro then 54 else 72) elseif micro then 95 elseif compact then 125 else 143
	UI.place(self.sentiment,20,sentimentY,cardW-40,if touchShort or micro then 17 else 24)
	self.sentiment.TextSize=if touchShort or micro then 10 else 11
	local buttonY=if touchShort then (if micro then 80 else 103) elseif micro then 120 elseif compact then 161 else 180
	local buttonW=(cardW-52)/2
	UI.place(self.left,20,buttonY,buttonW,44);UI.place(self.right,32+buttonW,buttonY,buttonW,44)
	UI.place(self.leftHint,20,229,buttonW,16);UI.place(self.rightHint,32+buttonW,229,buttonW,16)
	self.showChoiceHints=not compact
	self.leftHint.Visible,self.rightHint.Visible=not compact,not compact
	local feedbackX=if short then w-cardW-20 elseif stacked then 20 else phaseX
	local feedbackY=if touchShort then boardY+boardH+14 elseif short then 145 elseif stacked then 321 else 265
	local feedbackW=if short then cardW elseif stacked then w-40 else math.min(380,phaseW)
	UI.place(self.feedback,feedbackX,feedbackY,feedbackW,64)
	UI.place(self.feedbackTitle,14,10,feedbackW-28,20);UI.place(self.feedbackBody,14,33,feedbackW-28,20)
	UI.place(self.lifeline,cardX,cardY-30,cardW,24)
	UI.place(self.consensus,cardX,cardY-57,cardW,26)
	UI.place(self.help,20,h-49,w-196,24);self.help.Visible=not short
	UI.place(self.leave,if short then 20 else w-170,h-54,if short then 156 else 150,44)
	UI.place(self.standby,(w-260)/2,h*0.53,260,48)
end

function Run:render(model,t)
	local s=model.snapshot
	if not s then self.root.Visible=false;return end
	self.s=s;self.t=t
	local own=s.breakerId==model.userId
	local state=s.state
	local phase=TITLES[state] or "claim"
	local active=state~="IDLE" and state~="RESULT"
	self.round.Text=if own then (if s.round>0 then t("round",{n=s.round}) else "01  /  "..t("choose")) else t("spectating",{name=s.breakerName})
	self.title.Text=if state=="IDLE" then t("standby") else t(phase.."_title",{n=s.quota-s.breached})
	self.body.Text=if state=="IDLE" then t("available") elseif s.automatic and state=="TRANSITION" then t("auto_body") else t(phase.."_body")
	local stepIndex=if state=="CLAIM" then 1 elseif state=="BREACH" or state=="OPENING" then 2 elseif state=="OFFER" or state=="LIFELINE" or state=="TRANSITION" then 3 else 4
	for i,step in self.steps do
		step.label.Text=string.format("%02d  /  ",i)..t(({"choose","open","offer","result"})[i])
		step.label.TextColor3=if i==stepIndex then C.Ivory else C.Muted
		step.rule.BackgroundColor3=if i==stepIndex then C.Amber else C.Line
	end
	self.board.Visible=active and not self.hideBoard
	self.boardTitle.Text=t("remaining",{n=#s.remaining})
	self.claim.Text=t(if own then "claim_tag" else "breaker_claim",{n=if s.claimId then string.format("%02d",s.claimId) else "—"})..string.format("   ·   ×%.1f",s.heat)
	local remaining={};for _,value in s.remaining do remaining[value]=true end
	for i,cell in self.cells do
		local available=remaining[cell.value]
		cell.text.TextColor3=if available then (if i>6 then C.Amber else C.Text) else C.Line
		cell.frame.BackgroundTransparency=if available then 0.06 else 0.6
		cell.strike.Visible=not available
	end
	local offerState=state=="OFFER" or state=="FINAL_CHOICE" or state=="LIFELINE"
	self.card.Visible=offerState
	self.standby.Visible=state=="IDLE"
	self.standby.Text=t("play").."  →"
	local isFinal=state=="FINAL_CHOICE"
	self.cardTitle.Text=if own then (if isFinal then "FINAL  /  KEEP OR SWAP" else t("curator")) else t("vote")
	self.amount.Text=if isFinal then string.format("%02d  /  %02d",s.claimId or 0,s.finalId or 0) else Numbers.formatNumber(s.offer).." CR"
	self.possible.Text=if isFinal then t("final_body") else t("possible",{min=Numbers.formatNumber(s.remaining[1] or 0),max=Numbers.formatNumber(s.remaining[#s.remaining] or 0)})
	local leftKey,rightKey=if isFinal then "keep" else "extract",if isFinal then "swap" else "push"
	self.left.Text,self.right.Text=t(leftKey),t(rightKey)
	self.leftHint.Text,self.rightHint.Text=t(leftKey.."_hint"),t(rightKey.."_hint")
	local poll=s.poll
	if not own and poll.myVote then
		self.sentiment.Text=t("your_vote",{choice=t(string.lower(poll.myVote))})
	elseif poll.total==0 then self.sentiment.Text=if s.audience then t("no_votes") else t("quick_desc")
	else self.sentiment.Text=t("votes",{n=poll.total,left=math.floor(poll.left/poll.total*100+0.5),right=100-math.floor(poll.left/poll.total*100+0.5)}) end
	local enabled=(state=="OFFER" or state=="FINAL_CHOICE" or (state=="LIFELINE" and not own)) and (own or s.audience)
	if own and model.pending then enabled=false end
	UI.enabled(self.left,enabled);UI.enabled(self.right,enabled)
	self.leftHint.Visible,self.rightHint.Visible=self.showChoiceHints and own,self.showChoiceHints and own
	self.lifeline.Visible=not self.stacked and not self.touchShort and own and (s.lifelineAvailable or (s.lifelineUsed and state=="OFFER"))
	self.lifeline.Text=if s.lifelineAvailable then t("lifeline_ready") else t("lifeline_used")
	self.consensus.Visible=not self.stacked and not self.touchShort and s.consensus~=nil and state=="OFFER"
	self.consensus.Text=if s.consensus then t("consensus_"..string.lower(s.consensus)) else ""
	self.feedback.Visible=s.lastBreach~=nil and (state=="BREACH" or state=="OPENING" or state=="TRANSITION")
	if s.lastBreach then
		self.feedbackTitle.Text=t("opened",{n=Numbers.formatNumber(s.lastBreach.value)})
		self.feedbackTitle.TextColor3=if s.lastBreach.value>=2500 then C.Red else C.Teal
		self.feedbackBody.Text=if s.lastBreach.value>=2500 then t("opened_high") else t("opened_low")
	end
	self.help.Text=if not own then t("vote_note") elseif offerState then (if model.touch then t("decision_touch") else t("decision_keys")) elseif model.touch then t("touch_hint") else t("move_hint")
	self.leave.Text=if own then t("leave_run") else t("return_lobby")
	self.leave.Visible=state~="RESULT" and not model.touch
	if self.stacked or self.touchShort then
		if s.consensus and state=="OFFER" then self.body.Text=t("consensus_"..string.lower(s.consensus))
		elseif own and s.lifelineAvailable then self.body.Text=t("lifeline_ready") end
		if self.touchShort and own and s.lifelineAvailable then
			if self.h<380 then self.title.Text=t("lifeline_ready") else self.round.Text=t("lifeline_ready") end
		end
	end
	local key=s.arenaId..":"..s.runId..":"..s.phaseId
	if self.phaseKey~=key then self.phaseKey=key;self.duration=math.max(1,s.deadline-workspace:GetServerTimeNow()) end
end
function Run:tick(now)
	if not self.s or not self.card.Visible then return end
	local remaining=math.max(0,self.s.deadline-now)
	self.clock.Text=string.format("%02ds",math.ceil(remaining))
	local color=if remaining<=5 then C.Red else C.Amber
	self.clock.TextColor3,self.fill.BackgroundColor3=color,color
	self.fill.Size=UDim2.fromScale(math.clamp(remaining/(self.duration or 18),0,1),1)
end
return Run
