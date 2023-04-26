clearvars
clc

file = 'test.tif';

nCh = numel(imfinfo(file));

colors = [1, 0, 0; 0, 1, 0; 0, 0, 1; 1, 1, 0];


for iC = 1:nCh

    I = double(imread(file, iC));
    I = (I - min(I, [], 'all'))/(max(I, [], 'all') - min(I, [], 'all'));

    Icurr(:, :, 1) = I * colors(iC, 1);
    Icurr(:, :, 2) = I * colors(iC, 2);
    Icurr(:, :, 3) = I * colors(iC, 3);

    if iC > 1

        Irgb = 0.5 * Irgb + 0.5 * Icurr;

    elseif iC == 1

        Irgb = Icurr;

    end

end

Irgb = Irgb * 5;
imshow(Irgb)
imwrite(Irgb, 'corrected.tif')

%%

reader = BioformatsImage('D:\Projects\ALMC Tickets\T17229-Decker-ChromaticCorrection\data\ArgoCalibration\230407 SoRa 1x 100x Argo.nd2');

for iC = 1:reader.sizeC

    I = double(getPlane(reader, 1, iC, 1));
    I = (I - min(I, [], 'all'))/(max(I, [], 'all') - min(I, [], 'all'));

    Icurr(:, :, 1) = I * colors(iC, 1);
    Icurr(:, :, 2) = I * colors(iC, 2);
    Icurr(:, :, 3) = I * colors(iC, 3);

    if iC > 1

        Irgb = 0.5 * Irgb + 0.5 * Icurr;

    elseif iC == 1

        Irgb = Icurr;

    end

end

Irgb = Irgb * 5;
imshow(Irgb)
imwrite(Irgb, 'original.tif')






