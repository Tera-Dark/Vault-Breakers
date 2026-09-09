--!nonstrict
-- A summonable game menu, not a lobby page. The world remains the primary view.
local UI=require(script.Parent.Components)
local Preview=require(script.Parent.VaultPreview)
local C=UI.colors
local Menu={}
Menu.__index=Menu
local GOLD=Color3.fromRGB(255,196,75)
local TEAL=Color3.fromRGB(84,219,187)
local BLUE=Color3.fromRGB(130,190,251)
local function tile(parent,name,accent,callback)
	local root=UI.frame(parent,name.."Tile",C.Ink);root.BackgroundTransparency=1
	local shadow=UI.frame(root,"DropShadow",Color3.fromRGB(4,9,16));UI.corner(shadow,10)
	local button=UI.button(root,name,"","secondary",callback)
	button.BackgroundColor3=C.Panel;button.ClipsDescendants=true;button:SetAttribute("Accent",accent)
	local outline=button:FindFirstChildOfClass("UIStroke");outline.Color=accent;outline.Thickness=3;outline.Transparency=0
	local wash=UI.frame(button,"Backdrop",Color3.fromRGB(41,61,80));wash.Size=UDim2.fromScale(1,1)
	UI.new("UIGradient",wash,{Color=ColorSequence.new(Color3.fromRGB(78,107,127),Color3.fromRGB(15,26,42)),Rotation=80})
	local preview=Preview.new(button,name)
	local strip=UI.frame(button,"CaptionPlate",accent)
	local title=UI.gameText(strip,"ActionTitle","",28,C.Ink);title.TextStrokeTransparency=1;title.TextXAlignment=Enum.TextXAlignment.Center;title.TextScaled=true
	local titleConstraint=UI.new("UITextSizeConstraint",title,{MinTextSize=12,MaxTextSize=28})
	local caption=UI.text(strip,"ActionHint","",12,C.Ink);caption.TextXAlignment=Enum.TextXAlignment.Center
	local badge=UI.card(button,"ModeBadge",C.Ink)
	local badgeText=UI.text(badge,"BadgeText","",10,accent,true);badgeText.TextXAlignment=Enum.TextXAlignment.Center
	return {root=root,button=button,shadow=shadow,preview=preview,strip=strip,title=title,titleConstraint=titleConstraint,caption=caption,badge=badge,badgeText=badgeText,accent=accent}
end
local function sizeTile(t,x,y,w,h,compact)
	UI.place(t.root,x,y,w,h)
	UI.place(t.shadow,0,5,w,h-5);UI.place(t.button,0,0,w,h-5)
	local stripH=if compact then 43 else 61
	UI.place(t.preview,2,1,w-4,h-stripH)
	UI.place(t.strip,0,h-5-stripH,w,stripH)
	UI.place(t.title,7,if compact then 4 else 3,w-14,if compact then 32 else 33)
	t.title.TextSize=if compact then 21 else 28;t.titleConstraint.MaxTextSize=t.title.TextSize
	UI.place(t.caption,8,34,w-16,20);t.caption.Visible=not compact
	UI.place(t.badge,9,9,math.min(w-18,112),21);UI.place(t.badgeText,5,0,math.min(w-28,102),21)
	t.badge.Visible=h>=145
