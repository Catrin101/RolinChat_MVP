# Product Backlog MVP - RolinChat
## Data-Driven Architecture Edition

**Versión:** 1.1 (Ajustado al MVP del Documento Maestro)  
**Metodología:** Scrum adaptado para desarrollo en solitario  
**Duración Estimada:** 4 semanas (tiempo completo) / 8-10 semanas (tiempo parcial)  
**Principio Central:** **CODE ONCE, EXPAND FOREVER**

---

## 📐 ARQUITECTURA DATA-DRIVEN

```
┌─────────────────────────────────────────────────────────┐
│  CÓDIGO (escribes UNA VEZ en el MVP)                   │
├─────────────────────────────────────────────────────────┤
│  • AvatarManager.gd (lee JSON, aplica a Sprite2D)      │
│  • SceneController.gd (filtra acciones_rol.json)       │
│  • ChatController.gd (parsea comandos)                 │
│  • NetworkManager.gd (Host-Client)                     │
└─────────────────────────────────────────────────────────┘
                        ↓ lee datos de
┌─────────────────────────────────────────────────────────┐
│  CONTENIDO (expandes INFINITAMENTE post-MVP)           │
├─────────────────────────────────────────────────────────┤
│  • avatars/*.json (nuevos personajes)                  │
│  • razas.json (+ Orco, Dragón, Ángel...)               │
│  • sexos.json (+ No-Binario, Andrógino...)             │
│  • acciones_rol.json (+ 50 animaciones nuevas)         │
│  • maps/*.tscn (+ 10 salas temáticas)                  │
└─────────────────────────────────────────────────────────┘
```

**Post-MVP: Tú agregas contenido sin tocar código**

---

## 🎯 ÉPICAS DEL PROYECTO

| # | Épica | Objetivo Técnico | Objetivo de Validación |
|---|-------|------------------|------------------------|
| 1 | **CONECTIVIDAD** | Networking Host-Client funcional | "¿Pueden 4 amigos conectarse sin errores?" |
| 2 | **IDENTIDAD** | Sistema JSON de avatares completo | "¿La gente quiere personalizar avatares?" |
| 3 | **MUNDO** | Mapa con movimiento de avatares | "¿Se siente espacial el roleplay?" |
| 4 | **INTERACCIÓN** | Sistema de Escenas Conjuntas + Filtrado | "¿Las animaciones conjuntas generan emoción?" |
| 5 | **COMUNICACIÓN** | Chat con comandos especializados | "¿Los comandos /me, /roll mejoran la inmersión?" |

---

## 📅 SPRINT PLAN (4 semanas @ Tiempo Completo)

```
Semana 1: Networking + Chat Básico
Semana 2: Sistema de Avatares JSON
Semana 3: Mapa + Movimiento + Filtrado de Acciones
Semana 4: Escenas Conjuntas + Pulido
```

**Milestone Crítico:** Fin de Semana 3 = Demo jugable  
**Criterio de Éxito:** Semana 4 = Build para 10 testers

---

## 🚀 ÉPICA 1: CONECTIVIDAD (Sprint 1 - Semana 1)

### User Story 1.1: Crear Sala
**Como** JUGADOR HOST  
**Quiero** CREAR UNA SALA con código único  
**Para** QUE mis amigos puedan unirse sin exponer mi IP real

**Criterios de Aceptación:**
- [ ] Botón "Crear Sala" en menú principal
- [ ] Se genera código alfanumérico de 8 caracteres
- [ ] El código se muestra en pantalla para copiar (Ctrl+C)
- [ ] El host entra automáticamente a una sala lobby vacía
- [ ] El código funciona para conexiones en LAN

**Tareas Técnicas:**
```gdscript
# Implementar en NetworkManager.gd
- [ ] Implementar create_room()
- [ ] Generar código único (ej: "A7K2M9P1")
- [ ] Configurar ENetMultiplayerPeer como servidor
- [ ] Emitir señal room_created(code: String)
- [ ] Guardar código en variable global para mostrar en UI
```

**Tareas de UI:**
- [ ] Crear escena `main_menu.tscn`
- [ ] Botones: [Crear Sala] [Unirse] [Salir]
- [ ] Panel de "Código de Sala" con botón copiar
- [ ] Estilo: Fuentes legibles (mínimo 16px)

**Testing:**
- [ ] Crear sala → Código aparece
- [ ] Código no se repite entre ejecuciones
- [ ] Host puede ver lobby vacío

**Estimación:** 1 día

---

### User Story 1.2: Unirse a Sala
**Como** JUGADOR CLIENT  
**Quiero** UNIRME a una sala usando un código  
**Para** JUGAR con mis amigos

**Criterios de Aceptación:**
- [ ] Input field para ingresar código de 8 caracteres
- [ ] Botón "Conectar" se activa solo si el código es válido
- [ ] Si la conexión falla, muestra mensaje de error claro
- [ ] Si la conexión es exitosa, entra al lobby con el host

