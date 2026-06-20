-- startup.lua — sincroniza desde GitHub y arranca el elevador
-- Repo: https://github.com/adrianin22/Elevator  (debe ser PUBLICO para este script)
-- Si lo mantienes privado, hace falta la variante con token.

local USER, REPO, RAMA = "adrianin22", "Elevator", "main"
local ARCHIVOS = { "elevador.lua", "test.lua" }   -- añade aqui mas ficheros cuando los haya

local function baja(archivo)
  local url = ("https://raw.githubusercontent.com/%s/%s/%s/%s"):format(USER, REPO, RAMA, archivo)
  local r = http.get(url)
  if not r then return false end
  local datos = r.readAll(); r.close()
  local f = fs.open(archivo, "w"); f.write(datos); f.close()
  return true
end

term.clear(); term.setCursorPos(1, 1)
print("Sincronizando con GitHub...")
for _, a in ipairs(ARCHIVOS) do
  print((baja(a) and "  ok: " or "  FALLO (uso version local): ") .. a)
end

if fs.exists("elevador.lua") then
  shell.run("elevador.lua")
else
  print("No hay elevador.lua. Revisa el repo o la conexion 