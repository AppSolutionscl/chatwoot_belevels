# Parches sobre el código de Chatwoot

Cada archivo `*.patch` de esta carpeta se aplica, en orden alfabético, sobre el código oficial
de Chatwoot antes de construir la imagen (`scripts/preparar.sh`). Si un parche deja de aplicar
tras una actualización, el workflow falla y avisa: hay que rehacer ese parche para la nueva versión.

Para cambios chicos se prefieren archivos nuevos en `overlay/` y ediciones mínimas en `scripts/preparar.sh`.