**Tareas Técnicas:**
```gdscript
# NetworkManager.gd
- [ ] Implementar join_room(code: String)
- [ ] Validar formato de código (regex: [A-Z0-9]{8})
- [ ] Configurar ENetMultiplayerPeer como cliente
- [ ] Conectar a host usando código
- [ ] Emitir señal connection_successful o connection_failed(reason)
```

**Tareas de UI:**
- [ ] LineEdit con placeholder "Código de Sala"
- [ ] Botón "Unirse" (deshabilitado si input vacío)
- [ ] Panel de error: "No se pudo conectar. Verifica el código."

**Testing:**
- [ ] Código inválido → Error
- [ ] Código válido → Conecta al lobby
- [ ] 2 clientes pueden unirse a la misma sala

**Estimación:** 1 día

---

### User Story 1.3: Chat Básico Funcional
**Como** JUGADOR  
**Quiero** ENVIAR MENSAJES de texto  
**Para** COMUNICARME con otros jugadores

**Criterios de Aceptación:**
- [ ] Input de texto en la parte inferior
- [ ] Log de chat muestra mensajes de todos los jugadores
- [ ] Mensajes muestran el nombre del remitente
- [ ] Rate limiting: máximo 1 mensaje cada 0.5 segundos
- [ ] Máximo 500 caracteres por mensaje

**Tareas Técnicas:**
```gdscript
# ChatController.gd (sin comandos todavía, solo texto blanco)
- [ ] Implementar send_message(text: String)
- [ ] RPC @rpc("any_peer", "call_local") _receive_message(sender_id, text)
- [ ] Rate limiting (TIME_BETWEEN_MESSAGES = 0.5)
- [ ] Validación de longitud (MAX_MESSAGE_LENGTH = 500)
- [ ] Mostrar en RichTextLabel
```

**Tareas de UI:**
- [ ] RichTextLabel (scroll automático al final)
- [ ] LineEdit + Botón "Enviar"
- [ ] Formato: `[Nombre]: Mensaje`
- [ ] Color blanco para todo (sin comandos aún)

**Testing:**
- [ ] 3 jugadores chateando simultáneamente
- [ ] Spam bloqueado por rate limiting
- [ ] Mensajes largos truncados a 500 chars

**Estimación:** 1 día

---

### User Story 1.4: Manejo de Desconexiones
**Como** SISTEMA  
**Quiero** MANEJAR desconexiones inesperadas  
**Para** NO crashear el juego

**Criterios de Aceptación:**
- [ ] Si un client se desconecta, los demás reciben notificación en chat
- [ ] Si el HOST se desconecta, todos vuelven al menú principal
- [ ] No hay crashes ni errores en consola
- [ ] Avatares de jugadores desconectados se eliminan del mapa

**Tareas Técnicas:**
```gdscript
# NetworkManager.gd
- [ ] Conectar señal peer_disconnected(id)
- [ ] Implementar _on_peer_disconnected(id: int)
- [ ] Eliminar jugador del diccionario de peers
- [ ] Emitir señal player_left(id: int)
- [ ] Si host (id == 1) se va → emitir host_disconnected
```

**Testing:**
- [ ] Desconectar client → Notificación + avatar eliminado
- [ ] Desconectar host → Todos vuelven a menú

**Estimación:** 0.5 días

---

### User Story 1.5: Sincronización de Nombres
**Como** JUGADOR  
**Quiero** VER el nombre de otros jugadores  
**Para** SABER quién es quién

**Criterios de Aceptación:**
- [ ] Al conectar, cada jugador envía su nombre
- [ ] Los nombres se muestran en el chat
- [ ] Los nombres son únicos (si hay repetidos, agregar número)

**Tareas Técnicas:**
```gdscript
# NetworkManager.gd
- [ ] Diccionario player_names: Dictionary[int, String]
- [ ] RPC register_player(name: String)
- [ ] Función get_player_name(id: int) -> String
- [ ] Validación de nombres únicos
```

**Testing:**
- [ ] 3 jugadores con nombres diferentes → OK
- [ ] 2 jugadores con nombre "John" → "John", "John (2)"

**Estimación:** 0.5 días

---

**TOTAL SPRINT 1:** 4.5 días → **1 semana con buffer**

**Milestone 1 Alcanzado:** ✅ Sistema de red funcional, chat básico operativo

---

## 🎨 ÉPICA 2: IDENTIDAD (Sprint 2 - Semana 2)

### User Story 2.1: Estructura de Datos JSON para Avatares
**Como** SISTEMA  
**Quiero** UN FORMATO JSON estandarizado  
**Para** CARGAR avatares de forma consistente

