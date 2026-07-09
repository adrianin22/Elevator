-- startup.lua — sincroniza desde GitHub y arranca el elevador
-- Repo: https://github.com/adrianin22/Elevator  (publico)
-- Verifica la marca @@END@@ para rechazar descargas truncadas.

local USER, REPO, RAMA = "adrianin22", "Elevator", "main"
local ARCHIVOS = { "startup.lua", "elevador.lua", "test.lua" }
local MARCA = "@@END" .. "@@"   -- partido para no detectarse a si mismo

local function baja(archivo)
  local err
  for intento = 1, 5 do
    local url = ("https://raw.githubusercontent.com/%s/%s/%s/%s?cb=%d"):format(USER, REPO, RAMA, archivo, os.epoch("utc"))
    local r; r, err = http.get(url)
    if r then
      local datos = r.readAll() or ""; r.close()
      if datos:find(MARCA, 1, true) then
        local f = fs.open(archivo, "w")
        if not f then return false, "no puedo escribir " .. archivo end
        f.write(datos); f.close()
        return true
      end
      err = ("incompleta: %d bytes"):format(#datos)
    end
    sleep(1)
  end
  return false, err
end

term.clear(); term.setCursorPos(1, 1)
print("Sincronizando con GitHub...")
for _, a in ipairs(ARCHIVOS) do
  local ok, err = baja(a)
  if ok then print("  ok: " .. a)
  else print("  FALLO: " .. a .. " -> " .. tostring(err)) end
end

if fs.exists("elevador.lua") then
  shell.run("elevador.lua")
else
  print("No hay elevador.lua. Revisa el repo o la conexion.")
end
--@@END@@
