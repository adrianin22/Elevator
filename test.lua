-- test.lua — diagnostico SEGURO de los ion thrusters (no puede romper nada).
-- Para el elevador (manten Ctrl+T), ejecuta:  test   y mandame la pantalla.

local function try(f) local ok, v = pcall(f); if ok then return v else return "ERR:" .. tostring(v) end end

local ts = { peripheral.find("ion_thruster") }
print("ion_thruster encontrados: " .. #ts)
if #ts == 0 then print("Ninguno: activa el modem cableado (clic derecho)."); return end

local t = ts[1]
local name = peripheral.getName(t)
print("Nombre: " .. name .. "   Tipo: " .. peripheral.getType(name))
local ms = try(function() return peripheral.getMethods(name) end)
if type(ms) == "table" then print("Metodos: " .. table.concat(ms, ", ")) else print("Metodos: " .. tostring(ms)) end

print("")
print(">> setPowerNormalized(1.0)")
try(function() t.setPowerNormalized(1.0) end)
print("   getPower           = " .. tostring(try(function() return t.getPower() end)))
print("   getCurrentThrustKN = " .. tostring(try(function() return t.getCurrentThrustKN() end)))
print("   getEnergyAmountFe  = " .. tostring(try(function() return t.getEnergyAmountFe() end)))

print(">> setPower(15)")
try(function() t.setPower(15) end)
print("   getPower           = " .. tostring(try(function() return t.getPower() end)))

print("Manteniendo 4s: mira si los 3 echan humo...")
for i = 1, 20 do
  for _, x in ipairs(ts) do pcall(function() x.setPowerNormalized(1.0) end) end
  sleep(0.2)
end
print("   getCurrentThrustKN = " .. tostring(try(function() return t.getCurrentThrustKN() end)))

for _, x in ipairs(ts) do pcall(function() x.setPowerNormalized(0) end) end
print("Apagado.  >> MANDAME ESTA PANTALLA <<")
