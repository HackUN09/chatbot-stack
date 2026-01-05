#!/bin/bash
# --- CHATWOOT AUTO-PROVISIONING ---
echo "⏳ Esperando que Chatwoot esté listo para provisión..."
sleep 20

PASSWORD=$(grep "^CHATWOOT_DB_PASSWORD=" .env | cut -d '=' -f2)

docker exec chatwoot-web bundle exec rails runner "
begin
  u = User.find_or_initialize_by(email: 'admin@isekaichat.com')
  u.password = '$PASSWORD'
  u.password_confirmation = '$PASSWORD'
  u.name = 'Sentinel Admin'
  u.role = 'administrator'
  u.confirmed_at = Time.now
  if u.save!
    puts '✅ USUARIO ADMIN CREADO EXITOSAMENTE'
    a = Account.find_or_create_by(name: 'Isekai Stack')
    au = AccountUser.find_or_create_by(account_id: a.id, user_id: u.id, role: 'administrator')
    puts '✅ CUENTA Y VINCULACIÓN COMPLETADA'
  end
rescue => e
  puts \"❌ ERROR EN PROVISIÓN: #{e.message}\"
end
"
