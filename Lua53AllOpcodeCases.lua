-- Lua 5.3 opcode exercise file
--
-- This script targets Lua 5.3.  It includes the opcodes from Lua 5.2
-- and demonstrates the extra integer and bitwise operations
-- introduced in 5.3, such as floor division (`//`), bitwise and/or/xor
-- and shifts.  As with the 5.2 file the goal is to produce
-- straightforward code that encourages the Lua compiler to emit
-- representative opcodes.  See the comments for guidance on which
-- instruction each line should correspond to.

local u1, u2, u3

local function f1(a1, a2, ...)
    -- moves and constants
    local l0 = a1                    -- MOVE
    local l1 = 1                     -- LOADK (integer constant)
    local l2 = true                  -- LOADBOOL
    local l3 = nil                   -- LOADNIL
    -- global environment via _ENV
    local env = _ENV
    local g = env.print              -- GETTABUP
    env.dummy = g                    -- SETTABUP
    -- upvalue operations
    l2 = u2                          -- GETUPVAL
    u2 = l2                          -- SETUPVAL
    -- table indexing and update
    local l4 = l3[l2]                -- GETTABLE
    l3[l2] = l1                      -- SETTABLE
    -- create table with array and hash parts
    local t = { l1, l2; x = l2 }     -- NEWTABLE / SETLIST / SETTABLE
    -- self call
    local l6 = t:x()                 -- SELF / CALL
    -- arithmetic including integer division and bitwise ops
    local l7 = -((l0 + l1 - l2) * l3 / (#t or 1) % l1)^l6
    local l8 = #(not l7)             -- NOT, LEN
    local l9 = l7 .. l8              -- CONCAT
    -- additional integer operations
    l7 = l7 // l1                    -- IDIV (floor division)
    l7 = l7 & 3                      -- BAND (bitwise and)
    l7 = l7 | 1                      -- BOR (bitwise or)
    l7 = l7 ~ 2                      -- BXOR (bitwise xor)
    l7 = l7 << 1                     -- SHL (bitwise shift left)
    l7 = l7 >> 2                     -- SHR (bitwise shift right)
    l7 = ~l7                         -- BNOT (bitwise not)
    -- comparisons and jumps
    if l1 == l2 and l2 < l3 or l3 <= l4 then -- EQ, LT, LE, JMP
        for i = 1, 5, 2 do
            l0 = l0 and l2          -- TEST
        end
    else
        for k, v in ipairs(t) do
            l4 = l4 or l6           -- TESTSET
        end
    end
    -- vararg and closures
    do
        local v1, v2 = ...          -- VARARG
        local function inner()       -- CLOSURE
            return v1, v2           -- RETURN
        end
        inner()                      -- CALL
    end
    -- integer constants and floats for LOADINT/LOADFLT (though 5.3 still uses LOADK)
    local i32 = 0x5678              -- integer constant
    local f64 = 370.5               -- floating constant
    -- string constants (short and long) to show `SHRSTR` and long string handling
    local short = "" .. "abc"        -- SHRSTR
    local long = [[
        12345678901234567890123456789012345678901234567890
        12345678901234567890123456789012345678901234567890
        12345678901234567890123456789012345678901234567890
        12345678901234567890123456789012345678901234567890
        12345678901234567890123456789012345678901234567890
        12345678901234567890123456789012345678901234567890
    ]] -- long string (>=255 chars) ensures LONGSTR instructions
    return f1                      -- RETURN (tailcall if optimised)
end

return f1(0)