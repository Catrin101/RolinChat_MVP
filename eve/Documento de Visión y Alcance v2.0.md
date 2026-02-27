# **Documento de Visión y Alcance v2.0**

## **RolinChat \- Plataforma Social de Roleplay Narrativo**

**Versión:** 2.0 (MVP Ajustado)  
 **Motor:** Godot 4.5+ (GDScript)  
 **Plataforma:** PC (Windows/Linux)  
 **Desarrollador:** Solo Developer  
 **Modelo de Negocio:** Patreon \+ Contenido Modular Comunitario

---

## **1\. Resumen Ejecutivo**

**RolinChat** es una plataforma social 2D diseñada para entusiastas del roleplay narrativo que buscan una experiencia más inmersiva que el texto plano, pero más accesible que el 3D. A través de un sistema híbrido de vista isométrica (exploración) y vista lateral (escenas dramáticas), los jugadores crean historias colaborativas usando avatares modulares altamente personalizados y un chat especializado por comandos.

### **Diferenciador Clave:**

Sistema único de **Animaciones Conjuntas** donde dos jugadores participan en escenas pregrabadas (charlar, entrenar, conspirar) con roles Activo/Pasivo, transformando el chat de texto en una experiencia visual cinematográfica.

---

## **2\. Pilares de Diseño**

### **Pilar Emocional Central:**

*"Sentirse parte de una historia que están creando juntos, expresándose a través de un avatar único en un mundo que responde a sus acciones narrativas."*

### **Pilares Técnicos:**

1. **Libertad Narrativa**

   * Chat especializado con comandos IC (In Character) / OOC (Out Of Character)  
   * Separación clara entre diálogo del personaje y conversación entre jugadores  
   * Sistema de dados (/roll) para resolución de conflictos  
2. **Identidad Visual**

   * Sistema modular de avatares (Paper Doll) con persistencia JSON  
   * Diferenciación entre representación isométrica (mundo) y lateral (escenas)  
   * Cada jugador es visualmente único  
3. **Inmersión Interactiva**

   * Objetos del mundo como "portales" a escenas dramáticas  
   * Animaciones conjuntas con roles definidos (Activo/Pasivo)  
   * Transiciones fluidas entre exploración y actuación  
4. **Comunidad Primero**

   * Arquitectura Host-Client para sesiones privadas entre amigos  
   * Sistema de mods preparado para contenido generado por usuarios  
   * Modelo sostenible vía Patreon sin romper la experiencia

---

## **3\. Análisis de Mercado y Referencias**

### **Género: Social Sandbox / Roleplay Platform**

### **Público Objetivo:**

* **Primario:** Adultos jóvenes (18-35) con experiencia en roleplay textual (Discord, foros)  
* **Secundario:** Jugadores de MMORPGs que buscan experiencias narrativas casuales

### **Referencias (Inspiración, no copia):**

| Juego | Elemento Inspirador |
| ----- | ----- |
| **Club Penguin** | Salas temáticas, sistema de emotes |
| **Habbo Hotel** | Mobiliario interactivo, salas de usuario |
| **VRChat** | Avatares personalizados, sesiones privadas |
| **Roll20** | Comandos de chat especializados, sistema de dados |
| **Stardew Valley** | Cambio de sprites según contexto (isométrico) |

---

## **4\. Core Loop (Bucle Principal de Juego)**

\[Personalizar Avatar\]  
    ↓  
\[Crear/Unirse a Sala de Rol\]  
    ↓  
\[Explorar Mapa Isométrico\]  
    ↓  
\[Interactuar con Objetos/Jugadores\]  
    ↓  
\[Participar en Escena Conjunta\] ← (Diferenciador único)  
    ↓  
\[Continuar Roleplay en Chat\]  
    ↓  
\[Guardar Progreso/Historia\]  
    ↓  
(Loop continúa)

### **Hooks (Ganchos de Retención):**

