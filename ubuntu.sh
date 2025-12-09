#!/bin/bash
#
# Crossbar Development Environment - Ubuntu 24.04 LTS (Build APK Ready)
#

export DEBIAN_FRONTEND=noninteractive

# 1. Dependências Completas (Incluindo Java para o sdkmanager e libs do Crossbar)
sudo apt-get update -qq >/dev/null 2>&1
sudo apt-get install -y -qq \
    git \
    curl \
    unzip \
    xz-utils \
    zip \
    pkg-config \
    libgtk-3-dev \
    libayatana-appindicator3-dev \
    libsecret-1-dev \
    cmake \
    clang \
    ninja-build \
    libglu1-mesa \
    lcov \
    bc \
    openjdk-17-jdk \
    >/dev/null 2>&1

# Configurar JAVA_HOME para esta sessão (crítico para o sdkmanager funcionar)
export JAVA_HOME=$(readlink -f /usr/bin/java | sed "s:bin/java::")
export PATH=$PATH:$JAVA_HOME/bin

# 2. Flutter 3.38.0 (Versão estável mais recente)
cd ~
rm -rf flutter
git config --global http.postBuffer 1048576000 >/dev/null 2>&1
# Tenta clonar a tag específica ou fallback para stable
timeout 900 git clone https://github.com/flutter/flutter.git -b 3.38.0 --depth 1 >/dev/null 2>&1 || \
timeout 900 git clone https://github.com/flutter/flutter.git -b stable --depth 1 >/dev/null 2>&1

echo 'export PATH="$HOME/flutter/bin:$PATH"' >> ~/.bashrc
export PATH="$HOME/flutter/bin:$PATH"

# 3. Precache (incluindo Android)
flutter precache --linux --android >/dev/null 2>&1

# 4. Android SDK CLI (LATEST)
mkdir -p ~/Android/Sdk/cmdline-tools
cd ~/Android/Sdk/cmdline-tools
# Limpeza preventiva
rm -rf latest commandlinetools-linux-* 

wget -q https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip >/dev/null 2>&1
unzip -q commandlinetools-linux-11076708_latest.zip >/dev/null 2>&1
mv cmdline-tools latest
rm commandlinetools-linux-11076708_latest.zip >/dev/null 2>&1

# 5. Configurar variáveis Android
export ANDROID_HOME=$HOME/Android/Sdk
export ANDROID_SDK_ROOT=$ANDROID_HOME
export PATH=$ANDROID_HOME/cmdline-tools/latest/bin:$PATH
export PATH=$ANDROID_HOME/platform-tools:$PATH
export PATH=$ANDROID_HOME/build-tools/35.0.0:$PATH

# Adicionar ao .bashrc (com verificação para não duplicar)
grep -q "ANDROID_HOME" ~/.bashrc || echo 'export ANDROID_HOME=$HOME/Android/Sdk' >> ~/.bashrc
grep -q "ANDROID_SDK_ROOT" ~/.bashrc || echo 'export ANDROID_SDK_ROOT=$ANDROID_HOME' >> ~/.bashrc
grep -q "cmdline-tools/latest/bin" ~/.bashrc || echo 'export PATH=$ANDROID_HOME/cmdline-tools/latest/bin:$PATH' >> ~/.bashrc
grep -q "platform-tools" ~/.bashrc || echo 'export PATH=$ANDROID_HOME/platform-tools:$PATH' >> ~/.bashrc
grep -q "build-tools" ~/.bashrc || echo 'export PATH=$ANDROID_HOME/build-tools/35.0.0:$PATH' >> ~/.bashrc
grep -q "JAVA_HOME" ~/.bashrc || echo "export JAVA_HOME=$JAVA_HOME" >> ~/.bashrc

# 6. Instalar Componentes Android (Build APK Ready)
yes | $ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager --licenses >/dev/null 2>&1
$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager \
    "platform-tools" \
    "platforms;android-35" \
    "platforms;android-34" \
    "build-tools;35.0.0" \
    "build-tools;34.0.0" \
    "cmdline-tools;latest" >/dev/null 2>&1

# 7. Aceitar licenças do Flutter
yes | flutter doctor --android-licenses >/dev/null 2>&1

# 8. GitHub CLI (gh)
type -p curl >/dev/null || (sudo apt update && sudo apt install curl -y)
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
&& sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
&& echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
&& sudo apt update >/dev/null 2>&1 \
&& sudo apt install gh -y >/dev/null 2>&1

# 9. act (Local GitHub Actions)
curl --proto '=https' --tlsv1.2 -sSf https://raw.githubusercontent.com/nektos/act/master/install.sh | sudo bash >/dev/null 2>&1

echo ""
echo "================================"
echo "Setup concluído! ✅"
echo "================================"
echo ""
echo "Execute: source ~/.bashrc"
echo ""
echo "Para verificar: flutter doctor -v"
echo "Para build APK: flutter build apk --release"
echo ""