**Criterios de Aceptación:**
- [ ] Clase `AvatarData` puede serializar/deserializar JSON
- [ ] JSON incluye: nombre, descripción, imagen_url, raza_id, sexo_id
- [ ] Validación de campos obligatorios
- [ ] Generación automática de UUID único

**Estructura JSON:**
```json
{
  "id": "uuid-generado-automaticamente",
  "nombre": "Aria la Exploradora",
  "descripcion": "Una valiente aventurera que busca tesoros perdidos",
  "imagen_url": "res://assets/avatars/humano_femenino_01.png",
  "raza_id": "humano",
  "sexo_id": "femenino"
}
```

**Tareas Técnicas:**
```gdscript
# avatar_data.gd (Resource)
- [ ] Crear clase AvatarData extends Resource
- [ ] Propiedades: id, nombre, descripcion, imagen_url, raza_id, sexo_id
- [ ] Método to_json() -> Dictionary
- [ ] Método static from_json(data: Dictionary) -> AvatarData
- [ ] Método save_to_file(path: String) -> bool
- [ ] Método static load_from_file(path: String) -> AvatarData
- [ ] Validación de campos obligatorios
```

**Testing:**
- [ ] Guardar avatar → JSON creado en `user://profiles/`
- [ ] Cargar avatar → Datos correctos
- [ ] JSON malformado → Error controlado

**Estimación:** 1 día

---

### User Story 2.2: Archivos de Configuración Global
**Como** DISEÑADOR DE CONTENIDO (tú en el futuro)  
**Quiero** ARCHIVOS JSON maestros para razas/sexos  
**Para** AGREGAR opciones sin tocar código

**Criterios de Aceptación:**
- [ ] `razas.json` lista todas las razas disponibles
- [ ] `sexos.json` lista todos los sexos disponibles
- [ ] Sistema de carga automática al iniciar el juego
- [ ] IDs válidos en avatares se validan contra estos archivos

**Estructura de Archivos:**

**razas.json:**
```json
{
  "razas": [
    {
      "id": "humano",
      "nombre": "Humano",
      "descripcion": "Versátiles y adaptables"
    },
    {
      "id": "elfo",
      "nombre": "Elfo",
      "descripcion": "Ágiles y sabios"
    },
    {
      "id": "enano",
      "nombre": "Enano",
      "descripcion": "Fuertes y resistentes"
    }
  ]
}
```

**sexos.json:**
```json
{
  "sexos": [
    {
      "id": "masculino",
      "nombre": "Masculino",
      "icono": "♂"
    },
    {
      "id": "femenino",
      "nombre": "Femenino",
      "icono": "♀"
    }
  ]
}
```

**Tareas Técnicas:**
```gdscript
# config_loader.gd (Autoload)
- [ ] Cargar razas.json en _ready()
- [ ] Cargar sexos.json en _ready()
- [ ] Diccionarios razas_db y sexos_db
- [ ] Método get_raza(id: String) -> Dictionary
- [ ] Método get_sexo(id: String) -> Dictionary
- [ ] Validación de IDs
```

**Testing:**
- [ ] Razas y sexos se cargan al iniciar juego
- [ ] Avatar con raza_id inválido → Error claro

**Estimación:** 1 día

---

### User Story 2.3: Creador de Avatares (UI)
**Como** JUGADOR  
**Quiero** UNA INTERFAZ para crear mi avatar  
**Para** PERSONALIZAR mi personaje

**Criterios de Aceptación:**
- [ ] Input de texto para nombre (máx 30 caracteres)
- [ ] TextEdit para descripción (máx 500 caracteres)
- [ ] Selector de imagen (4 opciones prefabricadas mínimo)
- [ ] Selector de raza (lee de razas.json)
- [ ] Selector de sexo (lee de sexos.json)
- [ ] Preview del avatar en tiempo real
- [ ] Botón "Guardar Perfil"
- [ ] Botón "Cargar Perfil"

**Tareas de UI:**
```
avatar_creator.tscn
├── Panel (centrado)
│   ├── VBoxContainer
│   │   ├── LineEdit (Nombre)
│   │   ├── TextEdit (Descripción)
│   │   ├── OptionButton (Imagen - 4 opciones)
│   │   ├── OptionButton (Raza - desde JSON)
│   │   ├── OptionButton (Sexo - desde JSON)
│   │   ├── TextureRect (Preview)
│   │   ├── HBoxContainer
│   │   │   ├── Button "Guardar"
│   │   │   ├── Button "Cargar"
│   │   │   └── Button "Aleatorio"
```

**Tareas Técnicas:**
```gdscript
# avatar_creator_ui.gd
- [ ] Conectar señales de UI
- [ ] Método _on_save_pressed()
- [ ] Método _on_load_pressed() (FileDialog)
- [ ] Método _on_random_pressed() (combinación aleatoria)
- [ ] Actualizar preview al cambiar opciones
- [ ] Validación de nombre único
```

