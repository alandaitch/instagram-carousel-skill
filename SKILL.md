---
name: instagram-carousel
description: Genera carousels para Instagram (PNG 1080×1350) a partir de un tema. Usar cuando el usuario pida "un carousel/carrusel sobre X", "convertí esto en carousel", "hacé un carrusel de noticia/tip/reflexión" o dé un tema con formato carousel implícito. Flujo en dos pasos - primero propone el texto slide por slide para aprobar, después renderiza los PNG con Open Carrusel local usando uno de 6 templates HTML. No publica en Instagram. Also triggers on "Instagram carousel", "make a carousel about X".
---

# Instagram Carousel

Genera carousels para Instagram desde un tema. Renderiza PNG de 1080×1350 con [Open Carrusel](https://github.com/Hainrixz/open-carrusel) y 6 templates HTML incluidos. Deja los PNG y el caption en una carpeta local.

## Requisitos

- Open Carrusel clonado e instalado (`npm install`) en `open_carrusel_dir`.
- Python 3.10+.
- `config.json` en la raíz del skill (copiar de `config.example.json`). Ver [README](README.md).

## El contrato de dos pasos

Este skill trabaja SIEMPRE en dos pasos, en respuestas distintas.

**Paso 1:** proponer el contenido slide por slide en texto. Esperar aprobación.
**Paso 2:** solo tras aprobación explícita, generar los PNG.

Motivo: editar PNG cuesta un ciclo completo. Editar texto cuesta segundos.

- "OK" / "dale" / "perfecto" / "adelante" → arrancar Paso 2.
- "cambiá X" → repetir Paso 1 con el ajuste. Esperar OK de nuevo.
- Si el usuario pide saltar el Paso 1: explicar el motivo en una línea y proponer una versión corta (3–5 slides). Saltar solo si insiste.

---

## Paso 1 — Propuesta en texto

### 1.1 Detectar el formato

| Señal en el pedido | Formato |
|---|---|
| "acaba de salir", "lanzaron", anuncio, paper, fecha, evento | **Noticia** |
| "X tips", "cómo hacer Y", "trucos para", "N cosas que…" | **Tip** |
| opinión, reflexión, "qué pienso de", filosófico | **Reflexión** |

Si es ambiguo, preguntar antes de proponer.

### 1.2 Elegir el template

| Formato | Default | Alternativa | Cuándo usar la alternativa |
|---|---|---|---|
| Noticia | **Card Pop** (`card-pop`) | **Tech Terminal** (`tech-terminal`) | Tema técnico: release con benchmarks, código, audiencia developer |
| Tip | **Numbered Steps** (`numbered-steps`) | **Sticky Note** (`sticky-note`) | Tip lifestyle, casual, personal |
| Reflexión | **Diary** (`diary`) | **Soft Poetic** (`soft-poetic`) | Reflexión muy breve, una frase por slide |

Si proponés la alternativa, justificar en una línea. Detalle de cada template: [references/templates.md](references/templates.md).

### 1.3 Chrome del template

Cada template trae tres elementos de "chrome": top label (pill arriba), handle en el footer, paginación ("2 / 5").

| Tipo de pieza | Top label | Handle | Paginación |
|---|---|---|---|
| Carousel propio de la cuenta (opinión, tip, noticia comentada) | sí | sí | sí |
| Promo de evento / colaboración donde la cuenta es uno de varios protagonistas | no | no | no |
| Pieza que otra cuenta va a republicar | no | no | opcional |

Declarar el chrome en la propuesta: `Chrome: completo` / `Chrome: limpio` / `Chrome: parcial — solo X`. Si el usuario no dijo nada, elegir el default de la tabla y mencionarlo.

### 1.4 Escribir el contenido

**Voz.** Si el usuario tiene un skill o guía de voz propia (ej. `write-like-<nombre>`), aplicarla. Si no, seguir [references/writing.md](references/writing.md).

Reglas mínimas, siempre:

- **5 a 10 slides.** Sin relleno, sin recorte.
- **Un punto por slide.** Un headline corto + un subhead de una línea.
- **Integridad factual.** No inventar stats, fechas, anécdotas ni capacidades de productos. Marcar lo dudoso con `[VERIFICAR: ...]` para que el usuario lo corrija antes de aprobar.
- **Sin emojis en los slides.** Sin ALL CAPS (salvo una palabra puntual).
- **Cierre que frena, no que despide.** Nada de "Pruébalo hoy" / "Gracias por leer". Ver patrones en `references/writing.md`.

### 1.5 Estructura típica

| Formato | Patrón |
|---|---|
| **Noticia** | (1) Hook + qué pasó · (2) "3 cosas que cambian" · (3..N-1) Un dato por slide · (N) Pregunta / CTA |
| **Tip** | (1) Hook + promesa concreta · (2) El error común (opcional) · (3..N-1) Un tip por slide con el "cómo" · (N) Cierre que frena |
| **Reflexión** | (1) Declaración fuerte · (2..N-1) Beats con contraste · (N) Pregunta abierta / aforismo |

### 1.6 Caption

1–3 líneas que extiendan el carousel sin repetirlo. Puede cerrar con una pregunta. Hashtags: solo si el usuario los usa. Si no lo aclaró, preguntar una vez y recordar la respuesta en la sesión.

### 1.7 Formato de salida del Paso 1

```
**Carousel propuesto:** "<título corto, 4–7 palabras>"

**Formato:** <noticia | tip | reflexión>
**Template:** <nombre> · <razón en 1 línea si no es default>
**Chrome:** <completo | limpio | parcial — X>
**Slides:** <N>

---

**Slide 1 — Portada**
<contenido literal>

**Slide 2 — <2-3 palabras>**
<contenido literal>

...

---

**Caption:**
<caption>

---

¿OK así? Decime si querés cambios o si genero los PNG.
```

Si hay `[VERIFICAR: ...]`, listarlos arriba de todo.

---

## Paso 2 — Ejecución (solo tras OK explícito)

### 2.1 Verificar el server

```bash
bash <skill_dir>/scripts/ensure_server.sh
```

Sale 0 si Open Carrusel responde. Si no, lo levanta y espera hasta 90 s. Si falla, abortar y reportar el error literal.

### 2.2 Construir el HTML de cada slide

1. Abrir `templates/<template_tag>.html`.
2. Copiar el bloque `<style id="slide-css">...</style>` completo, sin modificar. Ese es el `style` del spec. NO copiar el bloque `preview-only`: sirve solo para ver el archivo en el navegador.
3. Para cada slide aprobado: copiar el `<article class="slide">` de ejemplo que más se parezca (portada / contenido / cierre). Mantener el esqueleto. Reemplazar solo el texto.
4. Usar las clases CSS existentes. No inventar clases nuevas.
5. Dejar `{{HANDLE}}` y `{{SIGNATURE}}` como están: el script los reemplaza con `config.json`.
6. Chrome limpio: borrar `<div class="top">` / `.top-bar` y `<div class="footer">` del article.
7. Ajustar la paginación al total real de slides ("2 / 7", no "2 / 5").

No incluir `<!DOCTYPE>`, `<html>`, `<head>` ni `<link>` de fuentes. Open Carrusel los agrega y carga las Google Fonts que detecta en el `<style>`.

### 2.3 Construir el spec

Guardar en un archivo temporal (ej. `/tmp/carousel-spec.json`):

```json
{
  "title": "Llegó Nimbus 2.0",
  "format": "noticia",
  "template_tag": "card-pop",
  "caption": "...",
  "hashtags": [],
  "style": "<style>...</style>",
  "slides": [
    {"body": "<article class=\"slide\">...</article>", "notes": "portada"},
    {"body": "<article class=\"slide\">...</article>", "notes": "resumen"}
  ]
}
```

Ejemplo completo: [examples/spec.example.json](examples/spec.example.json).

### 2.4 Renderizar

```bash
python3 <skill_dir>/scripts/publish_carousel.py /tmp/carousel-spec.json
```

En Windows, usar `python` en vez de `python3`: ahí `python3` suele ser el atajo de la Microsoft Store y no corre.

El script:
1. Lee `config.json` (handle, firma, colores, fuente, carpeta de salida).
2. Reemplaza placeholders e inyecta los colores de marca como variables CSS.
3. Crea el carousel en Open Carrusel y agrega cada slide.
4. Exporta el ZIP y lo descomprime en `output_dir/<slug>/`.
5. Guarda `caption.txt` en la misma carpeta.
6. Ejecuta `after_export` si está configurado.
7. Imprime `LOCAL_FOLDER`, `CAROUSEL_ID`, `TITLE_SLUG`, `SLIDE_COUNT`, `TOTAL_KB`.

Si falla, leer stderr y reportar el error literal.

### 2.5 Reportar

```
Listo, "<título>" generado.

📁 Carpeta: <LOCAL_FOLDER>
🖼️ <N> slides PNG (1080×1350), <TOTAL_KB> KB
📝 caption.txt incluido
```

---

## Edge cases

- **Regenerar tras feedback:** correr `publish_carousel.py --overwrite` para escribir en la misma carpeta. Sin el flag, el script crea `<slug>-v2`.
- **Variantes para comparar:** generar con títulos distintos (`"<tema> — azul"`, `"<tema> — naranja"`). Agruparlas en una carpeta madre con el nombre canónico.
- **Open Carrusel no levanta:** verificar que `open_carrusel_dir` existe y tiene `node_modules`. No instalar automáticamente. Avisar al usuario.
- **Export devuelve HTTP 500:** un slide tiene HTML inválido. Leer el mensaje, regenerar ese slide, reintentar.
- **`template_tag` inválido:** el script lista los 6 válidos. Corregir y reintentar.
- **Soft Poetic con texto largo:** no funciona. Cambiar a Diary.

## Archivos de referencia

- [references/templates.md](references/templates.md) — paleta, componentes CSS y estructura de cada template. Leer antes de escribir HTML.
- [references/writing.md](references/writing.md) — patrones de escritura para carousels: subheads, quotes, warnings, cierres.
- [templates/](templates/) — los 6 templates HTML con 5 slides de ejemplo cada uno. Abrir en el navegador para verlos.

## Lo que NO hace este skill

- No publica en Instagram. Deja los PNG listos para subir.
- No genera videos ni reels.
- No edita PNG ya generados. Regenera el carousel completo.
