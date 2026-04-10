-- Lua 5.4 opcode exercise file
--
-- This script exercises all opcodes in the Lua 5.4 VM (83 total).
-- It is designed to run under a Lua 5.4 interpreter and print
-- "PASSED" if everything completes without error.
--
-- Lua 5.4 significantly expands the instruction set.  Key additions
-- include dedicated load instructions (LOADI, LOADF, LOADFALSE,
-- LFALSESKIP, LOADTRUE), field/integer table access (GETI, GETFIELD,
-- SETI, SETFIELD), arithmetic with immediate and constant operands
-- (ADDI, ADDK, SUBK, MULK, MODK, POWK, DIVK, IDIVK, BANDK, BORK,
-- BXORK, SHRI, SHLI), to-be-closed variables (TBC), upvalue closing
-- (CLOSE), specialised returns (RETURN0, RETURN1), generic-for
-- preparation (TFORPREP), vararg preparation (VARARGPREP), and
-- comparisons with immediate/constant (EQI, EQK, LTI, LEI, GTI, GEI).
--
-- Opcode checklist (83):
--   MOVE, LOADI, LOADF, LOADK, LOADKX(*), LOADFALSE, LFALSESKIP,
--   LOADTRUE, LOADNIL, GETUPVAL, SETUPVAL, GETTABUP, GETTABLE,
--   GETI, GETFIELD, SETTABUP, SETTABLE, SETI, SETFIELD, NEWTABLE,
--   SELF, ADDI, ADDK, SUBK, MULK, MODK, POWK, DIVK, IDIVK,
--   BANDK, BORK, BXORK, SHRI, SHLI,
--   ADD, SUB, MUL, MOD, POW, DIV, IDIV,
--   BAND, BOR, BXOR, SHL, SHR,
--   MMBIN(**), MMBINI(**), MMBINK(**),
--   UNM, BNOT, NOT, LEN, CONCAT, CLOSE, TBC,
--   JMP, EQ, LT, LE, EQK, EQI, LTI, LEI, GTI, GEI,
--   TEST, TESTSET, CALL, TAILCALL,
--   RETURN, RETURN0, RETURN1,
--   FORLOOP, FORPREP, TFORPREP, TFORCALL, TFORLOOP,
--   SETLIST, CLOSURE, VARARG, VARARGPREP(**), EXTRAARG(*)
--
-- (*) LOADKX/EXTRAARG require >2^18 constants in the pool.
-- (**) MMBIN/MMBINI/MMBINK are emitted automatically after each
--      arithmetic/bitwise/concat operation for potential metamethod
--      dispatch.  VARARGPREP is emitted at the entry of every
--      vararg function.

local u1, u2, u3                     -- upvalue slots

-- give u2 a non-nil value so table-key use won't error
u2 = 99