**Testing:**
- [ ] Crear avatar → JSON guardado correctamente
- [ ] Cargar avatar → Campos poblados
- [ ] Preview se actualiza en tiempo real

**Estimación:** 2 días

---

### User Story 2.4: Gestión de Múltiples Avatares
**Como** JUGADOR  
**Quiero** CREAR Y GUARDAR múltiples avatares  
**Para** CAMBIAR de personaje según la partida

**Criterios de Aceptación:**
- [ ] Puedo guardar avatares con nombres únicos
- [ ] Puedo cargar cualquier avatar guardado
- [ ] Puedo eliminar avatares
- [ ] Lista de avatares disponibles en selector

**Tareas Técnicas:**
```gdscript
# avatar_manager.gd (Autoload)
- [ ] Método list_profiles() -> Array[String] (lista archivos en user://profiles/)
- [ ] Método load_profile(name: String) -> AvatarData
- [ ] Método delete_profile(name: String) -> bool
- [ ] current_avatar: AvatarData (avatar activo)
```

**Tareas de UI:**
- [ ] FileDialog para seleccionar avatar
- [ ] Confirmación antes de eliminar

**Testing:**
- [ ] Crear 3 avatares → 3 archivos JSON
- [ ] Cargar avatar 2 → Datos correctos
- [ ] Eliminar avatar 1 → Archivo borrado

**Estimación:** 1 día

---

### User Story 2.5: Sincronización de Avatares en Red
**Como** JUGADOR  
**Quiero** QUE mi avatar aparezca en pantalla de otros jugadores  
**Para** QUE me reconozcan visualmente

**Criterios de Aceptación:**
- [ ] Al conectar, envío datos de mi avatar al host
- [ ] El host reenvía los datos a todos los clientes
- [ ] Cada jugador ve los avatares correctos de los demás
- [ ] Los avatares se sincronizan antes de entrar al mapa

**Tareas Técnicas:**
```gdscript
# NetworkManager.gd
- [ ] Diccionario player_avatars: Dictionary[int, AvatarData]
- [ ] RPC register_avatar(avatar_json: String)
- [ ] Método get_player_avatar(id: int) -> AvatarData
- [ ] Sincronización al conectar nuevo jugador

# WorldController.gd (se creará en Sprint 3)
- [ ] Spawn de avatares usando AvatarData
```

**Testing:**
- [ ] 3 jugadores con avatares diferentes → Todos se ven correctamente

**Estimación:** 1 día

---

**TOTAL SPRINT 2:** 6 días → **1 semana con optimización**

**Milestone 2 Alcanzado:** ✅ Sistema JSON de avatares completo y sincronizado

---

## 🗺️ ÉPICA 3: MUNDO (Sprint 3 - Semana 3)

### User Story 3.1: Mapa Lobby Básico
**Como** JUGADOR  
**Quiero** UN MAPA VISUAL donde moverme  
**Para** EXPLORAR el espacio de juego

**Criterios de Aceptación:**
- [ ] Mapa isométrico de 16x16 tiles mínimo
- [ ] Colisiones con paredes y muebles
- [ ] Al menos 1 objeto interactivo (sofá para escenas)
- [ ] Estilo visual coherente (pixel art o flat design)

**Tareas de Arte:**
- [ ] Crear tileset básico:
  - Suelo (2-3 variantes)
  - Pared (esquinas + laterales)
  - Muebles (mesa, silla, sofá)
- [ ] Configurar TileMap en Godot
- [ ] Pintar mapa lobby

**Tareas Técnicas:**
```gdscript
# lobby.tscn
- [ ] Crear escena con TileMap
- [ ] Layer 0: Suelo
- [ ] Layer 1: Paredes (con colisiones)
- [ ] Layer 2: Muebles decorativos
- [ ] Agregar objeto interactivo (Area2D + CollisionShape2D)
```

**Testing:**
- [ ] Mapa se ve sin artefactos visuales
- [ ] Colisiones funcionan correctamente

**Estimación:** 1.5 días (incluye creación de assets)

---

### User Story 3.2: Movimiento de Avatares
**Como** JUGADOR  
**Quiero** MOVER mi avatar con WASD/Flechas  
**Para** NAVEGAR el mapa

**Criterios de Aceptación:**
- [ ] Input: WASD o flechas direccionales
- [ ] Movimiento suave (no teleport)
- [ ] No puedo atravesar paredes
- [ ] Mi avatar aparece como imagen estática del JSON

**Tareas Técnicas:**
```gdscript
# remote_avatar.gd (representa jugador en el mapa)
extends CharacterBody2D

@export var avatar_data: AvatarData
@onready var sprite = $Sprite2D
@onready var nametag = $NameLabel

const SPEED = 150.0

func _ready():
    sprite.texture = load(avatar_data.imagen_url)
    nametag.text = avatar_data.nombre

func _physics_process(delta):
    if is_multiplayer_authority():
        var input_vector = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
        velocity = input_vector * SPEED
        move_and_slide()
```

