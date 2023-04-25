clearvars
clc

load('20230425_SoRa1x_100x_Cy5Tritc.mat')

%reader = BioformatsImage('D:\Projects\ALMC Tickets\T17229-Decker-ChromaticCorrection\data\Validation\For_Carolyn_20230302_slide119_2.nd2');
reader = BioformatsImage('D:\Projects\ALMC Tickets\T17229-Decker-ChromaticCorrection\data\Validation\20230420 Beads for alignment\20230420_W1_SoRa_1x_100nm_100x_001.nd2');

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

    fixedCy5 = imwarp(Icy5norm, tform);

    Iout = imfuse(fixedCy5, Itritcnorm);
    % imwrite(Iout, ['20230302_slide119_2\20230419_corrected_z', int2str(iZ), '.tif'], 'Compression', 'none');
    imwrite(Iout, ['corrbeads\20230420_beads_corrected_z', int2str(iZ), '.tif'], 'Compression', 'none');

    Iout = imfuse(Icy5norm, Itritcnorm);
    % imwrite(Iout, ['20230302_slide119_2\20230419_original_z', int2str(iZ), '.tif'], 'Compression', 'none');
    imwrite(Iout, ['orbeads\20230420_beads_original_z', int2str(iZ), '.tif'], 'Compression', 'none');

    % imshow(Iout)

end