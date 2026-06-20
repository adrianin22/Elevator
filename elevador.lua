--[[ ============================================================
  ELEVADOR — control de 2 alturas (Create: Simulated + ComputerCraft)
  Computer A BORDO del elevador (sobre el Sub-Level de Sable).

  Diseño confirmado por Adrian:
    - El ordenador va EN el elevador. Lee su ALTURA real con CC: Sable
      (sublevel.getLogicalPose -> Y). No usa GPS.
    - SUBIR: 3 thrusters (uno en cada lado menos el frontal) encendidos con
      REDSTONE LOCAL (el ordenador está en la misma contraption -> sin link,
      sin el bug del link en movimiento).
    - BAJAR: se SUELTA el docking y baja por su propio peso.
    - DOCKING: se engancha al aproximarse a la altura ALTA (margen configurable).
    - Botón: en la plataforma (redstone local) o por rednet desde un botón fijo.

  Requiere: CC: Sable instalado y el ordenador montado en el Sub-Level.
  Ajusta el bloque CONFIG. Calibra las alturas y el campo de la Y (DEBUG_POSE).
============================================================ ]]

-------------------- CONFIG (ajusta a tu build) --------------------
-- Alturas (coordenada Y del mundo) de cada piso:
local ALTURA_ABAJO  = 64
local ALTURA_ARRIBA = 100
local TOL           = 0.5    -- margen para dar una altura por "alcanzada"
local MARGEN_DOCK   = 2.0    -- a esta distancia por debajo del tope: engancha docking y corta empuje

-- Salidas (lados del ordenador A BORDO):
local LADO_THRUSTERS = "bottom"  -- -> 3 thrusters (subir), redstone LOCAL
local LADO_DOCKING   = "back"    -- -> docking connector de la plataforma

-- Botón:
local MODO_BOTON  = "local"      -- "local" (lee un lado) o "rednet"
local LADO_BOTON  = "front"      -- si MODO_BOTON == "local"
local PROTO_REDNET= "elevador"   -- si MODO_BOTON == "rednet": protocolo/mensaje esperado

-- Docking / seguridad / control:
local DOCKING_NIVEL = true   -- true: docking con señal continua; false: por PULSO
local T_PULSO       = 0.3    -- s (modo docking por pulso)
local T_SUBIDA_MAX  = 15     -- s: corta thrusters si nunca llega arriba (seguridad)
local TICK          = 0.15   -- s: periodo del lazo de control
local DEBUG_POSE    = false  -- true: imprime la pose cruda para localizar el campo Y
-------------------------------------------------------------------

assert(sublevel, "CC: Sable no detectado. ¿El ordenador está en el Sub-Level y el mod instalado?")

local estado = "?"          -- ABAJO | SUBIENDO | ARRIBA | BAJANDO
local dockingEng = false
local timerCtl, timerSub = nil, nil

-- ---- lectura de altura (CC: Sable) ----
local function alturaY()
  local pose = sublevel.getLogicalPose()
  if DEBUG_POSE then print(textutils.serialize(pose)) end
  local p = pose.position or pose.pos or pose
  local y = p and (p.y or p[2])
  if type(y) ~= "number" then
    print(textutils.serialize(pose))
    error("No encuentro la Y en getLogicalPose(). Mira la estructura de arriba y ajusta alturaY().")
  end
  return y
end

-- ---- salidas ----
local function setThrusters(on) redstone.setOutput(LADO_THRUSTERS, on) end

local function setDocking(quiero)
  if DOCKING_NIVEL then
    redstone.setOutput(LADO_DOCKING, quiero)
  elseif quiero ~= dockingEng then
    redstone.setOutput(LADO_DOCKING, true); sleep(T_PULSO); redstone.setOutput(LADO_DOCKING, false)
  end
  dockingEng = quiero
end

-- ---- pantalla (base para la fase de monitores) ----
local function log(y)
  term.clear(); term.setCursorPos(1, 1)
  print("======= ELEVADOR =======")
  print("Estado : " .. estado)
  print(string.format("Altura : %.2f", y or alturaY()))
  print("Objetivo: " .. (estado == "BAJANDO" and ALTURA_ABAJO or ALTURA_ARRIBA))
  print("Thrust : " .. tostring(redstone.getOutput(LADO_THRUSTERS)))
  print("Docking: " .. tostring(dockingEng))
  print("-------------------------")
  print("Boton (" .. MODO_BOTON .. ") para alternar.")
end

-- ---- acción de botón ----
local function pulsar()
  if estado == "ABAJO" then
    estado = "SUBIENDO"; setDocking(false); setThrusters(true)
    timerSub = os.startTimer(T_SUBIDA_MAX)
  elseif estado == "ARRIBA" then
    estado = "BAJANDO"; setThrusters(false); setDocking(false)  -- soltar -> baja por su peso
  end
end

-- ---- lazo de control (se llama cada TICK) ----
local function control()
  local y = alturaY()
  if estado == "SUBIENDO" then
    if y >= ALTURA_ARRIBA - MARGEN_DOCK then
      setThrusters(false); setDocking(true); estado = "ARRIBA"; timerSub = nil
    end
  elseif estado == "BAJANDO" then
    if y <= ALTURA_ABAJO + TOL then
      setThrusters(false); estado = "ABAJO"
    end
  end
  log(y)
end

-- ---- arranque ----
local function init()
  if not sublevel.isInPlotGrid() then
    error("El ordenador NO está sobre un Sub-Level. Súbelo al elevador y ensambla la contraption.")
  end
  setThrusters(false)
  local y = alturaY()
  if y >= ALTURA_ARRIBA - MARGEN_DOCK then estado = "ARRIBA"; setDocking(true)
  else estado = "ABAJO"; setDocking(false) end
  if MODO_BOTON == "rednet" then peripheral.find("modem", rednet.open) end
  timerCtl = os.startTimer(TICK)
  log(y)
end

-- ---- bucle principal ----
init()
while true do
  local ev, a, b = os.pullEvent()
  if ev == "timer" then
    if a == timerCtl then
      control(); timerCtl = os.startTimer(TICK)
    elseif a == timerSub and estado == "SUBIENDO" then
      setThrusters(false); estado = "ABAJO"
      log(); print("[AVISO] Timeout de subida: thrusters cortados. Revisa thrusters/alturas.")
    end
  elseif ev == "redstone" then
    if MODO_BOTON == "local" and redstone.getInput(LADO_BOTON) then pulsar() end
  elseif ev == "rednet_message" then
    -- a=emisor, b=mensaje
    if MODO_BOTON == "rednet" and (b == PROTO_REDNET or b == "toggle") then pulsar() end
  end
end
