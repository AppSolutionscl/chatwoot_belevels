#!/usr/bin/env bash
# be levels · aplica nuestros cambios sobre el código oficial de Chatwoot.
# Uso: bash scripts/preparar.sh <carpeta-con-el-código-de-chatwoot>
# Falla (y detiene la construcción) si algo del código oficial cambió y un cambio ya no aplica.
set -euo pipefail

AQUI="$(cd "$(dirname "$0")/.." && pwd)"
CW="$(cd "${1:?Indica la carpeta con el código de Chatwoot}" && pwd)"

falla() { echo "ERROR: $*" >&2; exit 1; }

# 1. Edición Community: sin la carpeta enterprise (licencia aparte), igual que la imagen oficial -ce.
rm -rf "$CW/enterprise" "$CW/spec/enterprise"
echo "ok  edición community (sin enterprise/)"

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

# 4. Parches (opcionales), en orden.
shopt -s nullglob
for p in "$AQUI"/patches/*.patch; do
  git -C "$CW" apply --check "$p" 2>/dev/null || patch -d "$CW" -p1 --dry-run -s < "$p" >/dev/null || falla "el parche $(basename "$p") ya no aplica"
  patch -d "$CW" -p1 -s < "$p"
  echo "ok  parche $(basename "$p")"
done

echo "Listo: código de Chatwoot preparado con los cambios be levels."
