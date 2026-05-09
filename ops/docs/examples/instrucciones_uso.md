# 🤖 Guía Práctica: Cómo usar tu Bot de WhatsApp + Gmail

Este flujo no es un simple autorespondedor; es tu Secretario Ejecutivo de bolsillo. Aquí te explico exactamente cómo lo implementaría y usaría yo en el día a día.

---

## ⚙️ PASO 1: Conexión Inicial (Una sola vez)

Antes de que el bot pueda hacer magia, necesita las llaves de tus casas:

1. **Importa el Flujo:** En n8n, dale a `Import from File` y sube el archivo `flujo_whatsapp_gmail.json` que acabamos de guardar.
2. **Conecta WhatsApp:** 
   - Abre el nodo **Evolution Webhook** arriba a la izquierda. Copia la *Test URL* (o *Production URL*).
   - Ve a tu panel de Evolution API y pega esa URL en los Webhooks de tu instancia para que Evolution sepa a dónde enviar los mensajes.
   - Abre el nodo **Enviar texto1** y asegúrate de elegir tu credencial de `Evolution account`.
3. **Conecta a Dios (Gemini):**
   - Abre el nodo **Google Gemini Chat Model** y pon tu API Key gratuita de Google AI Studio.
4. **Dale la llave de tu Correo:**
   - Abre cualquiera de los dos nodos azules (**Get many messages en Gmail** o **Send a message en Gmail**).
   - Dale a "Create New Credential". Te pedirá iniciar sesión con tu cuenta de Google y darle permisos (OAuth2) para leer y enviar correos. Solo tú tendrás acceso a esto.

Una vez todo esté en verde, ¡activa el flujo arriba a la derecha!

---

## 📲 PASO 2: Cómo usarlo en la Práctica (Mi rutina diaria)

La magia de este sistema radica en el "System Prompt" que le configuramos. El bot fue instruido para actuar proactivamente. Así lo usaría yo:

### Escenario A: El Resumen Matutino (Acción Automática)
Son las 8:00 AM. Apenas agarro el celular, abro el chat de WhatsApp de mi propio bot y le escribo simplemente:
> **Tú:** Hola, buenos días.

Gemini tiene una regla que dice: *"Cuando el usuario salude, revisa el correo y dale un resumen"*. El bot irá a tu Gmail, leerá en silencio, y en menos de 5 segundos te responderá esto a tu WhatsApp:

> **Bot (WhatsApp):**
> 👋 ¡Hola! Aquí tu resumen de correos
> 
> 🔴 **Urgentes**
> - *Amazon Web Services* → _[Aviso de Suspensión de Cuenta]_
> 
> 📬 **Últimos 5 correos**
> 1. *Juan Pérez* — _Presupuesto 2026_
>   💬 El cliente solicita descuento del 10% para cerrar.
> 2. *Newsletter* — _Noticias de Tech_
>   💬 Resumen de la semana en IA.
> (etc...)
> 
> 📌 **Temas detectados**
> - 💰 _Pagos/Facturas:_ 1
> - ⚠️ _Alertas:_ 1
> 
> _¿Quieres que abra alguno o tomar alguna acción?_ 👇

### Escenario B: Profundizando sin salir de WhatsApp
Vi que Juan me pidió un descuento en el presupuesto, pero me da pereza abrir la app de Gmail para leer todo el hilo. Como el bot tiene **Memoria Temporal (Simple Memory)**, sabe de qué estamos hablando. Le respondo:

> **Tú:** ¿Qué más dice el correo de Juan Pérez? ¿Hasta cuándo tengo para responderle?

Gemini irá de nuevo a Gmail, buscará ese correo específico de Juan, lo leerá completo, y te lo resumirá en WhatsApp.

### Escenario C: Acción y Delegación
Decido que sí le daré el descuento a Juan. Sigo en el semáforo o caminando, así que en vez de escribir un correo formal, le lanzo un mensaje rápido (o incluso una nota de voz si tuviésemos el nodo de Whisper) a mi bot en WhatsApp:

> **Tú:** Dale. Envía un correo a Juan Pérez (juan@empresa.com) dile que aceptamos el descuento del 10% y que le enviaré el contrato ajustado esta tarde. Redáctalo formal pero amable.

Gemini obedecerá. Usará la herramienta `Send a message in Gmail`. Escribirá el asunto perfecto, redactará un cuerpo de correo impecable de 3 párrafos basándose en tu cruda instrucción, te lo pre-aprobará (si se lo pides) o lo enviará directamente, y te avisará por WhatsApp:

> **Bot (WhatsApp):**
> ✅ ¡Listo! Correo enviado a Juan Pérez confirmando el descuento del 10%. ¿Hay algo más en lo que pueda ayudarte?

---

### 🛡️ Sobre la Regla del Filtro ("No es del bot1")
En el flujo hay un nodo llamado `No es del bot1`. Esto es **vital**. Asegura que el bot solo reaccione a los mensajes que TÚ le mandes. Si él te responde "¡Listo! Correo enviado", Evolution API registrará ese mensaje y se lo devolverá a n8n. Gracias a ese filtro, n8n dice: *"Ah, este mensaje lo mandé yo mismo, lo ignoro"*, evitando que el bot se responda a sí mismo y entre en un bucle esquizofrénico gastando todo tu saldo de Gemini.
