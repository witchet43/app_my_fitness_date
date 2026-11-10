# Iteración 16 — Adultos revisados y Gym Shield más privado

## Seguridad añadida
- **No basta con declarar una fecha de nacimiento:** el backend de Dating exige que una cuenta tenga una decisión aprobada por un operador autorizado y aún vigente.
- El registro `app_private.adult_eligibility` guarda identificador de cuenta, fecha de aprobación, expiración, revocación y una referencia opaca al expediente externo; **no guarda fotografías ni documentos de identidad**.
- La API `public.operator_set_adult_eligibility` solo puede ejecutarla `service_role`. Usuarios normales y moderadores no pueden autoaprobarse.
- El operador **debe verificar por medios independientes la mayoría de edad fuera de la app**. Esta iteración implementa el control y la interfaz administrativa, **no** una integración con proveedor de identidad/edad ni verifica realmente a ninguna persona.
- La aprobación expira en como máximo 180 días. Puede revocarse, desactivando Dating de inmediato. Las verificaciones expiradas tampoco pueden descubrir ni aparecer como candidato.
- Gym Shield mantiene consentimiento recíproco, bloques y margen de 30 minutos, sin revelar gimnasio/horarios/razones de exclusión.
- Se restringe el descubrimiento a máximo **10 resultados por llamada y 10 consultas por hora**, para dificultar la inferencia por sondeo repetido. No es protección absoluta contra cuentas múltiples o correlación temporal.
- La aplicación presenta el estado de elegibilidad y bloquea activación/recomendaciones hasta revisión autorizada. La cuenta social sigue operando.

## Modelo operativo
1. El usuario es adulto según el proceso externo de verificación, diseñado antes de beta.
2. Un operador autorizado comprueba evidencia de tercero, documenta el resultado con referencia opaca fuera de la aplicación.
3. Desde un backend o consola privilegiada, y **nunca el cliente Expo**, ejecuta `public.operator_set_adult_eligibility` con ID de cuenta, referencia, vencimiento y `p_approve=true`.
4. Para revocar, usa la misma API con `p_approve=false`. Nadie en DEV ha recibido revisión por esta implementación.
5. No se debe aprobar a ningún usuario sin evaluación real; las aprobaciones que aparecen en pruebas son **totalmente sintéticas y transaccionales**.

## Pruebas y límites
- SQL: usuario sin revisar no puede activar Dating ni descubrir; cuenta revisada sí, adulto revocado o caducado no; 29/30 minutos, límites de tamaño y permisos de roles.
- Local GoTrue: con dos JWT de prueba reales, rechazo inicial y aprobación explícita con credencial de servicio de la **instancia local**; no hay conexión al hospedado.
- Todas las pruebas de migraciones anteriores conservan su orden. No se insertan registros reales en Supabase hospedado.
- Sigue pendiente integrar una verificación real de edad/identidad, comprobar su cumplimiento legal en México, operar atención/moderación y probar en dispositivo físico.
- **No usar para beta pública**: la aprobación manual es un candado administrativo, no una certificación automatizada de la mayoría de edad.
