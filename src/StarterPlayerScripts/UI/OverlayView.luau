--!nonstrict
local UI = require(script.Parent.Components)
local Numbers = require(game:GetService("ReplicatedStorage").VaultBreakers.Config.RewardPool)
local C = UI.colors
local Overlay = {}
Overlay.__index = Overlay
function Overlay.new(parent,actions)
	local self=setmetatable({actions=actions,mode=nil},Overlay)
	self.root=UI.frame(parent,"Overlay",C.Ink);self.root.Size=UDim2.fromScale(1,1);self.root.BackgroundTransparency=0.18;self.root.ZIndex=100;self.root.Visible=false;self.root.Active=true
	self.panel=UI.card(self.root,"OverlayPanel",C.Ink)
	self.heading=UI.text(self.panel,"OverlayHeading","",21,C.Ivory,true)
	self.close=UI.button(self.panel,"CloseOverlay","×","secondary",function()actions.closeOverlay()end)
	self.body=UI.new("ScrollingFrame",self.panel,{Name="Content",BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=3,ScrollBarImageColor3=C.Line,AutomaticCanvasSize=Enum.AutomaticSize.Y,CanvasSize=UDim2.new(),ScrollingDirection=Enum.ScrollingDirection.Y,ClipsDescendants=true})
	UI.new("UIListLayout",self.body,{Padding=UDim.new(0,12),SortOrder=Enum.SortOrder.LayoutOrder})
	UI.new("UIPadding",self.body,{PaddingRight=UDim.new(0,6),PaddingBottom=UDim.new(0,16)})
	return self
end
function Overlay:resize(w,h)
	local width=math.min(640,w-32)
	local height=math.min(600,h-32)
	self.width=width-48
	UI.place(self.panel,(w-width)/2,(h-height)/2,width,height)
	UI.place(self.heading,24,19,width-104,37);UI.place(self.close,width-66,16,44,44)
	UI.place(self.body,24,78,width-48,height-100)
end
function Overlay:clear()
	for _,child in self.body:GetChildren() do if child:IsA("GuiObject") then child:Destroy() end end
end
function Overlay:paragraph(title,text,index,color)
	local row=UI.card(self.body,"Section"..index,C.Panel)
	row.Size=UDim2.new(1,-4,0,0);row.AutomaticSize=Enum.AutomaticSize.Y;row.LayoutOrder=index
	UI.new("UIPadding",row,{PaddingTop=UDim.new(0,16),PaddingBottom=UDim.new(0,16),PaddingLeft=UDim.new(0,16),PaddingRight=UDim.new(0,16)})
	UI.new("UIListLayout",row,{Padding=UDim.new(0,10),SortOrder=Enum.SortOrder.LayoutOrder})
	local heading=UI.text(row,"Title",title,14,color or C.Amber,true)
	heading.Size=UDim2.new(1,0,0,0);heading.AutomaticSize=Enum.AutomaticSize.Y;heading.LayoutOrder=1
	local body=UI.text(row,"Description",text,14,C.Muted)
	body.Size=UDim2.new(1,0,0,0);body.AutomaticSize=Enum.AutomaticSize.Y;body.LayoutOrder=2
	return row
end
function Overlay:render(mode,model,t)
	self.mode=mode;self.root.Visible=mode~=nil
	if not mode then return end
	self:clear()
	self.body.CanvasPosition=Vector2.zero
	if mode=="HOW" then
		self.heading.Text=t("guide_title")
		for i=1,4 do self:paragraph(t("guide"..i),t("guide"..i.."_body"),i,if i==2 then C.Teal else C.Amber) end
		self:paragraph("VAULT BREAKERS",t("guide_note"),5,C.Muted)
	elseif mode=="SETTINGS" then
		self.heading.Text=t("settings")
		for index,item in { {key="sound",hint="sound_hint",setting="sound"}, {key="motion",hint="motion_hint",setting="reducedMotion"}, {key="language",hint="language",setting="language"} } do
			local row=UI.card(self.body,"Preference"..index,C.Panel);row.LayoutOrder=index;row.Size=UDim2.new(1,-4,0,110)
			local title=UI.text(row,"Name",t(item.key),16,C.Ivory,true);title.Position=UDim2.fromOffset(16,12);title.Size=UDim2.new(1,-145,0,26)
			local hint=UI.text(row,"Hint",if item.setting=="language" then "中文  /  English" else t(item.hint),12,C.Muted);hint.Position=UDim2.fromOffset(16,43);hint.Size=UDim2.new(1,-150,0,55)
			local current=model.settings[item.setting]
			local text=if item.setting=="language" then (if current=="zh" then "中文" else "English") else (if current then t("on") else t("off"))
			local toggle=UI.button(row,"Toggle",text,if current==true then "primary" else "secondary",function()
				self.actions.setting(item.setting,if item.setting=="language" then (if current=="zh" then "en" else "zh") else not current)
			end)
			toggle.Size=UDim2.fromOffset(108,44);toggle.Position=UDim2.new(1,-122,0,32)
		end
	elseif mode=="BOARD" then
		self.heading.Text=t("board")
		if model.recap and model.directory and not model.directory.myArena then
			local recap=UI.button(self.body,"LastRecap",t("last_recap"),"secondary",self.actions.showRecap)
			recap.Size=UDim2.new(1,-4,0,48);recap.LayoutOrder=0
		end
		local rows=model.directory and model.directory.board or {}
		if #rows==0 then self:paragraph(t("board"),t("board_empty"),1,C.Teal) end
		for i,entry in rows do
			self:paragraph(string.format("%02d  /  %s",i,entry.name),Numbers.formatNumber(entry.best).." CR     ·     HEAT ×"..string.format("%.1f",entry.heat).."     ·     "..t("rep").." "..entry.reputation,i,if i==1 then C.Amber else C.Ivory)
		end
		self:paragraph("STUDIO RECORDS",t("board_note"),99,C.Muted)
	elseif mode=="CONFIRM" then
		self.heading.Text=t("leave_title")
		self:paragraph(t("leave_title"),t("leave_body"),1,C.Amber)
		local stay=UI.button(self.body,"Stay",t("stay"),"primary",self.actions.closeOverlay);stay.Size=UDim2.new(1,-4,0,48);stay.LayoutOrder=2
		local leave=UI.button(self.body,"ConfirmLeave",t("leave_confirm"),"secondary",self.actions.abort);leave.Size=UDim2.new(1,-4,0,48);leave.LayoutOrder=3
	end
end
return Overlay
