--!nonstrict
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local CameraController = {}
CameraController.__index = CameraController
function CameraController.new() return setmetatable({ owned=false,key="" },CameraController) end
function CameraController:restore()
	if self.tween then self.tween:Cancel();self.tween=nil end
	local camera=self.camera
	if camera and self.owned then
		camera.CameraType=Enum.CameraType.Custom
		camera.FieldOfView=self.originalFov or 70
		local character=Players.LocalPlayer and Players.LocalPlayer.Character
		local humanoid=character and character:FindFirstChildOfClass("Humanoid")
		if humanoid then camera.CameraSubject=humanoid end
	end
	self.owned=false;self.key=""
end
function CameraController:update(view,snapshot,settings,userId,context)
	local camera=workspace.CurrentCamera
	if camera~=self.camera then
		self:restore()
		self.camera=camera
	end
	if not camera then return false end
	local seated=context and context.seatView and settings.seatCamera~=false and not(snapshot and snapshot.breakerId==userId)
	local intro=snapshot and snapshot.state=="SHOWTIME"and not settings.reducedMotion
	local key=tostring(seated)..":"..tostring(view)..":"..tostring(snapshot and snapshot.runId)..":"..tostring(snapshot and snapshot.phaseId)..":"..tostring(settings.reducedMotion)
	if key==self.key then return true end
	local own=snapshot and snapshot.breakerId==userId
	local reveal=snapshot and snapshot.state=="REVEAL" and not settings.reducedMotion
	if not seated and not intro and (view=="LOBBY" or not snapshot or (own and not reveal)) then
		self:restore();self.key=key;return true
	end
	local world=workspace:FindFirstChild("VaultWorld")
	if not world then self:restore();return false end
	local target
	if seated then
		local cameras=world:FindFirstChild("Cameras");local node=cameras and cameras:FindFirstChild("Lobby")
		if node then target=node.CFrame end
	elseif intro then
		local cameras=world:FindFirstChild("Cameras");local node=cameras and cameras:FindFirstChild("MAINIntro")
		if node then target=node.CFrame end
	elseif reveal and snapshot.revealId then
		local arena=world:FindFirstChild(view)
		local vault=arena and arena:FindFirstChild(string.format("Vault_%02d",snapshot.revealId))
		local anchor=vault and vault:FindFirstChild("Interaction")
		if anchor then target=CFrame.lookAt(anchor.Position+anchor.CFrame.LookVector*11+Vector3.new(0,2.1,0),anchor.Position+Vector3.new(0,0.6,0)) end
		-- Wait for this specific door. Do not cache a fallback wide shot as a successful reveal.
		if not target then return false end
	else
		local cameras=world:FindFirstChild("Cameras")
		local node=cameras and cameras:FindFirstChild(view.."Wide")
		if node then target=node.CFrame end
	end
	if not target then return false end
	if not self.owned then self.originalFov=camera.FieldOfView end
	self.owned=true;self.key=key
	camera.CameraType=Enum.CameraType.Scriptable
	if self.tween then self.tween:Cancel() end
	if (reveal or intro or seated)and not settings.reducedMotion then
		self.tween=TweenService:Create(camera,TweenInfo.new(if seated then .9 elseif intro then 1.1 else .7,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{CFrame=target,FieldOfView=if seated then 65 elseif intro then 57 else 53})
		self.tween:Play()
	else camera.CFrame=target;camera.FieldOfView=if settings.reducedMotion then 65 else 62 end
	return true
end
return CameraController
