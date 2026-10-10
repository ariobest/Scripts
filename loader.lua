--// Ario loader: run THIS file in your executor.
--// Loads from local files first (workspace/Ario/...), falls back to BaseUrl.
local Ario = {
	Folder  = "Ario",
	BaseUrl = "", -- e.g. "https://raw.githubusercontent.com/you/repo/main/" (optional)
	Version = "1.0",
}
getgenv().Ario = Ario

function Ario.Import(path)
	local src
	local local_path = Ario.Folder .. "/" .. path
	if isfile and readfile and isfile(local_path) then
		src = readfile(local_path)
	elseif Ario.BaseUrl ~= "" then
		src = game:HttpGet(Ario.BaseUrl .. path)
	end
	assert(src, "[Ario] missing file: " .. local_path)
	local fn, err = loadstring(src, "=" .. path)
	assert(fn, "[Ario] " .. path .. ": " .. tostring(err))
	return fn()
end

Ario.Window = Ario.Import("core/Window.lua")

function Ario.OnKeyValid()
	local ok, err = pcall(Ario.Import, "main.lua")
	if not ok then warn("[Ario] main.lua failed: " .. tostring(err)) end
end

Ario.Import("core/Keysystem.lua")
