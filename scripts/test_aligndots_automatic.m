clearvars
clc

%reader = BioformatsImage('D:\Projects\ALMC Tickets\T17229-Decker-ChromaticCorrection\data\Set 2\230407 W1 100x Argo003.nd2');
reader = BioformatsImage('D:\Projects\ALMC Tickets\T17229-Decker-ChromaticCorrection\data\Set 2\230407 SoRa 1x 100x Argo.nd2');

%%
Icy5 = getPlane(reader, 1, 1, 1);
Itritc = getPlane(reader, 1, 2, 1);
Idapi = getPlane(reader, 1, 4, 1);

Icy5norm = normalizeImage(Icy5);
Itritcnorm = normalizeImage(Itritc);
Idapinorm = normalizeImage(Idapi);

%% Align the dots
%moving, ref
[optimizer,metric] = imregconfig("monomodal");

%tform = imregtform(Icy5norm, Itritcnorm, 'similarity', optimizer, metric);
[tform, moveCorr] = imregdemons(Icy5norm, Itritcnorm, [500 400 200], 'AccumulatedFieldSmoothing', 1.3);

% %Correct the moving image
% moveCorr = imwarp(Icy5norm, tform);
% 
% tform = fitgeotform2d(posCy5, postritc, 'affine');

%Correct the moving image
%moveCorr = imwarp(Icy5norm, tform, 'OutputView', imref2d(size(Itritcnorm)));

figure(2)
imshowpair(moveCorr, Itritcnorm)
title('Corrected')

figure(4)
imshowpair(Icy5norm, Itritcnorm)
title('Original')
%%
% %Export images
% C = imfuse(moveCorr, Itritcnorm);
% imwrite(C, '20230418_chromatic_corrected.tif', 'Compression', 'none')
% 
% C = imfuse(Icy5norm, Itritcnorm);
% imwrite(C, '20230418_chromatic_original.tif', 'Compression', 'none')
% 
save('20230425_SoRa1x_100x_Cy5Tritc.mat', 'tform')
