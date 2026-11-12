# Brand Lab — Laboratorio visual de My Fitness Date

**Estado:** implementación de un **laboratorio de diseño interactivo** para exploración de marca, solicitado por el propietario.  
**Ruta pública prevista:** `https://my-fitness-date.pages.dev/brand-lab/`.  
**Mecanismo de publicación:** bundle de Cloudflare Pages dentro del despliegue Flutter existente; no se crea un servicio nuevo.  
**Issue:** [#50](https://github.com/witchet43/app_my_fitness_date/issues/50).  
**Dirección de producto:** elegante, sobria, para personas adultas —prioritariamente 40+— que valoran relaciones estables y vida activa. Se evitan corazones, neones y gamificación romántica.

## Capacidades entregadas

1. **Nombre y frase:** nombre libre (hasta 35 caracteres), lema editable (95 caracteres) y ocho opciones: My Fitness Date, FITTED, Cadence, Pace, Sync, MFD, Ritmo y Concordia.
2. **Logotipos:** diez conceptos **SVG geométricos originales**: Monograma, Cadencia, Cumbres, Vínculo, Pulso, Brújula, Trayectoria, Horizonte, Geometría y Movimiento. Las ilustraciones son propuestas, no el logotipo oficial. La palabra de marca cambia según el nombre seleccionado.
3. **Paletas:** cinco combinaciones (Bosque, Azul noche, Tierra, Pizarra, Salvia) con control de color principal, acento y fondo; modo claro/oscuro aplicado a las vistas ilustrativas.
4. **Tipografía:** cuatro parejas de fuentes **locales del sistema**. Las opciones comparan Georgia, Palatino, Garamond y sans contemporánea, con fallbacks: no se contacta a proveedores externos ni se incorporan fuentes propietarias.
5. **Vista previa:** tres pantallas hipotéticas (landing, app, onboarding) y modo escritorio/móvil. El único perfil mostrado, «Claudia · 52», está rotulado **PERFIL ILUSTRATIVO**, no procede de usuarios reales.
6. **Tono y componentes:** sereno/editorial/directo; esquinas suaves/geométricas. El texto de la propuesta responde al tono sin inferir características de usuarios.
7. **Guardado:** `localStorage` (clave `mfd.brand-lab.draft.v1`) únicamente en este navegador; restauración, aviso de cambios no guardados, restablecimiento con confirmación.
8. **Exportaciones:** descarga JSON con la configuración elegida y bandera explícita `owner_approval_required: true`; exportación SVG del logotipo y wordmark seleccionados, con escapado XML de entradas. No hay escrituras de backend.

## Importante: NO cambiar la marca publicada

La opción de guardar conserva un **borrador visual local**, sin servidor. El usuario puede observar y exportar propuestas, **pero ni cambiar de nombre ni exportar implica reemplazar** la marca global, términos legales, OAuth, dominio, splash Android/iOS o logotipos de tienda. No existe una ruta pública de «aplicar identidad a producción». Esa tarea futura requiere autorización de administrador, validaciones, historial, rollback, permisos de API y QA de releases.

La página **es accesible por URL directa** y no es un panel de administración privado. Cualquier visitante puede probar controles **solo en su navegador**. Se evita promocionar esta ruta como una funcionalidad de citas o como aplicación de cambios a terceros.

## Seguridad, privacidad y accesibilidad

- Archivos HTML/CSS/JS estáticos, sin cookies propias, sin autenticación ni API calls. `connect-src 'none'`, scripts propios, `noindex`, sin fuentes externas ni analíticas.
- El contenido de texto libre se inserta mediante `textContent`, colores se validan como valores HEX y SVG exportado escapa XML.
- Teclado, etiquetas, estados `aria-pressed`, texto de estado `aria-live`, salto al contenido, vistas en móvil y `prefers-reduced-motion`.
- Colores candidatos y tipografía se diseñan para contraste y legibilidad; **no se reclama auditoría WCAG 2.2 AA completa** sin captura/revisión manual.

## Arquitectura y evidencia

- `apps/flutter_client/cloudflare/brand-lab/index.html`
- `apps/flutter_client/cloudflare/brand-lab/brand-lab.css`
- `apps/flutter_client/cloudflare/brand-lab/brand-lab.js`
- `apps/flutter_client/cloudflare/_redirects` y `_headers` para rutas y CSP.
- `scripts/test_brand_lab_static.py`: tests sin dependencias.
- `.github/workflows/brand-lab-static.yml`: validación rápida de PR.
- `.github/workflows/cloudflare-pages-production.yml`: empaquetado y smoke de los recursos en producción.

**Validar después del merge:** GitHub Actions verde, `/mfd-release.json` igual al SHA de main, HTTP 200 en `/brand-lab/`, `/brand-lab/brand-lab.css` y `/brand-lab/brand-lab.js`, comprobar visualmente guardado, exportación, navegación con teclado, claro/oscuro y mobile. No atribuir resultados ficticios a usuarios.

## Evolución posterior (no incluida)

- Acceso administrativo autenticado y permisos explícitos.
- Versionado central por cuenta, aprobación y workflow de publicación, rollback, auditoría y pruebas de contraste automatizadas.
- Importación sincronizada entre dispositivos y revisión de marca/trademark/naming.
- Rediseño global de portada/perfiles por la dirección elegida y aprobación del propietario.

El laboratorio no reemplaza la documentación de requisitos de FitDating ni altera su elegibilidad, Gym Shield o controles de privacidad.
