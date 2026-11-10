# 💰 Finanzas Personales — App móvil con Machine Learning

App de **Salud Financiera y Control de Gastos**: los clientes registran ingresos y gastos, y el backend usa
**Machine Learning** para (1) **predecir el gasto del mes y la capacidad de ahorro**, (2) **detectar gasto desmedido** y
(3) **sugerir la categoría** de un gasto a partir de su descripción. Los administradores consultan estadísticas
(tablas y gráficas) y pueden promover clientes a administradores.

| Capa | Tecnología | Arquitectura |
|---|---|---|
| Frontend móvil | Flutter (Provider) | **MVVM**: `models/` (Modelo) · `views/` (Vista) · `viewmodels/` (VistaModelo, con validaciones de entrada) |
| Backend | Node.js + Express | **MC**: `models/` (esquemas Zod + acceso a datos) · `controllers/` (+ `routes/`, `middleware/`) |
| Base de datos | MySQL | tablas `users`, `transactions`, `ml_models` |
| ML | JavaScript puro (sin librerías externas) | Regresión Ridge + Naive Bayes, ejecutados **en el backend** |

```
finanzas_app/
├── backend/        API Node.js (src/models, src/controllers, src/routes, src/ml, src/services, src/scripts)
│   ├── sql/schema.sql
│   └── tests/      pruebas automáticas (ml.test.js) y script e2e.sh con las pruebas del PDF
├── frontend/       App Flutter (lib/models, lib/views, lib/viewmodels, lib/services)
└── .github/workflows/build-apk.yml   ← compila el APK automáticamente
```

---
## 1. Levantar el backend

Requisitos: Node 18+ y MySQL 5.7/8 (o MariaDB).

```bash
cd backend
cp .env.example .env        # edita credenciales de MySQL y JWT_SECRET
npm install
npm run init-db             # crea la base y las tablas
npm run init-admin          # crea el PRIMER administrador (ver §4) 
npm run seed -- --reset     # (opcional pero recomendado) datos de prueba + entrena el ML
npm start                   # http://localhost:3000   (prueba: /health)
```
> `seed` ya crea el admin de prueba; si lo usas no necesitas `init-admin` (puedes demostrar ambos).

### Cuentas de prueba (creadas por `npm run seed`)
| Rol | Correo | Contraseña |
|---|---|---|
| Administrador | `admin@demo.com` | `Admin1234` |
| Cliente | `cliente@demo.com` | `Cliente1234` |
| Clientes extra (40) | `usuario02@demo.com` … `usuario41@demo.com` | `Demo12345` |

Los datos de prueba (≈7 000 transacciones, 6 meses + mes en curso) son **sintéticos y reproducibles** (semilla fija en `src/scripts/demoData.js`).

### Publicar el backend (para que el APK funcione en cualquier teléfono)
Opciones gratuitas: **Render** (Web Service, root `backend`, build `npm install`, start `npm start`) + una BD MySQL en
**Aiven**, **Railway** o **FreeSQLDatabase**. Define las variables de `.env` en el panel (usa `DB_SSL=true` si el proveedor lo exige) y ejecuta una vez
`npm run init-db && npm run seed` apuntando a esa BD (desde tu PC con el `.env` de producción).
Alternativa para la demo: correr el backend en tu PC y exponerlo con `ngrok http 3000` o `cloudflared tunnel --url http://localhost:3000`.

---
## 2. Obtener el APK

**Opción A — GitHub Actions (recomendada, no necesitas instalar Flutter):**
1. Sube la carpeta completa a un repo de GitHub (el PDF pide GitHub de todas formas).
2. `Settings → Secrets and variables → Actions → Variables → New repository variable`: `API_URL` = URL pública de tu backend (ej. `https://mi-api.onrender.com`, sin `/` final).
3. Pestaña **Actions → Build APK → Run workflow**. Al terminar, descarga el artefacto **finanzas-app-apk** → `app-release.apk`. Instálalo en el teléfono.

**Opción B — local** (Flutter 3.22+ instalado):
```bash
cd frontend
bash tool/prepare_android.sh      # genera android/ con permiso de internet
flutter pub get
flutter build apk --release --dart-define=API_URL=https://TU_BACKEND
# APK: build/app/outputs/flutter-apk/app-release.apk
```
Para probar en el **emulador** sin `--dart-define`: el valor por defecto es `http://10.0.2.2:3000` (tu `localhost`).
Para un teléfono físico en la misma Wi‑Fi usa `--dart-define=API_URL=http://IP_DE_TU_PC:3000`.

---
## 3. Machine Learning (Opción A del PDF)

Todo se ejecuta **en el backend** con los datos que los propios clientes capturan en MySQL (solo registros válidos); la app solo muestra el resultado.

**a) Predicción de gasto (regresión Ridge)** — `GET /api/ml/prediction`
- *Objetivo:* gasto total del mes en curso a partir de los meses completos anteriores.
- *Variables:* gasto del mes anterior · nº de transacciones del mes anterior (frecuencia) · ingresos del mes anterior · promedio de gasto de 3 meses · ingreso mensual del perfil.
- *Salidas:* gasto esperado, ahorro estimado (ingreso esperado − gasto esperado), desglose por categoría, proyección al cierre del mes y **alertas de gasto desmedido** (supera lo esperado, supera el presupuesto o es atípico: > media + 1.5σ).
- *Evaluación:* validación **temporal** (el último mes de cada cliente se reserva para prueba). Se reportan MAE, RMSE, R² y la mejora frente al baseline "repetir el mes anterior". Con los datos de prueba: R² ≈ 0.90, MAE ≈ $1,770 vs. $2,120 del baseline (≈16 % mejor).

