--!nonstrict
local UI = require(script.Parent.Components)
local Numbers = require(game:GetService("ReplicatedStorage").VaultBreakers.Config.RewardPool)
local Catalog=require(game:GetService("ReplicatedStorage").VaultBreakers.Config.CosmeticCatalog)
local C = UI.colors
local Overlay = {}
Overlay.__index = Overlay
function Overlay.new(parent,actions)
	local self=setmetatable({actions=actions,mode=nil},Overlay)
	self.root=UI.frame(parent,"Overlay",C.Ink);self.root.Size=UDim2.fromScale(1,1);self.root.BackgroundTransparency=1;self.root.ZIndex=100;self.root.Visible=false;self.root.Active=false
	self.panel=UI.card(self.root,"OverlayPanel",C.Ink);self.panel.Active=true
	self.panel:FindFirstChildOfClass("UIStroke").Thickness=2
	self.heading=UI.gameText(self.panel,"OverlayHeading","",24,C.Ivory);self.heading.TextScaled=true
	UI.new("UITextSizeConstraint",self.heading,{MinTextSize=14,MaxTextSize=24})
	self.close=UI.gameButton(self.panel,"CloseOverlay","×","secondary",function()actions.closeOverlay()end)
	self.back=UI.gameButton(self.panel,"BackToMenu","←","secondary",actions.backToMenu)
	self.body=UI.new("ScrollingFrame",self.panel,{Name="Content",BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=3,ScrollBarImageColor3=C.Line,AutomaticCanvasSize=Enum.AutomaticSize.Y,CanvasSize=UDim2.new(),ScrollingDirection=Enum.ScrollingDirection.Y,ClipsDescendants=true})
	UI.new("UIListLayout",self.body,{Padding=UDim.new(0,12),SortOrder=Enum.SortOrder.LayoutOrder})
	UI.new("UIPadding",self.body,{PaddingRight=UDim.new(0,6),PaddingBottom=UDim.new(0,16)})
	return self