**Tareas de Sincronización:**
```gdscript
# Agregar MultiplayerSynchronizer
- [ ] Sincronizar position (tipo: lerp)
- [ ] Solo authority puede mover
```

**Testing:**
- [ ] 2 jugadores moviéndose sin lag
- [ ] Colisiones previenen atravesar paredes

**Estimación:** 1 día

---

### User Story 3.3: Nametags Flotantes
**Como** JUGADOR  
**Quiero** VER EL NOMBRE de otros jugadores  
**Para** IDENTIFICAR quién es quién

**Criterios de Aceptación:**
- [ ] Label flotante encima de cada avatar
- [ ] Sigue al avatar al moverse
- [ ] Fuente legible (mínimo 12px)
- [ ] Contraste con el fondo (outline negro)

**Tareas Técnicas:**
```gdscript
# En remote_avatar.tscn
- [ ] Agregar Label como hijo de CharacterBody2D
- [ ] position.y = -40 (encima del sprite)
- [ ] Configurar LabelSettings:
  - Font size: 12
  - Outline size: 2
  - Outline color: negro
```

**Testing:**
- [ ] Nametags visibles en todos los jugadores
- [ ] Se mueven con el avatar

**Estimación:** 0.5 días

---

### User Story 3.4: Sistema de Filtrado de Acciones
**Como** SISTEMA  
**Quiero** FILTRAR acciones disponibles por raza/sexo  
**Para** MOSTRAR solo interacciones válidas

**Criterios de Aceptación:**
- [ ] `acciones_rol.json` define combinaciones válidas
- [ ] Al interactuar con objeto, sistema filtra acciones
- [ ] Solo muestra acciones compatibles con ambos jugadores
- [ ] Si no hay acciones compatibles, muestra mensaje

**Estructura de acciones_rol.json:**
```json
{
  "acciones": [
    {
      "id": "charlar_sofa",
      "nombre": "Charlar en el Sofá",
      "combinaciones_sexo": [
        ["masculino", "femenino"],
        ["femenino", "femenino"],
        ["masculino", "masculino"]
      ],
      "combinaciones_raza": [
        ["humano", "elfo"],
        ["humano", "humano"],
        ["elfo", "elfo"]
      ],
      "imagen_url": "res://assets/scenes/charlar_sofa.png"
    },
    {
      "id": "entrenar_juntos",
      "nombre": "Entrenar Juntos",
      "combinaciones_sexo": [
        ["masculino", "masculino"]
      ],
      "combinaciones_raza": [
        ["humano", "humano"],
        ["enano", "enano"]
      ],
      "imagen_url": "res://assets/scenes/entrenar.png"
    }
  ]
}
```

**Tareas Técnicas:**
```gdscript
# action_filter.gd
class_name ActionFilter

static func get_compatible_actions(player1: AvatarData, player2: AvatarData) -> Array:
    var acciones = ConfigLoader.acciones_db
    var compatible = []
    
    for accion in acciones:
        if _is_compatible(accion, player1, player2):
            compatible.append(accion)
    
    return compatible

static func _is_compatible(accion: Dictionary, p1: AvatarData, p2: AvatarData) -> bool:
    var sexos_match = false
    var razas_match = false
    
    # Verificar combinaciones de sexo
    for combo in accion["combinaciones_sexo"]:
        if (combo[0] == p1.sexo_id and combo[1] == p2.sexo_id) or \
           (combo[0] == p2.sexo_id and combo[1] == p1.sexo_id):
            sexos_match = true
            break
    
    # Verificar combinaciones de raza
    for combo in accion["combinaciones_raza"]:
        if (combo[0] == p1.raza_id and combo[1] == p2.raza_id) or \
           (combo[0] == p2.raza_id and combo[1] == p1.raza_id):
            razas_match = true
            break
    
    return sexos_match and razas_match
```

**Tareas de Carga:**
```gdscript
# config_loader.gd
- [ ] Cargar acciones_rol.json al iniciar
- [ ] Variable acciones_db: Array
```

**Testing:**
- [ ] Humano M + Elfo F → Muestra "Charlar en el Sofá"
- [ ] Humano M + Humano M → Muestra "Charlar" y "Entrenar"
- [ ] Elfo F + Enano M → No hay acciones compatibles

**Estimación:** 1.5 días

---

### User Story 3.5: Interacción con Objetos
**Como** JUGADOR  
**Quiero** INTERACTUAR con objetos del mapa  
**Para** INICIAR escenas conjuntas

**Criterios de Aceptación:**
- [ ] Al acercarme a objeto, aparece prompt "Presiona E"
- [ ] Al presionar E, sistema verifica si hay otro jugador cerca
- [ ] Si hay alguien, muestra lista de acciones compatibles
- [ ] Si no hay nadie, muestra mensaje "Necesitas otro jugador"

