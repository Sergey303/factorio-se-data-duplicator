"""Run the real Factorio data-stage Lua code under liblua5.4 with mock prototypes.
No game engine is emulated; these tests validate recipe-generation invariants only.
"""
from __future__ import annotations
import ctypes
import ctypes.util
import pathlib
import sys

LIB_PATH = ctypes.util.find_library("lua5.4")
if not LIB_PATH:
    print("SKIP: liblua5.4 not installed", file=sys.stderr)
    sys.exit(2)
lib = ctypes.CDLL(LIB_PATH)
lib.luaL_newstate.restype = ctypes.c_void_p
lib.luaL_openlibs.argtypes = [ctypes.c_void_p]
lib.luaL_loadfilex.argtypes = [ctypes.c_void_p, ctypes.c_char_p, ctypes.c_char_p]
lib.luaL_loadfilex.restype = ctypes.c_int
lib.lua_pcallk.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.c_int, ctypes.c_int, ctypes.c_longlong, ctypes.c_void_p]
lib.lua_pcallk.restype = ctypes.c_int
lib.lua_tolstring.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.c_void_p]
lib.lua_tolstring.restype = ctypes.c_char_p
lib.lua_close.argtypes = [ctypes.c_void_p]
lib.lua_createtable.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.c_int]
lib.lua_pushstring.argtypes = [ctypes.c_void_p, ctypes.c_char_p]
lib.lua_rawseti.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.c_longlong]
lib.lua_setglobal.argtypes = [ctypes.c_void_p, ctypes.c_char_p]
ROOT = pathlib.Path(__file__).resolve().parents[1]


def run(failure: int, probes: bool) -> None:
    state = lib.luaL_newstate()
    assert state
    try:
        lib.luaL_openlibs(state)
        lib.lua_createtable(state, 3, 0)
        for ix, value in enumerate([str(failure), str(probes).lower(), str(ROOT / "mod/data-final-fixes.lua")], 1):
            lib.lua_pushstring(state, value.encode())
            lib.lua_rawseti(state, -2, ix)
        lib.lua_setglobal(state, b"arg")
        status = lib.luaL_loadfilex(state, str(ROOT / "tests/mock_test.lua").encode(), None)
        if not status:
            status = lib.lua_pcallk(state, 0, -1, 0, 0, None)
        if status:
            raise AssertionError((lib.lua_tolstring(state, -1, None) or b"Unknown Lua error").decode(errors="replace"))
    finally:
        lib.lua_close(state)


if __name__ == "__main__":
    for p in (0, 1, 10, 49, 50, 99, 100):
        for probes in (False, True):
            run(p, probes)
    print("All 14 mocked Lua integration scenarios passed.")