end
function Menu.new(parent,actions)
	local self=setmetatable({actions=actions},Menu)
	self.root=UI.frame(parent,"QuickMenu",C.Ink);self.root.BackgroundTransparency=1;self.root.Active=false
	self.logoShadow=UI.gameText(self.root,"LogoDepth","VAULT BREAKERS",64,C.Ink);self.logoShadow.TextXAlignment=Enum.TextXAlignment.Center
	self.logo=UI.gameText(self.root,"GameLogo","VAULT BREAKERS",64,Color3.new(1,1,1));self.logo.TextXAlignment=Enum.TextXAlignment.Center
	self.logo.TextScaled=true;self.logoShadow.TextScaled=true
	UI.new("UITextSizeConstraint",self.logo,{MaxTextSize=68,MinTextSize=26})
	UI.new("UITextSizeConstraint",self.logoShadow,{MaxTextSize=68,MinTextSize=26})
	UI.new("UIGradient",self.logo,{Color=ColorSequence.new(Color3.fromRGB(255,249,225),GOLD),Rotation=90})
	self.subtitle=UI.gameText(self.root,"MenuSubtitle","",14,C.Ivory);self.subtitle.TextXAlignment=Enum.TextXAlignment.Center
	self.stageTile=tile(self.root,"STAGES",TEAL,function()actions.overlay("STAGES")end)
	self.playTile=tile(self.root,"PLAY",GOLD,function()
		if self.resultOwn then actions.replay()elseif self.resume or self.queued then actions.closeMenu()else actions.play("AUTO")end
	end)
	self.watchTile=tile(self.root,"WATCH",BLUE,function()actions.watch("MAIN")end)
	self.play=self.playTile.button;self.stagesButton=self.stageTile.button;self.watchButton=self.watchTile.button
	self.how=UI.gameButton(self.root,"Guide","","secondary",function()actions.overlay("HOW")end)
	self.board=UI.gameButton(self.root,"Records","","secondary",function()actions.overlay("BOARD")end)
	self.settings=UI.gameButton(self.root,"Settings","","secondary",function()actions.overlay("SETTINGS")end)
	self.context=UI.gameButton(self.root,"ContextAction","","secondary",function()
		if self.queued then actions.cancelQueue()else actions.leave()end
	end)
	self.note=UI.text(self.root,"MenuHint","",11,C.Muted);self.note.TextXAlignment=Enum.TextXAlignment.Center
	-- Explicit gamepad paths, with disabled targets skipped by native GUI navigation.
	self.stagesButton.NextSelectionRight=self.play;self.play.NextSelectionLeft=self.stagesButton
	self.play.NextSelectionRight=self.watchButton;self.watchButton.NextSelectionLeft=self.play
	for _,pair in {{self.stagesButton,self.how},{self.play,self.board},{self.watchButton,self.settings}}do pair[1].NextSelectionDown=pair[2];pair[2].NextSelectionUp=pair[1]end
	self.how.NextSelectionRight=self.board;self.board.NextSelectionLeft=self.how;self.board.NextSelectionRight=self.settings;self.settings.NextSelectionLeft=self.board
	return self
end
function Menu:resize(w,availableH,short)
	local portrait=w<540 and not short
	local compact=short or portrait
	local tiny=short and availableH<200
	local logoH=if tiny then 0 elseif short then 30 elseif portrait then 76 else 96
	local top=logoH+(if tiny then 4 elseif short then 9 else 31)
	local footerY
	if portrait then
		local sideW=(w-16)/2
		sizeTile(self.playTile,2,top,w-4,191,false)
		sizeTile(self.stageTile,2,top+207,sideW-2,139,true)
		sizeTile(self.watchTile,sideW+14,top+207,sideW-2,139,true)
		footerY=top+363
	else
		local centerW=math.floor(w*.38)
		local sideW=math.floor((w-centerW-28)/2)
		local centerH=if tiny then 104 elseif short then 112 else 231
		local sideH=if tiny then 96 elseif short then 99 else 191
		sizeTile(self.stageTile,2,top+centerH-sideH,sideW-2,sideH,compact)
		sizeTile(self.playTile,sideW+14,top,centerW,centerH,compact)
		sizeTile(self.watchTile,sideW+centerW+28,top+centerH-sideH,sideW-2,sideH,compact)
		footerY=top+centerH+(if short then 10 else 17)
	end
	self.contentHeight=footerY+(if self.context.Visible then 105 elseif tiny then 46 elseif short then 66 else 94)
	self.root.Size=UDim2.fromOffset(w,self.contentHeight)
	self.root.Position=UDim2.fromOffset(0,math.max(0,math.floor((availableH-self.contentHeight)/2)))
	self.logo.Visible,self.logoShadow.Visible=not tiny,not tiny
	self.logo.TextSize=if short then 34 elseif portrait then 39 else 64;self.logoShadow.TextSize=self.logo.TextSize
	UI.place(self.logoShadow,4,5,w-8,logoH);UI.place(self.logo,2,0,w-4,logoH)
	UI.place(self.subtitle,10,logoH,w-20,23);self.subtitle.Visible=not short
	local footerW=math.min(w-4,650);local x=(w-footerW)/2;local buttonW=(footerW-20)/3
	for i,button in {self.how,self.board,self.settings}do
		UI.place(button,x+(i-1)*(buttonW+10),footerY,buttonW,if short then 44 else 48)
		button.TextSize=if portrait or short then 15 else 18
	end
	UI.place(self.context,(w-math.min(w-4,280))/2,footerY+58,math.min(w-4,280),44)
	UI.place(self.note,6,footerY+61,w-12,33)