**Tareas Técnicas:**
```gdscript
# interactive_object.gd (agregado a objetos del mapa)
extends Area2D

signal interaction_requested(players: Array)

var nearby_players = []

func _ready():
    body_entered.connect(_on_body_entered)
    body_exited.connect(_on_body_exited)

func _on_body_entered(body):
    if body is RemoteAvatar:
        nearby_players.append(body)

func _on_body_exited(body):
    nearby_players.erase(body)

func _input(event):
    if event.is_action_pressed("interact") and nearby_players.size() > 0:
        interaction_requested.emit(nearby_players)
```

**Tareas de UI:**
- [ ] Label "Presiona E" aparece en objeto
- [ ] Solo visible si jugador está cerca

**Testing:**
- [ ] Acercarme a sofá → Prompt aparece
- [ ] Presionar E con 1 jugador → "Necesitas otro jugador"
- [ ] Presionar E con 2 jugadores → Lista de acciones

**Estimación:** 1 día

---

**TOTAL SPRINT 3:** 5.5 días → **1 semana**

**Milestone 3 Alcanzado:** ✅ Mapa funcional + Sistema de filtrado listo

---

## 🎬 ÉPICA 4: INTERACCIÓN (Sprint 4 - Semana 4, Parte 1)

### User Story 4.1: Selección de Acción
**Como** JUGADOR  
**Quiero** ELEGIR una acción de la lista filtrada  
**Para** INICIAR una escena conjunta

**Criterios de Aceptación:**
- [ ] UI muestra lista de acciones compatibles
- [ ] Cada opción muestra nombre y preview de imagen
- [ ] Solo puedo elegir si ambos jugadores aceptaron
- [ ] Si alguien rechaza, volvemos al mapa

**Tareas de UI:**
```
action_selector.tscn
├── Panel (centrado, semi-transparente)
│   ├── Label "Selecciona una acción"
│   ├── VBoxContainer (lista de botones)
│   │   ├── Button (Acción 1)
│   │   ├── Button (Acción 2)
│   │   └── Button "Cancelar"
```

**Tareas Técnicas:**
```gdscript
# scene_controller.gd
- [ ] Método show_action_selector(actions: Array)
- [ ] RPC action_selected(action_id: String)
- [ ] RPC action_cancelled()
- [ ] State Machine: IDLE → SELECTING_ACTION → WAITING_PARTNER
```

**Testing:**
- [ ] Ambos eligen misma acción → Continúa
- [ ] Uno cancela → Vuelven al mapa

**Estimación:** 1 día

---

### User Story 4.2: Ventana de Animación Conjunta
**Como** JUGADOR  
**Quiero** VER una ventana con la imagen de la acción  
**Para** VISUALIZAR la escena

**Criterios de Aceptación:**
- [ ] Ventana fullscreen con imagen de la acción
- [ ] Imagen se carga desde imagen_url del JSON
- [ ] Botón "Despedirse" para terminar
- [ ] Al terminar, volvemos al mapa

**Tareas de UI:**
```
scene_viewer.tscn
├── ColorRect (fondo negro semi-transparente)
│   ├── TextureRect (imagen de la acción, centrada)
│   ├── Label (nombre de la acción, arriba)
│   └── Button "Despedirse" (abajo)
```

**Tareas Técnicas:**
```gdscript
# scene_viewer.gd
- [ ] Método show_scene(action: Dictionary)
- [ ] Cargar imagen desde action["imagen_url"]
- [ ] Señal farewell_pressed
- [ ] RPC end_scene()
```

**Testing:**
- [ ] Imagen se muestra correctamente
- [ ] Ambos jugadores ven la misma imagen
- [ ] "Despedirse" termina la escena

**Estimación:** 1 día

---

### User Story 4.3: Cambio de Avatar en Tiempo Real
**Como** JUGADOR  
**Quiero** CAMBIAR de avatar sin salir de la sala  
**Para** ADAPTAR mi personaje a la narrativa

**Criterios de Aceptación:**
- [ ] Botón "Cambiar Avatar" en el menú de pausa
- [ ] Abre selector de avatares guardados
- [ ] Al elegir, mi sprite se actualiza en el mapa
- [ ] Todos los jugadores ven el cambio

**Tareas Técnicas:**
```gdscript
# avatar_manager.gd
- [ ] RPC change_avatar(new_avatar_json: String)
- [ ] Método update_avatar_visual(player_id: int)

# remote_avatar.gd
- [ ] Método reload_texture(new_avatar: AvatarData)
```

**Testing:**
- [ ] Cambio de Humano M a Elfo F → Sprite se actualiza
- [ ] Otros jugadores ven el cambio
- [ ] Filtrado de acciones se recalcula

**Estimación:** 1 día

---

**TOTAL SPRINT 4 (Parte 1):** 3 días

