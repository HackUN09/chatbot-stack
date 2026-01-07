# 🚀 GUÍA DE DESPLIEGUE A GITHUB (HackUN09 Edition)

Esta guía asegura que tu Sentinel OS v9.0 se suba a GitHub con la identidad correcta y de forma blindada.

---

## 1. Configurar Identidad (HackUN09)
Asegúrate de que tus commits lleven tu firma oficial:
```bash
git config --global user.name "HackUN09"
git config --global user.email "wamr1991.1@gmail.com"
```

## 2. Preparar el Lanzamiento v9.0
Antes de subir, realizamos el "sellado" de la versión:
```bash
# Añadir todos los cambios (limpios por .gitignore)
git add .

# Commit Maestro
git commit -m "Genesis v9.0: Sentinel OS - Super-Link Edition (Automated)"

# Crear etiqueta de versión oficial
git tag -a v9.0.0 -m "Genesis Edition v9.0"
```

## 3. Subir a GitHub
Vincular y empujar (incluyendo las etiquetas de versión):
```bash
# Cambiar a rama principal
git branch -M main

# Vincular (Reemplaza con tu URL real)
git remote add origin https://github.com/HackUN09/chatbot-stack.git

# Subir código y etiquetas
git push -u origin main --tags
```

---

## 🛡️ Protocolo de Seguridad
- **Permisos**: Mantén el repositorio como **Private** en GitHub.
- **Blindaje**: El archivo `.gitignore` ya está configurado para excluir `persistence/`, `.env` y archivos temporales. **Nunca desactives Git**.
- **Snapshots**: Antes de un comando destructivo, usa la **Opción 6** del Maestro para un respaldo local.

---
*¡Código subido, versión sellada. v9.0 operacional en la nube!*
