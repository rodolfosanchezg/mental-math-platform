# T08 — QA independiente

TASK: T08
FROM: VALERIO
TO: AURELIO
STATUS: PASS — READY TO CLOSE
CORRECTION ITERATION: 0

## Validación real completada

- TC-001 / AC-A01: login correcto contra Supabase Auth HTTP 200.
- Perfil propio HTTP 200 validado por módulo productivo usando JWT/RLS.
- Chrome con la aplicación real: pantalla autenticada accesible tras login.
- Sesión conservada en memoria; recargar requiere login según documentación.
- TC-003 / AC-A04: contraseña incorrecta real produce error genérico.
- Email técnico nunca visible; contraseña eliminada del campo.
- TC-004 / AC-A05: logout remoto HTTP 204 y bloqueo inmediato de pantalla
  autenticada, también tras evento pageshow.
- Sesiones remotas de QA cerradas. Sin valores sensibles impresos ni uso de
  credenciales administrativas/PG. QA no editó archivos del repositorio.

## Evidencia anterior conservada

- Contrato automatizado, Chrome con respuestas controladas y servicio público
  real: PASS; no repetidos innecesariamente en esta reanudación.
- AC-A02 / AC-A03: regex antes de red, email técnico interno, errores genéricos,
  sin signup ni recuperación. Acceso anónimo denegado, signup/Anonymous OFF.
- .env ignorados y no versionados; sin claves privadas en frontend/herramientas.
- git diff --check PASS; fuentes aprobadas sin modificaciones.

## Historial

La primera revisión quedó BLOCKED por ausencia de cuenta de prueba para TC-001
/ TC-004. Rodolfo creó la cuenta administrativamente y proporcionó variables
AUTH_TEST en archivo local protegido. Se completó únicamente la validación
pendiente, sin repetir implementación ni consumir una corrección automática.
Resultado final PASS; ningún defecto observado o pendiente.

## Límites

No se repitió aislamiento HTTP entre dos usuarios; se conserva evidencia T04
con roles/claims SQL. Home completo y juego corresponden a tareas posteriores.
Logout elimina acceso local y cierra sesión remota; la caducidad de un access
JWT emitido mantiene el comportamiento propio de Supabase.

## Acción

Cerrar T08 con documentación, commit y push verificado; entrar CHECKPOINT_WAIT
y entregar Checkpoint 2. No iniciar T09 sin aprobación explícita de Rodolfo.
