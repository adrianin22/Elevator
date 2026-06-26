-- elevador.lua (3 alturas: 64 / -17 / -62, velocidad estable)
local TF1,TF2="computercraft:redstone_relay","computercraft:redstone_relay"
local DF1,DF2="computercraft:redstone_relay","minecraft:deepslate"
local R_NORMAL="redstone_relay_3"   -- boton normal (toggle arriba/medio)
local R_FONDO="redstone_relay_5"    -- boton: bajar al fondo (-62)
local BTN="top"
local Y_TOP,Y_MID,Y_BOT=64,-17,-62
local MD=1.5
local VOBJ=7        -- velocidad objetivo (b/s)
local DECEL=5       -- ultimos N bloques: frena hasta 0
local HOVER=8       -- fuerza 0-15 que ~cancela gravedad (TUNEAR)
local KP=1.5        -- ganancia (TUNEAR)
local TICK=0.15

local function ok(p) return p and "OK" or "FALTA" end
local rl,rl5,br
while true do
  rl=peripheral.wrap(R_NORMAL)
  rl5=peripheral.wrap(R_FONDO)
  br=peripheral.find("redstone_link_bridge")
  if sublevel and rl and rl5 and br then break end
  term.clear();term.setCursorPos(1,1)
  print("ELEVADOR: esperando hardware")
  print("Sable:"..ok(sublevel).." relay3:"..ok(rl).." relay5:"..ok(rl5))
  print("link_bridge:"..ok(br))
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

local target,moviendo,yp=Y_MID,false,nil
local function pin(y,v,vt)
  term.clear();term.setCursorPos(1,1)
  print("=== ELEVADOR ===")
  print("Destino: "..target.."  "..(moviendo and "MOVIENDO" or "PARADO"))
  print(("Altura %.2f"):format(y))
  print(("Vel %.2f  obj %.2f"):format(v or 0, vt or 0))
  print("Senal: "..sig.."/15")
end
local function ctl()
  local y=Y(); local v=yp and (y-yp)/TICK or 0; yp=y
  local vt=0
  if moviendo then
    local d=target-y
    vt=(d>=0 and 1 or -1)*VOBJ*math.min(1,math.abs(d)/DECEL)
    setS(HOVER+KP*(vt-v))
    if math.abs(d)<=MD then setS(0);dock(true);moviendo=false end
  else
    setS(0);dock(true)
  end
  pin(y,v,vt)
end
local function irA(t) if not moviendo then target=t;dock(false);moviendo=true end end
local function botonNormal()
  if moviendo then return end
  local y=Y()
  if y>=Y_TOP-MD or y<=Y_BOT+MD then irA(Y_MID) else irA(Y_TOP) end
end

local y0=Y()
target=(y0>=(Y_TOP+Y_MID)/2) and Y_TOP or ((y0>=(Y_MID+Y_BOT)/2) and Y_MID or Y_BOT)
setS(0); dock(true)
local bp,bp5=false,false
local tm=os.startTimer(TICK)
while true do
  local e,a=os.pullEvent()
  if e=="timer" and a==tm then
    local b=rl.getInput(BTN)
    if b and not bp then botonNormal() end
    bp=b
    local b5=rl5.getInput(BTN)
    if b5 and not bp5 then irA(Y_BOT) end
    bp5=b5
    ctl()
    tm=os.startTimer(TICK)
  end
end
--@@END@@
