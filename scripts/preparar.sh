#!/usr/bin/env bash
# be levels · aplica nuestros cambios sobre el código oficial de Chatwoot.
# Uso: bash scripts/preparar.sh <carpeta-con-el-código-de-chatwoot>
# Falla (y detiene la construcción) si algo del código oficial cambió y un cambio ya no aplica.
set -euo pipefail

AQUI="$(cd "$(dirname "$0")/.." && pwd)"
CW="$(cd "${1:?Indica la carpeta con el código de Chatwoot}" && pwd)"

falla() { echo "ERROR: $*" >&2; exit 1; }

# 1. Edición: `community` quita la carpeta enterprise (como la imagen oficial -ce);
#    `enterprise` la conserva (código con licencia Enterprise de Chatwoot: requiere una licencia o prueba válida,
#    que el hub de Chatwoot asocia al identificador de la instalación).
EDICION="$(tr -d '[:space:]' < "$AQUI/CHATWOOT_EDITION" 2>/dev/null || echo community)"
case "$EDICION" in
  community)
    rm -rf "$CW/enterprise" "$CW/spec/enterprise"
    printf '\nENV CW_EDITION="ce"\n' >> "$CW/docker/Dockerfile"
    echo "ok  edición community (sin enterprise/)" ;;
  enterprise)
    [[ -d "$CW/enterprise" ]] || falla "no existe $CW/enterprise"
    printf '\nENV CW_EDITION="ee"\n' >> "$CW/docker/Dockerfile"
    echo "ok  edición enterprise (con enterprise/)" ;;
  *) falla "CHATWOOT_EDITION debe ser community o enterprise (hay: $EDICION)" ;;
esac

# 2. Archivos propios (overlay/ se copia encima, con las mismas rutas).
cp -R "$AQUI/overlay/." "$CW/"
echo "ok  archivos propios copiados"

# 3. Ediciones mínimas en archivos de Chatwoot.
WOOT="$CW/app/javascript/dashboard/assets/scss/_woot.scss"
[[ -f "$WOOT" ]] || falla "no existe $WOOT"
grep -q "@import 'belevels';" "$WOOT" || printf "\n// be levels\n@import 'belevels';\n" >> "$WOOT"
echo "ok  tema importado en _woot.scss"

COLORS="$CW/theme/colors.js"
if ! grep -q "belevels-brand" "$COLORS"; then
  grep -q "brand: '#2781F6'," "$COLORS" || falla "theme/colors.js ya no tiene brand: '#2781F6' (revisar el color de marca)"
  sed -i "s|brand: '#2781F6',|brand: 'rgb(var(--belevels-brand) / <alpha-value>)',|" "$COLORS"
fi
echo "ok  color de marca"

# Valores por defecto de la marca (instalaciones nuevas; las existentes las actualiza lib/tasks/belevels.rake).
ICFG="$CW/config/installation_config.yml"
[[ -f "$ICFG" ]] || falla "no existe $ICFG"
python3 - "$ICFG" <<'PY'
import re, sys
p = sys.argv[1]; s = open(p).read()
for name, value in {
    'INSTALLATION_NAME': 'CRM be levels Chile',
    'BRAND_NAME': 'be levels',
    'LOGO': '/belevels/logo.png',
    'LOGO_DARK': '/belevels/logo_dark.png',
    'LOGO_THUMBNAIL': '/belevels/logo_thumbnail.png',
}.items():
    s, n = re.subn(r"(- name: %s\n  value: )'[^']*'" % name, r"\1'%s'" % value, s)
    if n != 1: sys.exit("installation_config.yml: no se encontró %s" % name)
open(p, 'w').write(s)
PY
echo "ok  marca por defecto en installation_config.yml"

# Color del navegador (barra/tiles) en las plantillas: azul Chatwoot -> negro be levels.
grep -rl "#2781F6" "$CW/app/views" | xargs -r sed -i 's/#2781F6/#121212/g'
echo "ok  color del navegador"

# 4. Parches (opcionales), en orden.
shopt -s nullglob
for p in "$AQUI"/patches/*.patch; do
  git -C "$CW" apply --check "$p" 2>/dev/null || patch -d "$CW" -p1 --dry-run -s < "$p" >/dev/null || falla "el parche $(basename "$p") ya no aplica"
  patch -d "$CW" -p1 -s < "$p"
  echo "ok  parche $(basename "$p")"
done

echo "Listo: código de Chatwoot preparado con los cambios be levels."
