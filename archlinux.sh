#!/bin/bash
#
# Crossbar Development Environment - Arch Linux (VERSÕES MAIS RECENTES 2025)
# chaotic-aur/flutter-bin 3.38.3 + aur/jdk 25.0.1 + chaotic-aur/android-sdk
#

echo "🚀 Crossbar Dev Environment - Arch Linux (Latest 2025)"
echo "chaotic-aur/flutter-bin 3.38.3 + aur/jdk 25.0.1 + android-sdk-cmdline-tools"
echo "===================================================================="

# 1. Atualizar sistema
echo "🛠 1/10 Atualizando sistema..."
paru -Sy --noconfirm

# 2. Dependências Flutter Desktop + Testes
echo "📦 2/10 Dependências Flutter + Testes..."
paru -S --noconfirm --needed \
    pkgconf \
    gtk3 \
    libkeybinder3 \
    xz \
    glib2 \
    gcc \
    clang \
    cmake \
    ninja \
    base-devel \
    lcov \
    bc

# 3. Flutter 3.38.3 (chaotic-aur - MAIS RECENTE)
echo "🦋 3/10 Flutter 3.38.3 (chaotic-aur/flutter-bin)..."
paru -S --noconfirm --needed chaotic-aur/flutter-bin

# 4. Java 25.0.1 (aur/jdk - MAIS RECENTE)
echo "☕ 4/10 Java 25.0.1 (aur/jdk)..."
paru -S --noconfirm --needed aur/jdk

# 5. Android SDK Command Line Tools (chaotic-aur - MAIS RECENTE)
echo "📱 5/10 Android SDK Command Line Tools (chaotic-aur)..."
paru -S --noconfirm --needed chaotic-aur/android-sdk-cmdline-tools-latest

# 6. Configurar variáveis (PATHs corretos para pacotes AUR/Chaotic-AUR)
cat >> ~/.bashrc << 'EOF'

# Flutter 3.38.3 (chaotic-aur/flutter-bin)
export PATH="/opt/flutter/bin:$PATH"

# Java 25.0.1 (aur/jdk)
export JAVA_HOME="/usr/lib/jvm/jdk"
export PATH="$JAVA_HOME/bin:$PATH"

# Android SDK (chaotic-aur/android-sdk-cmdline-tools-latest)
export ANDROID_HOME="/opt/android-sdk"
export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$PATH"
export PATH="$ANDROID_HOME/platform-tools:$PATH"
EOF

# Aplicar agora
export PATH="/opt/flutter/bin:$PATH"
export JAVA_HOME="/usr/lib/jvm/jdk"
export PATH="$JAVA_HOME/bin:$PATH"
export ANDROID_HOME="/opt/android-sdk"
export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$PATH"
export PATH="$ANDROID_HOME/platform-tools:$PATH"

echo "⚙️  6/10 Aplicando variáveis de ambiente..."

# 7. Licenças + Componentes Android (API 35 + 36)
echo "📜 7/10 Licenças Android..."
yes | $ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager --licenses

echo "📦 8/10 Componentes Android (API 35+36)..."
$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager "platform-tools"
$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager "platforms;android-35"
$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager "platforms;android-36"
$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager "build-tools;35.0.0"
$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager "build-tools;36.0.0"

# 8. Licenças Flutter
echo "🔑 9/10 Licenças Flutter..."
yes | flutter doctor --android-licenses

# 9. Verificação final
echo "🔍 10/10 Verificando instalação..."
flutter doctor

echo ""
echo "🎉 INSTALAÇÃO 100% COMPLETA!"
echo "═══════════════════════════════════════════════════════════════"
echo "📦 Stack instalado (VERSÕES MAIS RECENTES):"
echo "  • Flutter: $(flutter --version | head -1)"
echo "  • Java:    $(java -version 2>&1 | head -1)"
echo "  • Android: API 35+36 (/opt/android-sdk)"
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "✅ Use: source ~/.bashrc"
echo "✅ Teste: flutter create test_app && cd test_app && flutter run -d linux"
echo ""
echo "🛠 Ambiente pronto para desenvolvimento Crossbar!"
