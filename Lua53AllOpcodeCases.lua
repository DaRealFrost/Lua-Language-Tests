-- Lua 5.3 opcode exercise file
--
-- This script exercises all opcodes in the Lua 5.3 VM (47 total).
-- It is designed to run under a Lua 5.3 interpreter and print
-- "PASSED" if everything completes without error.
--
-- Lua 5.3 retains the 5.2 instruction set and adds integer floor
-- division (IDIV) and bitwise operations (BAND, BOR, BXOR, SHL,
-- SHR, BNOT).
--
-- Opcode checklist (47):
--   MOVE, LOADK, LOADKX(*), LOADBOOL, LOADNIL,
--   GETUPVAL, GETTABUP, GETTABLE, SETTABUP, SETUPVAL,
--   SETTABLE, NEWTABLE, SELF,
--   ADD, SUB, MUL, MOD, POW, DIV, IDIV,
--   BAND, BOR, BXOR, SHL, SHR,
--   UNM, BNOT, NOT, LEN, CONCAT,
--   JMP, EQ, LT, LE, TEST, TESTSET,
--   CALL, TAILCALL, RETURN,
--   FORLOOP, FORPREP, TFORCALL, TFORLOOP,
--   SETLIST, CLOSURE, VARARG, EXTRAARG(*)
--
-- (*) LOADKX and EXTRAARG require a constant pool exceeding 2^18
--     entries (262144+ constants).  They cannot be exercised in a
--     source file of reasonable size.

local u1, u2, u3                     -- upvalue slots

-- give u2 a non-nil value so table-key use won't error
u2 = 42

local function f1(a1, a2, ...)
    -- MOVE: register-to-register copy
    local l0 = a1                    -- MOVE

    -- LOADK: load constant into register
    local l1 = 1                     -- LOADK (integer)
    local l2 = "hello"              -- LOADK (string)

    -- LOADBOOL: load boolean (B = value, C = skip flag)
    local l3 = true                  -- LOADBOOL B(1) C(0)
    local l4 = false                 -- LOADBOOL B(0) C(0)
    -- LOADBOOL with C=1 (skip next instruction) via comparison result
    local cmp = (l1 == 1)            -- EQ + JMP + LOADBOOL(C=1) + LOADBOOL(C=0)

    -- LOADNIL: set a range of registers to nil
    local n1, n2, n3                 -- LOADNIL

    -- GETTABUP: index an upvalue table (_ENV for globals)
    local printfn = _ENV["print"]    -- GETTABUP
    local ipairsfn = _ENV["ipairs"]  -- GETTABUP
    local tostringfn = _ENV["tostring"] -- GETTABUP

    -- SETTABUP: set field in upvalue table
    _ENV["_test53"] = true           -- SETTABUP

    -- GETUPVAL / SETUPVAL: direct upvalue access
    local up = u2                    -- GETUPVAL
    u2 = l1                          -- SETUPVAL

    -- NEWTABLE: create empty table
    local t = {}                     -- NEWTABLE

    -- SETTABLE / GETTABLE: table write/read with register key
    t[l1] = l2                       -- SETTABLE
    local g1 = t[l1]                 -- GETTABLE

    -- NEWTABLE + SETLIST: table constructor with array part
    local list = { 10, 20, 30 }      -- NEWTABLE / SETLIST

    -- SELF: method-call sugar (obj:method())
    t.f = function(self) return self end -- CLOSURE / SETTABLE
    local s = t:f()                  -- SELF / CALL

    -- ADD / SUB / MUL / DIV / MOD / POW: binary arithmetic (from 5.2)
    local v = l1
    v = v + 2                        -- ADD
    v = v - 1                        -- SUB
    v = v * 3                        -- MUL
    v = v / 2                        -- DIV
    v = v % 5                        -- MOD
    v = v ^ 2                        -- POW

    -- IDIV: integer floor division (new in 5.3)
    local iv = 100
    iv = iv // 7                     -- IDIV

    -- BAND / BOR / BXOR / SHL / SHR: bitwise binary (new in 5.3)
    iv = iv & 0xFF                   -- BAND
    iv = iv | 0x10                   -- BOR
    iv = iv ~ 0x05                   -- BXOR
    iv = iv << 2                     -- SHL
    iv = iv >> 1                     -- SHR

    -- BNOT: bitwise not (new in 5.3)
    iv = ~iv                         -- BNOT

    -- UNM: unary minus
    local neg = -v                   -- UNM

    -- NOT: logical not
    local nb = not l3                -- NOT

    -- LEN: length operator
    local ln = #list                 -- LEN

    -- CONCAT: string concatenation
    local c = l2 .. l2               -- CONCAT

    -- EQ + JMP: equality test
    if l1 == 1 then end              -- EQ / JMP

    -- LT + JMP: less-than
    if l1 < 2 then end              -- LT / JMP

    -- LE + JMP: less-or-equal
    if l1 <= 1 then end             -- LE / JMP

    -- TEST: truthiness test (if R(A) then ...)
    if l3 then v = 1 end            -- TEST / JMP

    -- TESTSET: conditional assignment (x = a or b)
    local ts = l4 or l1              -- TESTSET

    -- FORPREP / FORLOOP: numeric for-loop
    local sum = 0
    for i = 1, 5 do                 -- FORPREP / FORLOOP
        sum = sum + i
    end

    -- TFORCALL / TFORLOOP: generic for-loop with iterator
    for k, val in ipairsfn(list) do  -- TFORCALL / TFORLOOP
        sum = sum + val
    end

    -- VARARG: access variadic arguments
    local va1, va2 = ...             -- VARARG

    -- CLOSURE: create a new closure capturing upvalues
    local function inner()           -- CLOSURE
        return va1, u1               -- GETUPVAL / RETURN
    end
    inner()                          -- CALL

    -- RETURN
    return sum
end

-- exercise CALL
f1(1, 2, 3, 4)

-- exercise TAILCALL
local function tail(x)
    return f1(x, 0)                 -- TAILCALL
end
tail(1)

-- clean up test global
_ENV["_test53"] = nil

print("PASSED")
