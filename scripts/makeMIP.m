function MIP = makeMIP(reader, channel)

MIP = zeros(reader.height, reader.width, 'uint16');

for iZ = 1:reader.sizeZ

    MIP = max(MIP, getPlane(reader, iZ, channel, 1));

end