* **Expresión Personal:** "Mi avatar es único y representa mi personaje"  
* **Progresión Social:** "Cada sesión construye la historia de mi personaje"  
* **FOMO de Contenido:** "Quiero las nuevas animaciones/mapas del Patreon"  
* **Creación Comunitaria:** "Puedo crear mods y compartirlos"

---

## **5\. Especificaciones Técnicas**

### **5.1. Arquitectura de Datos (JSON)**

#### **CharacterProfile.json**

{  
  "profile\_id": "unique\_uuid",  
  "character\_name": "Aria Stormwind",  
  "backstory": "Una guerrera elfa...",  
  "personality\_traits": \["Valiente", "Sarcástica"\],  
  "avatar\_isometric": {  
    "body\_type": 1,  
    "skin\_tone": 2,  
    "hair\_style": 5,  
    "outfit": 3,  
    "color\_modulation": {"r": 1.0, "g": 0.8, "b": 0.9, "a": 1.0}  
  },  
  "avatar\_sideview": {  
    "head": 2,  
    "torso": 5,  
    "legs": 3,  
    "bust\_size": 2,  // Solo para avatares femeninos  
    "hair": 5,  
    "outfit\_top": 1,  
    "outfit\_bottom": 4,  
    "shoes": 2  
  }  
}

#### **RoomConfig.json**

{  
  "room\_id": "tavern\_01",  
  "room\_name": "La Taberna del Dragón Ebrio",  
  "map\_scene": "res://maps/tavern.tscn",  
  "max\_players": 8,  
  "access\_code": "DRAG1234",  
  "interactive\_objects": \[  
    {  
      "object\_id": "sofa\_main",  
      "position": {"x": 320, "y": 180},  
      "scene\_template": "sofa\_chat"  
    }  
  \]  
}

---

### **5.2. Arquitectura de Networking**

**Modelo:** Host-Client (Godot High-Level Multiplayer)  
 **Justificación:** Sesiones privadas entre amigos, sin necesidad de servidor dedicado

#### **Flujo de Conexión:**

\[Host crea sala\]  
    ↓  
\[Sistema genera código de 8 caracteres\]  
    ↓  
\[Host comparte código\]  
    ↓  
\[Clients ingresan código\]  
    ↓  
\[Validación de código en host\]  
    ↓  
\[Sincronización de avatares vía RPC\]

#### **Sincronización:**

* **Posición de avatares:** `MultiplayerSynchronizer` (interpolación automática)  
* **Mensajes de chat:** `RPC` con validación de longitud (max 500 caracteres)  
* **Estados de escenas:** `RPC` en modo `authority` (solo host decide)

#### **Seguridad Básica (MVP):**

\# Rate limiting simple  
const MESSAGE\_COOLDOWN: float \= 0.5  \# 500ms entre mensajes  
var \_last\_message\_time: float \= 0.0

func send\_message(text: String) \-\> void:  
    var current\_time \= Time.get\_ticks\_msec() / 1000.0  
    if current\_time \- \_last\_message\_time \< MESSAGE\_COOLDOWN:  
        return  
      
    text \= text.substr(0, 500\)  \# Limitar caracteres  
    \_last\_message\_time \= current\_time  
    rpc("\_receive\_message", multiplayer.get\_unique\_id(), text)

---

## **6\. Sistemas de Juego (Detallado)**

### **6.1. Creador de Avatares (Modular Paper Doll)**

#### **Vista Isométrica:**

* **Técnica:** Sprites estáticos intercambiables  
* **Componentes:** Cuerpo base \+ Cabello \+ Ropa \+ Accesorios  
* **Colores:** Modulación RGBA por categoría

#### **Vista Lateral (Rigging):**

* **Técnica:** Skeleton2D con huesos modulares

