local errno = require('lschema.ddl.errno');
local lschema = require('lschema');
local myschema = lschema.new('myschema');
local isa = myschema.isa('uint16');
local err, _;

isa:makeCheck();
-- invalid
for _, val in ipairs({
    -- boolean
        true, false,
    -- string
        'string', '',
    -- function
        function()end,
    -- table
        {},
    -- thread
        coroutine.create(function() end),
    -- inf
        -(1/0), 1/0,
    -- nan
        0/0,
    -- float
        0.1,
    -- negative float
        -0.1,
    -- int8
        -128,
    -- int16
        -32768,
    -- int32
        -2147483648,
    -- uint16 max + 1
        65536,
    -- uint32
        4294967295
}) do
    _, err = isa( val );
    ifNil( err );
    ifNotEqual( err.errno, errno.ETYPE );
    ifNotEqual( err.etype, 'ETYPE' );
end

-- valid
for val = 0, 65535 do
    _, err = isa( val );
    ifNotNil( err );
    ifNotEqual( _, val );
end
