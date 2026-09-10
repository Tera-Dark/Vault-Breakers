--!nonstrict
local UI=require(script.Parent.Parent.UI.Components)
local Locale=require(script.Parent.Parent.UI.Locale)
local Rules=require(game:GetService("ReplicatedStorage").VaultBreakers.Shared.ReactionRules)
local C=UI.colors
local Audience={};Audience.__index=Audience
function Audience.new(parent)return setmetatable({parent=parent,bubbles={},seen={}},Audience)end
function Audience:receive(packet,feeds,language)
	local now=workspace:GetServerTimeNow()
	local live=feeds and feeds.MAIN
	if not live or live.runId~=packet.runId or packet.arenaId~="MAIN"or packet.expiresAt<=now or packet.createdAt>now+.5 or not table.find(Rules.ORDER,packet.key)or self.seen[packet.id]then return false end
	local world=workspace:FindFirstChild("VaultWorld");local main=world and world:FindFirstChild("MAIN")
	local anchor=main and main:FindFirstChild("ReactionAnchor",true);if not anchor then return false end
	self.seen[packet.id]=packet.expiresAt
	while #self.bubbles>=Rules.MAX_VISIBLE do self.bubbles[1].gui:Destroy();table.remove(self.bubbles,1)end
	local gui=UI.new("BillboardGui",self.parent,{Name="AudienceReaction",Adornee=anchor,Size=UDim2.fromOffset(250,66),AlwaysOnTop=false,MaxDistance=180})
	local panel=UI.card(gui,"Bubble",C.Ink);panel.Size=UDim2.fromScale(1,1)
	local by=UI.text(panel,"Who",packet.name,11,C.Muted,true);UI.place(by,12,7,226,18);by.TextTruncate=Enum.TextTruncate.AtEnd;by.TextWrapped=false
	local text=UI.gameText(panel,"Reaction",Locale.text(language,"reaction_"..packet.key),19,C.Ivory);UI.place(text,12,27,226,29)
	table.insert(self.bubbles,{gui=gui,panel=panel,text=text,by=by,at=packet.createdAt,expires=packet.expiresAt,runId=packet.runId})
	self:tick(now,live.runId,false);return true
end
function Audience:tick(now,runId,reduced)
	for key,untilTime in self.seen do if untilTime<now then self.seen[key]=nil end end
	for i=#self.bubbles,1,-1 do
		local b=self.bubbles[i]
		if now>=b.expires or b.runId~=runId then b.gui:Destroy();table.remove(self.bubbles,i)
		else
			b.gui.StudsOffsetWorldSpace=Vector3.new(0,(i-1)*2.2+(if reduced then 0 else math.min(.65,(now-b.at)*.4)),0)
			local fade=math.clamp((now-(b.expires-.45))/.45,0,1);b.panel.BackgroundTransparency=.04+.96*fade;b.text.TextTransparency=fade;b.by.TextTransparency=fade
		end
	end
end
function Audience:destroy()for _,b in self.bubbles do b.gui:Destroy()end;self.bubbles={};self.seen={}end
return Audience