**Componentes:**  
 Skeleton2D├── Bone\_Torso│   ├── Sprite\_Head (intercambiable)│   ├── Sprite\_Torso (intercambiable)│   └── Bone\_Bust (solo femenino)├── Bone\_Arm\_L│   └── Sprite\_Arm\_L├── Bone\_Arm\_R└── Bone\_Legs    ├── Sprite\_Leg\_L    └── Sprite\_Leg\_R

* 

#### **Hoja de Personaje:**

* Campos de texto limitados (Nombre: 30 chars, Backstory: 500 chars)  
* Visible al hacer clic derecho sobre el avatar de otro jugador  
* No afecta gameplay, solo roleplay

---

### **6.2. Sistema de Escenas Conjuntas (El Diferenciador)**

#### **Concepto:**

Transformar objetos del mundo (sofás, mesas de entrenamiento, balcones) en "portales" a escenas dramáticas donde dos jugadores actúan en una mini-obra con roles predefinidos.

#### **Arquitectura:**

**Paso 1: Definición de Templates**

res://data/scene\_templates/  
├── sofa\_chat.json          \# Charlar en sofá  
├── training\_spar.json      \# Combate de práctica  
└── balcony\_conspire.json   \# Conspirar en balcón

**Paso 2: Estructura de Escena**

sofa\_chat.tscn  
├── Background (TextureRect)        \# Fondo decorativo  
├── UI\_RoleSelection (Panel)        \# Menú para elegir Activo/Pasivo  
├── UI\_ActionButtons (HBoxContainer)  
│   ├── ButtonFinisher (Button)     \# "Despedirse"  
│   └── ButtonExit (Button)         \# "Salir de escena"  
├── Character\_Active (Node2D)  
│   ├── Skeleton2D  
│   │   ├── Bone\_Torso  
│   │   └── Bone\_Arms  
│   └── AnimationPlayer  
│       ├── "sit\_idle\_left"  
│       ├── "chat\_gesture\_left"  
│       └── "wave\_goodbye\_left"  
└── Character\_Passive (Node2D)  
    └── (Misma estructura espejo)

**Paso 3: Estado de la Escena (State Machine)**

enum SceneState {  
    WAITING\_SECOND\_PLAYER,  \# Solo 1 jugador ha entrado  
    SELECTING\_ROLES,        \# Ambos eligen Activo/Pasivo  
    PLAYING\_LOOP,           \# Animación en bucle  
    PLAYING\_FINISHER,       \# Animación de salida  
    CLEANUP                 \# Destruyendo escena  
}

#### **Flujo Técnico (Networking):**

\[Jugador A interactúa con objeto en host\]  
    ↓  
Host: rpc("notify\_scene\_available", object\_id, player\_a\_id)  
    ↓  
\[Jugador B ve prompt: "Unirse a escena?"\]  
    ↓  
Client B: rpc\_id(1, "request\_join\_scene", object\_id)  
    ↓  
Host: Valida disponibilidad, instancia escena  
Host: rpc("load\_joint\_scene", scene\_path, player\_a\_id, player\_b\_id)  
    ↓  
\[Ambos clients cargan escena, aplican JSON de avatares\]  
    ↓  
Clients: rpc\_id(1, "select\_role", "active" o "passive")  
    ↓  
Host: Valida roles únicos, rpc("start\_animation\_loop")  
    ↓  
\[Loop continúa hasta que alguien presiona "Despedirse"\]  
    ↓  
Client X: rpc\_id(1, "trigger\_finisher")  
    ↓  
Host: rpc("play\_finisher\_animation")  
    ↓  
\[Animación termina, ambos regresan al mapa isométrico\]

#### **Diferenciación Activo/Pasivo:**

* **Activo:** Inicia la acción (abraza, ataca, invita)  
* **Pasivo:** Recibe/responde (es abrazado, esquiva, acepta)  
* **Implementación:** Animaciones espejo con timing sincronizado

**Ejemplo: Sofá \- Charlar**

* **Activo:** Gesto de invitación → sentado a la izquierda → gesticula  
* **Pasivo:** Se sienta a la derecha → escucha atentamente → responde

