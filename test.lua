-- test.lua — diagnostico SEGURO. Para el elevador con Ctrl+T y ejecuta: test
-- (puede que el elevador se mueva un poco si los thrusters arrancan)
local function try(f) local ok, v = pcall(f); if ok then return v else return "ERR:" .. tostring(v) end end

-- 1) Suelta cualquier redstone (por si el docking lo tiene anclado)
for _, s in ipairs({ "top", "bottom", "left", "right", "front", "back" }) do
  pcall(redstone.setOutput, s, false)
end
sleep(0.5)

-- 2) ¿Esta ensamblado como objeto fisico?
print("== CONTRAPTION ==")
if sublevel then
  print("isInPlotGrid = " .. tostring(try(function() return sublevel.isInPlotGrid() end)))
else
  print("sublevel = nil (no hay CC: Sable)")
end

-- 3) Thrusters, ya sin docking
local ts = { peripheral.find("ion_thruster") }
print("== THRUSTERS: " .. #ts .. " ==")
if #ts == 0 then print("ninguno"); return end
local t = ts[1]

try(function() t.setPowerNormalized(0.6) end)
sleep(0.4)
print("getPower(set 0.6) = " .. tostring(try(function() return t.getPower() end)))
print("obstruccion       = " .. tostring(try(function() return t.getObstruction() end)))
print("airflow           = " .. tostring(try(function() return t.getAirflowMs() end)))
print("thrust kN         = " .. tostring(try(function() return t.getCurrentThrustKN() end)))
print("FE                = " .. tostring(try(function() return t.getEnergyAmountFe() end)))

print("Manteniendo 2s sin docking (mira si arrancan)...")
for i = 1, 10 do
  for _, x in ipairs(ts) do pcall(function() x.setPowerNormalized(0.6) end) end
  sleep(0.2)
end
print("getPower final = " .. tostring(try(function() return t.getPower() end)))
print("thrust final   = " .. t