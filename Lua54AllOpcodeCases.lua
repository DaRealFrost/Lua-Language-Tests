-- Lua 5.4 opcode exercise file
--
-- Lua 5.4 significantly expands the instruction set compared to
-- previous releases.  In addition to the 5.3 integer and bitwise
-- operations, it introduces dedicated opcodes for loading small
-- integers (`OP_LOADI`) and floats (`OP_LOADF`), boolean literals
-- (`OP_LOADTRUE`, `OP_LOADFALSE`, `OP_LFALSESKIP`), field and
-- integer table access (`GETFIELD`, `SETFIELD`, `GETI`, `SETI`),
-- incremental addition (`ADDI`) and many variants of arithmetic
-- instructions using either register or constant operands.  There
-- are also instructions for to‑be‑closed variables (`TBC`),
-- specialised returns (`RETURN0`, `RETURN1`), new generic for
-- loop prep (`TFORPREP`) and vararg prep (`VARARGPREP`).  This
-- script attempts to exercise as many of these as feasible in one
-- place.  Comments next to each line indicate the intended opcode.

local u1, u2, u3

local function f1(a1, a2, ...)
    -- integer and float loads
    local li = 42                    -- LOADI
    local lf = 3.14                  -- LOADF
    local bigconst = 9e9             -- LOADK/LOADKX depending on constant pool
    -- booleans and nil
    local bfalse = false             -- LOADFALSE
    local btrue  = true              -- LOADTRUE
    local bskip = false
    if not bskip then bskip = true end -- LFALSESKIP
    local lnil = nil                 -- LOADNIL
    -- environment/global access
    local env = _ENV
    local printfn = env["print"]     -- GETTABUP
    env["dummy"] = printfn           -- SETTABUP
    -- upvalue access
    local up = u2                    -- GETUPVAL
    u2 = up                          -- SETUPVAL
    -- table creation and field/index operations
    local t = {}                     -- NEWTABLE
    t[li] = lf                       -- SETI (integer index)
    t[1] = li                        -- SETI
    t[up] = li                       -- SETTABLE (generic)
    t.x = lf                         -- SETFIELD (string key)
    local ti = t[1]                  -- GETI
    local tv = t[li]                 -- GETI
    local tx = t.x                   -- GETFIELD
    local tg = t[up]                 -- GETTABLE
    -- newtable with list and hash portions
    local list = { 1, 2, 3; y = "y" } -- NEWTABLE/SETLIST/SETTABLE
    -- self/method call
    if t.method then
        local r = t:method()         -- SELF / CALL
    end
    -- arithmetic with immediate operands
    li = li + 3                      -- ADDI (R[A] := R[B] + sC)
    li = li - 2                      -- ADDI with negative -> SUBI (handled by ADDI)
    li = li * 2                      -- MULK (R[A] := R[B] * K[C])
    li = li // 2                     -- IDIVK
    li = li % 3                      -- MODK
    li = li ^ 2                      -- POWK
    li = li & 7                      -- BANDK
    li = li | 1                      -- BORK
    li = li ~ 2                      -- BXORK
    li = li >> 1                     -- SHRI
    li = li << 2                     -- SHLI
    -- arithmetic between registers
    local a, b = 5, 3                -- LOADI, LOADI
    local sum  = a + b               -- ADD
    local diff = a - b               -- SUB
    local prod = a * b               -- MUL
    local div  = a / b               -- DIV
    local idiv = a // b              -- IDIV
    local mod  = a % b               -- MOD
    local pow  = a ^ b               -- POW
    local band = a & b               -- BAND
    local bor  = a | b               -- BOR
    local bxor = a ~ b               -- BXOR
    local shl  = a << b              -- SHL
    local shr  = a >> b              -- SHR
    -- unary operations
    local neg  = -a                  -- UNM
    local bnot = ~a                  -- BNOT
    local logicnot = not bfalse      -- NOT
    local lengtht = #list            -- LEN
    local concat = tostring(sum) .. tostring(diff) -- CONCAT
    -- comparisons: register/constant versions
    if a == b then                   -- EQ
        li = li + 1
    elseif a < b then               -- LT
        li = li + 2
    elseif a <= b then              -- LE
        li = li + 3
    end
    if a == 5 then                   -- EQI (compare register with signed imm)
        li = li + 4
    end
    if a < 5 then                    -- LTI
        li = li + 5
    end
    if a <= 5 then                   -- LEI
        li = li + 6
    end
    if a > 1 then                    -- GTI (using symmetric <=)
        li = li + 7
    end
    if a >= 1 then                   -- GEI
        li = li + 8
    end
    if a == 1.0 then                 -- EQK (compare with float constant)
        li = li + 9
    end
    -- TEST and TESTSET: use short‑circuiting expressions
    if li and btrue then             -- TEST
        li = li + 10
    end
    if li or bfalse then             -- TESTSET (sets R[A] := R[B] when truthy)
        li = li + 11
    end
    -- numeric for‑loop (FORPREP/FORLOOP)
    for i = 1, 3 do
        li = li + i
    end
    -- generic for with iterator table (TFORPREP/TFORCALL/TFORLOOP)
    for k, v in pairs(list) do
        li = li + (v or 0)
    end
    -- closure capturing upvalue
    do
        local v1, v2 = ...          -- VARARG
        local function inner()       -- CLOSURE
            return v1, v2           -- RETURN
        end
        inner()                      -- CALL
    end
    -- to‑be‑closed variable (TBC).  The `<close>` annotation signals
    -- to the compiler that the variable should be automatically
    -- closed when it goes out of scope.
    do
        local h <close> = function() end -- TBC
    end
    -- demonstrate RETURN0 and RETURN1
    local function ret0()
        return                       -- RETURN0
    end
    local function ret1(x)
        return x                    -- RETURN1
    end
    ret0()
    ret1(li)
    -- tail call to f1 to trigger TAILCALL/RETURN
    return f1                      -- RETURN (tailcall)
end

-- entry point: call f1 with a simple argument
return f1(0)