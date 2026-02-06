# Feature 013: Padronização de Ícones de Tray Multi-Plataforma

**Status:** 🟡 Planejado
**Prioridade:** Alta
**Versão Alvo:** v1.10.0
**Data de Criação:** 2026-02-06
**Última Atualização:** 2026-02-06

---

## 📋 Sumário Executivo

Este documento detalha a padronização de ícones de tray (bandeja do sistema) para funcionar corretamente em todas as plataformas suportadas: Linux (GNOME/KDE), macOS, Windows e Android. O problema atual é que os ícones não se adaptam corretamente ao tema do sistema operacional, resultando em baixa visibilidade ou aparência inconsistente.

---

## 🔍 Pesquisa e Evidências

### Fontes Consultadas

| Fonte | URL | Descoberta Principal |
|-------|-----|---------------------|
| GNOME HIG - Symbolic Icons | https://developer.gnome.org/hig/guidelines/ui-icons.html | Ícones simbólicos monocromáticos são recoloríveis pelo contexto |
| Freedesktop SNI Spec | https://specifications.freedesktop.org/status-notifier-item/latest-single/ | Spec recomenda `IconName` sobre `IconPixmap` |
| Flutter Issue #101438 | https://github.com/flutter/flutter/issues/101438 | `platformBrightness` detecta tema do app Flutter, não do shell GNOME |
| Apple HIG - Menu Bar Extras | https://bjango.com/articles/designingmenubarextras/ | Template images (preto+alpha) são automaticamente tintados |
| Android 13 Themed Icons | https://developer.android.com/about/versions/13/features | Requer camada `monochrome` no adaptive icon |
| tray_manager Flutter | https://pub.dev/packages/tray_manager | Não expõe `isTemplate` para macOS nativamente |
| AppIndicator GNOME | https://github.com/ubuntu/gnome-shell-extension-appindicator/issues/253 | Ícones `-symbolic` respeitam cor do painel |

### Análise do Código Atual

#### Arquivos de Ícones Existentes

```
assets/icons/
├── tray_icon_dark.png   # 48x48, RGBA - Ícone PRETO (para fundos claros)
├── tray_icon_light.png  # 48x48, RGBA - Ícone BRANCO (para fundos escuros)
├── tray_icon_macos.png  # 44x44, RGBA - Ícone PRETO com alpha
└── tray_icon.ico        # Multi-res ICO para Windows
```

#### Lógica de Seleção Atual (`lib/services/tray_service.dart:167-177`)

```dart
if (Platform.isLinux) {
  final brightness = SchedulerBinding.instance.platformDispatcher.platformBrightness;
  _lastBrightness = brightness;

  if (brightness == Brightness.dark) {
    candidate = 'assets/icons/tray_icon_light.png'; // Tema escuro = ícone claro ✓
  } else {
    candidate = 'assets/icons/tray_icon_dark.png';  // Tema claro = ícone escuro ✓
  }
}
```

**Veredicto:** A lógica de seleção está CORRETA semanticamente (tema escuro → ícone claro, tema claro → ícone escuro).

#### Bug Identificado (`lib/services/tray_service.dart:150-161`)

```dart
void _onThemeChanged() {
  if (!Platform.isLinux) return;

  final currentBrightness = SchedulerBinding.instance.platformDispatcher.platformBrightness;

  if (_lastBrightness != currentBrightness) {
    _lastBrightness = currentBrightness;
    LoggerService().info('Theme changed to: $currentBrightness');
    _resolveIconPath();  // ← Recalcula o path...
    // ❌ MAS NÃO REAPLICA O ÍCONE! Falta: trayManager.setIcon(_iconPath!)
  }
}
```

---

## 🎯 Problemas Identificados por Plataforma

### Linux/GNOME

| Problema | Causa Raiz | Impacto |
|----------|-----------|---------|
| Ícone não muda ao trocar tema em runtime | `_onThemeChanged` não chama `setIcon()` após recalcular path | Alto |
| `platformBrightness` pode não refletir tema do shell | Flutter detecta tema do app, não do desktop environment | Médio |
| Modo Separate (SNI) já funciona bem | Usa Freedesktop IconName | N/A |

### macOS

| Problema | Causa Raiz | Impacto |
|----------|-----------|---------|
| Ícone pode não adaptar automaticamente | `tray_manager` não expõe API para marcar como template | Médio |
| Arquivo `tray_icon_macos.png` está correto | 44x44, preto com alpha - formato correto | N/A |

### Windows

| Problema | Causa Raiz | Impacto |
|----------|-----------|---------|
| Não testado | Usuário não reportou problemas | Baixo |
| Sem detecção de tema | Windows não tem mecanismo nativo automático | Médio |

### Android (Launcher Icon)