---

## 💬 ÉPICA 5: COMUNICACIÓN (Sprint 4 - Semana 4, Parte 2)

### User Story 5.1: Comandos de Chat Especializados
**Como** JUGADOR  
**Quiero** USAR COMANDOS /me, /roll, //  
**Para** ENRIQUECER mi roleplay

**Criterios de Aceptación:**
- [ ] `texto normal` → IC (blanco)
- [ ] `//texto` o `/ooc texto` → OOC (gris)
- [ ] `/me acción` → Acción (naranja itálico)
- [ ] `/roll XdY` → Dado (verde con resultado)

**Tareas Técnicas:**
```gdscript
# command_parser.gd
class_name CommandParser

static func parse(text: String, sender: String) -> Dictionary:
    if text.begins_with("//") or text.begins_with("/ooc"):
        return {
            "type": "ooc",
            "sender": sender,
            "text": text.trim_prefix("//").trim_prefix("/ooc ").strip_edges()
        }
    elif text.begins_with("/me "):
        return {
            "type": "action",
            "sender": sender,
            "text": text.trim_prefix("/me ").strip_edges()
        }
    elif text.begins_with("/roll "):
        var dice_str = text.trim_prefix("/roll ").strip_edges()
        var result = _roll_dice(dice_str)
        return {
            "type": "roll",
            "sender": sender,
            "dice": dice_str,
            "result": result
        }
    else:
        return {"type": "ic", "sender": sender, "text": text}

static func _roll_dice(notation: String) -> int:
    var parts = notation.split("d")
    if parts.size() != 2:
        return 0
    
    var num_dice = int(parts[0])
    var die_size = int(parts[1])
    
    if num_dice <= 0 or die_size <= 0:
        return 0
    
    var total = 0
    for i in range(num_dice):
        total += randi() % die_size + 1
    return total
```

**Tareas de Formato:**
```gdscript
# message_formatter.gd
class_name MessageFormatter

static func format(parsed: Dictionary) -> String:
    match parsed["type"]:
        "ic":
            return "[color=white]%s: %s[/color]" % [parsed["sender"], parsed["text"]]
        "ooc":
            return "[color=gray](OOC) %s: %s[/color]" % [parsed["sender"], parsed["text"]]
        "action":
            return "[color=orange][i]* %s %s[/i][/color]" % [parsed["sender"], parsed["text"]]
        "roll":
            return "[color=green]🎲 %s rolled %s: %d[/color]" % [parsed["sender"], parsed["dice"], parsed["result"]]
    return ""
```

**Actualización de ChatController:**
```gdscript
# chat_controller.gd
func send_message(text: String):
    # Validaciones anteriores...
    
    var parsed = CommandParser.parse(text, player_name)
    var formatted = MessageFormatter.format(parsed)
    
    rpc("_receive_message", formatted)
```

**Testing:**
- [ ] Texto normal → Blanco
- [ ] `//Hola` → Gris con (OOC)
- [ ] `/me sonríe` → Naranja itálico
- [ ] `/roll 1d20` → Verde con resultado

**Estimación:** 1 día

---

**TOTAL SPRINT 4 (Completo):** 4 días → **1 semana con pulido**

---

## 🎨 FASE 6: PULIDO Y TESTING (Integrado en Sprint 4)

### Tareas de Pulido
- [ ] **Sonido:**
  - Click de botón (UI)
  - Sonido de mensaje nuevo en chat
  - Música ambiente para lobby (loop de 1-2 min)

- [ ] **UI/UX:**
  - Tooltips en botones importantes
  - Pantalla de carga al conectar
  - Mensajes de error claros

- [ ] **Optimización:**
  - Reducir lag en sincronización de movimiento
  - Limitar historial de chat a 100 mensajes

- [ ] **Build:**
  - Exportar para Windows (exe)
  - Exportar para Linux (x86_64)
  - Íconos y metadata del juego

**Estimación:** Integrado en el desarrollo, ~4 horas al final

---

## ✅ DEFINITION OF DONE (DoD)

Una tarea está **DONE** cuando:
- [ ] Código implementado y funcional
- [ ] Testing manual completado (checklist)
- [ ] Sin errores en consola de Godot
- [ ] Documentado con comentarios (si es complejo)
- [ ] Integrado con sistemas existentes
- [ ] Probado con 2+ instancias (si es networking)
- [ ] Agregado a checklist de testing final

---

## 🧪 CHECKLIST DE TESTING FINAL

### Pre-Launch Testing (Semana 4, último día)
- [ ] **Networking:**
  - [ ] 4 jugadores pueden conectarse simultáneamente
  - [ ] Chat funciona con 4 jugadores
  - [ ] Desconexión de host maneja correctamente

- [ ] **Avatares:**
  - [ ] 4 avatares diferentes se ven correctamente
  - [ ] Cambio de avatar funciona en tiempo real
  - [ ] Filtrado de acciones es correcto