---

### **6.3. Chat de Rol Avanzado**

#### **Implementación:**

* Usa `RichTextLabel` con BBCode para colores  
* Panel transparente superpuesto a la escena

#### **Comandos Básicos (MVP):**

| Comando | Tipo | Color | Ejemplo | Función |
| ----- | ----- | ----- | ----- | ----- |
| `(texto)` | IC | Blanco | `Hola, ¿cómo estás?` | Diálogo del personaje |
| `//texto` o `/ooc texto` | OOC | Gris | `//Tengo que salir 5 min` | Charla entre jugadores |
| `/me acción` | Acción | Naranja/Itálica | `/me sonríe pícaramente` | Narración de acciones |
| `/roll XdY` | Dado | Verde | `/roll 1d20` | Genera número aleatorio (1-20) |

#### **Comandos Post-MVP:**

* `/w [usuario] [mensaje]` \- Susurro privado  
* `/desc [texto]` \- Descripción de ambiente (color amarillo)  
* `/afk` \- Avatar se vuelve semi-transparente (alpha 0.5)

#### **Sincronización:**

@rpc("any\_peer", "call\_local")  
func \_receive\_message(sender\_id: int, text: String):  
    var sender\_name \= \_get\_player\_name(sender\_id)  
    var formatted\_text \= \_parse\_chat\_command(text, sender\_name)  
    chat\_log.append\_text(formatted\_text \+ "\\n")

func \_parse\_chat\_command(text: String, sender: String) \-\> String:  
    if text.begins\_with("//") or text.begins\_with("/ooc"):  
        return "\[color=gray\](OOC) %s: %s\[/color\]" % \[sender, text.trim\_prefix("//")\]  
    elif text.begins\_with("/me"):  
        return "\[color=orange\]\[i\]\* %s %s\[/i\]\[/color\]" % \[sender, text.trim\_prefix("/me ")\]  
    elif text.begins\_with("/roll"):  
        var dice \= text.trim\_prefix("/roll ").strip\_edges()  
        var result \= \_roll\_dice(dice)  
        return "\[color=green\]🎲 %s rolled %s: %d\[/color\]" % \[sender, dice, result\]  
    else:  
        return "\[color=white\]%s: %s\[/color\]" % \[sender, text\]

---

## **7\. Dirección de Arte e Interfaz**

### **Paleta de Colores:**

* **Primario:** Tonos cálidos (beige, marrón) para UI de pergamino/fantasía  
* **Secundario:** Azul oscuro para elementos técnicos (networking, opciones)  
* **Acentos:** Dorado para botones principales, rojo para salir/cancelar

### **Estilo Visual:**

* **Isométrico:** Pixel art 32x32 base, perspectiva 2:1  
* **Lateral:** Pixel art detallado, escala \~128px de altura para personajes  
* **UI:** Vector limpio (Godot Control nodes), fuentes legibles (mínimo 14px)

### **HUD (Heads-Up Display):**

┌─────────────────────────────────────┐  
│ \[Logo\] \[Sala: Taberna\] \[8/8\]  \[⚙️\] │ ← Header bar  
├─────────────────────────────────────┤  
│                                     │  
│        \[Mapa Isométrico\]            │ ← Área de juego  
│                                     │  
│  \[Avatares de jugadores\]            │  
│                                     │  
├─────────────────────────────────────┤  
│ Chat:                               │  
│ Player1: Hola                       │ ← Chat log (RichTextLabel)  
│ //Player2: Qué tal                  │  
│ \* Player1 se sienta                 │  
├─────────────────────────────────────┤  
│ \[Input de texto\]          \[Enviar\] │ ← Input bar  
└─────────────────────────────────────┘

---

## **8\. Alcance del MVP y Roadmap**

### **Definición de MVP (Producto Mínimo Viable):**

