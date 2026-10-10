ARIO LOADER
1. Unzip so the folder is:  <executor workspace>/Ario/
     Ario/loader.lua, Ario/main.lua, Ario/core/Keysystem.lua, Ario/core/Window.lua
2. Execute:
     loadstring(readfile("Ario/loader.lua"))()
3. Key system opens first. On a valid key, main.lua runs and opens the window.

Edit main.lua to build your hub (tabs, buttons, toggles).
Optional: set Ario.BaseUrl in loader.lua to host the files online (needs trailing /).
