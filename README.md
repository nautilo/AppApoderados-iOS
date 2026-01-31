# AppApoderado (iOS Swift WKWebView wrapper) - listo para Codemagic

Este repo es un wrapper iOS (Swift + WKWebView) que abre:
- https://gladiatorcontrolbase.com/colegio/guardian/login

Incluye un bridge compatible con tu web:
- `AndroidShare.shareText("...")` -> abre el Share Sheet nativo en iOS.

## Qué tienes que ajustar (rápido)
1) **Bundle ID**
   - Está en `project.yml` como: `PRODUCT_BUNDLE_IDENTIFIER: cl.apoderado.webview`
   - Debe coincidir con el App ID que crees en App Store Connect.

2) **Codemagic App Store Connect integration**
   - En Codemagic crea la integración de App Store Connect (API Key).
   - En `codemagic.yaml` cambia:
     - `YOUR_APP_STORE_CONNECT_INTEGRATION_NAME`

## Build + TestFlight (desde Windows)
1) Sube este proyecto a GitHub/GitLab.
2) En App Store Connect crea la app con el mismo Bundle ID.
3) En Codemagic conecta el repo.
4) Ejecuta el workflow `ios-testflight`.

Codemagic generará el Xcode project con XcodeGen en cada build y luego compilará y subirá a TestFlight.

## Cambiar URL base
Edita `Sources/WebContainerViewController.swift`:
- `startUrl = URL(string: "https://...")!`

## Notas
- Se dejó `NSAllowsArbitraryLoadsInWebContent = true` en `Resources/Info.plist` por si tu web carga algún recurso HTTP.
  Si todo es HTTPS, puedes quitarlo.
- Si tu web usa cámara/mic (WebRTC), ya están las descripciones de permisos en `Info.plist`.
