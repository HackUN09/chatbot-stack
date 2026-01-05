import os

env_path = '.env'
updates = {
    'AUTHENTICATION_TYPE': 'apikey',
    'CONFIG_SESSION_PHONE_VERSION': '2.3000.1015901307',
    'CORS_ORIGIN': '*',
    'CORS_METHODS': 'GET,POST,PUT,DELETE,PATCH,OPTIONS',
    'VITE_EVOLUTION_API_URL': '', # Will fill later
    'VITE_EVOLUTION_API_KEY': '', # Will fill later
}

if os.path.exists(env_path):
    with open(env_path, 'r', encoding='utf-8') as f:
        lines = f.readlines()
    
    env_vars = {}
    for line in lines:
        line = line.strip()
        if line and '=' in line and not line.startswith('#'):
            k, v = line.split('=', 1)
            env_vars[k.strip()] = v.strip()
    
    # Update with new values
    env_vars.update(updates)
    
    # Ensure VITE vars match the ones in env
    domain = env_vars.get('DOMAIN', 'localhost')
    env_vars['VITE_EVOLUTION_API_URL'] = f'https://api.{domain}'
    env_vars['VITE_EVOLUTION_API_KEY'] = env_vars.get('EVOLUTION_API_KEY', '')

    with open(env_path, 'w', encoding='utf-8') as f:
        for k, v in sorted(env_vars.items()):
            f.write(f'{k}={v}\n')
    print("🚀 .env optimizado para Sentinel v5.1")
else:
    print("❌ .env no encontrado")