*"La versión más simple del producto que permite validar el concepto central con usuarios reales."*

### **Criterios de Éxito del MVP:**

1. ✅ 10 usuarios pueden crear avatares y conectarse  
2. ✅ Pueden chatear en tiempo real con comandos IC/OOC  
3. ✅ Pueden participar en 1 animación conjunta y entender el sistema  
4. ✅ El juego no crashea en sesiones de 30+ minutos  
5. ✅ La experiencia genera interés para seguir el desarrollo (feedback cualitativo)

---

### **Roadmap de Desarrollo (Solo Developer, Tiempo Parcial)**

#### **FASE 1: Core de Conectividad (Semanas 1-4)**

**Objetivo:** Validar que el networking funciona antes de invertir en arte

**Tareas:**

* \[ \] Menú principal con UI básica (Crear Sala / Unirse)  
* \[ \] Sistema de códigos de sala (generación aleatoria de 8 caracteres)  
* \[ \] Conexión Host-Client usando Godot Multiplayer API  
* \[ \] Chat básico funcional (solo texto blanco, sin comandos todavía)  
* \[ \] Sincronización de nombres de jugadores  
* \[ \] Sistema de desconexión (¿qué pasa si el host se va?)

**Criterio de Aceptación:**

* 2 instancias de Godot en la misma red local pueden chatear

**Herramientas de Testing:**

* Ejecutar 2 copias del proyecto en modo debug  
* Log de mensajes RPC en Output console

---

#### **FASE 2: Identidad (Avatar System) (Semanas 5-9)**

**Objetivo:** Los jugadores pueden crear y ver avatares únicos

**Tareas:**

* \[ \] Diseñar 3 opciones de pixel art por categoría:  
  * Isométrico: Cuerpo, Cabello, Outfit  
  * Lateral: Cabeza, Torso, Piernas, Cabello, Ropa (top/bottom), Zapatos  
  * Opcional: Variación de "bust size" para avatares femeninos  
* \[ \] UI del creador de personajes (sliders/botones para cambiar partes)  
* \[ \] Sistema de guardado local (JSON en `user://profiles/`)  
* \[ \] Sistema de carga de JSON al entrar a sala  
* \[ \] Sincronización RPC de datos de avatar al conectar  
* \[ \] Aplicación dinámica de texturas a Skeleton2D (lateral)

**Criterio de Aceptación:**

* Jugador A ve el avatar personalizado de Jugador B en su pantalla  
* Los avatares persisten entre sesiones (guardado local)

**Desafío Técnico:**

* Sincronizar el JSON completo del avatar sin exceder límites de RPC  
* Solución: Enviar solo índices numéricos, no rutas de archivos

---

#### **FASE 3: Mapa Base (Semanas 10-12)**

**Objetivo:** Contexto espacial para el roleplay

**Tareas:**

* \[ \] Diseñar 1 mapa de lobby isométrico (16x16 tiles mínimo)  
* \[ \] Implementar movimiento de avatares (WASD/Flechas)  
* \[ \] Colisiones básicas (paredes, muebles)  
* \[ \] Sincronización de posición vía `MultiplayerSynchronizer`  
* \[ \] Sistema de nametags (nombre del personaje flotando sobre el avatar)

**Criterio de Aceptación:**

* 4 jugadores pueden moverse simultáneamente sin lag visible  
* No hay atravesar paredes

---

#### **FASE 4: Sistema de Escenas (MVP) (Semanas 13-18)**

**Objetivo:** Demostrar el diferenciador clave del juego

**Tareas:**

* \[ \] Diseñar y rigguear 2 personajes laterales base (Skeleton2D)  
* \[ \] Crear 1 set de animaciones:  
  * `sit_idle_left/right` (loop)  
  * `chat_gesture_left/right` (loop)  
  * `wave_goodbye_left/right` (one-shot)  
