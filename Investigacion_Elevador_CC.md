# Elevador con ComputerCraft — Investigación de mods y APIs

> Objetivo: un elevador (objeto físico de **Create: Simulated**) que con **un botón** alterne entre **dos alturas** (das al botón → sube a la altura A; das otra vez → baja a la altura B), controlado con **ComputerCraft**. Más adelante se añadirán monitores con estado del elevador y pantallas de información.
>
> Este documento recoge **solo lo verificado en fuentes oficiales** (wikis/docs de cada mod). Lo que es decisión de diseño o depende de tu build concreto está marcado como **[A CONFIRMAR]**. Fuentes al final.
>
> Fecha de la investigación: 2026-06-20.

---

## ★ Tu build (confirmado) y resumen del diseño

| Dato | Valor confirmado |
|------|------------------|
| Tipo de elevador | Objeto físico (sub-level de **Create: Simulated**) |
| Qué lo mueve | **Thrusters redstone/cinéticos** (empuje analógico, escala con redstone 0–15) |
| Computadora | **Fuera** del elevador (no a bordo) → la API `sublevel` de CC: Sable **no se usa** |
| Parada en cada altura | **Docking connector** en cada altura (idea del usuario) |
| Versión | **Minecraft 1.21.1 — NeoForge** |

**Consecuencia inmediata:** como la computadora va fuera, NO puede leer la altura con CC: Sable. El sensado tiene que ser **externo** (el docking connector y/o un detector por piso). Y el reto central pasa a ser **cómo llega la orden de empuje a un thruster que está sobre una contraption en movimiento** (ver §7, es la decisión clave que queda).

**Versiones a usar (todo NeoForge 1.21.1):**

| Mod | Versión / nota |
|-----|----------------|
| Create: Simulated / Aeronautics (+ Thrusters) | NeoForge 1.21.1 (motor Sable) |
| CC: Sable | NeoForge 1.21.1 (archivos 1.0.0 → 1.1.1; docs act. 2026-05-13) — *solo necesaria si algún día pones un computer a bordo* |
| CC:C Bridge | mc1.21.1, **v1.7.3** (jun 2026), (Neo)Forge + Fabric |
| Tom's Peripherals | 1.21 NeoForge (para las pantallas de la fase 2) |
| CC: Tweaked | la build de CC:Tweaked para 1.21.1 NeoForge |

---

## 0. Aclaración crítica antes de nada

Hay **dos cosas distintas** que la gente llama "elevador" en Create, y el enfoque cambia por completo:

1. **Elevator Pulley** (Create *normal/vanilla*): bloque dedicado de ascensor. Se mueve por **animación scripted**, se detiene solo en "pisos" marcados con **Redstone Contacts**, y cada piso se puede **llamar con una señal de redstone** y **emite redstone cuando el ascensor está parado ahí**. Es trivial de controlar con ComputerCraft.

2. **Objeto físico de Create: Simulated** (lo que tú tienes): es una **contraption de física real** (motor *Sable*), también llamada **sub-level**. No se "teletransporta" entre pisos: **flota/cae con física** y hay que **empujarlo con fuerza** (thrusters) y **frenarlo/sostenerlo** activamente. Mucho más realista, pero más complejo de controlar.

Como tu elevador es del tipo **(2)**, este documento se centra ahí, pero incluyo el tipo **(1)** como **alternativa robusta** por si te compensa.

---

## 1. Inventario de mods y qué aporta cada uno

| Mod | Para qué sirve en este proyecto |
|-----|--------------------------------|
| **Create: Simulated / Aeronautics** (motor *Sable*) | Es de donde sale tu elevador físico. Aporta el ensamblaje a *sub-level*, los **componentes de redstone** y los **thrusters** (empuje) que mueven el objeto. |
| **CC: Sable** | Addon de CC:Tweaked **específico para el motor Sable**. Da la **`sublevel` API** (una computadora *montada sobre el elevador* puede leer su posición/altura, velocidad, masa…) y la **`aero` API** (gravedad, drag, presión del aire). **Es la pieza que te deja "sentir" la altura del elevador desde Lua.** |
| **CC: Tweaked** | La base: computadoras, **API `redstone`** (encender/apagar señales), **eventos** (botón, timer…), **peripherals** y **monitores**. |
| **CC:C Bridge** (el "create redstone bridge") | Puente CC:Tweaked ↔ Create. Aporta el **RedRouter** (mandar redstone por un cable largo, ideal para cablear el elevador) y los bloques **Source/Target** (mostrar datos en Flip Display, Nixie, Lectern, Sign y leer datos de Create como Stress Units). Muy útil para **las pantallas de la fase 2**. |
| **Tom's Peripherals** | Addon de **monitores de alta resolución y gráficos 2D/3D** (GPU, carga/guardado de PNG, input de ratón). Sobre todo para **las pantallas de información** que quieres después. |

