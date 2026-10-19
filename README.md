# Chatwoot · be levels

Chatwoot oficial (edición community) con la marca be levels. Este repositorio **no copia el código de Chatwoot**:
guarda solo nuestros cambios, y GitHub Actions los aplica sobre la versión oficial al construir la imagen.

| Archivo | Para qué |
|---------|----------|
| `CHATWOOT_VERSION` | Versión oficial de Chatwoot sobre la que se construye (ej. `v4.18.0`) |
| `overlay/` | Archivos propios que se copian encima del código (mismas rutas): el tema `_belevels.scss` (DM Sans, negro be levels), los logos del login (`public/belevels/`), los favicons e iconos (`public/*.png`, `manifest.json`) y `lib/tasks/belevels.rake`, que pone nombre y logos de la instalación en cada arranque |
| `scripts/preparar.sh` | Aplica los cambios: quita `enterprise/`, copia `overlay/`, hace ediciones mínimas (importa el tema, color de marca, nombre y logos por defecto, color del navegador) y aplica `patches/` |
| `patches/` | Cambios más grandes al código, como archivos `.patch` (vacío por ahora) |
| `.github/workflows/construir.yml` | Construye la imagen y la publica en `ghcr.io/<dueño>/chatwoot-belevels` en cada cambio en `main` |
| `.github/workflows/actualizar.yml` | Cada lunes revisa si hay versión nueva de Chatwoot: abre un pull request si nuestros cambios aplican, o un issue si hay que ajustar algo |

## Actualizar a una versión nueva de Chatwoot

1. Llega un pull request "Actualizar Chatwoot a vX.Y.Z" → **Merge pull request**.
2. Pestaña **Actions** → espera a que "Construir imagen be levels" termine en verde; el resumen muestra el nombre de la imagen.
3. Dokploy: backup manual de la base `chatwoot` → en el compose cambia el tag de `image:` → **Deploy**.
   Las migraciones de la base corren solas al arrancar.

## Cambiar algo de la marca

- Colores y tipografía: `overlay/app/javascript/dashboard/assets/scss/_belevels.scss`.
- Nombre de la instalación, nombre de marca y rutas de los logos: `overlay/lib/tasks/belevels.rake` (y los mismos valores en `scripts/preparar.sh`).
- Logos del login: `overlay/public/belevels/logo.png` (modo claro) y `logo_dark.png` (modo oscuro). Favicons: `overlay/public/*.png`.

Subir el cambio a `main`:
se construye una imagen nueva con tag `vX.Y.Z-bl.N`.
