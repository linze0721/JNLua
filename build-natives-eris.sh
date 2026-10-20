#!/bin/bash
mkdir -p native-build
mkdir -p native-debug
rm -f native-build/*.so native-build/*.dll
rm -f native-debug/*.so native-debug/*.dll

# Lua 5.5 has no Eris branch, so it is built from the official sources
# without persistence support.
LUA55_VERSION="5.5.1"

if [ ! -d eris ]; then
	git clone https://github.com/MovingBlocks/eris
fi
if [ ! -d lua-$LUA55_VERSION ]; then
	curl -LO https://www.lua.org/ftp/lua-$LUA55_VERSION.tar.gz
	tar xzf lua-$LUA55_VERSION.tar.gz
fi

cd native

for lua_ver in 5.2 5.3 5.4 5.5; do
for arch_type in i686 amd64; do
for plat_type in windows linux; do

MY_GCC="gcc"
MY_STRIP="strip"
MY_LIB_SUFFIX="so"
MY_PLATFORM_CFLAGS="-DLUA_USE_POSIX"
MY_JNI_CFLAGS=""

if [ "$arch_type" == "i686" ]; then
	MINGW_GCC="i686-w64-mingw32-gcc"
	MINGW_STRIP="i686-w64-mingw32-strip"
	MY_CFLAGS="-fPIC -O2 -m32"
	MY_LDFLAGS="-m32 -static-libgcc"
else
	MINGW_GCC="x86_64-w64-mingw32-gcc"
	MINGW_STRIP="x86_64-w64-mingw32-strip"
	MY_CFLAGS="-fPIC -O2 -m64"
	MY_LDFLAGS="-m64 -static-libgcc"
fi

LUA_TYPE="posix"

if [ "$plat_type" = "windows" ]; then
	LUA_TYPE="mingw"
	MY_GCC="$MINGW_GCC"
	MY_STRIP="$MINGW_STRIP"
	MY_LIB_SUFFIX="dll"
	MY_PLATFORM_CFLAGS=""
	MY_JNI_CFLAGS="-Iwin32"
	MY_JNLUA_LDFLAGS="$MY_LDFLAGS -Wl,--export-all-symbols"
	if [ "$arch_type" == "i686" ]; then
		MY_JNLUA_LDFLAGS="$MY_JNLUA_LDFLAGS -Wl,--kill-at"
	fi
fi
if [ -z "$MY_JNLUA_LDFLAGS" ]; then
	MY_JNLUA_LDFLAGS="$MY_LDFLAGS"
fi

MY_ERIS_CFLAGS="-DJNLUA_USE_ERIS"

if [ "$lua_ver" == "5.2" ]; then
	MY_JNLUA_SUFFIX="52"
	MY_LUA_CFLAGS=""
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
	MY_LUA_CFLAGS=""
	MY_ERIS_CFLAGS=""
	LUA_SRC_DIR="../lua-$LUA55_VERSION"
fi

# Eris builds do not support the mingw make target (it builds a DLL instead
# of a static library), so use the generic target with Windows support.
if [ "$plat_type" = "windows" ] && [ "$lua_ver" != "5.5" ]; then
	LUA_TYPE="generic"
	MY_LUA_CFLAGS="$MY_LUA_CFLAGS -DLUA_USE_WINDOWS"
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

CFLAGS="$MY_CFLAGS $MY_ERIS_CFLAGS $MY_PLATFORM_CFLAGS $MY_JNI_CFLAGS" LDFLAGS="$MY_JNLUA_LDFLAGS" ARCH=amd64 JNLUA_SUFFIX="$MY_JNLUA_SUFFIX" \
  LUA_LIB_NAME=lua LUA_INC_DIR="$LUA_SRC_DIR/src" LUA_LIB_DIR="$LUA_SRC_DIR/src" LIB_SUFFIX="$MY_LIB_SUFFIX" \
  CC="$MY_GCC" LUA_VERSION="$lua_ver" \
  make -f Makefile.linux libjnlua

cp libjnlua"$MY_JNLUA_SUFFIX"."$MY_LIB_SUFFIX" ../native-debug/libjnlua-"$lua_ver"-"$plat_type"-"$arch_type"."$MY_LIB_SUFFIX"
"$MY_STRIP" libjnlua"$MY_JNLUA_SUFFIX"."$MY_LIB_SUFFIX"
mv libjnlua"$MY_JNLUA_SUFFIX"."$MY_LIB_SUFFIX" ../native-build/libjnlua-"$lua_ver"-"$plat_type"-"$arch_type"."$MY_LIB_SUFFIX"

done
done
done
