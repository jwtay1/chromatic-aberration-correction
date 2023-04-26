clearvars
clc

CC = ChromaticRegistration;

CC = calculateCorrection(CC, 'D:\Projects\ALMC Tickets\T17229-Decker-ChromaticCorrection\data\ArgoCalibration\230407 SoRa 1x 100x Argo.nd2', ...
    'Debug', false, ...
    'ReferenceChannel', 'SoRa-TRITC');
return





%%
reader = BioformatsImage('D:\Projects\ALMC Tickets\T17229-Decker-ChromaticCorrection\data\ArgoCalibration\230407 SoRa 1x 100x Argo.nd2');

registerImage(CC, reader);

%%

I = getPlane(reader, 1, 2, 1);
I2 = getPlane(reader, 1, 3, 1);

I1corr = registerImage(CC, I2, 'SoRa-TRITC');
I2corr = registerImage(CC, I2, 'SoRa-FITC');

figure(1)
imshowpair(I, I2)
title('Original')

figure(2)
imshowpair(I1corr, I2corr)
title('Corrected')