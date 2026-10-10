--// Runs after a valid key. Build your hub here with Ario.Window.
local Ario = getgenv().Ario
local win = Ario.Window.new({ Title = "ario@hub:~" })

local home = win:Tab("Home")
home:Label("Welcome to Ario")
home:Button("Say hi", function() print("hi from Ario") end)

local main = win:Tab("Main")
main:Toggle("Example toggle", false, function(on) print("toggle:", on) end)

local misc = win:Tab("Misc")
misc:Button("Close window", function() win:Destroy() end)
