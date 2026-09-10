--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local names = { "Action", "Snapshot", "Directory", "Profile", "Notice", "Reaction" }
local folder: Folder
if RunService:IsServer() then
	local old = ReplicatedStorage:FindFirstChild("VaultRemotes")
	if old then old:Destroy() end
	folder = Instance.new("Folder")
	folder.Name = "VaultRemotes"
	for _, name in names do
		local event = Instance.new("RemoteEvent")
		event.Name = name
		event.Parent = folder
	end
	folder.Parent = ReplicatedStorage
else
	folder = ReplicatedStorage:WaitForChild("VaultRemotes") :: Folder
end
local Remotes = {}
function Remotes.getEvent(name: string): RemoteEvent
	assert(table.find(names, name), "Unknown remote: " .. name)
	return folder:WaitForChild(name) :: RemoteEvent
end
return Remotes
