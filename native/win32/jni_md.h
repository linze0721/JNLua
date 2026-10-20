/*
 * JNI platform definitions for building JNLua for Windows.
 *
 * Linux JDK distributions do not ship include/win32/jni_md.h, so the
 * definitions required for a Windows DLL are provided here.
 */

#ifndef _JAVASOFT_JNI_MD_H_
#define _JAVASOFT_JNI_MD_H_

#define JNIEXPORT __declspec(dllexport)
#define JNIIMPORT __declspec(dllimport)
#define JNICALL __stdcall

typedef long jint;
typedef __int64 jlong;
typedef signed char jbyte;

#endif /* _JAVASOFT_JNI_MD_H_ */
