-- elevador.lua (3 alturas, botones por frecuencia de redstone link)
local TF1,TF2="computercraft:redstone_relay","computercraft:redstone_relay"
local DF1,DF2="computercraft:redstone_relay","minecraft:deepslate"
local MF1,MF2="minecraft:stripped_jungle_wood","minecraft:stone"  -- pulso al llegar a MID
local Y_TOP,Y_MID,Y_BOT=62,-17,-59
-- Botones: link de Create en modo TRANSMITIR junto a cada boton, con este par de frecuencia
local BTNS={
  {"minecraft:crimson_stem","minecraft:stripped_crimson_stem",Y_TOP,"TOP"},
  {"minecraft:pale_oak_log","minecraft:stripped_pale_oak_log",Y_MID,"MID"},
  {"minecraft:cherry_wood","minecraft:stripped_cherry_log",Y_BOT,"BOT"},
}
local MID_EXTRA=3  -- subiendo desde abajo hacia MID, apunta 3 bloques mas arriba
local MD=1.5
local VOBJ=7
local DECEL=5
local HOVER=8
local KP=1.5
local HOLD_S=8
local HOLD_T=1
local TICK=0.15

local function ok(p) return p and "OK" or "FALTA" end
local br
while true do
  br=peripheral.find("redstone_link_bridge")
  if sublevel and br then break end
  term.clear();term.setCursorPos(1,1)
  print("ELEVADOR: esperando hardware")
  print("Sable:"..ok(sublevel).."  link_bridge:"..ok(br))
  print("(Ctrl+T para salir)")
  sleep(1.5)
end

local sig=0
local function setS(s)
  s=math.floor(s+0.5); if s<0 then s=0 elseif s>15 then s=15 end
  sig=s; br.sendLinkSignal(TF1,TF2,s)
end
local function dock(q) br.sendLinkSignal(DF1,DF2,q and 15 or 0) end
local function pulsoMid() br.sendLinkSignal(MF1,MF2,15); sleep(0.3); br.sendLinkSignal(MF1,MF2,0) end
local function Y()
  local p=sublevel.getLogicalPose()
  local pp=p.position or p.pos or p
  return pp.y or pp[2]
end

local target,moviendo,frenando,holdN,yp=Y_MID,false,false,0,nil
local dest="?"
local function pin(y,v,vt)
  term.clear();term.setCursorPos(1,1)
  print("=== ELEVADOR ===")
  local fase=frenando and "FRENANDO" or (moviendo and "MOVIENDO" or "PARADO")
  print("Destino: "..dest.." ("..target..")  "..fase)
  print(("Altura %.2f"):format(y))
  print(("Vel %.2f  obj %.2f"):format(v or 0, vt or 0))
  print("Senal: "..sig.."/15")
end
local function ctl()
  local y=Y(); local v=yp and (y-yp)/TICK or 0; yp=y
  local vt=0
  if frenando then
    setS(HOLD_S)
    holdN=holdN-1
    if holdN<=0 then setS(0); frenando=false; moviendo=false end
  elseif moviendo then
    local d=target-y
    vt=(d>=0 and 1 or -1)*VOBJ*math.min(1,math.abs(d)/DECEL)
    setS(HOVER+KP*(vt-v))
    if math.abs(d)<=MD then
      dock(true); frenando=true; holdN=math.ceil(HOLD_T/TICK)
      if dest=="MID" then pulsoMid() end
    end
  else
    setS(0);dock(true)
  end
  pin(y,v,vt)
end
local function irA(t,n)
  if moviendo or frenando then return end
  if math.abs(Y()-t)<=MD then return end  -- ya estamos ahi
  target=t;dest=n;dock(false);moviendo=true
end

local y0=Y()
target=(y0>=(Y_TOP+Y_MID)/2) and Y_TOP or ((y0>=(Y_MID+Y_BOT)/2) and Y_MID or Y_BOT)
dest=(target==Y_TOP and "TOP") or (target==Y_MID and "MID") or "BOT"
setS(0); dock(true)
local prev={false,false,false}
local tm=os.startTimer(TICK)
while true do
  local e,a=os.pullEvent()
  if e=="timer" and a==tm then
    for i,b in ipairs(BTNS) do
      local s=(b and br.getLinkSignal(b[1],b[2]) or 0)>0
      if s and not prev[i] then
        local t=b[3]