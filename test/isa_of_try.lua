local lschema = require('lschema');
local myschema = lschema.new('myschema');
local isa;

-- set enum
myschema.enum 'myenum' {
    'name1',
    'name2'
}

myschema.struct 'mystruct' {
    field = myschema.isa('string')
};

-- isa type
for _, typ in ipairs({
    'string',
    'number',
    'unsigned',
    'int',
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
    isa = myschema.isa( typ );
    if typ == 'enum' then
        ifNotTrue(isolate(function()
            isa:of( myschema.enum.myenum );
        end));
    elseif typ == 'struct' then
        ifNotTrue(isolate(function()
            isa:of( myschema.struct.mystruct );
        end));
    -- does not support a of attribute
    else
        -- attempted to access to undefined value
        ifTrue(isolate(function()
            local fn = isa.of;
        end));
    end
    
    -- array
    -- does not support array
    if typ == 'table' then
        ifTrue(isolate(function()
            isa = myschema.isa( typ .. '[]' );
        end));
    else
        isa = myschema.isa( typ .. '[]' );
        if typ == 'enum' then
            ifNotTrue(isolate(function()
                isa:of( myschema.enum.myenum );
            end));
        elseif typ == 'struct' then
            ifNotTrue(isolate(function()
                isa:of( myschema.struct.mystruct );
            end));
        -- does not support a of attribute
        else
            -- attempted to access to undefined value
            ifTrue(isolate(function()
                local fn = isa.of;
            end));
        end
    end
end
