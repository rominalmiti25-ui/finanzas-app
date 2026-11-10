#!/usr/bin/env bash
# Prueba de punta a punta de los requisitos del PDF. Requiere API en marcha + `npm run seed`.
# Uso: bash tests/e2e.sh [URL_BASE]   (por defecto http://localhost:3000)
B=${1:-http://localhost:3000}
j() { curl -s -w "\n[HTTP %{http_code}]" -H 'Content-Type: application/json' "$@"; }
tok() { curl -s -H 'Content-Type: application/json' -d "{\"email\":\"$1\",\"password\":\"$2\"}" $B/api/auth/login | python3 -c "import sys,json;print(json.load(sys.stdin).get('token',''))"; }
echo "=== 1. Login correcto (admin y cliente) e incorrecto"
AT=$(tok admin@demo.com Admin1234); CT=$(tok cliente@demo.com Cliente1234)
echo "token admin: ${AT:0:20}...  token cliente: ${CT:0:20}..."
j -d '{"email":"cliente@demo.com","password":"Incorrecta1"}' $B/api/auth/login
echo; echo "=== 2. Cliente intenta operación de admin (debe dar 403)"
j -H "Authorization: Bearer $CT" $B/api/admin/stats
j -X PATCH -H "Authorization: Bearer $CT" $B/api/users/3/promote
echo; echo "=== 3. Registro intentando asignarse rol admin (debe dar 400)"
j -d '{"name":"Hacker","email":"h@x.com","password":"Clave1234","age":25,"monthly_income":1000,"monthly_budget":800,"role":"admin"}' $B/api/auth/register
echo; echo "=== 4. Dato inválido directo a la API (monto negativo, categoría inventada)"
j -H "Authorization: Bearer $CT" -d '{"type":"gasto","amount":-50,"category":"Inventada","tx_date":"2026-01-01"}' $B/api/transactions
echo; echo "=== 5. Registro inválido insertado directo en la BD no aparece en /users"
mysql -uroot finanzas_db -e "INSERT INTO users (name,email,password_hash,role,age,monthly_income,monthly_budget) VALUES ('Edad Negativa','neg@x.com','$(printf 'x%.0s' {1..40})','cliente',-5,0,0);"
j -H "Authorization: Bearer $AT" $B/api/users | python3 -c "
import sys,json;raw=sys.stdin.read().split('\n[HTTP')[0];d=json.loads(raw)
print('usuarios devueltos:',len(d['users']),'| ¿aparece neg@x.com?',any(u['email']=='neg@x.com' for u in d['users']),'| ¿hay password_hash?','password_hash' in raw)"
echo; echo "=== 6. Acceso a registro de otro cliente (cambiar id)"
OTHER=$(mysql -uroot finanzas_db -N -e "SELECT id FROM transactions WHERE user_id <> (SELECT id FROM users WHERE email='cliente@demo.com') LIMIT 1")
j -H "Authorization: Bearer $CT" $B/api/transactions/$OTHER
j -X DELETE -H "Authorization: Bearer $CT" $B/api/transactions/$OTHER
echo; echo "=== 7. Promover cliente a admin y verificar acceso tras nuevo login"
NT=$(tok usuario02@demo.com Demo12345)
j -H "Authorization: Bearer $NT" $B/api/admin/stats | tail -1
UID2=$(mysql -uroot finanzas_db -N -e "SELECT id FROM users WHERE email='usuario02@demo.com'")
j -X PATCH -H "Authorization: Bearer $AT" $B/api/users/$UID2/promote
NT=$(tok usuario02@demo.com Demo12345)
j -H "Authorization: Bearer $NT" $B/api/admin/stats | tail -1
echo; echo "=== 8. Panel admin (resumen)"
curl -s -H "Authorization: Bearer $AT" $B/api/admin/stats | python3 -c "
import sys,json;d=json.load(sys.stdin);print(d['summary']);print('excluidos:',d['excludedInvalid']);print(d['budgetRanges']);print(d['categoryDistribution'][0])"
echo; echo "=== 9. ML: categorizar y predecir"
j -H "Authorization: Bearer $CT" -d '{"description":"gasolina para el coche"}' $B/api/ml/categorize
curl -s -H "Authorization: Bearer $CT" $B/api/ml/prediction | python3 -m json.tool | head -40
echo; echo "=== 10. Crear transacción válida"
j -H "Authorization: Bearer $CT" -d "{\"type\":\"gasto\",\"amount\":199.5,\"category\":\"Alimentación\",\"description\":\"Tacos\",\"tx_date\":\"$(date +%F)\"}" $B/api/transactions