**b) Categorización automática (NLP, Naive Bayes multinomial)** — `POST /api/ml/categorize`
- Variable: texto de la descripción (tokenizado, sin acentos ni stopwords). Evaluación hold-out 80/20 (exactitud).
- En la app: botón **“Sugerir categoría con IA”** al registrar un gasto.
- ⚠️ Con los datos sintéticos la exactitud sale ≈100 % porque las descripciones siguen plantillas; con datos reales será menor. Dilo así en tu exposición.

**Entrenamiento:** automático al arrancar el servidor si no hay modelo, con `npm run seed`, o desde la app (admin → *Reentrenar modelos*, `POST /api/admin/ml/train`). Los modelos y métricas se guardan en la tabla `ml_models`.
El panel del admin muestra la **efectividad** (MAE, R², exactitud).

> Nota: la predicción es para el **mes en curso** (el último mes completo es la base). Un cliente necesita ≥ 1 mes completo de historial; si no, la app lo indica.

---
## 4. Cuentas, roles y seguridad (requisitos del PDF)

- **Primer administrador:** `npm run init-admin` lee `ADMIN_NAME/ADMIN_EMAIL/ADMIN_PASSWORD` del `.env`, valida con las mismas reglas y guarda la contraseña con **Argon2id** (igual que el resto de usuarios).
- **Contraseñas:** solo se guarda el hash Argon2id; las respuestas **nunca** incluyen hash ni secretos.
- **Rol desde el servidor:** el JWT solo lleva el id; en **cada** petición el middleware recarga al usuario de MySQL y toma su rol de ahí. Registro con campo `role` → `400` (esquema `.strict()`).
- **Promoción:** `PATCH /api/users/:id/promote` (solo admin). Persiste en BD; con el nuevo login (o incluso sin él) la cuenta ya ejerce permisos.
- **Validación en el frontend:** en los ViewModels (`validateEmail`, `validateAmount`, …). Si hay errores, el `Form` marca qué corregir y **no envía**.
- **Validación en el backend:** esquemas Zod (`src/models/schemas.js`) para body, params y query; funciona igual desde Postman/curl.
- **Validación de lo leído de BD:** cada fila pasa por el esquema antes de responder; las inválidas se **excluyen** de listados, estadísticas y ML (consulta individual → error controlado `422`).
- **Propiedad de registros:** cambiar el `:id` de una transacción de otro cliente → `403`. Ni los admins ven transacciones ajenas (solo agregados).
- Extras: Helmet, límite de tamaño de body, rate-limit en login/registro, mismo mensaje para correo inexistente/contraseña incorrecta.

### Endpoints
| Método | Ruta | Acceso |
|---|---|---|
| POST | `/api/auth/register`, `/api/auth/login` | público |
| GET | `/api/auth/me` | autenticado |
| GET/POST | `/api/transactions` | cliente (propias) |
| GET/PUT/DELETE | `/api/transactions/:id` | dueño |
| GET | `/api/ml/prediction` · POST `/api/ml/categorize` | autenticado |
| GET | `/api/users` (también `/users`) | admin |
| PATCH | `/api/users/:id/promote` | admin |
| GET | `/api/admin/stats` | admin |
| POST | `/api/admin/ml/train` | admin |

---
## 5. Checklist de las pruebas del PDF (§9) y cómo demostrarlas

Con el backend y `seed` listos, `bash backend/tests/e2e.sh [URL]` ejecuta casi todas por curl. Pruebas unitarias: `cd backend && npm test`.

| Prueba | Cómo demostrarla |
|---|---|
| Login con ambas cuentas y contraseña incorrecta | App: entrar con `admin@demo.com` y `cliente@demo.com`; contraseña errónea → “Credenciales incorrectas”. |
| Promover cliente a admin | App (admin) → pestaña **Usuarios** → *Hacer admin* → cerrar sesión e iniciar con esa cuenta: ve el panel admin. |
| Dato inválido en formulario | App: monto `-5`, vacío o categoría sin elegir → mensaje de error y no se envía. |
| Dato inválido directo a la API | `curl -X POST $URL/api/transactions -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -d '{"type":"gasto","amount":-50,"category":"X","tx_date":"2026-01-01"}'` → `400`. |
| Registro inválido directo en BD | `INSERT INTO users (name,email,password_hash,role,age,monthly_income,monthly_budget) VALUES ('Edad Negativa','neg@x.com','xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx','cliente',-5,0,0);` → no aparece en `GET /users` ni en estadísticas. |
| Panel admin | App (admin) → Estadísticas: tablas + gráficas de barras y líneas, calculadas solo con datos válidos. |
| Flujo ML | App (cliente) → **Predicción**: resultado del backend; y “Sugerir categoría con IA” al agregar un gasto. |
| Transacciones desde la app | Agregar / listar / eliminar movimientos con normalidad. |



