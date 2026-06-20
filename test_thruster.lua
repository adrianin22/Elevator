-- test_thruster.lua — comprueba la API REAL de los ion thrusters y por que no empujan.
-- Ejecuta:  test_thruster   (y mandame lo que imprime)

local ts = { peripheral.find("ion_thruster") }
print("Ion thrusters encontrados: " .. #ts)
if #ts == 0 then
  print("Ninguno. Activa el modem hub (clic derecho, anillo rojo).")
  return
end

local name = peripheral.getName(ts[1])
print("Peripheral: " .. name)
print("Tipo: " .. peripheral.getType(name))
print("--- METODOS REALES ---")
local ms = peripheral.getMethods(name)
table.sort(ms)
print(table.concat(ms, ", "))
print("----------------------")

local t = ts[1]
local function show(fn, ...)
  if not t[fn] then print("  " .. fn .. " -> (NO existe)"); return end
  local ok, v = pcall(t[fn], ...)
  print("  " .. fn .. " -> " .. (ok and tostring(v) or ("ERROR " .. tostring(v))))
end

print("Encendiendo a tope...")
if t.setPowerNormalized then t.setPowerNormalized(1.0) end
if t.setPower then t.setPower(15) end   -- por si acaso, ambas
sleep(0.6)

print("Lecturas con throttle al maximo:")
show("getPower")
show("getCurrentThrustPN")
show("getCurrentThrustKN")
show("getDisplayedThrustKN")
show("getObstruction")
show("getAirflowMs")
show("getEnergyAmountFe")

print("Mantengo 5s: mira si los 3 thrusters arrancan/echan humo...")
sleep(5)
show("getPower")
show("getCurrentThrustKN")

if t.setPowerNormalized then t.setPowerNormalized(0) end
if t.setPower then t.setPower(0) end
print("Apagado. Fin.")