- [ ] **Mapa:**
  - [ ] Colisiones funcionan
  - [ ] Movimiento fluido sin lag
  - [ ] Nametags legibles

- [ ] **Escenas:**
  - [ ] 2 acciones diferentes ejecutables
  - [ ] Imágenes se cargan correctamente
  - [ ] "Despedirse" funciona

- [ ] **Chat:**
  - [ ] Todos los comandos funcionan
  - [ ] Rate limiting previene spam
  - [ ] Historial no excede 100 mensajes

- [ ] **Estabilidad:**
  - [ ] 30 minutos de juego sin crashes
  - [ ] Sin errores en consola
  - [ ] FPS estable (60+)

---

## 📊 CRITERIOS DE ÉXITO DEL MVP

### Métricas de Validación
1. **Técnicas:**
   - [ ] Build funcional en Windows y Linux
   - [ ] 0 crashes en sesiones de 30+ minutos
   - [ ] 4 jugadores simultáneos sin lag visible

2. **Experiencia:**
   - [ ] 10 usuarios pueden crear avatares
   - [ ] Entienden el sistema de filtrado de acciones
   - [ ] Completan al menos 1 escena conjunta

3. **Feedback:**
   - [ ] Al menos 5/10 testers dicen "Seguiría jugando esto"
   - [ ] 3/10 testers mencionan features que quieren ver

---

## 🚀 POST-MVP: EXPANSIÓN SIN CÓDIGO

Una vez completado el MVP, tú puedes expandir el juego **SIN TOCAR CÓDIGO**:

### Agregar Nuevas Razas
```json
// razas.json - solo editar este archivo
{
  "razas": [
    // ... razas existentes
    {
      "id": "dragon",
      "nombre": "Dragón",
      "descripcion": "Poderosos y majestuosos"
    }
  ]
}
```

### Agregar Nuevas Acciones
```json
// acciones_rol.json
{
  "acciones": [
    // ... acciones existentes
    {
      "id": "volar_juntos",
      "nombre": "Volar Juntos",
      "combinaciones_sexo": [["masculino", "femenino"]],
      "combinaciones_raza": [["dragon", "humano"]],
      "imagen_url": "res://assets/scenes/volar.png"
    }
  ]
}
```

### Agregar Nuevos Mapas
1. Duplicar `lobby.tscn`
2. Pintar nuevo diseño
3. Guardar como `taberna.tscn`
4. Listo ✅

---

## 📈 ROADMAP POST-MVP

### Alta Prioridad (Post-MVP Inmediato)
- [ ] 2 mapas adicionales (Taberna, Bosque)
- [ ] 5 acciones conjuntas más
- [ ] Comando `/w` (susurro)
- [ ] Sistema de "Hoja de Personaje" (UI extra)

### Media Prioridad (v0.2)
- [ ] Exportador de logs de chat
- [ ] Sistema de mods (carpeta `mods/`)
- [ ] Minijuegos (ajedrez, dados)

### Baja Prioridad (v0.3+)
- [ ] Soporte para 3+ jugadores en escenas
- [ ] Sistema de achievements
- [ ] Integración con Discord (Rich Presence)

---

## ⚠️ RIESGOS Y MITIGACIÓN

| Riesgo | Probabilidad | Impacto | Mitigación |
|--------|--------------|---------|------------|
| **Networking inestable** | Media | Alto | Testing exhaustivo en Semana 1 |
| **Scope Creep** | Alta | Crítico | Referirse a este backlog, rechazar features |
| **Arte toma demasiado tiempo** | Alta | Medio | Usar assets placeholder, mejorar en v0.2 |
| **Burnout** | Media | Alto | Sprints de 1 semana con descansos |
| **Filtrado de acciones buggy** | Media | Medio | Tests unitarios para ActionFilter |

---

## 📝 NOTAS FINALES

### Principios de Desarrollo
1. **Completar > Perfeccionar:** Un sistema funcional es mejor que uno perfecto sin terminar
2. **Testing Temprano:** Probar networking ANTES de arte
3. **Data-Driven:** Si algo puede ser JSON, que sea JSON
4. **Scope Controlado:** Solo lo del backlog, nada más

### Próximos Documentos Necesarios
1. **Arquitectura de Sistemas (Diagramas UML)** - Para visualizar clases
2. **Guía de Assets** - Nomenclatura y especificaciones técnicas
3. **Manual de Usuario** - Tutorial in-game

---

**ESTE BACKLOG ES TU BIBLIA DE DESARROLLO**

No agregues features que no estén aquí.  
No te saltes sprints.  
Cada fase valida que la anterior funciona.

---

**Versión:** 1.1  
**Última Actualización:** Febrero 2026  
**Estado:** ✅ Listo para Implementación

---

**FIN DEL PRODUCT BACKLOG MVP**
