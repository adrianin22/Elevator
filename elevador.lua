-- elevador.lua - empuje por Create Redstone Link controlado desde Lua
-- (mod "CC: Create Redstone Link", peripheral "redstone_link_bridge").
--
-- El setPowerNormalized de los ion thrusters esta ROTO en v1.1.4 (issues #44/#48): no responden
-- al peripheral, pero SI a redstone. Mandamos esa redstone por un Create Redstone Link cuya
-- frecuencia fijamos DESDE LUA:
--   bridge.sendLinkSignal(freq1, freq2, fuerza)   -- fuerza 0..15
-- El receptor del link (misma frecuencia) va junto a los thrusters y les da la redstone.
--
-- IMPORTANTE en el juego:
--   * Los thrusters DESCONECTADOS del modem (si un ordenador esta "attached", ignoran la redstone).
--   * Coloca el bloque "CC Redstone Link Bridge" en la red del ordenador (peripheral redstone_link_bridge).

----------------- CONFIG -----------------
local FREQ1     = "computercraft:redstone_relay"   -- frecuencia del link, slot 1
local FREQ2     = "computercraft:redstone_relay"   -- frecuencia del link, slot 2
local FUERZA_ON = 15                                -- 1..15 = empuje ; 0 = parado

local BTN_SIDE  = "top"     -- boton: entrada del redstone_relay
local DOCK_SIDE = "back"    -- docking: salida del redstone_relay

local ALTURA_ARRIBA = 63
local ALTURA_ABAJO  = -17
local MARGEN_DOCK   = 1.5    -- distancia bajo 63 para enganchar arriba y cortar empuje
local MARGEN_ABAJO  = 1.0
local VEL_SUBIR     = 1.0    -- bloques/seg objetivo (on/off para no pasarse)
local DOCKING_NIVEL = true
local T_PULSO       = 0.3
local TICK          = 0.15
local DEBUG_POSE    = false  -- true UNA vez para ver la estructura de getLogicalPose
------------------------------------------

assert(sublevel, "CC: Sable no detectado (el ordenador debe ir sobre el sub-level).")
local relay = peripheral.find("redstone_relay")
assert(relay, "No encuentro el redstone_relay (activa el modem hub).")
local bridge = peripheral.find("redstone_link_bridge")
assert(bridge, "No encuentro el redstone_link_bridge (coloca el bloque CC Redstone Link Bridge en la red).")

local empuje = false
local function setThrust(on)
  empuje = on
  bridge.sendLinkSignal(FREQ1, FREQ2, on and FUERZA_ON or 0)
end

local dockingEng = false
local function setDocking(q)
  if DOCKING_NIVEL then
    relay.setOutput(DOCK_SIDE, q)
  elseif q ~= dockingEng then
    relay.setOutput(DOCK_SIDE, true); sleep(T_PULSO); relay.setOutput(DOCK_SIDE, false)
  end
  dockingEng = q
end

local function alturaY()
  local pose = sublevel.getLogicalPose()
  if DEBUG_POSE then print(textutils.serialize(pose)) end
  local pp = pose.position or pose.pos or pose
  local y = pp and (pp.y or pp[2])
  if type(y) ~= "number" then print(textutils.serialize(pose)); error("Ajusta alturaY(): no encuentro la Y.") end
  return y
end

local estado = "ABAJO"   -- ABAJO | SUBIENDO | ARRIBA | BAJANDO
local yPrev = nil

local function pintar(y, vy)
  term.clear(); term.setCursorPos(1, 1)
  print("========= ELEVADOR =========")
  print("Estado: " .. estado)
  print(string.format("Altura: %.2f   Vel: %.2f b/s", y, vy or 0))
  print("Empuje: " .. (empuje and "ON" or "OFF") .. "   Docking: " .. tostring(dockingEng))
  print("----------------------------")
  if estado == "SUBIENDO" or estado == "BAJANDO" then
    print(">> EN MOVIMIENTO - boton BLOQUEADO <<")
  else
    print("Pulsa el boton para " .. (estado == "ABAJO" and "SUBIR" or "BAJAR") .. ".")
  end
end

local function control()
  local y = alturaY()
  local vy = yPrev and (y - yPrev) / TICK or 0
  yPrev = y

  if estado == "SUBIENDO" then
    setThrust(vy < VEL_SUBIR)            -- on/off para mantener ~VEL_SUBIR
    if y >= ALTURA_ARRIBA - MARGEN_DOCK then
      setThrust(false); setDocking(true); estado = "ARRIBA"
    end
  elseif estado == "BAJANDO" then
    setThrust(false)                     -- baja por su peso
    if y <= ALTURA_ABAJO + MARGEN_ABAJO then
      setDocking(true); estado = "ABAJO"
    end
  else -- parado
    setThrust(false)
  end
  pintar(y, vy)
end

-- El estado SOLO cambia estando PARADO. En movimiento el boton se ignora.
local function boton()
  if estado == "SUBIENDO" or estado == "BAJANDO" then return end
  if estado == "ABAJO" then
    setDocking(false); estado = "SUBIENDO"
  elseif estado == "ARRIBA" then
    setDocking(false); estado = "BAJANDO"
  end
end

do
  setThrust(false)
  local y = alturaY()
  if y >= ALTURA_ARRIBA - MARGEN_DOCK then estado = "ARRIBA" else estado = "ABAJO" end
  setDocking(true)
end