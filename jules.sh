#!/bin/bash
#
# Crossbar Development Environment - Ubuntu 24.04 LTS (SNAPSHOT ULTRA SIMPLES)
#

export DEBIAN_FRONTEND=noninteractive

# 1. Dependências mínimas Flutter Desktop
sudo apt-get update -qq >/dev/null 2>&1
sudo apt-get install -y -qq \
    git \
    pkg-config \
    libgtk-3-dev \
    unzip \
    wget \
    lcov \
    bc \
    >/dev/null 2>&1

# 2. Flutter 3.38.0 (Git)
cd ~
rm -rf flutter
git config --global http.postBuffer 1048576000 >/dev/null 2>&1
timeout 900 git clone https://github.com/flutter/flutter.git -b 3.38.0 --depth 1 >/dev/null 2>&1 || \
timeout 900 git clone https://github.com/flutter/flutter.git -b stable --depth 1 >/dev/null 2>&1

echo 'export PATH="$HOME/flutter/bin:$PATH"' >> ~/.bashrc
export PATH="$HOME/flutter/bin:$PATH"

# 3. Precache
flutter precache --linux >/dev/null 2>&1

# 4. Android SDK CLI (LATEST)
mkdir -p ~/Android/Sdk/cmdline-tools
cd ~/Android/Sdk/cmdline-tools
wget -q https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip >/dev/null 2>&1
unzip -q commandlinetools-linux-11076708_latest.zip >/dev/null 2>&1
mv cmdline-tools latest
rm commandlinetools-linux-11076708_latest.zip >/dev/null 2>&1

# 5. APENAS Android PATH (SEM JAVA_HOME)
export ANDROID_HOME=$HOME/Android/Sdk
export PATH=$ANDROID_HOME/cmdline-tools/latest/bin:$PATH
export PATH=$ANDROID_HOME/platform-tools:$PATH

echo 'export ANDROID_HOME=$HOME/Android/Sdk' >> ~/.bashrc
echo 'export PATH=$ANDROID_HOME/cmdline-tools/latest/bin:$PATH' >> ~/.bashrc
echo 'export PATH=$ANDROID_HOME/platform-tools:$PATH' >> ~/.bashrc

# 6. Licenças + API 35 (SEM Java)
yes | $ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager --licenses >/dev/null 2>&1
$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager "platform-tools" >/dev/null 2>&1
$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager "platforms;android-35" >/dev/null 2>&1
$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager "build-tools;35.0.0" >/dev/null 2>&1

# 7. Licenças Flutter
source ~/.bashrc >/dev/null 2>&1
yes | flutter doctor --android-licenses >/dev/null 2>&1
