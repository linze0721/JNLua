#!/bin/bash
ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

mkdir -p native-build
mkdir -p native-debug
rm -f native-build/*.dylib
rm -f native-debug/*.dylib

# Eris has no Lua 5.5 branch, so the 5.5 natives are built from the official
# sources with the compatibility patches in native/eris.
LUA55_VERSION="5.5.1"
LUA_VERSIONS="${LUA_VERSIONS:-5.2 5.3 5.4 5.5}"
ARCHS="${ARCHS:-amd64}"
PLATFORMS="${PLATFORMS:-mac}"

if [ ! -d eris ]; then
	git clone https://github.com/MovingBlocks/eris
fi

if [[ " $LUA_VERSIONS " == *" 5.5 "* ]]; then
	git -C eris checkout master-lua5.4
	if [ ! -f lua-$LUA55_VERSION.tar.gz ]; then
		curl -LO https://www.lua.org/ftp/lua-$LUA55_VERSION.tar.gz
	fi
	rm -rf lua-$LUA55_VERSION
	tar xzf lua-$LUA55_VERSION.tar.gz
	cp eris/src/eris.c eris/src/eris.h lua-$LUA55_VERSION/src/
	git apply --directory=lua-$LUA55_VERSION "$ROOT/native/eris/eris-libs-lua5.5.patch" || exit 1
	git apply --directory=lua-$LUA55_VERSION "$ROOT/native/eris/eris-lua5.5.patch" || exit 1
fi

cd native

for lua_ver in $LUA_VERSIONS; do
for arch_type in $ARCHS; do
for plat_type in $PLATFORMS; do

MY_GCC="gcc"
MY_STRIP="strip"
MY_LIB_SUFFIX="dylib"

if [ "$arch_type" == "i686" ]; then
	MY_CFLAGS="-fPIC -O2 -m32"
	MY_LDFLAGS="-m32 -dynamic"
else
	MY_CFLAGS="-fPIC -O2 -m64"
	MY_LDFLAGS="-m64 -dynamic"
fi

MY_ERIS_CFLAGS="-DJNLUA_USE_ERIS"
MY_LUA_CFLAGS=""
LUA_TYPE="posix"

if [ "$lua_ver" == "5.2" ]; then
	MY_JNLUA_SUFFIX="52"
	ERIS_BRANCH="master"
	LUA_SRC_DIR="../eris"
elif [ "$lua_ver" == "5.3" ]; then
	MY_JNLUA_SUFFIX="53"
	MY_LUA_CFLAGS="-DLUA_COMPAT_5_2"
	ERIS_BRANCH="master-lua5.3"
	LUA_SRC_DIR="../eris"
elif [ "$lua_ver" == "5.4" ]; then
	MY_JNLUA_SUFFIX="54"
	MY_LUA_CFLAGS="-DLUA_COMPAT_5_3 -Wno-error=incompatible-pointer-types"
	ERIS_BRANCH="master-lua5.4"
	LUA_SRC_DIR="../eris"
else
	MY_JNLUA_SUFFIX="55"
	MY_ERIS_CFLAGS="-DJNLUA_USE_ERIS"
	LUA_TYPE="macosx"
	LUA_SRC_DIR="../lua-$LUA55_VERSION"
fi

cd "$LUA_SRC_DIR"

if [ "$lua_ver" == "5.5" ]; then
	make clean
	make CC="$MY_GCC" MYCFLAGS="$MY_CFLAGS" $LUA_TYPE
else
	git checkout "$ERIS_BRANCH"
	make clean
	make CC="$MY_GCC" CFLAGS="$MY_CFLAGS $MY_LUA_CFLAGS" LDFLAGS="$MY_LDFLAGS" $LUA_TYPE
fi

cd ../native
rm -f *.dll *.so build/*.o

CFLAGS="$MY_CFLAGS $MY_ERIS_CFLAGS -DLUA_USE_POSIX" LDFLAGS="$MY_LDFLAGS" ARCH=amd64 JNLUA_SUFFIX="$MY_JNLUA_SUFFIX" \
  LUA_LIB_NAME=lua LUA_INC_DIR="$LUA_SRC_DIR/src" LUA_LIB_DIR="$LUA_SRC_DIR/src" LIB_SUFFIX="$MY_LIB_SUFFIX" \
  CC="$MY_GCC" LUA_VERSION="$lua_ver" \
  make -f Makefile.mac libjnlua

cp libjnlua"$MY_JNLUA_SUFFIX"."$MY_LIB_SUFFIX" ../native-debug/libjnlua-"$lua_ver"-"$plat_type"-"$arch_type"."$MY_LIB_SUFFIX"
"$MY_STRIP" libjnlua"$MY_JNLUA_SUFFIX"."$MY_LIB_SUFFIX"
mv libjnlua"$MY_JNLUA_SUFFIX"."$MY_LIB_SUFFIX" ../native-build/libjnlua-"$lua_ver"-"$plat_type"-"$arch_type"."$MY_LIB_SUFFIX"

done
done
done
