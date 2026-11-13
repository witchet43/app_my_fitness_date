# B11 — Integración local y bloqueo del DEV alojado (sin Cloud Build)

Fecha: 13 de noviembre de 2026. Proyecto: My Fitness Date / FITTED.

## Hechos verificados en Supabase

- El único proyecto My Fitness Date conectado es **`my_fitness_date_prod`** (`jtrdvnwbxpfdnbzasvcj`), PostgreSQL 17, no un DEV separado.
- El otro proyecto activo de la organización es `mi_universidad_virtual_prod`.
- Organización `witchet43@gmail.com's Org`, plan **Free**, dos proyectos activos.
- `get_cost(project)` cotizó **$0 USD/mes**, pero `create_project(my_fitness_date_dev)` rechazó la creación: el dueño alcanzó el máximo de **2 proyectos gratuitos**. No se creó un proyecto nuevo ni se generó un cobro.
- `get_cost(branch)` cotizó **$0.01344 USD/hora**: no se creó una rama de pago sin aceptar ese importe por separado.
- Las 23 migraciones de la base alojada son B1–B5 y anteriores, sin B11. Las nuevas tablas `member_rhythm_b11` y `fitdating_matches_b11` **NO están alojadas**; el gate de publicación permanece cerrado.
- No se pausó, borró, restauró ni modificó ninguna base de producción.

## Resultado probado en infraestructura local efímera

- [GitHub QA técnica](https://github.com/witchet43/app_my_fitness_date/actions/runs/43373200546): Node 62, PostgreSQL 24 migraciones + 21 tests SQL, Gym Shield 8, Flutter analyzer y 75 widgets.
- [Auth de correo](https://github.com/witchet43/app_my_fitness_date/actions/runs/43373628629): confirmación vía Mailpit, restauración de contraseña y OTP de un uso.
- [Dos JWT y privacidad entre miembros](https://github.com/witchet43/app_my_fitness_date/actions/runs/43375861804): anti-BOLA y no activación de discovery al verificar edad.
- [Guardado y restauración real de perfil B11](https://github.com/witchet43/app_my_fitness_date/actions/runs/43380583296): consentimiento separado, escritura/read por propietario, sesión nueva, bloqueo de lectura y escritura cruzada, revocación que elimina perfil.
- El recorrido de API HTTP local se valida con `scripts/local-edge-profile-b11.mts`. **No afirmar que está verde antes de contar con el run final aprobado.**

## Cómo iniciar la aplicación real sin un build de distribución

Desde la carpeta raíz de la rama `feature/b11-one-final-real-product-20261112`, en un equipo con Docker, Node, Flutter y Chrome:

```bash
bash scripts/run_b11_local_preview.sh
```

El comando inicia un **Supabase local desechable** (Auth/PostgREST/PostgreSQL/Mailpit), sirve la función `member-api-v26` en modo exclusivamente loopback y ejecuta Flutter en `http://127.0.0.1:5173/`. Mailpit local se consulta en `http://127.0.0.1:54324/`.

El script también crea una red Docker con los puertos vinculados exclusivamente a 127.0.0.1, tal como recomienda Supabase para no exponer Auth/Postgres a redes públicas. Si Docker no admite esa red, el script falla en lugar de abrir el stack en la LAN.

Los valores locales de compilación y la función Edge únicamente permiten HTTP cuando `MFD_LOCAL_QA=true`, `Uri.base.host=127.0.0.1` y el API también es `127.0.0.1:54321`. Los documentos legales se leen desde las URLs públicas HTTPS. El cliente no recibe credenciales privadas. El servicio alojado conserva HTTPS obligatorio, URL PROD fijada y los flags de lanzamiento originales.

**Aviso:** se destruyen los datos de QA local al cerrar el script (`stop --no-backup`). No usar cuentas reales. No constituye una vista previa remota accesible desde otra computadora.

## Barreras para una preview accesible desde cualquier lugar

1. Crear un proyecto Supabase DEV independiente requiere liberar una plaza del plan gratuito sin interrumpir los dos proyectos de producción **o** aceptar expresamente el costo de infraestructura adicional. No pausar ninguno de los existentes por automatización.
2. Después de contar con un DEV real, cambiar `infra/supabase-targets.json`, ejecutar `scripts/check_supabase_target.py development <REF_DEV>`, aplicar la migración B11 con historial y verificar RLS, migraciones y seguridad.
3. Desplegar `member-api-b11-preview` **solo en DEV**, configurar el OAuth/localización y los activos legales, ejecutar pruebas E2E contra el entorno y entonces generar una única compilación web de QA (primero GitHub Actions, no Cloud Build).
4. La producción romántica sigue bloqueada por verificación de edad independiente, moderación atendida, privacidad/legalidad, fotografías revisadas y pruebas de dispositivos físicos. Nunca declarar falsamente completos los requisitos.

No se gastan minutos de Google Cloud Build, no se cambia `main`, no se habilita FitDating y el PR #77 permanece en Draft.