* \[ \] Implementar aplicación dinámica de texturas a Skeleton2D  
* \[ \] Crear template de escena: `sofa_chat.tscn`  
* \[ \] Sistema de detección de interacción (Area2D en objeto del mapa)  
* \[ \] UI de selección de roles (Activo/Pasivo)  
* \[ \] State Machine para flujo de escena  
* \[ \] Sincronización RPC de estado de animación  
* \[ \] Transición fluida entre mapa y escena

**Criterio de Aceptación:**

* 2 jugadores completan todo el flujo sin errores:  
  1. Interactuar con sofá  
  2. Esperar segundo jugador  
  3. Seleccionar roles  
  4. Ver animación  
  5. Despedirse  
  6. Regresar al mapa

**Desafío Técnico:**

* Timing de animaciones (¿qué pasa si un jugador tiene lag?)  
* Solución: Host es la autoridad del timing, clients solo reproducen

---

#### **FASE 5: Comandos de Chat (Semanas 19-20)**

**Objetivo:** Completar las herramientas narrativas básicas

**Tareas:**

* \[ \] Implementar parsing de comandos:  
  * `//` → OOC (gris)  
  * `/me` → Acción (naranja itálico)  
  * `/roll XdY` → Dado (verde)  
* \[ \] Sistema de dados sincronizado (host genera número, lo envía a todos)  
* \[ \] Historial de chat (guardar últimos 100 mensajes)

**Criterio de Aceptación:**

* Todos los comandos funcionan correctamente  
* El chat se ve consistente en todas las pantallas

---

#### **FASE 6: Pulido y Testing Alfa (Semanas 21-24)**

**Objetivo:** Preparar para feedback externo

**Tareas:**

* \[ \] SFX básicos (clic de botón, sonido de mensaje nuevo)  
* \[ \] Música de fondo para lobby (loop ambient)  
* \[ \] Pantalla de carga/transición  
* \[ \] Manejo de errores (qué mostrar si falla la conexión)  
* \[ \] Tutorial in-game (tooltips básicos)  
* \[ \] Build para Windows/Linux  
* \[ \] Testing con 5-8 usuarios reales  
* \[ \] Recopilar feedback (encuesta Google Forms)

**Criterio de Aceptación:**

* Build estable que no crashea en 30 minutos de juego  
* Al menos 5 piezas de feedback positivo sobre el sistema de escenas

---

### **Post-MVP (Backlog Priorizado):**

**Alta Prioridad (para Beta Pública):**

* \[ \] 2 salas temáticas adicionales (Bosque, Castillo)  
* \[ \] 4 animaciones conjuntas más (variedad de contextos)  
* \[ \] Comandos `/w` (susurro) y `/afk`  
* \[ \] Sistema de "Hoja de Personaje" (inspeccionar avatar)

**Media Prioridad:**

* \[ \] Soporte para mods (carpeta `/mods/` con estructura estandarizada)  
* \[ \] Sistema de reputación/kudos entre jugadores  
* \[ \] Exportador de logs de roleplay (guardar historia como .txt)

**Baja Prioridad:**

* \[ \] Minijuegos (dados de poker, ajedrez narrativo)  
* \[ \] Sistema de "escenas grupales" (3-4 jugadores)  
* \[ \] Integración con Discord (Rich Presence)

---

## **9\. Modelo de Monetización y Sostenibilidad**

### **Filosofía:**

*"El contenido central es gratis. Los patrons pagan por influencia en el desarrollo y acceso anticipado."*

### **Tiers de Patreon (Propuesta):**

| Tier | Precio/mes | Beneficios |
| ----- | ----- | ----- |
| **Aprendiz** | $3 | \- Acceso al Discord exclusivo\<br\>- Rol especial con color\<br\>- Ver roadmap interno |
| **Narrador** | $7 | \- Todo lo anterior\<br\>- Acceso anticipado a builds (1 semana antes)\<br\>- Voto en encuestas de contenido |
| **Leyenda** | $15 | \- Todo lo anterior\<br\>- Proponer 1 animación conjunta por trimestre\<br\>- Créditos en el juego |

