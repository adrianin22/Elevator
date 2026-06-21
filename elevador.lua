-- elevador.lua (compacto)
local TF1,TF2="computercraft:redstone_relay","computercraft:redstone_relay"
local DF1,DF2="computercraft:redstone_relay","minecraft:deepslate"
local BTN="top"
local YA,YB=63,-17
local MD,MB=1.5,1.0
local TICK=0.15

local function ok(p) return p and "OK" or "FALTA" end
local rl,br
while true do
  rl=peripheral.find("redstone_relay")
  br=peripheral.find("redstone_link_bridge")
  if sublevel and rl and br then break end
  term.clear();term.setCursorPos(1,1)
  print("ELEVADOR: esperando hardware")
  print("Sable: "..ok(sublevel))
  print("relay: "..ok(rl))
  print("link_bridge: "..ok(br))
  print("(Ctrl+T para salir)")
  sleep(1.5)
end

local function thr(o) br.sendLinkSignal(TF1,TF2,o and 15 or 0) end
local function dock(q) br.sendLinkSignal(DF1,DF2,q and 15 or 0) end
local function Y()
  local p=sublevel.getLogicalPose()
  local pp=p.position or p.pos or p
  return pp.y or pp[2]
end

local st,emp="ABAJO",false
local function pin(y)
  term.clear();term.setCursorPos(1,1)
  print("=== ELEVADOR ===")
  print("Estado: "..st)
  print(("Altura %.2f"):format(y))
  print("Empuje: "..(emp and "ON" or "OFF"))
  if st=="SUBIENDO" or st=="BAJANDO" then print(">> en movimiento <<")
  else print("Pulsa boton para "..(st=="ABAJO" and "SUBIR" or "BAJAR")) end
end
local function setemp(o) emp=o; thr(o) end
local function ctl()
  local y=Y()
  if st=="SUBIENDO" then
    setemp(true)
    if y>=YA-MD then setemp(false);dock(true);st="ARRIBA" end
  elseif st=="BAJANDO" then
    setemp(false)
    if y<=YB+MB then dock(true);st="ABAJO" end
  else setemp(false);dock(true) end
  pin(y)
end
local function bt()
  if st=="SUBIENDO" or st=="BAJANDO" then return end
  if st=="ABAJO" then dock(false);st="SUBIENDO"
  elseif st=="ARRIBA" then dock(false);st="BAJANDO" end
end

setemp(false)
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