---

## 2. Create: Simulated — cómo se mueve un objeto físico

Hechos verificados:

- Al **ensamblar** (bloques pegados con *super glue* / *honey glue*; según versión, mediante un **Physics Assembler**) el conjunto pasa a ser una **Physics Contraption**, también llamada **sub-level**, que se mueve y rota con física real. **[A CONFIRMAR: método exacto de ensamblaje en tu versión]**
- El empuje se consigue con **thrusters**. El **thruster cinético/redstone** (Create: Simulated Thrusters):
  - **Se activa con una señal de redstone.**
  - Su **empuje escala con el nivel de potencia de redstone** (0–15), es decir, es **analógico**: más señal = más fuerza.
  - Requiere **fuerza rotacional (Stress Units)** como cualquier máquina de Create, y alcanza el empuje máximo a unas RPM configurables.
- **Consecuencia de diseño clave:** con los mods que tú listas, **ComputerCraft NO aplica fuerza directamente**. La computadora solo puede **encender/apagar/ajustar redstone**, y esa redstone es la que activa los thrusters. La altura se controla **indirectamente**: redstone → thruster → fuerza → física.

⚠️ **Caveat conocido (sourced):** hay reportes de que **redstone links y redstone sobre contraptions móviles simuladas no siempre transmiten bien la señal** mientras se mueven (issues abiertos en Create y en el proyecto Simulated). Hay que tenerlo en cuenta para el cableado del elevador en movimiento (ver §7).

### 2.1 Docking Connector (Create Aeronautics) — tu mecanismo de parada

Hechos verificados:

- El **Docking Connector** es un bloque de Create Aeronautics que permite **acoplar (dock)** una nave/contraption física a una estación fija.
- Cuando está **acoplado**, puede **transferir energía** (FE) y, con un docking port, **ítems** hacia/desde el almacenamiento de la nave.
- Tiene **integración con redstone** y se usa para **automatizar el dock/undock** en rutas repetibles.
- Existe un bloque **Claw** que **detecta y apunta a connectors cercanos** para acoplar con precisión.

Para tu elevador, la idea encaja bien: un docking connector en cada altura **ancla la plataforma cuando llega** (parada estable, sin tener que sostenerla flotando), y su integración de redstone puede servir para **avisar al computer de que llegó**.