end
function Menu:render(model,t)
	local directory=model.directory
	local main
	for _,arena in (directory and directory.arenas)or{}do if arena.id=="MAIN"then main=arena end end
	self.resume=directory and directory.myArena~=nil
	self.queued=directory and (directory.queuePosition or 0)>0
	self.resultOwn=self.resume and model.snapshot and model.snapshot.state=="RESULT"
	self.subtitle.Text=if self.resume and not self.resultOwn then t("menu_live")else t("menu_tagline")
	self.playTile.title.Text=if self.resultOwn then string.upper(t("replay"))elseif self.resume then t("menu_resume")elseif self.queued then t("menu_queued",{n=directory.queuePosition})else t("menu_play")
	self.playTile.caption.Text=if self.resultOwn then t("menu_play_hint")elseif self.resume then t("menu_live")elseif self.queued then t("queue_explore")else t("menu_play_hint")
	self.playTile.badgeText.Text=if self.resultOwn then t("complete")elseif self.resume then t("on_air")elseif self.queued then t("menu_waiting")else t("menu_free")
	self.stageTile.title.Text=t("menu_stages");self.stageTile.caption.Text=t("menu_stages_hint");self.stageTile.badgeText.Text=t("menu_two_studios")
	self.watchTile.title.Text=t("menu_watch");self.watchTile.caption.Text=if main and not main.available then t("menu_watch_hint")else t("menu_no_live")
	self.watchTile.badgeText.Text=if main and not main.available then t("on_air")else t("standby")
	self.how.Text,self.board.Text,self.settings.Text=t("menu_how"),t("menu_records"),t("menu_settings")
	local profile=model.profile or{}
	local loaded=directory~=nil and profile.status~=nil and profile.status~="LOADING"
	UI.enabled(self.play,loaded or self.resume==true)
	UI.enabled(self.stagesButton,directory~=nil and not self.resume)
	UI.enabled(self.watchButton,main~=nil and not main.available and not self.resume)
	for _,item in {self.playTile,self.stageTile,self.watchTile}do
		local disabled=item.button:GetAttribute("Disabled")
		item.preview.ImageColor3=if disabled then Color3.fromRGB(125,136,148)else Color3.new(1,1,1)
		item.strip.BackgroundColor3=if disabled then item.accent:Lerp(C.Ink,.6)else item.accent
		item.title.TextColor3=if disabled then C.Muted else C.Ink
		item.caption.TextColor3=item.title.TextColor3
		if model.menuOpen then Preview.prepare(item.preview)end
	end
	self.context.Visible=self.resume or self.queued or (directory and directory.view~="LOBBY")or false
	self.context.Text=if self.queued then t("cancel_queue")elseif self.resume then t("leave_run")else t("return_lobby")
	self.note.Visible=not self.context.Visible
	local warning=profile.status=="SESSION_ONLY"or profile.status=="SAVE_DELAYED"
	self.note.Text=t(if profile.status=="SESSION_ONLY"then"session_only"elseif profile.status=="SAVE_DELAYED"then"save_delayed"else"menu_close_hint")
	self.note.TextColor3=if warning then C.Amber else C.Muted
	if profile.status=="LOADING"then self.playTile.caption.Text=t("loading")end
end
return Menu
