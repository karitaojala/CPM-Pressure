function outp32(address,byte)

global cogent;

%test for correct number of input arguments
if(nargin ~= 2)
    error('usage: outp(address,data)');
end

io32(cogent.io.ioObj,address,byte);
