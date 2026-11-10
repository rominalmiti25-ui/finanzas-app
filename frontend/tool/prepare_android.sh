#!/usr/bin/env bash
# Genera la carpeta android/ (plantilla oficial de Flutter) y le agrega lo necesario para consumir la API:
#   - permiso INTERNET (en release no viene por defecto)
#   - tráfico HTTP permitido (por si el backend de demostración no tiene HTTPS)
# Uso (dentro de /frontend):  bash tool/prepare_android.sh
set -euo pipefail
rm -rf android
TMP=$(mktemp -d)
flutter create --platforms=android --project-name finanzas_app --org com.proyecto.finanzas "$TMP/scaffold" >/dev/null
cp -r "$TMP/scaffold/android" ./android
MANIFEST=android/app/src/main/AndroidManifest.xml
sed -i 's|<application|<uses-permission android:name="android.permission.INTERNET"/>\n    <application\n        android:usesCleartextTraffic="true"|' "$MANIFEST"
sed -i 's|android:label="finanzas_app"|android:label="Finanzas"|' "$MANIFEST"
echo "android/ listo. Manifest:"; head -12 "$MANIFEST"
