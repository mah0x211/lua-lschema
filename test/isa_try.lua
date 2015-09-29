local lschema = require('lschema');
local schema = lschema.new('test');
local isa = schema.isa;

-- isa type
for _, typ in ipairs({
    'string',
    'number',
    'int8',
    'int16',
    'int32',
    'uint8',
    'uint16',
    'uint32',
    'boolean',
    'table',
    'enum',
    'struct'
}) do
    ifNotTrue(isolate(function()
        isa( typ );
    end));
    -- does not support table array
    if typ == 'table' then
        ifTrue(isolate(function()
            isa( typ .. '[]' );
        end));
    else
        ifNotTrue(isolate(function()
            isa( typ .. '[]' );
        end));
    end
end