### **Objetivos de Financiación (Stretch Goals):**

| Meta | Desbloqueables |
| ----- | ----- |
| **$100/mes** | Nueva sala temática cada 2 meses |
| **$300/mes** | Contratar artista para acelerar animaciones |
| **$500/mes** | Servidor dedicado (24/7, sin depender de host) |
| **$1000/mes** | Desarrollo a tiempo completo |

### **Sistema de Mods:**

* Estructura de carpetas documentada  
* Templates de JSON disponibles en GitHub  
* Los mejores mods comunitarios se integran al juego base (con crédito al autor)  
* **NO SE MONETIZAN MODS** (evita problemas legales)

---

## **10\. Riesgos Técnicos y Mitigación**

| Riesgo | Probabilidad | Impacto | Mitigación |
| ----- | ----- | ----- | ----- |
| **Complejidad del rigging** | Alta | Alto | Comenzar con animaciones simples (3 frames por loop) |
| **Bugs de sincronización** | Media | Alto | Testing exhaustivo en Fase 1, logging detallado |
| **Scope creep** | Alta | Crítico | Referirse a este documento, rechazar features fuera de roadmap |
| **Burnout del desarrollador** | Media | Crítico | Trabajar en sprints de 2 semanas, tomarse breaks |
| **Falta de usuarios** | Media | Alto | Marketing en comunidades de roleplay (Reddit, Discord) |

---

## **11\. Métricas de Éxito (KPIs)**

### **Fase MVP:**

* \[ \] 50 descargas en itch.io en el primer mes  
* \[ \] 10 usuarios activos semanales  
* \[ \] Al menos 3 patrons en Patreon  
* \[ \] Tasa de retención \>30% (usuarios que vuelven después de la primera sesión)

### **Fase Beta:**

* \[ \] 200 descargas totales  
* \[ \] 50 usuarios activos semanales  
* \[ \] $100/mes en Patreon  
* \[ \] Al menos 5 mods creados por la comunidad

---

## **12\. Conclusión y Próximos Pasos**

**RolinChat** es un proyecto ambicioso pero alcanzable con enfoque disciplinado. El MVP está diseñado para validar el concepto central (animaciones conjuntas) sin ahogarse en features secundarias.

### **Decisión Clave:**

El éxito del proyecto depende de **completar la Fase 4** (sistema de escenas) con alta calidad. Si esa fase no genera entusiasmo en testers, el proyecto debe pivotar o reevaluarse.

### **Próximo Documento a Crear:**

1. **Product Backlog (Historias de Usuario)** \- Descomposición de cada fase en tareas accionables  
2. **Arquitectura de Sistemas (Diagramas UML)** \- Diagramas de clases para NetworkManager, SceneController, AvatarBuilder  
3. **Guía de Arte Técnico** \- Especificaciones de sprites, paleta de colores, nomenclatura de archivos

---

**Versión:** 2.0  
 **Última Actualización:** Febrero 2026  
 **Estado:** Listo para Desarrollo

---

## **Apéndice: Glosario de Términos**

* **IC (In Character):** Diálogo que el personaje dice en el mundo ficticio  
* **OOC (Out Of Character):** Conversación entre jugadores sobre el juego  
* **Paper Doll:** Técnica de sprites intercambiables (como vestir muñecas de papel)  
* **Rigging:** Proceso de asociar sprites a un esqueleto de huesos para animación  
* **RPC (Remote Procedure Call):** Función que se ejecuta en otra computadora vía red  
* **Host-Client:** Modelo donde un jugador (host) controla la lógica del juego  
* **State Machine:** Sistema que gestiona transiciones entre estados (ej: IDLE → PLAYING → FINISHED)  
* **Scope Creep:** Crecimiento incontrolado del alcance del proyecto (el enemigo \#1)

