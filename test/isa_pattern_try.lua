local lschema = require('lschema');
local myschema = lschema.new('myschema');
local isa;

myschema.pattern 'email' {
    require('lschema.ddl.pattern').email
}

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
        isa:of( myschema.enum.myenum );
    elseif typ == 'struct' then
        isa:of( myschema.struct.mystruct );
    end

    -- does not support a pattern constraint
    if typ ~= 'string' then
        -- attempted to access to undefined value
        ifTrue(isolate(function()
            local fn = isa.pattern;
        end));
    else
        ifNotTrue(isolate(function()
            isa:pattern( myschema.pattern.email );
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
            isa:of( myschema.enum.myenum );
        elseif typ == 'struct' then
            isa:of( myschema.struct.mystruct );
        end

        -- does not support a pattern constraint
        if typ ~= 'string' then
            -- attempted to access to undefined value
            ifTrue(isolate(function()
                local fn = isa.pattern;
            end));
        else
            ifNotTrue(isolate(function()
                isa:pattern( myschema.pattern.email );
            end));
        end
    end
end
