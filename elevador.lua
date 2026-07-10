-- elevador.lua (3 alturas, botones por frecuencia de redstone link)
local TF1,TF2="computercraft:redstone_relay","computercraft:redstone_relay"
local DF1,DF2="computercraft:redstone_relay","minecraft:deepslate"
local MF1,MF2="minecraft:stripped_jungle_wood","minecraft:stone"  -- pulso al llegar a MID
local Y_TOP,Y_MID,Y_BOT=61,-17,-59
local Y_TOP_LOW=60   -- TOP: docking al cruzar 60 (zona 60..61)
-- Botones: link de Create en modo TRANSMITIR junto a cada boton, con este par de frecuencia
local BTNS={
  {"minecraft:crimson_stem","minecraft:stripped_crimson_stem",Y_TOP,"TOP"},
  {"minecraft:pale_oak_log","minecraft:stripped_pale_oak_log",Y_MID,"MID"},
  {"minecraft:cherry_wood","minecraft:stripped_cherry_log",Y_BOT,"BOT"},
}
-- Bulbs indicadores: link de Create en modo RECIBIR junto a cada bulb
local BULBS={
  TOP={"minecraft:acacia_trapdoor","minecraft:acacia_pressure_plate"},
  MID={"minecraft:pale_oak_slab","minecraft:pale_oak_stairs"},
  BOT={"minecraft:mangrove_door","minecraft:cherry_stairs"},
}
local BLINK_T=3  -- ticks entre parpadeos (3*0.15s)
local MID_EXTRA=3  -- subiendo desde abajo hacia MID, apunta 3 bloques mas arriba
local MD=1.5
local ANTICIPO=0.45  -- s: adelanta el docking segun la velocidad actual
local VOBJ_UP=5    -- velocidad objetivo subiendo (b/s)
local VOBJ_DOWN=5  -- bajando: mas lenta para que sea alcanzable modulando, no apagando
local A_DEC=2  -- deceleracion asumida (b/s^2)
local V_MIN=2  -- velocidad de aproximacion final (b/s): decelera solo UN POCO, nunca a 0
local HOVER=8
local KP=1.0
local KI=0.25  -- integral anti-atasco: corrige el error de flotacion cerca del destino
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
local function VY()  -- velocidad vertical real del motor de fisicas
  local okv,vel=pcall(sublevel.getVelocity)
  if okv and vel then return vel.y or vel[2] end
  return nil
end

local target,moviendo,frenando,holdN,yp=Y_MID,false,false,0,nil
local integ=0
local dest="?"
local bulbState={TOP=-1,MID=-1,BOT=-1}
local function setBulb(n,v)
  if bulbState[n]~=v then bulbState[n]=v; br.sendLinkSignal(BULBS[n][1],BULBS[n][2],v) end
end
local function nearestFloor(y)
  local dT,dM,dB=math.abs(y-Y_TOP),math.abs(y-Y_MID),math.abs(y-Y_BOT)
  if dT<=dM and dT<=dB then return "TOP" elseif dM<=dB then return "MID" else return "BOT" end
end
local blink,blinkN=false,0
local function bulbs(y)
  if moviendo and not frenando then          -- viajando: parpadea el destino
    blinkN=blinkN+1
    if blinkN>=BLINK_T then blinkN=0; blink=not blink end
    for n in pairs(BULBS) do setBulb(n,(n==dest and blink) and 15 or 0) end
  else                                       -- llegando o parado: fijo el mas cercano
    local nf=frenando and dest or nearestFloor(y)
    for n in pairs(BULBS) do setBulb(n,n==nf and 15 or 0) end
  end
end
local function pin(y,v,vt)
  term.clear();term.setCursorPos(1,1)
  print("=== ELEVADOR ===")
  local fase=frenando and "FRENANDO" or (moviendo and "MOVIENDO" or "PARADO")
  print("Destino: "..dest.." ("..target..")  "..fase)
  print(("Altura %.2f"):format(y))
  print(("Vel %.2f  obj %.2f"):format(v or 0, vt or 0))
  print("Senal: "..sig.."/15")
end
local function setSlew(s)  -- max +-2 niveles por tick para evitar trompicones
  local d=s-sig
  if d>2 then s=sig+2 elseif d<-2 then s=sig-2 end
  setS(s)
end
local function ctl()
  local y=Y()
  local v=VY()
  if not v then v=yp and (y-yp)/TICK or 0 end  -- fallback: derivada de posicion
  yp=y
  local vt=0
  if frenando then
    setS(HOLD_S)
    holdN=holdN-1
    if holdN<=0 then setS(0); frenando=false; moviendo=false end
  elseif moviendo then
    local d=target-y
    -- crucero constante; cerca del destino decelera suave hasta V_MIN (siempre analogico 1-15)
    vt=(d>=0 and 1 or -1)*math.min((d>=0 and VOBJ_UP or VOBJ_DOWN), math.max(V_MIN, math.sqrt(2*A_DEC*math.abs(d))))
    local err=vt-v
    local u=HOVER+KP*err+integ
    -- anti-windup: no integrar hacia la saturacion
    if (u>0 and u<15) or (u<=0 and err>0) or (u>=15 and err<0) then
      integ=integ+KI*err
      if integ>6 then integ=6 elseif integ<-6 then integ=-6 end
      u=HOVER+KP*err+integ
    end
    if d<0 and u>HOVER+4 then u=HOVER+4 end  -- bajando: frena sin salir disparado arriba
    setSlew(u)
    local llego
    if dest=="TOP" then llego=y>=Y_TOP_LOW  -- TOP: dock al cruzar 60, subiendo lento
    else llego=math.abs(d)<=MD+math.abs(v)*ANTICIPO end
    if llego then
      dock(true); frenando=true; holdN=math.ceil(HOLD_T/TICK)
      if dest=="MID" then pulsoMid() end
    end
  else
    setS(0);dock(true)
  end
  bulbs(y)
  pin(y,v,vt)
end
local function irA(t,n)
  if moviendo or frenando then return end
  if math.abs(Y()-t)<=MD then return end  -- ya estamos ahi
  target=t;dest=n;integ=0;dock(false);moviendo=true
  setS(HOVER)  -- arranca en equilibrio aprox, no desde 0
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
        if b[4]=="MID" and Y()<Y_MID then t=Y_MID+MID_EXTRA end
        irA(t,b[4])
      end
      prev[i]=s
    end
    ctl()
    tm=os.startTimer(TICK)
  end
end
--@@END@@
