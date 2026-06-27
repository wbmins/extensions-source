#!/bin/bash
set -euo pipefail

export https_proxy=http://127.0.0.1:7890
# export http_proxy=http://127.0.0.1:7890

# 环境路径配置
export JAVA_HOME="${JAVA_HOME:-/opt/temurin17}"
export ANDROID_HOME="${ANDROID_HOME:-/opt/android-sdk}"
export PATH="$JAVA_HOME/bin:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH"

java_ready() {
    [ -x "$JAVA_HOME/bin/java" ] && "$JAVA_HOME/bin/java" -version >/dev/null 2>&1
}

android_sdk_ready() {
    [ -x "$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager" ]
}

check_deps() {
    local missing=()
    command -v curl >/dev/null 2>&1 || missing+=("curl")
    command -v unzip >/dev/null 2>&1 || missing+=("unzip")
    
    if [ ${#missing[@]} -ne 0 ]; then
        echo "❌ 缺少以下工具: ${missing[*]}"
        return 1
    else
        echo "✅ 所有依赖已安装"
        return 0
    fi
}

# --- 函数：安装 Java 17 ---
prepare_java() {
    if ! java_ready; then
        echo "Missing Java 17. Downloading Temurin 17..."
        # 适用于 Linux x64
        local JAVA_URL="https://github.com/adoptium/temurin17-binaries/releases/download/jdk-17.0.10%2B7/OpenJDK17U-jdk_x64_linux_hotspot_17.0.10_7.tar.gz"
        local TEMP_TAR="/tmp/temurin17.tar.gz"
        mkdir -p "$JAVA_HOME"
        curl -fL --retry 3 -o "$TEMP_TAR" "$JAVA_URL"
        tar -xzf "$TEMP_TAR" -C "$JAVA_HOME" --strip-components=1
        rm -f "$TEMP_TAR"
        echo "✅ Java 17 安装完成"
    else
        echo "✅ Java 17 已存在"
    fi
}

# --- 函数：安装 Android SDK ---
prepare_android() {
    if ! android_sdk_ready; then
        echo "Missing Android SDK. Installing to $ANDROID_HOME..."
        local SDK_URL="https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip"
        local TEMP_ZIP="/tmp/sdk.zip"
        local TEMP_SDK_DIR="/tmp/android-sdk-cmdline-tools"
        
        mkdir -p "$ANDROID_HOME/cmdline-tools/latest"
        rm -rf "$TEMP_SDK_DIR"
        curl -fL --retry 3 -o "$TEMP_ZIP" "$SDK_URL"
        unzip -q "$TEMP_ZIP" -d "$TEMP_SDK_DIR"
        cp -a "$TEMP_SDK_DIR/cmdline-tools/." "$ANDROID_HOME/cmdline-tools/latest/"
        rm -f "$TEMP_ZIP"
        rm -rf "$TEMP_SDK_DIR"

        # 第一步：接受所有许可协议
        set +o pipefail
        yes | "$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager" \
            --sdk_root="$ANDROID_HOME" --licenses
        set -o pipefail
        # 第二步：安装组件
        "$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager" \
            --sdk_root="$ANDROID_HOME" \
            "platform-tools" \
            "platforms;android-34" \
            "build-tools;36.0.0"
        echo "✅ Android SDK 安装完成"
    else
        echo "✅ Android SDK 已存在"
    fi
}

build_apk() {
    echo "🏗️ 开始 Gradle 编译..."
    chmod +x ./gradlew
    if [ ! -f "signingkey.jks" ]; then
        /opt/temurin17/bin/keytool -genkeypair \
            -alias ehentai \
            -keyalg RSA \
            -keysize 2048 \
            -validity 3650 \
            -keystore signingkey.jks \
            -storetype JKS \
            -storepass ehentai \
            -keypass ehentai \
            -dname "CN=Unknown, OU=Unknown, O=Unknown, L=Unknown, ST=Unknown, C=Unknown"
    fi
    # 如果更新了signingkey.jks需要通过/opt/temurin17/bin/keytool -list -v -keystore ehentai.jks 这个命令查看SHA256并更新repo.json的signingKeyFingerprint
    KEY_STORE_PASSWORD=ehentai \
    ALIAS=ehentai \
    KEY_PASSWORD=ehentai \
    ANDROID_HOME="$ANDROID_HOME" \
    JAVA_HOME="$JAVA_HOME" \
    ./gradlew :src:all:ehentai:assembleRelease
}

# ==========================================
#               主程序流程
# ==========================================

# 1. 环境准备
echo "🔍 检查环境..."
check_deps
prepare_java
prepare_android
# 3. 执行编译
build_apk || exit 1

if [ $? -eq 0 ]; then
    echo "🎉 流程全部完成！"
else
    echo "❌ 编译过程中出错。"
    exit 1
fi