| Problema | Causa Raiz | Impacto |
|----------|-----------|---------|
| Ícone não respeita Material You | Falta `adaptive_icon_monochrome` no pubspec.yaml | Alto |
| Themed Icons não funcionam | Sem camada monochrome no adaptive icon | Alto |

### Android (Widgets)

| Problema | Causa Raiz | Impacto |
|----------|-----------|---------|
| Widgets usam apenas emojis | Layout XML usa `TextView` para ícones | Médio |
| Não suporta ícones de arquivo | `CrossbarWidgetBase.kt` só faz `setTextViewText` | Médio |

---

## 📊 Especificações Técnicas por Plataforma

### Linux - StatusNotifierItem (SNI)

```
Protocolo: D-Bus
Métodos de Ícone:
  - IconName (string): Nome Freedesktop, ex: "battery-level-50-symbolic"
  - IconPixmap (array): Raw ARGB32 pixels
  
Recomendação da Spec: "Visualizations are encouraged to prefer icon names over icon pixmaps"

Tamanhos Comuns: 22x22, 24x24, 48x48
Formatos: PNG (bitmap), SVG (via tema)
Dark/Light: Controlado pelo StatusNotifierHost (GNOME Shell, KDE Plasma)
```

### macOS - NSStatusItem

```
Template Images:
  - NSImage.isTemplate = true
  - Sistema IGNORA cores, usa apenas canal alfa
  - Automaticamente tintado baseado no contraste do fundo

Tamanho: 22pt altura (44px @2x), até 37pt em MacBooks com notch
Formatos: PNG (1x + 2x), PDF, SVG
Opacidade: Apple usa 35% para estados desabilitados
```

### Windows - NotifyIcon

```
Formato: ICO obrigatório (multi-resolução: 16, 32, 48)
Dark/Light: NÃO tem suporte nativo
Detecção: Registry key HKCU\...\Themes\Personalize\AppsUseLightTheme
  - 0 = dark mode
  - 1 = light mode
```

### Android - Notification Icons / Themed Icons

```
Formato: PNG com transparência obrigatória
Cor: Sistema usa APENAS canal alfa - ignora cores completamente
Renderização: Branco na status bar, accent color no notification shade

Material You (Android 13+):
  - Requer <monochrome> em ic_launcher.xml
  - Adaptive icon foreground é usado como máscara
```

---

## 🛠️ Plano de Implementação

### Fase 1: Correções Imediatas (v1.10.0) 🟢

> **Escopo:** Resolver bugs críticos sem mudanças arquiteturais

#### 1.1 Linux - Reaplicar Ícone ao Trocar Tema

**Arquivo:** `lib/services/tray_service.dart`
**Linha:** ~150-161

```dart
void _onThemeChanged() {
  if (!Platform.isLinux) return;

  final currentBrightness = SchedulerBinding.instance.platformDispatcher.platformBrightness;

  if (_lastBrightness != currentBrightness) {
    _lastBrightness = currentBrightness;
    LoggerService().info('Theme changed to: $currentBrightness');
    
    // Recalcular path E reaplicar ícone
    unawaited(_updateIconForTheme());
  }
}

Future<void> _updateIconForTheme() async {
  await _resolveIconPath();
  if (_unifiedTrayActive && _iconPath != null) {
    try {
      await trayManager.setIcon(_iconPath!);
      LoggerService().info('Tray icon updated to: $_iconPath');
    } catch (e) {
      LoggerService().warning('Failed to update tray icon: $e');
    }
  }
}
```

**Validação:**
- [ ] Trocar tema GNOME (Settings → Appearance) em runtime
- [ ] Ícone deve atualizar sem reiniciar o app
- [ ] Log deve mostrar "Tray icon updated to: ..."

---

#### 1.2 Android - Adicionar Monochrome Icon

**Arquivo:** `pubspec.yaml`
**Seção:** `flutter_launcher_icons`

```yaml
flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/icons/icon.png"
  adaptive_icon_foreground: "assets/icons/icon.png"
  adaptive_icon_background: "#FFFFFF"
  adaptive_icon_monochrome: "assets/icons/icon_monochrome.png"  # ← ADICIONAR
```

**Arquivo:** `Makefile` (adicionar ao target `icons`)

```makefile
# Gerar ícone monocromático (branco com transparência)
$(ICONS_DIR)/icon_monochrome.png: $(ICONS_DIR)/icon.png
	@echo "Generating monochrome icon..."
	magick $< -alpha extract -negate PNG32:$@
```

**Comandos:**
```bash
make icons
flutter pub run flutter_launcher_icons
```

**Validação:**
- [ ] Android 13+ com "Themed icons" ativado nas configurações
- [ ] Ícone do launcher deve usar cor dinâmica do Material You
- [ ] Verificar `android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml` contém `<monochrome>`

---

### Fase 2: Melhorias Nativas (v1.11.0) 🟡

