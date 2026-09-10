--!strict
-- Opt-in only after independent-experience DataStore acceptance. Never silently call
-- the current-server board a global/historical ranking when reads fail.
return table.freeze({Enabled=false,WriteSeconds=60,RefreshSeconds=180,StoreName="VaultBreakers_Highlights_v1"})
