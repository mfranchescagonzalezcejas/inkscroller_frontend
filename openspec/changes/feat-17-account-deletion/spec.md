# Spec — Account Deletion Flow

## Resumen

Agregar un flujo de eliminación de cuenta desde la app, accesible desde una nueva pantalla de configuración. El backend ya expone `DELETE /users/me` (deployado en `api.dev.inkscroller.devdigi.dev`).

---

## Requisitos funcionales

### RF1 — Pantalla de configuración

- Nueva ruta `/settings` accesible desde el área autenticada
- La pantalla muestra el email del usuario autenticado
- Contiene una sección "Account" con el botón "Eliminar cuenta"
- El acceso a settings puede ser desde un ícono de engranaje o avatar en el header de la app

### RF2 — Advertencia y confirmación

- Al tocar "Eliminar cuenta" se muestra un diálogo de advertencia con:
  - Título: "¿Eliminar cuenta?"
  - Descripción: "Esta acción es irreversible. Se borrarán tu perfil, historial de lectura, preferencias y todos los datos asociados a tu cuenta."
  - Un campo de texto donde el usuario debe escribir "DELETE" para confirmar (o un botón de doble confirmación)
  - Botón "Cancelar"
  - Botón "Eliminar mi cuenta" (deshabilitado hasta que se cumpla la confirmación)

### RF3 — Ejecución del borrado

- Llama a `DELETE /users/me` con el token de Firebase
- Muestra estado de carga mientras se procesa
- En caso de éxito (204):
  - Cierra sesión (Firebase signOut)
  - Redirige a la pantalla de login
  - Muestra un snackbar o notificación: "Cuenta eliminada exitosamente"
- En caso de error:
  - Muestra mensaje de error contextual
  - Ofrece opción de reintentar

### RF4 — Recurso web

- URL: https://inkscroller-delete-account.vercel.app
- Se declara en Play Console > Data Safety > Account Deletion
- Contiene formulario con mailto: support@devdigi.dev

---

## Escenarios (Gherkin)

### Escenario 1: Eliminación exitosa
```gherkin
Dado que el usuario está autenticado y navega a /settings
Cuando toca "Eliminar cuenta"
Y confirma escribiendo "DELETE" en el campo de confirmación
Y toca "Eliminar mi cuenta"
Entonces se llama a DELETE /users/me
Y se muestra un indicador de carga
Y al recibir 204 se cierra la sesión
Y se redirige a la pantalla de login
```

### Escenario 2: Error de red
```gherkin
Dado que el usuario está en el flujo de eliminación
Y toca "Eliminar mi cuenta"
Pero la petición falla por error de red
Entonces se muestra un mensaje: "Error de conexión. Intentá de nuevo."
Y el botón de reintentar está disponible
Cuando toca reintentar
Entonces se reintenta la llamada a DELETE /users/me
```

### Escenario 3: Token expirado
```gherkin
Dado que el usuario está en el flujo de eliminación
Y toca "Eliminar mi cuenta"
Pero la API responde 401 (token expirado)
Entonces se fuerza el refresh del token
Y se reintenta la llamada
O si el refresh falla, se redirige a login
```

### Escenario 4: Cancelar eliminación
```gherkin
Dado que el usuario está en el diálogo de confirmación
Cuando toca "Cancelar"
Entonces el diálogo se cierra
Y el usuario permanece en /settings
Y su cuenta no se modifica
```

---

## Tests requeridos

| Test | Tipo | Descripción |
|------|------|-------------|
| Delete account success | Unit/widget | Confirma llamada API, sign-out, redirección |
| Delete account network error | Unit/widget | Muestra error, botón reintentar |
| Delete account 401 | Unit/widget | Refresh token + retry, o redirect a login |
| Delete account cancel | Widget | Diálogo se cierra sin acción |
| Delete account confirmation required | Widget | Botón deshabilitado hasta escribir DELETE |
| Settings page renders | Widget | La página se construye con email del usuario |
| Settings navigation | Integration | Ruta /settings es accesible desde área autenticada |

---

## Criterios de aceptación

1. El usuario puede llegar a /settings desde la navegación principal
2. El flujo de borrado tiene al menos una confirmación explícita
3. La llamada a DELETE /users/me se ejecuta con el token actual
4. En éxito: sign-out + redirect a login
5. En error: mensaje visible + opción de reintentar
6. La URL https://inkscroller-delete-account.vercel.app responde 200 y contiene el mail de contacto
