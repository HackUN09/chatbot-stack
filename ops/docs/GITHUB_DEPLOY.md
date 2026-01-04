# 🚀 GUÍA DE DESPLIEGUE A GITHUB

Sigue estos pasos para subir tu proyecto de forma profesional y segura. Gracias al `.gitignore` que configuramos, tus secretos (`.env`) y bases de datos están protegidos.

---

## 1. Inicializar el Repositorio Local
Abre una terminal en la raíz de tu proyecto (`chatbot-stack`) y ejecuta:

```bash
# Inicializar Git
git init

# Añadir todos los archivos (Git filtrará automáticamente lo que está en .gitignore)
git add .

# Crear el primer commit
git commit -m "feat: Initial release - Isekai Hardened Stack v4.1 God Mode"
```

## 2. Crear el Repositorio en GitHub
1. Ve a tu cuenta de [GitHub](https://github.com/new).
2. Ponle un nombre (ej: `chatbot-stack`).
3. **IMPORTANTE**: Selecciona **Private** (Privado) si no quieres que el código sea público aún.
4. **NO** selecciones "Initialize this repository with a README" (ya lo tenemos creado aquí).
5. Haz clic en **Create repository**.

## 3. Vincular y Subir
GitHub te dará un link que termina en `.git`. Ejecuta estos comandos reemplazando `TU_URL_AQUI` por ese link:

```bash
# Cambiar a la rama principal
git branch -M main

# Vincular con GitHub
git remote add origin TU_URL_AQUI

# Subir el código
git push -u origin main
```

---

## 🛡️ Consejos de Seguridad Pro
- **Nunca borres el .gitignore**: Es tu escudo protector.
- **Doble Verificación**: Antes del `git push`, puedes ejecutar `git status` para confirmar que no se están subiendo carpetas pesadas como `persistence/` o el archivo `.env`.
- **Snapshots**: Antes de cada gran cambio, usa la **Opción 6** del Sistema Maestro para tener un respaldo local rápido en `.zip`.

---
*¡Felicidades! Tu infraestructura ahora vive en la nube de forma profesional.*
