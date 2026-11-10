# Auditoría de diseño visual — My Fitness Date V25
**Sistema:** Flutter Web/Android/iOS · **Dirección:** Active Chemistry
**Estado:** Diseño implementado en código, validación CI y despliegue pendiente de evidencia; experiencia web pública anónima. No declarar beta real.

## Base auditada (V24)
Se revisaron `apps/flutter_client/lib/src/app.dart`, `features/pace_calculator.dart` y el contrato de publicación Cloudflare.
- Identidad de marca: título de aplicación `my_fitness_date`, signos de desarrollo (`DEV`, `Flutter · Web / Android / iOS · API Gateway`), ausencia de promesa emocional y jerarquía de marca.
- Sistema de color: fondo `#091319` + único acento dominante `#B6F266`; comunica ejercicio tecnológico, pero no diferencia visualmente comunidad, conexión afectiva y progreso deportivo.
- Navegación: comunidad/actividades/citas con énfasis equivalente; tarjetas de contenido genéricas y poca distinción entre pantalla de descubrimiento, ejercicio disponible y características futuras.
- Confianza: la advertencia de registro no habilitado existe, pero las posibilidades de Gym Shield no se comunican como beneficio claro, con lenguaje principalmente de arquitectura.
- Responsive: `NavigationRail` + `NavigationBar` presentes; composición de héroe e inputs sin sistema de marca, espacios ni jerarquía editorial.
- Prueba visual humana y accesibilidad asistida **no realizadas**; estas observaciones proceden del código, no de entrevistas ni métricas de usuarios.

## Posicionamiento
**My Fitness Date: Encuentra tu ritmo. Conecta de verdad.**
Aplicación de encuentros con afinidad deportiva, abierta al running, gimnasio, entrenamiento funcional, caminatas y movimiento. Estética emocional, atlética, premium y no excluyente; sin estereotipos corporales y sin sexualización de perfiles. Se evita prometer coincidencias o usuarios que aún no existen.

## Tokens de marca
| Uso | Token | HEX |
| --- | --- | --- |
| Base noche | Ink | `#10121E` |
| Base profunda | Ink Deep | `#0A0D16` |
| Contenedores | Surface | `#191D2C` |
| Superficie elevada | Raised | `#23283A` |
| Amor / acciones primarias | Coral | `#FF617B` |
| Entrenamiento / actividad | Lime | `#C8FF6B` |
| Afinidad / social | Lilac | `#A995FF` |
| Texto primario | Pearl | `#F6F5F7` |
| Texto secundario | Muted | `#C3C6D3` |
| Divisores | Outline | `#3A4054` |

**Contrastes calculados sRGB**, no sustituyen revisión visual manual con lector de pantalla: Pearl/Ink 17.14:1; Muted/Ink 10.95:1; Coral/Ink 6.43:1; Lime/Ink 15.94:1; Lilac/Ink 7.48:1; Ink Deep/Coral 6.70:1; Ink Deep/Lime 16.61:1. Superan 4.5:1 para esos pares nominales; transparencias, gradientes, iconos y textos sobre otras superficies necesitan revisión específica.

## Jerarquía e interacción implementadas
1. **FitCommunity**: héroe editorial, identidad deportiva+afectiva, CTA activo a calculadora (entrega pública real), CTA a vista previa de FitDating, tarjetas de tres pilares y acceso a privacidad.
2. **FitTogether / Actividades**: calculadora rediseñada con entradas accesibles, resultados destacados de ritmo y velocidad, validación y cálculo exclusivamente en dispositivo. Eventos futuros señalados como no disponibles.
3. **FitDating / Gym Shield**: promesa de privacidad, vista previa explícita sin perfiles ni coincidencias reales, selector visual ilustrativo que no persiste ni cambia reglas del servidor, información sobre edad y moderación pendiente.
4. **Navegación**: Rail para pantallas anchas y barra inferior táctil para móvil; estados de selección diferenciados por color, labels y semántica. Botones con acciones reales.
5. **Diseño adaptable**: héroe en dos columnas a partir de ancho suficiente, composición vertical en móvil, formularios de ritmo apilados en menos de 440 px y selector Gym Shield con desplazamiento horizontal.
6. **Confianza y seguridad**: ninguna fotografía de usuario inventada; no se capturan ni muestran perfiles, nombre de usuarios, estadísticas ficticias, swipes ni mensajería. El QA login no se expone en build público `MFD_QA_LOGIN_UI=false`.

## Verificación necesaria para publicar
- `flutter analyze`, `flutter test`, build web y regresiones de identidad, Gym Shield y calculadora.
- Widget tests a 390x844 y 800x600, identidad de marca, CTA funcional y pantalla de citas explícitamente cerrada.
- Revisión manual en browser real 320, 390, 768, 1440, alto contraste, escala de texto 200%, teclado, foco visible, lector de pantalla y touch targets >=44 px.
- Revisión legal/editorial del posicionamiento antes de anunciar registro o citas.
- Merge a `main`, Cloudflare Pages Direct Upload con commit exacto, smoke HTTP que compare `mfd-release.json`.
- Publicar solo artefactos anónimos; los nueve gates de beta real en `release/readiness.json` continúan obligatorios.

## Criterios para próximas iteraciones
Si se habilitan perfiles verificados, añadir retratos autorizados, pronombres opcionales, intereses deportivos y detalles de seguridad sin inferir identidad, edad o atributos sensibles desde imágenes. Un posible «match» solo se mostrará tras consentimiento y validación real; no llenar el diseño con perfiles sintéticos sin etiquetar.