> **Escopo:** Usar mecanismos nativos de cada OS para máxima compatibilidade

#### 2.1 Linux - Validar/Criar Ícone Simbólico Freedesktop

**Novo Arquivo:** `assets/icons/com.verseles.crossbar-symbolic.svg`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16">
  <!-- Ícone simbólico seguindo spec Freedesktop -->
  <!-- Usar apenas preto (#000000) com opacidade variável -->
  <path fill="#000000" fill-opacity="1.0" d="..."/>
</svg>
```

**Instalação (make install):**
```bash
install -Dm644 assets/icons/com.verseles.crossbar-symbolic.svg \
  $(DESTDIR)/usr/share/icons/hicolor/symbolic/apps/com.verseles.crossbar-symbolic.svg
```

**Uso no código (modo Separate já usa, validar modo Unified):**
```dart
if (Platform.isLinux) {
  // Tentar IconName primeiro (instalado via make install)
  // Fallback para PNG em dev mode
}
```

---

#### 2.2 macOS - Validar Template Image

**Verificação necessária:**
1. Confirmar que `tray_manager` aplica `isTemplate: true` automaticamente
2. Se não, investigar fork ou PR upstream

**Arquivo atual:** `assets/icons/tray_icon_macos.png`
- Formato: 44x44, RGBA ✓
- Conteúdo: Preto com alpha ✓ (verificado via `file` command)

**Teste:**
```bash
# Verificar que é preto com transparência
magick identify -verbose assets/icons/tray_icon_macos.png | grep -A5 "Channel statistics"
```

---

#### 2.3 Windows - Detecção de Tema (Opcional)

**Dependência:** `package:win32` ou platform channel

```dart
Future<bool> _detectWindowsTheme() async {
  if (!Platform.isWindows) return false;
  
  // Via platform channel para ler registry:
  // HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize
  // AppsUseLightTheme: 0 = dark, 1 = light
  
  final result = await _windowsChannel.invokeMethod<int>('getAppsUseLightTheme');
  return result == 1; // true = light theme
}
```

**Prioridade:** Baixa (usuário não reportou problemas)

---

### Fase 3: Widgets Mobile (v1.12.0) 🔵

> **Escopo:** Suportar ícones não-emoji nos widgets Android/iOS

#### 3.1 Android - Migrar para ImageView

**Arquivo:** `android/app/src/main/res/layout/crossbar_widget_small.xml`

```xml
<!-- ANTES -->
<TextView
    android:id="@+id/widget_icon"
    android:text="📊"
    android:textSize="32sp" />

<!-- DEPOIS: Dual-mode (emoji fallback + image support) -->
<FrameLayout
    android:layout_width="32dp"
    android:layout_height="32dp">
    
    <!-- ImageView para ícones de arquivo -->
    <ImageView
        android:id="@+id/widget_icon_image"
        android:layout_width="match_parent"
        android:layout_height="match_parent"
        android:scaleType="fitCenter"
        android:visibility="gone" />
    
    <!-- TextView para emojis (fallback) -->
    <TextView
        android:id="@+id/widget_icon_emoji"
        android:layout_width="match_parent"
        android:layout_height="match_parent"
        android:gravity="center"
        android:text="📊"
        android:textSize="28sp" />
</FrameLayout>
```

**Arquivo:** `android/app/src/main/kotlin/.../CrossbarWidgetBase.kt`

```kotlin
fun updateIcon(views: RemoteViews, iconData: String?) {
    if (iconData == null || iconData.isEmpty()) {
        // Emoji padrão
        views.setViewVisibility(R.id.widget_icon_image, View.GONE)
        views.setViewVisibility(R.id.widget_icon_emoji, View.VISIBLE)
        views.setTextViewText(R.id.widget_icon_emoji, "📊")
    } else if (iconData.startsWith("/") || iconData.startsWith("file://")) {
        // Caminho de arquivo
        val bitmap = BitmapFactory.decodeFile(iconData.removePrefix("file://"))
        if (bitmap != null) {
            views.setViewVisibility(R.id.widget_icon_emoji, View.GONE)
            views.setViewVisibility(R.id.widget_icon_image, View.VISIBLE)
            views.setImageViewBitmap(R.id.widget_icon_image, bitmap)
        }
    } else {
        // Emoji ou texto
        views.setViewVisibility(R.id.widget_icon_image, View.GONE)
        views.setViewVisibility(R.id.widget_icon_emoji, View.VISIBLE)
        views.setTextViewText(R.id.widget_icon_emoji, iconData)
    }
}
```

---

#### 3.2 iOS - SF Symbols

**Arquivo:** `ios/CrossbarWidget/CrossbarWidget.swift`

```swift
@ViewBuilder
func iconView(for icon: String) -> some View {
    if icon.hasPrefix("sf:") {
        // SF Symbol nativo
        let symbolName = String(icon.dropFirst(3))
        Image(systemName: symbolName)
            .font(.system(size: 32))
            .widgetAccentable()  // iOS 16+ Lock Screen support
    } else if icon.count <= 2 {
        // Emoji (1-2 caracteres)
        Text(icon)
            .font(.system(size: 32))
    } else if let uiImage = loadImageFromAppGroup(icon) {
        // Imagem do App Group
        Image(uiImage: uiImage)
            .resizable()
            .scaledToFit()
            .frame(width: 32, height: 32)
    } else {
        // Fallback
        Text("📊")
            .font(.system(size: 32))
    }
}

private func loadImageFromAppGroup(_ path: String) -> UIImage? {
    guard let containerURL = FileManager.default.containerURL(
        forSecurityApplicationGroupIdentifier: "group.com.verseles.crossbar"
    ) else { return nil }
    
    let fileURL = containerURL.appendingPathComponent(path)
    return UIImage(contentsOfFile: fileURL.path)
}
```

---

## ✅ Critérios de Aceitação (Definition of Done)

### Fase 1
- [ ] Linux: Ícone atualiza ao trocar tema GNOME em runtime
- [ ] Android: Ícone do launcher respeita Material You (Android 13+)
- [ ] `make analyze` passa sem erros
- [ ] `make coverage` ≥ 35%
- [ ] `make linux` e `make android` compilam

### Fase 2
- [ ] Linux: Ícone simbólico funciona quando instalado via `make install`
- [ ] macOS: Ícone adapta automaticamente em light/dark mode
- [ ] Windows: (Opcional) Ícone muda baseado no tema do sistema

### Fase 3
- [ ] Android widgets: Suportam ícones PNG além de emojis
- [ ] iOS widgets: Suportam SF Symbols via prefixo `sf:`
- [ ] Widgets funcionam em Lock Screen (iOS 16+)

---

## 📁 Arquivos Afetados

### Fase 1
- `lib/services/tray_service.dart` - Correção do bug de tema
- `pubspec.yaml` - Adicionar `adaptive_icon_monochrome`
- `Makefile` - Adicionar geração de ícone monocromático
- `assets/icons/icon_monochrome.png` - Novo arquivo

### Fase 2
- `assets/icons/com.verseles.crossbar-symbolic.svg` - Novo arquivo
- `Makefile` - Adicionar instalação de ícone simbólico

### Fase 3
- `android/app/src/main/res/layout/crossbar_widget_*.xml` - Layouts
- `android/app/src/main/kotlin/.../CrossbarWidgetBase.kt` - Kotlin
- `ios/CrossbarWidget/CrossbarWidget.swift` - SwiftUI

---

## 🔗 Referências

- [Freedesktop StatusNotifierItem Spec](https://specifications.freedesktop.org/status-notifier-item/latest-single/)
- [Freedesktop Icon Theme Spec](https://specifications.freedesktop.org/icon-theme/latest/)
- [GNOME HIG - UI Icons](https://developer.gnome.org/hig/guidelines/ui-icons.html)
- [Apple HIG - Menu Bar Extras](https://developer.apple.com/design/human-interface-guidelines/menu-bar-extras)
- [Android Adaptive Icons](https://developer.android.com/develop/ui/views/launch/icon_design_adaptive)
- [Android 13 Themed Icons](https://developer.android.com/about/versions/13/features)
- [Flutter Issue #101438 - Theme detection on GNOME 42](https://github.com/flutter/flutter/issues/101438)
- [tray_manager package](https://pub.dev/packages/tray_manager)

---

## 📝 Notas de Implementação

### Por que `platformBrightness` pode falhar no Linux?

O Flutter usa `platformDispatcher.platformBrightness` que lê configurações via XDG Desktop Portal (após Flutter 3.0). Isso geralmente funciona, mas:

1. **GNOME 42+** mudou como expõe preferências de cor
2. O Flutter Engine teve que ser corrigido (PR #33100) para ler do portal correto
3. Em versões antigas do Flutter ou configurações não-padrão, pode retornar valor incorreto

**Solução robusta:** Além de ouvir `onPlatformBrightnessChanged`, considerar usar ícone simbólico Freedesktop que delega a decisão para o shell.

### Trade-offs da Abordagem IconName vs IconPixmap

| Aspecto | IconName (Freedesktop) | IconPixmap (PNG direto) |
|---------|------------------------|-------------------------|
| Integração nativa | ✅ Perfeita | ⚠️ Manual |
| Respeita tema | ✅ Automático | ❌ App decide |
| Dev mode | ❌ Requer instalação | ✅ Funciona direto |
| Escalabilidade | ✅ SVG infinito | ❌ Rasterizado |
| Complexidade | Média | Baixa |

**Recomendação:** Usar IconName quando instalado, fallback para IconPixmap em dev mode.