end
function Overlay:resize(w,h)
	local width=math.min(640,w-32)
	local height=math.min(600,h-100)
	self.width=width-48
	UI.place(self.panel,(w-width)/2,math.max(84,(h-height)/2),width,height)
	UI.place(self.back,16,12,44,44);UI.place(self.heading,73,13,width-146,44);UI.place(self.close,width-60,12,44,44)
	UI.place(self.body,20,72,width-40,height-86)
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
	self.preferenceButtons={};self.defaultButton=self.close
	self.body.CanvasPosition=Vector2.zero
	if mode=="HOW" then
		self.heading.Text=t("guide_title")
		for i=1,4 do self:paragraph(t("guide"..i),t("guide"..i.."_body"),i,if i==2 then C.Teal else C.Amber) end
		self:paragraph("VAULT BREAKERS",t("guide_note"),5,C.Muted)
	elseif mode=="SETTINGS" then
		self.heading.Text=t("settings")
		for index,item in { {key="sound",hint="sound_hint",setting="sound"}, {key="music",hint="music_hint",setting="music"}, {key="crowd",hint="crowd_hint",setting="crowd"}, {key="seat_camera",hint="seat_camera_hint",setting="seatCamera"}, {key="floor_guides",hint="floor_guides_hint",setting="floorGuides"}, {key="motion",hint="motion_hint",setting="reducedMotion"}, {key="language",hint="language",setting="language"} } do
			local row=UI.card(self.body,"Preference"..index,C.Panel);row.LayoutOrder=index;row.Size=UDim2.new(1,-4,0,110)
			local title=UI.text(row,"Name",t(item.key),16,C.Ivory,true);title.Position=UDim2.fromOffset(16,12);title.Size=UDim2.new(1,-145,0,26)
			local hint=UI.text(row,"Hint",if item.setting=="language" then "中文  /  English" else t(item.hint),12,C.Muted);hint.Position=UDim2.fromOffset(16,43);hint.Size=UDim2.new(1,-150,0,55)
			local current=model.settings[item.setting]
			local text=if item.setting=="language" then (if current=="zh" then "中文" else "English") else (if current then t("on") else t("off"))
			local toggle=UI.button(row,"Toggle",text,if current==true then "primary" else "secondary",function()
				self.actions.setting(item.setting,if item.setting=="language" then (if current=="zh" then "en" else "zh") else not current)
			end)
			toggle.Size=UDim2.fromOffset(108,44);toggle.Position=UDim2.new(1,-122,0,32)
			self.preferenceButtons[item.setting]=toggle
		end
	elseif mode=="STAGES" then
		self.heading.Text=t("menu_stages")
		local d=model.directory
		local queued=d and (d.queuePosition or 0)>0
		for i,arena in (d and d.arenas)or{}do
			local main=arena.id=="MAIN"
			local row=UI.card(self.body,"Stage"..arena.id,C.Panel);row.LayoutOrder=i;row.Size=UDim2.new(1,-4,0,180)
			local accent=if main then C.Amber else C.Teal
			local tag=UI.text(row,"Studio","STUDIO 0"..i,11,accent,true);tag.Position=UDim2.fromOffset(16,10);tag.Size=UDim2.new(1,-32,0,20)
			local title=UI.gameText(row,"StageTitle",t(if main then "main"else"quick"),25,C.Ivory);title.Position=UDim2.fromOffset(16,33);title.Size=UDim2.new(1,-32,0,33)
			local description=UI.text(row,"Description",t(if main then "main_desc"else"quick_desc"),13,C.Muted);description.Position=UDim2.fromOffset(16,68);description.Size=UDim2.new(1,-32,0,30)
			local status=UI.text(row,"Status",if arena.available then t("available")else t("playing",{name=arena.name}),12,accent,true);status.Position=UDim2.fromOffset(16,97);status.Size=UDim2.new(1,-32,0,23);status.TextTruncate=Enum.TextTruncate.AtEnd;status.TextWrapped=false
			local watch=main and not arena.available
			local button=UI.gameButton(row,"Join"..arena.id,t(if watch then "watch"elseif main then "enter"elseif arena.available then "join_quick"else"queue_quick"),if main then "primary"else"teal",function()
				if watch then self.actions.watch(arena.id)else self.actions.play(arena.id)end
			end)
			button.Position=UDim2.fromOffset(16,126);button.Size=UDim2.new(1,-32,0,44);button.TextSize=16
			UI.enabled(button,not d.myArena and (watch or(not queued and model.profile.status~="LOADING")))
			if button.Active and self.defaultButton==self.close then self.defaultButton=button end
		end
		if queued then
			local cancel=UI.gameButton(self.body,"CancelQueue",t("cancel_queue"),"secondary",self.actions.cancelQueue);cancel.Size=UDim2.new(1,-4,0,48);cancel.LayoutOrder=5
		end
	elseif mode=="BOARD" then
		self.heading.Text=t("board")
		local style=UI.gameButton(self.body,"OpenStyle",t("style_menu"),"secondary",function()self.actions.overlay("STYLE")end)
		style.Size=UDim2.new(1,-4,0,48);style.LayoutOrder=-2
		local p=model.profile or{}
		self:paragraph(t("menu_my_record"),if p.status=="LOADING"then t("loading")else string.format("%s: %s\n%s: %s CR\n%s: %s",t("rep"),Numbers.formatNumber(p.reputation or 0),t("best"),Numbers.formatNumber(math.max(p.bestExtract or 0,p.bestFinal or 0)),t("runs"),tostring(p.runs or 0)),-1,C.Amber)
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
	elseif mode=="STYLE_CONFIRM"then
		self.heading.Text=t("style_confirm")
		local id=model.styleConfirm;local item=id and Catalog.ITEMS[id]
		if not item then return end
		self:paragraph(t(item.name),t("style_confirm_body",{n=Numbers.formatNumber(item.price)}),1,C.Amber)
		local buy=UI.gameButton(self.body,"ConfirmPurchase",t("style_buy",{n=Numbers.formatNumber(item.price)}),"primary",function()self.actions.style("BUY_STYLE",id);self.actions.overlay("STYLE")end)
		buy.Size=UDim2.new(1,-4,0,48);buy.LayoutOrder=2;UI.enabled(buy,not model.stylePending)
		local cancel=UI.gameButton(self.body,"CancelPurchase",t("style_cancel"),"secondary",function()self.actions.overlay("STYLE")end);cancel.Size=UDim2.new(1,-4,0,48);cancel.LayoutOrder=3
		self.defaultButton=cancel
	elseif mode=="STYLE"then
		self.heading.Text=t("style_menu")
		local p=model.profile or{};local owned=p.ownedCosmetics or{};local earned=p.achievements or{}
		self:paragraph(t("style_trim"),t("style_rules"),-1,C.Teal)
		for i,id in Catalog.ORDER do
			local item=Catalog.ITEMS[id];local row=UI.card(self.body,"Style"..id,C.Panel);row.Size=UDim2.new(1,-4,0,135);row.LayoutOrder=i
			local color=if item.rgb then Color3.fromRGB(table.unpack(item.rgb))else C.Silver
			local swatch=UI.mark(row,"WheelTone",color);UI.place(swatch,16,17,36,36)
			local title=UI.gameText(row,"StyleName",t(item.name),18,C.Ivory);title.Position=UDim2.fromOffset(68,15);title.Size=UDim2.new(1,-84,0,27)
			local price=UI.text(row,"Price",if owned[id]then t("style_owned")else Numbers.formatNumber(item.price).." CR",13,C.Muted);price.Position=UDim2.fromOffset(68,46);price.Size=UDim2.new(1,-84,0,23)
			local equipped=p.equippedCosmetic==id
			local button=UI.gameButton(row,"StyleAction",if equipped then t("style_current")elseif owned[id]then t("style_equip")else t("style_buy",{n=Numbers.formatNumber(item.price)}),if equipped then "teal"else"secondary",function()
				if owned[id]then self.actions.style("EQUIP_STYLE",id)else self.actions.confirmStyle(id)end
			end)
			button.Position=UDim2.fromOffset(16,78);button.Size=UDim2.new(1,-32,0,44);button.TextSize=15
			UI.enabled(button,not equipped and not model.stylePending and p.status~="LOADING"and(owned[id]or p.status=="READY"or p.status=="SAVE_DELAYED"))
		end
		self:paragraph(t("style_titles"),t("style_title_rules"),10,C.Amber)
		local none=UI.gameButton(self.body,"NoTitle",t("title_none"),"secondary",function()self.actions.style("EQUIP_TITLE","")end);none.Size=UDim2.new(1,-4,0,44);none.LayoutOrder=11
		UI.enabled(none,p.equippedTitle~=""and not model.stylePending)
		for i,id in Catalog.TITLES do
			local row=self:paragraph(t("title_"..id),t("title_"..id.."_hint"),12+i,if earned[id]then C.Amber else C.Muted)
			local button=UI.gameButton(row,"EquipTitle",if p.equippedTitle==id then t("style_current")elseif earned[id]then t("style_equip")else t("style_locked"),"secondary",function()self.actions.style("EQUIP_TITLE",id)end)
			button.Size=UDim2.new(1,0,0,44);button.LayoutOrder=3;button.TextSize=15
			UI.enabled(button,earned[id]==true and p.equippedTitle~=id and not model.stylePending)
		end
	elseif mode=="CONFIRM" then
		self.heading.Text=t("leave_title")
		self:paragraph(t("leave_title"),t("leave_body"),1,C.Amber)
		local stay=UI.button(self.body,"Stay",t("stay"),"primary",self.actions.closeOverlay);stay.Size=UDim2.new(1,-4,0,48);stay.LayoutOrder=2
		local leave=UI.button(self.body,"ConfirmLeave",t("leave_confirm"),"secondary",self.actions.abort);leave.Size=UDim2.new(1,-4,0,48);leave.LayoutOrder=3
	end
end
function Overlay:focusTarget(setting)
	return (setting and self.preferenceButtons and self.preferenceButtons[setting])or self.defaultButton or self.close
end
return Overlay
