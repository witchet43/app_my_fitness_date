# Flutter client — my_fitness_date V22

Primer cliente **Flutter/Dart** compartido para web, Android e iOS.
Este código sustituirá gradualmente el cliente Expo, sin eliminarlo
hasta alcanzar paridad y pasar QA.

## Arranque

Se requiere Flutter SDK estable, Android SDK y Xcode en macOS para iOS.

```bash
cd apps/flutter_client
flutter create . --project-name my_fitness_date --platforms=web,android,ios
flutter pub get
flutter analyze
flutter test
flutter run -d chrome --web-port=5173 --dart-define=MFD_API_BASE_URL=http://localhost:8080
```

`flutter create` genera los directorios de plataforma hasta que se
confirmen identificadores finales de aplicaciones, firma y provisioning.
El código de Dart y las pruebas se versionan; **la app no contiene secretos**.

`MFD_API_BASE_URL` es la URL base del API Gateway (HTTPS en entornos remotos).
La app solo consulta `GET /healthz` sin autenticación. `GET
/v1/dating/candidates` ya dispone de cliente tipado, pero está bloqueado
en la UI hasta implementar el flujo seguro de identidad y aprobación
de edad. La selección de Gym Shield en UI es informativa en V22 y no
modifica las reglas en servidor.

## Estado

- Presentación inicial adaptativa: Comunidad, Actividades, Citas.
- `ApiClient`: consumo HTTP del gateway sin acceso directo a Supabase.
- CI: `flutter analyze`, `flutter test` y build web en GitHub Actions.
- **Pendiente:** sesión/login, conectividad Auth alojada, paridad de
  pantallas, artefactos nativos firmados, pruebas físicas y beta.
