# Elevator

Ascensor gigante en Minecraft —un **objeto físico de Create: Simulated**— que alterna entre **dos alturas** con un solo botón, controlado por **ComputerCraft**. Más adelante: monitores de estado e información.

## Estado del proyecto

- **Fase 1 — Investigación y diseño** *(en curso)*: documentación de mods/APIs y arquitectura de control. ✅ Investigación completa.
- **Decisión pendiente (clave)**: cómo llega la orden de empuje al thruster mientras la plataforma está en movimiento (latch + docking connector / redstone link / mini-relé + `rednet`). Detalle en el documento.
- **Fase 2 — Pantallas** *(después)*: estado del elevador e info con **Tom's Peripherals** y los bloques **Source/Target** de CC:C Bridge.

## Build

- **Minecraft 1.21.1 — NeoForge**
- Create: Simulated / Aeronautics (+ Thrusters) · motor *Sable*
- CC: Tweaked · CC: Sable · CC:C Bridge (v1.7.3) · Tom's Peripherals

Resumen del build confirmado:

| Dato | Valor |
|------|-------|
| Tipo de elevador | Objeto físico (sub-level de Create: Simulated) |
| Empuje | Thrusters redstone/cinéticos (analógico 0–15) |
| Computadora | Fuera del elevador (sensado externo) |
| Parada por altura | Docking connector (a verificar redstone) |

## Documentación

- **[Investigación de mods y APIs + diseño de control](Investigacion_Elevador_CC.md)** — todo verificado con fuentes oficiales, sin inventar.

## Principio del proyecto

Informarse de todo primero, sin inventar nada; cuando algo no se sabe, se busca en las APIs/docs oficiales. Lo que depende del build concreto va marcado como **[A CONFIRMAR]** / **[VERIFICAR EN JUEGO]**.