⚠️ **Bugs conocidos (importantes para tu caso, sourced):**
- *"Docking Connectors do not work properly on Create contraptions"* — si un docking connector está **alimentado y conectado a un objeto físico** y luego se forma en una contraption de Create, **parpadea rápidamente** y queda en un estado donde la contraption **no está realmente conectada** (issue #511).
- *"Docking connector only works with Create pipes"* — limitaciones de transferencia (issue #1001).

➡️ **Conclusión honesta:** el docking connector es prometedor como **tope/ancla**, pero su comportamiento exacto con **redstone** sobre objetos físicos **hay que probarlo en tu mundo** antes de confiar el control a él. Por eso el diseño de §7 incluye un **sensor de llegada alternativo garantizado** (observer / redstone contact por piso) que funciona aunque el connector falle.

**[VERIFICAR EN JUEGO]** lo más importante a comprobar:
1. ¿El docking connector **emite redstone** (lado mundo) cuando la plataforma está acoplada? → así el computer sabe "está arriba/abajo".
2. ¿Acoplar **inmoviliza** de verdad la plataforma con el thruster aún encendido? (define si hay que cortar empuje al llegar).
3. ¿Se puede **forzar el undock con redstone** desde el lado fijo?

---

## 3. CC: Sable — leer la física del elevador desde Lua

La computadora debe estar **colocada encima del elevador** (formar parte del sub-level). Entonces tiene acceso a estas APIs. **Importante: la API es de SOLO LECTURA de física** (no hay método para "aplicar fuerza" ni "mover"; eso se hace por redstone → thrusters).

### 3.1 API `sublevel`

| Función | Devuelve | Uso para el elevador |
|---------|----------|----------------------|
| `sublevel.isInPlotGrid()` | boolean | ¿La computadora está sobre un sub-level? (comprobar antes de nada). |
| `sublevel.getUniqueId()` | string (UUID) | Identificar el elevador. |
| `sublevel.getName()` / `setName(nombre)` | string / — | Nombrar el sub-level. |
| **`sublevel.getLogicalPose()`** | table (posición, orientación, escala, punto de rotación) | **La altura actual del elevador.** ← el dato central del control. |
| `sublevel.getLastPose()` | table | Pose anterior (útil para estimar movimiento). |
| `sublevel.getVelocity()` | vector | Velocidad global. |
| `sublevel.getLinearVelocity()` | vector | Velocidad lineal (saber si sube/baja y cómo de rápido). |
| `sublevel.getAngularVelocity()` | vector | Velocidad angular (detectar bamboleo). |
| `sublevel.getCenterOfMass()` | vector | Centro de masa. |
| `sublevel.getMass()` / `getInverseMass()` | number | Masa (un elevador "gigante" pesa mucho → necesita más empuje). |
| `sublevel.getInertiaTensor()` / `getInverseInertiaTensor()` | matrix | Tensor de inercia (estabilidad). |

> Todas estas funciones **dan error si la computadora no está sobre un sub-level**. Por eso siempre se comprueba `isInPlotGrid()` primero.
>
> **[VERIFICAR EN JUEGO]** la doc dice que `getLogicalPose()` devuelve "position, orientation, scale, rotation point" pero **no fija los nombres exactos de los campos**. Antes de programar el control, ejecuta una vez:
> ```lua
> print(textutils.serialize(sublevel.getLogicalPose()))
> print(textutils.serialize(sublevel.getLinearVelocity()))
> ```
> y apunta la estructura real (p. ej. si la altura es `pose.position.y`, `pose.pos[2]`, etc.). **No inventar la forma; confirmarla.**

CC: Sable también incluye el datapack **CC: Advanced Math** con la API `quaternion` para rotaciones 3D (no imprescindible para subir/bajar, sí si quieres corregir inclinación).

### 3.2 API `aero` (física del dimension)

| Función | Devuelve | Uso |
|---------|----------|-----|
| `aero.getGravity()` | vector | Saber cuánta fuerza hacia abajo hay que compensar para **sostener** el elevador. |
| `aero.getAirPressure(pos)` | number | Presión del aire en una posición. |
| `aero.getMagneticNorth()` | vector | Norte magnético del dimension. |
| `aero.getUniversalDrag()` | number | Constante de drag (rozamiento). |
| `aero.getRaw()` / `getDefault()` | table | Toda la config física en crudo. |

---

## 4. CC: Tweaked — base de control

### 4.1 API `redstone` (módulo `redstone`, alias `rs`)

Lados válidos: `"top"`, `"bottom"`, `"left"`, `"right"`, `"front"`, `"back"` (`redstone.getSides()`).

| Función | Qué hace |
|---------|----------|
| `redstone.setOutput(side, on)` | Enciende/apaga señal (on = fuerza 15). |
| `redstone.getOutput(side)` | Lee la salida actual (bool). |
| `redstone.getInput(side)` | **Lee entrada (bool)** → así se lee el **botón**. |
| `redstone.setAnalogOutput(side, value)` | Señal analógica **0–15** → **control fino del thruster**. |
| `redstone.getAnalogOutput(side)` / `getAnalogInput(side)` | Lee fuerza de señal 0–15. |
| `redstone.setBundledOutput(side, mask)` / `getBundledInput(side)` / `testBundledInput(side, mask)` | Cables agrupados (16 canales por color). |

**Eventos** (con `os.pullEvent`): cuando cambia una entrada de redstone se dispara el evento `"redstone"`. Esto permite **esperar el botón sin hacer polling**:

```lua
os.pullEvent("redstone")   -- se despierta cuando cambia algún input
```

Otros eventos útiles: `timer` (con `os.startTimer`), `monitor_touch` (pantallas táctiles para la fase 2).

### 4.2 Peripherals / monitores
La API `peripheral` (`peripheral.wrap`, `peripheral.find`, `peripheral.call`) conecta monitores, modems, etc. Los **monitores** de CC:Tweaked sirven para el panel de estado básico; para gráficos más serios, Tom's Peripherals (§6).

---

## 5. CC:C Bridge — el "create redstone bridge"

### 5.1 RedRouter (control de redstone por cable largo)
- Nombre de peripheral: **`"redrouter"`**. Se conecta por **cualquier lado**.
- Funciona **casi igual que la API `redstone`** (sin soporte de cables agrupados/bundled).
- Los **lados son relativos a la orientación del bloque** (como en una turtle): `"left"`, `"right"`, `"front"`, `"back"`, etc.
- Dispara el evento **`"redstone"`** con parámetro `string: attached_name` cuando cambia una señal.

| Método | Qué hace |
|--------|----------|
| `setOutput(side, on)` | Señal on/off. |
| `setAnalogOutput(side, value)` | Señal **0–15** (control fino del thruster). |
| `getOutput(side)` / `getInput(side)` | Lee salida / entrada (bool). |
| `getAnalogOutput(side)` / `getAnalogInput(side)` | Lee fuerza 0–15. |

> **Por qué importa:** el RedRouter permite llevar la redstone "por un cable simple e infinitamente largo", lo que ayuda a **cablear señales hacia/desde un elevador en movimiento** de forma más limpia que con redstone física suelta (recuerda el caveat de §2).

### 5.2 Source / Target Blocks (sobre todo para las pantallas de la fase 2)
- **Source Block**: una computadora **envía** datos para mostrarlos en **Flip Display, Nixie Tube, Lectern o Sign**.
- **Target Block**: una computadora **lee** información de Create con precisión (p. ej. **Stress Units** actuales).
- Documentación detallada de estos bloques: wiki oficial (ver Fuentes). **[Pendiente de profundizar en la fase de pantallas.]**

---

## 6. Tom's Peripherals — para las pantallas de información (fase 2)
- Addon de **monitores de alta resolución** con **gráficos 2D y 3D** dibujables desde Lua.
- **GPU** que puede **cargar y guardar PNG**.
- Soporta **input de ratón** en sus monitores y en los Advanced Monitors.
- Encaje: aquí irán el **estado del elevador, animaciones, plano de pisos, etc.** Detalle de funciones: su wiki (ver Fuentes). **[Pendiente de profundizar en la fase de pantallas.]**

---

## 7. Diseño del control de 2 alturas (alternar con un botón)

### EL RETO CENTRAL de tu caso (computer fuera + thruster a bordo)

Con tu build confirmado aparece **un problema que hay que resolver sí o sí**:

> El **thruster está sobre la plataforma que se mueve**, pero el **computer está fuera**. ¿Cómo cambia el computer la señal de redstone que enciende/regula ese thruster mientras la plataforma vuela?

No hay forma mágica: **algo tiene que llevar la orden hasta la contraption en movimiento.** Las opciones reales son:

1. **Latch a bordo disparado por el docking connector (sin computer ni modem a bordo).** En la plataforma pones el thruster + un **latch** (p. ej. *Powered Latch* de Create o un RS-latch). El docking connector, al acoplar, transmite una señal que **engancha** el latch. **Encaja con tu "computer fuera", pero depende de que el docking connector transmita redstone a la contraption** → **[VERIFICAR]** (bug #511). Es lo más limpio **si funciona** en tu versión.
2. **Create Redstone Link inalámbrico** (emisor fuera, receptor en la plataforma que activa el thruster). Simple de cablear, pero ⚠️ **bug conocido**: los redstone links **no transmiten bien sobre contraptions en movimiento** (#5399, #336). Arriesgado justo cuando vuela.
3. **Mini-computer a bordo + modem inalámbrico (rednet).** El "cerebro" sigue fuera; a bordo va solo un **relé** diminuto que recibe `rednet` y pone la redstone del thruster localmente. Es **lo más robusto y fiable** del ecosistema CC. Choca con tu preferencia de "nada a bordo", pero un relé de 1 bloque no es el cerebro — es un cable inteligente. **Mi recomendación si la opción 1 falla en pruebas.**

👉 **Esta es la decisión que falta para cerrar el programa** (ver pregunta al final). El resto del diseño vale para las tres opciones; solo cambia *cómo* el computer "enciende el thruster".

---

### Arquitectura RECOMENDADA para tu caso — Computer fijo + docking + sensor de piso

**Reparto de trabajo:**

- **Lado fijo (tu computer, fuera):**
  - **Lee** si la plataforma está acoplada arriba o abajo (redstone del docking connector **[VERIFICAR]**, o de un **observer/redstone contact** puesto en cada altura — este último funciona seguro).
  - **Lee el botón** (entrada de redstone / evento `"redstone"`).
  - **Ordena** el viaje al piso contrario (según la opción 1/2/3 de arriba: pulso al connector, al redstone link, o `rednet` al relé).
- **Lado móvil (la plataforma):**
  - Thruster(s) + (según opción) latch / receptor de link / mini-relé.
  - Para **bajar**: o un thruster apuntando hacia abajo, o simplemente **cortar empuje y dejar caer con física**, frenando cerca del dock inferior.

**Flujo del toggle (un botón):**
1. Botón pulsado.
2. El computer mira **dónde está** (acoplado arriba o abajo).
3. Manda "ir al otro piso": ordena **undock** + **empuje** hacia el destino.
4. La plataforma sube/baja y **se acopla** en el docking connector del destino (parada estable).
5. El computer detecta la llegada (redstone del connector o del observer) y **corta el empuje**.

Esqueleto Lua del **computer fijo** (plantilla — ajustar lados y el método de "encender thruster" según tu opción 1/2/3):

```lua
-- === Computer FIJO (fuera del elevador). Plantilla, ajustar en juego. ===
local BOTON      = "front"    -- entrada del boton
local SENS_ABAJO = "left"     -- entrada: acoplado abajo (connector u observer)
local SENS_ARRIBA= "right"    -- entrada: acoplado arriba
local CMD_SUBIR  = "back"     -- salida que ordena "subir" (a connector/link/rele)
local CMD_BAJAR  = "top"      -- salida que ordena "bajar"

-- estado persistente (sobrevive a reinicios del computer)
local function leerEstado()
  if fs.exists("piso") then local h=fs.open("piso","r"); local v=h.readAll(); h.close(); return v end
  return "abajo"
end
local function guardarEstado(v) local h=fs.open("piso","w"); h.write(v); h.close() end

local destino = nil

local function pararTodo()
  redstone.setOutput(CMD_SUBIR,false); redstone.setOutput(CMD_BAJAR,false)
end

local function irArriba()
  destino="arriba"; redstone.setOutput(CMD_BAJAR,false); redstone.setOutput(CMD_SUBIR,true)
end
local function irAbajo()
  destino="abajo"; redstone.setOutput(CMD_SUBIR,false); redstone.setOutput(CMD_BAJAR,true)
end

pararTodo()
print("Elevador listo. Piso actual:", leerEstado())

while true do
  local ev = os.pullEvent("redstone")
  -- 1) boton -> alternar destino
  if redstone.getInput(BOTON) then
    if leerEstado()=="abajo" then irArriba() else irAbajo() end
  end
  -- 2) llegada -> cortar empuje y guardar piso
  if destino=="arriba" and redstone.getInput(SENS_ARRIBA) then
    pararTodo(); guardarEstado("arriba"); destino=nil; print("Llego arriba")
  elseif destino=="abajo" and redstone.getInput(SENS_ABAJO) then
    pararTodo(); guardarEstado("abajo"); destino=nil; print("Llego abajo")
  end
end
```

> Este esqueleto **no toca la contraption en movimiento directamente**: solo lee sensores fijos y acciona salidas fijas (`CMD_SUBIR`/`CMD_BAJAR`). Lo que esas salidas hagan llegar al thruster (latch por connector, redstone link, o `rednet` a un relé) es la opción 1/2/3 que elijas. Así el "computer fuera" funciona de verdad.
>
> **Antirrebote del botón:** si el botón genera varios eventos, añade un `os.startTimer` o ignora pulsos mientras `destino ~= nil`.

---

### Arquitectura A (referencia) — Computer A BORDO con CC: Sable
**NO es tu caso actual** (dijiste computer fuera), pero la dejo por si lo cambias: la computadora va **montada sobre el elevador** (sub-level), lee su altura con CC: Sable (`sublevel.getLogicalPose`) y controla los thrusters con redstone, haciendo un **lazo de control** para llegar y **mantenerse** en la altura objetivo.

Flujo:
1. Botón pulsado → cambia el **objetivo** entre altura A y altura B (toggle).
2. Bucle de control: comparar altura actual (`getLogicalPose`) con el objetivo y **ajustar el empuje** (`setAnalogOutput` 0–15) para subir, bajar o **sostener** contra la gravedad.
3. Al llegar (dentro de una tolerancia y con velocidad ~0), mantener empuje de **hover** (sostén).

Esqueleto Lua (plantilla — **revisar nombres de campos de pose y lados de redstone con tu build**):

```lua
-- === Plantilla. Ajustar lados, campo de altura y tuning en el juego. ===
local THRUST_SIDE = "bottom"   -- lado del computer cableado a los thrusters
local BUTTON_SIDE = "back"     -- lado donde llega el botón
local ALTURA_A = 80            -- [A CONFIRMAR] coordenada Y del piso de arriba
local ALTURA_B = 64            -- [A CONFIRMAR] coordenada Y del piso de abajo
local TOL      = 0.3           -- tolerancia en bloques

assert(sublevel.isInPlotGrid(), "El computer no esta sobre el sub-level")

local objetivo = ALTURA_A
local enA = true

local function alturaActual()
  local pose = sublevel.getLogicalPose()
  -- [VERIFICAR] el campo real: pose.position.y / pose.pos[2] / ...
  return pose.position.y
end

local function aplicarControl()
  local y = alturaActual()
  local err = objetivo - y
  if err > TOL then
    redstone.setAnalogOutput(THRUST_SIDE, 15)      -- subir fuerte
  elseif err < -TOL then
    redstone.setAnalogOutput(THRUST_SIDE, 0)       -- dejar caer (o thruster inferior si lo hay)
  else
    redstone.setAnalogOutput(THRUST_SIDE, 8)       -- [TUNEAR] hover/sostener
  end
end

while true do
  aplicarControl()
  local ev = os.pullEvent()                         -- "redstone" (boton) o "timer"
  if ev == "redstone" and redstone.getInput(BUTTON_SIDE) then
    if enA then objetivo = ALTURA_B else objetivo = ALTURA_A end
    enA = not enA
  end
  os.startTimer(0.2)                                -- re-evaluar el control periodicamente
end
```

> El valor de "hover" (8 en el ejemplo) es **el empuje que iguala a la gravedad**. Como tu elevador es **gigante** (mucha masa, §3.1) habrá que **tunearlo en el juego**; idealmente con un control proporcional usando `getLinearVelocity()` para no oscilar.

**Pros:** sensado real de altura, robusto a empujones. **Contras:** sostener contra física es delicado (overshoot/oscilación) → requiere tuneo o un PID sencillo.

### Arquitectura B — Sensado por pisos (más simple, sin lazo fino)
En lugar de leer la altura continuamente, pones **detectores en cada piso** (p. ej. observers / redstone contacts en el hueco) que avisan "el elevador llegó arriba/abajo". La computadora **empuja hasta que el sensor del piso destino se activa** y entonces corta. Funciona muy bien si el elevador tiene **topes mecánicos** (descansa físicamente en cada altura) → no hay que "sostener" activamente.

**Pros:** mucho más simple y estable. **Contras:** necesitas construir los sensores/topes; menos "preciso" que coordenadas.

### Arquitectura C — Alternativa robusta: Elevator Pulley de Create vanilla
Si no es imprescindible que el elevador sea física pura, el **Elevator Pulley** está hecho **exactamente** para esto:
- Marcas cada piso con **Elevator Contacts**.
- Cada contacto **se llama con redstone** y **emite redstone cuando el ascensor está parado ahí**.
- ComputerCraft solo tiene que **mandar un pulso de redstone al contacto del piso destino** y **leer** el contacto para saber que llegó. El frenado/parada en el piso lo hace el propio Create.

El toggle de 2 alturas se vuelve casi trivial:
```lua
-- Pseudocódigo Elevator Pulley
local enArriba = false
while true do
  os.pullEvent("redstone")
  if redstone.getInput("back") then           -- boton
    if enArriba then
      redstone.setOutput("left", true); sleep(0.2); redstone.setOutput("left", false)  -- llamar piso abajo
    else
      redstone.setOutput("right", true); sleep(0.2); redstone.setOutput("right", false) -- llamar piso arriba
    end
    enArriba = not enArriba
  end
end
```
**Pros:** estabilidad y parada exacta gratis. **Contras:** no es el objeto físico de Simulated que ya construiste.

---

## 8. Lo que queda por decidir (para cerrar el programa)

Ya confirmado: thrusters redstone · computer fuera · docking connector por altura · MC 1.21.1 NeoForge. Falta decidir:

1. **Cómo llega la orden al thruster en movimiento** — la **decisión clave** (opción 1 latch+connector / 2 redstone link / 3 mini-relé + `rednet`, §7). Recomiendo **probar la 1** y, si el connector no transmite redstone bien (bug #511), pasar a la **3**.
2. **Cómo baja la plataforma** — ¿thruster apuntando hacia abajo, o cortar empuje y dejar caer con física (frenando cerca del dock)?
3. **Detección de llegada** — ¿confiamos en el redstone del docking connector, o ponemos un **observer/redstone contact fijo** en cada altura como sensor garantizado?
4. **Dónde está el botón** — ¿en un piso fijo (ideal, cableado directo al computer) o en la plataforma que se mueve (necesitaría también un link/relé)?

Cuando me digas esto (sobre todo el punto 1), te escribo el **programa Lua final** ya adaptado, no la plantilla.

---

## 9. Fuentes

- Create — Elevator Pulley (Create Wiki / Fandom): https://createmod.wiki/wiki/Elevator_Pulley · https://create.fandom.com/wiki/Elevator_Pulley
- Create — Redstone Contact: https://create.fandom.com/wiki/Redstone_Contact
- Create — Redstone Link: https://create.fandom.com/wiki/Redstone_Link
- Create: Simulated / Aeronautics (proyecto): https://github.com/Creators-of-Aeronautics/Simulated-Project · Wiki: https://createaeronautics.miraheze.org/wiki/Main_Page
- Create: Simulated Thrusters: https://modrinth.com/mod/create-simulated-thrusters · https://www.curseforge.com/minecraft/mc-mods/create-simulated-thrusters
- Redstone en contraptions simuladas (bug conocido): https://github.com/Creators-of-Aeronautics/Simulated-Project/issues/336 · https://github.com/Creators-of-Create/Create/issues/5399
- Docking Connector — bugs en contraptions físicas: https://github.com/Creators-of-Aeronautics/Simulated-Project/issues/511 · https://github.com/Creators-of-Aeronautics/Simulated-Project/issues/1001
- Docking / logística aérea (referencia de uso): https://www.curseforge.com/minecraft/mc-mods/create-aeronautics-automated-logistics
- CC: Sable (NeoForge 1.21.1) archivos: https://www.curseforge.com/minecraft/mc-mods/cc-sable/files/all
- **CC: Sable** (addon Sable para CC:Tweaked): https://modrinth.com/mod/cc-sable · GitHub: https://github.com/TechTastic/CC-Sable · **Docs API: https://techtastic.github.io/CC-Sable/** (módulos `sublevel` y `aero`)
- **CC:C Bridge** — repo: https://github.com/tweaked-programs/cccbridge · Wiki/docs: https://cccbridge.tweaked-programs.cc/ · RedRouter: https://cccbridge.tweaked-programs.cc/peripherals/RedRouterBlockPeripheral/
- **CC: Tweaked** — API redstone: https://tweaked.cc/module/redstone.html · peripheral: https://tweaked.cc/module/peripheral.html · web: https://tweaked.cc/
- **Tom's Peripherals**: https://modrinth.com/mod/toms-peripherals · https://www.curseforge.com/minecraft/mc-mods/toms-peripherals
