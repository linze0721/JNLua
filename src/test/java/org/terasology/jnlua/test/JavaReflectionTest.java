/*
 * Copyright (C) 2008,2012 Andre Naef
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

package org.terasology.jnlua.test;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertTrue;

import java.util.ArrayList;
import java.util.List;

import org.junit.Test;

import org.terasology.jnlua.Converter;
import org.terasology.jnlua.DefaultConverter;
import org.terasology.jnlua.LuaState;

/**
 * Contains unit tests for Java reflection.
 */
public class JavaReflectionTest extends AbstractLuaTest {
	// -- Test cases
	/**
	 * Tests Java reflection from Lua.
	 */
	@Test
	public void testReflection() throws Exception {
		runTest("org/terasology/jnlua/test/Reflection.lua", "Reflection");
	}

	/**
	 * Tests that method proxies are cached per state and can be reused.
	 */
	@Test
	public void testMethodProxyCaching() throws Exception {
		luaState.openLibs();
		List<String> values = new ArrayList<String>();
		luaState.pushJavaObject(values);
		luaState.setGlobal("values");
		luaState.load("for i = 1, 100 do values:add('x') end return values:size()", "=proxy");
		luaState.call(0, 1);
		assertEquals(100, luaState.toInteger(-1));
		luaState.pop(1);

		LuaState other = createLuaState();
		try {
			other.openLibs();
			List<String> otherValues = new ArrayList<String>();
			other.pushJavaObject(otherValues);
			other.setGlobal("values");
			other.load("values:add('y'); return values:size()", "=proxy");
			other.call(0, 1);
			assertEquals(1, other.toInteger(-1));
		} finally {
			other.close();
		}
	}

	/**
	 * Tests that a primitive return value stays a Lua number and that a custom
	 * converter is still used for it.
	 */
	@Test
	public void testPrimitiveReturn() throws Exception {
		luaState.openLibs();
		List<String> values = new ArrayList<String>();
		luaState.pushJavaObject(values);
		luaState.setGlobal("values");
		luaState.load("assert(values:size() == 0); return type(values:size())", "=primitive");
		luaState.call(0, 1);
		assertEquals("number", luaState.toString(-1));
		luaState.pop(1);

		final int[] conversions = new int[1];
		final Converter delegate = DefaultConverter.getInstance();
		luaState.setConverter(new Converter() {
			public int getTypeDistance(LuaState state, int index, Class<?> formalType) {
				return delegate.getTypeDistance(state, index, formalType);
			}

			public <T> T convertLuaValue(LuaState state, int index, Class<T> formalType) {
				return delegate.convertLuaValue(state, index, formalType);
			}

			public void convertJavaObject(LuaState state, Object object) {
				if (object instanceof Integer) {
					conversions[0]++;
				}
				delegate.convertJavaObject(state, object);
			}
		});
		luaState.load("return values:size()", "=primitive");
		luaState.call(0, 1);
		assertEquals(0, luaState.toInteger(-1));
		luaState.pop(1);
		assertTrue(conversions[0] > 0);
	}
}
