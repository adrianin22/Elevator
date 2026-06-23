-- elevador.lua (control de velocidad + frenado al llegar)
local TF1,TF2="computercraft:redstone_relay","computercraft:redstone_relay"
local DF1,DF2="computercraft:redstone_relay","minecraft:deepslate"
local BTN="top"
local YA,YB=64,-17
local MD,MB=1.5,1.0
local VOBJ=7      -- velocidad objetivo (bloques/seg)
local DECEL=5     -- ultimos N bloques: decelera de VOBJ hasta 0
local HOVER=8     -- fuerza redstone 0-15 que ~cancela gravedad (TUNEAR)
local KP=1.5      -- ganancia (TUNEAR)
local TICK=0.15

local function ok(p) return p and "OK" or "FALTA" end
local rl,br
while true do
  rl=peripheral.find("redstone_relay")
  br=peripheral.find("redstone_link_bridge")
  if sublevel and rl and br then break end
  term.clear();term.setCursorPos(1,1)
  print("ELEVADOR: esperando hardware")
  print("Sable: "..ok(sublevel)); print("relay: "..ok(rl)); print("link_bridge: "..ok(br))
  print("(Ctrl+T para salir)")
  sleep(1.5)
end

local sig=0
local function setS(s)
  s=math.floor(s+0.5); if s<0 then s=0 elseif s>15 then s=15 end
  sig=s; br.sendLinkSignal(TF1,TF2,s)
end
local function dock(q) br.sendLinkSignal(DF1,DF2,q and 15 or 0) end
local function Y()
  local p=sublevel.getLogicalPose()
  local pp=p.position or p.pos or p
  return pp.y or pp[2]
end

local st,yp="ABAJO",nil
local function pin(y,v,vt)
  term.clear();term.setCursorPos(1,1)
  print("=== ELEVADOR ===")
  print("Estado: "..st)
  print(("Altura %.2f"):format(y))
  print(("Vel %.2f  obj %.2f"):format(v or 0, vt or 0))
  print("Senal: "..sig.."/15")
  if st=="SUBIENDO" or st=="BAJANDO" then print(">> en movimiento <<")
  else print("Pulsa boton para "..(st=="ABAJO" and "SUBIR" or "BAJAR")) end
end
local function ctl()
  local y=Y(); local v=yp and (y-yp)/TICK or 0; yp=y
  local vt=0
  if st=="SUBIENDO" then
    vt=VOBJ*math.max(0,math.min(1,(YA-y)/DECEL))
    setS(HOVER+KP*(vt-v))
    if y>=YA-MD then setS(0);dock(true);st="ARRIBA" end
  elseif st=="BAJANDO" then
    vt=-VOBJ*math.max(0,math.min(1,(y-YB)/DECEL))
    setS(HOVER+KP*(vt-v))
    if y<=YB+MB then setS(0);dock(true);st="ABAJO" end
  else setS(0);dock(true) end
  pin(y,v,vt)
end
local function bt()
  if st=="SUBIENDO" or st=="BAJANDO" then return end
  if st=="ABAJO" then dock(false);st="SUBIENDO"
  elseif st=="ARRIBA" then dock(false);st="BAJANDO" end
end

setS(0)
local y0=Y(); st=(y0>=YA-MD) and "ARRIBA" or "ABAJO"; dock(true)
local bp=false
local tm=os.startTimer(TICK)
while true do
  local e,a=os.pullEvent()
  if e=="timer" and a==tm then
    local b=rl.getInput(BTN)
    if b and not bp then bt() end
    bp=b
    ctl()
    tm=os.startTimer(TICK)
  end
end
--@@END@@
