clearvars
clc

reader = BioformatsImage('D:\Projects\ALMC Tickets\T17229-Decker-ChromaticCorrection\data\Set 2\230407 W1 100x Argo003.nd2');

%%
Icy5 = getPlane(reader, 1, 1, 1);
Itritc = getPlane(reader, 1, 2, 1);
Idapi = getPlane(reader, 1, 4, 1);

Icy5norm = normalizeImage(Icy5);
Itritcnorm = normalizeImage(Itritc);
Idapinorm = normalizeImage(Idapi);

%%
maskcy5 = imbinarize(Icy5norm);
maskcy5 = imopen(maskcy5, strel('disk', 2));
maskcy5 = bwareaopen(maskcy5, 150);

masktritc = imbinarize(Itritcnorm);
masktritc = imopen(masktritc, strel('disk', 2));
masktritc = bwareaopen(masktritc, 150);

%Remove cross region for now
maskcy5(1067:1253, 1049:1274) = false;
masktritc(1067:1253, 1049:1274) = false;

maskcy5(:, 1:100) = false;
maskcy5(2170:end, :) = false;

masktritc(1067:1253, 1049:1274) = false;

masktritc(:, 1:100) = false;
masktritc(2170:end, :) = false;

%Also remove spots along the edge of the image

dataCy5 = regionprops(maskcy5, 'Centroid');
datatritc = regionprops(masktritc, 'Centroid');

posCy5 = cat(1, dataCy5.Centroid);
postritc = cat(1,datatritc.Centroid);

%% Register the point cloud

%Find nearest neighbors
% D = pdist2(posCy5, postritc);
% 
% M = matchpairs(D, 1.05 * max(D, [], 'all'));
% 
% sorted = postritc(M(:, 1), :);

dist = sqrt(sum((posCy5 - postritc).^2, 2));

iDel = dist > 10;

posCy5(iDel, :) = [];
postritc(iDel, :) = [];


dd = posCy5 - postritc;

figure(3)
quiver(posCy5(:, 1), posCy5(:, 2), dd(:, 1), dd(:, 2))




%%
figure(1)
showoverlay(Itritcnorm, masktritc)
hold on
plot(postritc(:, 1), postritc(:, 2), 'o')
plot(posCy5(:, 1), posCy5(:, 2), 'ro')
hold off
title('TRITC image (ref) with positions')

%%



%% Align the dots
%moving, ref
tform = fitgeotform2d(posCy5, postritc, 'polynomial', 2);

% %Correct the moving image
% moveCorr = imwarp(Icy5norm, tform);
% 
% tform = fitgeotform2d(posCy5, postritc, 'affine');

%Correct the moving image
moveCorr = imwarp(Icy5norm, tform, OutputView=imref2d(size(Itritcnorm)));

figure(2)
imshowpair(moveCorr, Itritcnorm)
title('Corrected')

figure(4)
imshowpair(Icy5norm, Itritcnorm)
title('Original')
%%
%Export images
C = imfuse(moveCorr, Itritcnorm);
imwrite(C, '20230418_chromatic_corrected.tif', 'Compression', 'none')

C = imfuse(Icy5norm, Itritcnorm);
imwrite(C, '20230418_chromatic_original.tif', 'Compression', 'none')