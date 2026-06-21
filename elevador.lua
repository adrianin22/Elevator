-- elevador.lua (compacto)
local F="computercraft:redstone_relay"
local BTN,DOCK="top","back"
local YA,YB=63,-17
local MD,MB=1.5,1.0
local VS=1.0
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

local function thr(o) br.sendLinkSignal(F,F,o and 15 or 0) end
local function dock(q) rl.setOutput(DOCK,q) end
local function Y()
  local p=sublevel.getLogicalPose()
  local pp=p.position or p.pos or p
  return pp.y or pp[2]
end

local st,yp,emp="ABAJO",nil,false
local function pin(y,v)
  term.clear();term.setCursorPos(1,1)
  print("=== ELEVADOR ===")
  print("Estado: "..st)
  print(("Altura %.2f  Vel %.2f"):format(y,v or 0))
  print("Empuje: "..(emp and "ON" or "OFF"))
  if st=="SUBIENDO" or st=="BAJANDO" then print(">> en movimiento <<")
  else print("Pulsa boton para "..(st=="ABAJO" and "SUBIR" or "BAJAR")) end
end
local function setemp(o) emp=o; thr(o) end
local function ctl()
  local y=Y(); local v=yp and (y-yp)/TICK or 0; yp=y
  if st=="SUBIENDO" then
    setemp(true)
    if y>=YA-MD then setemp(false);dock(true);st="ARRIBA" end
  elseif st=="BAJANDO" then
    setemp(false)
    if y<=YB+MB then dock(true);st="ABAJO" end
  else setemp(false) end
  pin(y,v)
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
