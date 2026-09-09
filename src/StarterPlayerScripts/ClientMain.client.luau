--!nonstrict
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local UserInputService=game:GetService("UserInputService")
local LocalizationService=game:GetService("LocalizationService")
local Remotes=require(ReplicatedStorage:WaitForChild("VaultBreakers").Network.Remotes)
local App=require(script.Parent.UI.App)
local UI=require(script.Parent.UI.Components)
local State=require(script.Parent.Controllers.ClientState)
local Camera=require(script.Parent.Controllers.CameraController)
local Effects=require(script.Parent.Controllers.AudiovisualController)
local Prompts=require(script.Parent.Controllers.PromptController)
local player=Players.LocalPlayer
local model={
	userId=player.UserId,profile={status="LOADING"},directory=nil,snapshot=nil,pending=false,
	touch=UserInputService.TouchEnabled,
	settings={language=if LocalizationService.RobloxLocaleId:sub(1,2)=="zh" then "zh" else "en",sound=true,reducedMotion=false},
}
local state=State.new(model)
local app,effects
local camera,prompts=Camera.new(),Prompts.new(player.UserId)
local lastSync=-math.huge
local function send(command,payload) Remotes.getEvent("Action"):FireServer(command,payload or {}) end
local function sync()
	if os.clock()-lastSync<1 then return end
	lastSync=os.clock();send("SYNC")
end
local function render()
	state:select()
	app:render()
	camera:update(state:view(),model.snapshot,model.settings,player.UserId)
	effects:update(model.snapshot,model.settings)
	prompts:update(model.snapshot,model.settings.language,app.overlayMode~=nil or model.showRecap or model.syncing)
end
local function matchAction(command,choice)
	local payload=state:beginAction(command,choice,os.clock())
	if not payload then return end
	send(command,payload);app:render()
end
local actions={}
function actions.play(target)
	state:hideRecap();app:showOverlay(nil);render();send("PLAY",{target=target})
end
function actions.watch(target)state:hideRecap();render();send("WATCH",{target=target})end
function actions.cancelQueue()send("CANCEL_QUEUE")end
function actions.overlay(mode)app:showOverlay(mode);render()end
function actions.closeOverlay()actions.overlay(nil)end
function actions.setting(key,value)
	model.settings[key]=value;render();app:refreshOverlay()
end
function actions.choice(index)
	if app.overlayMode or model.showRecap or (index~=1 and index~=2) then return end
	local s=model.snapshot
	if not s then return end
	local own=s.breakerId==player.UserId
	local final=s.state=="FINAL_CHOICE"
	if not final and s.state~="OFFER" and not (s.state=="LIFELINE" and not own) then return end
	if not own and not s.audience then return end
	if workspace:GetServerTimeNow()>=s.deadline then sync();return end
	local choice=if final then (if index==1 then "KEEP" else "SWAP") else (if index==1 then "EXTRACT" else "PUSH")
	matchAction(if not own then "VOTE" elseif final then "FINAL" else "DECIDE",choice)
end
function actions.leave()
	if model.showRecap then actions.returnLobby();return end
	if model.snapshot and model.snapshot.breakerId==player.UserId then actions.overlay("CONFIRM") else send("LOBBY") end
end
function actions.abort()actions.closeOverlay();matchAction("LEAVE_RUN")end
function actions.replay()
	state:hideRecap();render()
	if model.snapshot and model.snapshot.breakerId==player.UserId then matchAction("REPLAY") else actions.play("AUTO") end
end
function actions.returnLobby()
	state:hideRecap();render()
	if model.snapshot and model.snapshot.breakerId==player.UserId then matchAction("LEAVE_RUN") else send("LOBBY") end
end
function actions.showRecap()
	if model.recap and model.directory and not model.directory.myArena then
		model.showRecap=true;actions.closeOverlay()
	end
end
app=App.new(player:WaitForChild("PlayerGui"),model,actions)
effects=Effects.new(app.root)
UI.click=function()effects:play("Click")end
Remotes.getEvent("Directory").OnClientEvent:Connect(function(data)
	local accepted,assignmentChanged=state:directory(data)
	if not accepted then return end
	if assignmentChanged then app:showOverlay(nil) end
	render()
end)
Remotes.getEvent("Snapshot").OnClientEvent:Connect(function(data)
	if state:snapshot(data) then render() end
end)
Remotes.getEvent("Profile").OnClientEvent:Connect(function(data)model.profile=data;render()end)
Remotes.getEvent("Notice").OnClientEvent:Connect(function(key,args)state:clearPending();app:notify(key,args);render()end)
UserInputService.InputBegan:Connect(function(input,processed)
	if processed or UserInputService:GetFocusedTextBox() then return end
	if input.KeyCode==Enum.KeyCode.One or input.KeyCode==Enum.KeyCode.ButtonX then actions.choice(1)
	elseif input.KeyCode==Enum.KeyCode.Two or input.KeyCode==Enum.KeyCode.ButtonY then actions.choice(2)
	elseif input.KeyCode==Enum.KeyCode.ButtonB and app.overlayMode then actions.closeOverlay() end
end)
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()camera:update(state:view(),model.snapshot,model.settings,player.UserId)end)
player.CharacterAdded:Connect(function(character)
	camera:restore()
	task.spawn(function()
		local humanoid=character:WaitForChild("Humanoid",10)
		if humanoid and player.Character==character then camera:restore();render() end
	end)
end)
local refreshAt=0
RunService.RenderStepped:Connect(function()
	local localNow=os.clock()
	if state:expirePending(localNow) then app:render();sync() end
	local now=workspace:GetServerTimeNow()
	app:tick(now);effects:tick(model.snapshot,now)
	if localNow>=refreshAt then
		refreshAt=localNow+0.2
		camera:update(state:view(),model.snapshot,model.settings,player.UserId)
		prompts:update(model.snapshot,model.settings.language,app.overlayMode~=nil or model.showRecap or model.syncing)
		if model.syncing and localNow-lastSync>=2 then sync() end
	end
end)
-- Subscribe before requesting state. No optimistic decision replay on a timeout.
task.spawn(function()
	for _=1,20 do
		sync()
		if model.directory and model.profile.status~="LOADING" then break end
		task.wait(1)
	end
end)
print("[Vault Breakers] Client ready: role-aware broadcast UI, two studios, local preferences.")