local function f1(a1, a2, ...)       -- VARARGPREP (implicit at entry)
    -- ─── load instructions ───────────────────────────────────
    local li = 42                    -- LOADI (small integer)
    local m = li                     -- MOVE (register copy)
    local lf = 3.14                  -- LOADF (float that fits sBx encoding)
    local bigk = 9e18               -- LOADK (too large for LOADI/LOADF)
    local bfalse = false             -- LOADFALSE
    local btrue = true               -- LOADTRUE
    local lnil = nil                 -- LOADNIL

    -- LFALSESKIP: boolean result of a comparison
    -- generates: LT -> LFALSESKIP -> LOADTRUE
    local cmp = (a1 < a2)            -- LFALSESKIP + LOADTRUE (comparison-to-boolean)

    -- ─── environment / upvalue access ────────────────────────
    local printfn = _ENV["print"]    -- GETTABUP
    _ENV["_test54"] = 1              -- SETTABUP
    u2 = li                          -- SETUPVAL
    local up = u2                    -- GETUPVAL

    -- ─── table creation and access variants ──────────────────
    local t = {}                     -- NEWTABLE

    -- generic register key
    t[up] = li                       -- SETTABLE
    local tg = t[up]                 -- GETTABLE

    -- integer key (compile-time literal)
    t[1] = li                        -- SETI
    local ti = t[1]                  -- GETI

    -- string key
    t.x = lf                         -- SETFIELD
    local tx = t.x                   -- GETFIELD

    -- table constructor with array part
    local list = { 1, 2, 3; y = "y" } -- NEWTABLE / SETLIST

    -- SELF: method call sugar
    t.method = function(self) return self end -- CLOSURE / SETFIELD
    local s = t:method()             -- SELF / CALL

    -- ─── arithmetic with immediate operand ───────────────────
    li = li + 3                      -- ADDI (+ MMBINI)

    -- ─── arithmetic with constant-table operand ──────────────
    -- values outside signed-byte range [-127..128] force *K variants
    li = li + 256                    -- ADDK (256 > 128, + MMBINK)
    li = li - 256                    -- SUBK (+ MMBINK)
    li = li * 2                      -- MULK (+ MMBINK)
    local divr = li / 3              -- DIVK (+ MMBINK)
    li = li // 2                     -- IDIVK (+ MMBINK)
    li = li % 7                      -- MODK (+ MMBINK)
    local powr = li ^ 2              -- POWK (+ MMBINK)
    li = li & 0xFF                   -- BANDK (+ MMBINK)
    li = li | 0x01                   -- BORK (+ MMBINK)
    li = li ~ 0x02                   -- BXORK (+ MMBINK)
    li = li >> 1                     -- SHRI (+ MMBINI)
    li = li << 2                     -- SHLI (+ MMBINI)

    -- ─── arithmetic between registers ────────────────────────
    local a, b = 5, 3                -- LOADI, LOADI
    local rr
    rr = a + b                       -- ADD (+ MMBIN)
    rr = a - b                       -- SUB (+ MMBIN)
    rr = a * b                       -- MUL (+ MMBIN)
    rr = a / b                       -- DIV (+ MMBIN)
    rr = a // b                      -- IDIV (+ MMBIN)
    rr = a % b                       -- MOD (+ MMBIN)
    rr = a ^ b                       -- POW (+ MMBIN)
    rr = a & b                       -- BAND (+ MMBIN)
    rr = a | b                       -- BOR (+ MMBIN)
    rr = a ~ b                       -- BXOR (+ MMBIN)
    rr = a << b                      -- SHL (+ MMBIN)
    rr = a >> b                      -- SHR (+ MMBIN)

    -- ─── unary operations ────────────────────────────────────
    local neg  = -a                  -- UNM
    local bnot = ~a                  -- BNOT
    local logicnot = not bfalse      -- NOT
    local lenl = #list               -- LEN
    local cat = tostring(a) .. tostring(b) -- CONCAT

    -- ─── comparisons: register vs register ───────────────────
    if a == b then li = li + 1 end   -- EQ + JMP
    if a < b then li = li + 1 end   -- LT + JMP
    if a <= b then li = li + 1 end  -- LE + JMP

    -- ─── comparisons: immediate integer (sB) ────────────────
    if a == 5 then li = li + 1 end  -- EQI
    if a < 10 then li = li + 1 end  -- LTI
    if a <= 10 then li = li + 1 end -- LEI
    if a > 1 then li = li + 1 end   -- GTI
    if a >= 1 then li = li + 1 end  -- GEI

    -- ─── comparison: constant (K table) ─────────────────────
    local str = "test"
    if str == "test" then li = li + 1 end -- EQK

    -- ─── test / testset ──────────────────────────────────────
    if li then li = li + 1 end       -- TEST
    local ts = bfalse or li          -- TESTSET

    -- ─── numeric for ─────────────────────────────────────────
    for i = 1, 3 do                  -- FORPREP / FORLOOP
        li = li + i
    end

    -- ─── generic for (TFORPREP is new in 5.4) ───────────────
    for k, v in pairs(list) do       -- TFORPREP / TFORCALL / TFORLOOP
        li = li + (tonumber(v) or 0)
    end

    -- ─── CLOSE: close upvalues on break/goto ────────────────
    for i = 1, 1 do
        local captured = 0
        local function cap() return captured end -- CLOSURE (captures local)
        break                        -- CLOSE (close upvalue before break)
    end

    -- ─── TBC: to-be-closed variable ─────────────────────────
    do
        local h <close> = setmetatable({}, { -- TBC
            __close = function() end
        })
    end

    -- ─── vararg ──────────────────────────────────────────────
    local va1, va2 = ...             -- VARARG

    -- ─── closure ─────────────────────────────────────────────
    local function inner()           -- CLOSURE
        return va1, u1               -- GETUPVAL / RETURN
    end
    inner()                          -- CALL

    -- RETURN (multi-value)
    return li
end

-- RETURN0: function with no return values
local function ret0()
    -- (empty body, implicit return)  -- RETURN0
end

-- RETURN1: function returning exactly one value
local function ret1(x)
    return x                        -- RETURN1
end

-- exercise CALL
f1(1, 2, 3, 4)
ret0()
ret1(42)

-- exercise TAILCALL
local function tail(x)
    return f1(x, 0)                 -- TAILCALL
end
tail(1)

-- clean up test global
_ENV["_test54"] = nil

print("PASSED")
