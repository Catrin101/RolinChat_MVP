# **Documento Maestro: Concepto y Especificaciones de Diseño del MVP**

## **1\. Visión General del Proyecto**

Este MVP (Producto Mínimo Viable) define una plataforma de juego de rol multijugador ligera basada en un modelo **Host-Client**. La meta es permitir que los jugadores interactúen en mapas 2D con avatares altamente personalizables y dinámicos, utilizando un sistema de lógica basado en datos (JSON) para las interacciones sociales y de rol.

## **2\. Arquitectura de Red y Salas**

* **Sistema de Host:** Un jugador actúa como servidor. Los demás se conectan a través de una "IP de Sala" o código identificador único que no compromete datos personales.  
* **Gestión de Salas:** El Host asigna un nombre a la sala y selecciona el mapa de juego inicial.  
* **Persistencia:** La información de la sala y el estado del mapa se mantienen activos mientras el Host esté conectado.

## **3\. Sistema de Avatares (Gestión de Fichas)**

Los avatares se gestionan mediante archivos JSON locales. Los jugadores pueden crear, editar, eliminar y, lo más importante, **cambiar de avatar en tiempo real** durante la partida sin abandonar la sala.

### **Estructura del Avatar (avatar.json)**

`{`  
  `"id": "uuid-unico",`  
  `"nombre": "Nombre del Personaje",`  
  `"descripcion": "Breve biografía narrativa",`  
  `"imagen_url": "link_a_la_imagen_estatica.png",`  
  `"raza_id": "id_procedente_de_lista",`  
  `"sexo_id": "id_procedente_de_lista"`  
`}`

`El apartado de imagen_url debe de soportar tanto archivos locales como links de internet.`

## **4\. Archivos de Configuración Global**

Para que el sistema sea modular, existen tres archivos JSON maestros que el motor consulta constantemente:

1. **razas.json**: Lista predefinida de razas disponibles (Ej: Humano, Elfo, Enano).  
2. **sexos.json**: Lista predefinida de sexos disponibles.  
3. **acciones\_rol.json**: Define la lógica de compatibilidad para las animaciones conjuntas.

## **5\. El Motor de Animaciones Conjuntas**

En este MVP, las "animaciones" no son archivos de video, sino una **ventana de UI superpuesta** que muestra imágenes ejemplificando acciones de rol.

### **Lógica de Filtrado y Reconocimiento**

Cuando ocurre una interacción conjunta, el sistema analiza los perfiles de los involucrados y filtra el archivo acciones\_rol.json bajo estos criterios:

* **Combinación de Sexo:** Verifica si los sexos de los participantes están permitidos para la acción.  
* **Combinación de Raza:** Verifica si las razas de los participantes son compatibles con la acción.

### **Estructura de la Acción (acciones\_rol.json)**

`{`  
  `"id": "id_accion",`  
  `"nombre": "Nombre de la Acción",`  
  `"combinaciones_sexo": [["M", "F"], ["F", "F"], ["M", "M"]],`  
  `"combinaciones_raza": [["Humano", "Elfo"], ["Humano", "Humano"]],`  
  `"imagen_url": "link_a_la_ilustracion_de_la_accion.png"`  
`}`

`El apartado de imagen_url debe de soportar tanto archivos locales como links de internet.`

*La interfaz solo mostrará al usuario las acciones que pasen estos filtros de compatibilidad.*

## **6\. Jugabilidad y Mapas 2D**

* **Entorno:** Mapas 2D de vista aérea (top-down) con sistema de rejilla.  
* **Colisiones:** El mapa incluye objetos sólidos y objetos interactivos (triggers).  
* **Movimiento:** Los avatares se mueven en 4 direcciones (WASD/Flechas) y se representan por la imagen estática definida en su JSON.  
* **Interacción:** Al tocar un objeto interactivo, se dispara el menú de "Acciones de Rol" filtrado por la raza y sexo del avatar (o avatares) presentes.

## **7\. Sistema de Chat**

* Se mantiene el sistema de chat estándar establecido en la documentación previa del proyecto, permitiendo la comunicación textual entre los jugadores de la sala sin modificaciones adicionales.

## **8\. Flujo de Usuario en el MVP**

1. **Preparación:** El jugador configura sus archivos JSON de avatar.  
2. **Conexión:** El Host crea la sala, eligiendo un mapa para la temática; los Clientes se unen mediante el código.  
3. **Juego:** Los jugadores navegan el mapa elegido. Si desean cambiar de rol, eligen otro archivo de avatar y el sistema actualiza automáticamente su apariencia y sus interacciones disponibles (acciones de raza/sexo).  
4. **Rol:** Al interactuar, se despliega la ventana de "animación" con la imagen correspondiente a la acción elegida.