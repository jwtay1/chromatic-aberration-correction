clearvars
clc

load('20230419_SoRa1x_100x_Cy5Tritc.mat')

reader = BioformatsImage('D:\Projects\ALMC Tickets\T17229-Decker-ChromaticCorrection\data\Validation\For_Carolyn_20230302_slide119_2.nd2');

%%
% Icy5 = getPlane(reader, 18, 'SoRa-Cy5', 1);
% Itritc = getPlane(reader, 18, 'SoRa-TRITC', 1);

%Icy5 = makeMIP(reader, 'SoRa-Cy5');
%Itritc = makeMIP(reader, 'SoRa-TRITC');

for iZ = 1:reader.sizeZ

    Icy5 = getPlane(reader, iZ, 'SoRa-Cy5', 1);
    Itritc = getPlane(reader, iZ, 'SoRa-TRITC', 1);

    Icy5norm = normalizeImage(Icy5);
    Itritcnorm = normalizeImage(Itritc);

    fixedCy5 = imwarp(Icy5norm, tform, OutputView=imref2d(size(Itritc)));

    Iout = imfuse(fixedCy5, Itritcnorm);
    imwrite(Iout, ['20230302_slide119_2\20230419_corrected_z', int2str(iZ), '.tif'], 'Compression', 'none');

    Iout = imfuse(Icy5norm, Itritcnorm);
    imwrite(Iout, ['20230302_slide119_2\20230419_original_z', int2str(iZ), '.tif'], 'Compression', 'none');

    % imshow(Iout)

end