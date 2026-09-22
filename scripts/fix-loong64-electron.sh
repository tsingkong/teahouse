#!/bin/bash
# loong64 Electron 原生模块修复:headers 元数据与二进制不符(二进制无指针压缩)
set -e
ELECTRON_VERSION=32.2.5
CG="$HOME/.cache/node-gyp/$ELECTRON_VERSION/include/node/config.gypi"
[ -f "$CG" ] || { echo "先构建一次以生成 node-gyp 缓存"; exit 1; }
[ -f "$CG.orig" ] || cp "$CG" "$CG.orig"
sed -i \
  -e "s/'v8_enable_pointer_compression': 1,/'v8_enable_pointer_compression': 0,/" \
  -e "s/'v8_enable_pointer_compression_shared_cage': 1,/'v8_enable_pointer_compression_shared_cage': 0,/" \
  -e "s/'v8_enable_31bit_smis_on_64bit_arch': 1,/'v8_enable_31bit_smis_on_64bit_arch': 0,/" \
  -e "s/'v8_enable_sandbox': 1,/'v8_enable_sandbox': 0,/" "$CG"
# 中和 gypi 强制注入(如存在)
for f in node_modules/@electron/node-gyp/addon.gypi \
         "$HOME/.cache/node-gyp/$ELECTRON_VERSION/include/node/common.gypi"; do
  [ -f "$f" ] && sed -i.bak \
    -e 's/V8_31BIT_SMIS_ON_64BIT_ARCH/V8_NEUTERED_A/g' \
    -e 's/V8_ENABLE_SANDBOX/V8_NEUTERED_B/g' "$f" || true
done
echo "patch 完成。重编:"
cd node_modules/better-sqlite3 && rm -rf build bin
../../node_modules/.bin/node-gyp configure --release --runtime=electron \
  --target=$ELECTRON_VERSION --dist-url=http://127.0.0.1:8000/data/loong64/Electron
../../node_modules/.bin/node-gyp build
echo "验证: $(node -e 'console.log(process.versions.modules)')"
