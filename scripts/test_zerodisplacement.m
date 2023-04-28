%What displacement field will return the same image?

clearvars
clc

reader = BioformatsImage('D:\Projects\ALMC Tickets\T17229-Decker-ChromaticCorrection\data\ArgoCalibration\230407 SoRa 1x 100x Argo.nd2');

I = getPlane(reader, 1, 1, 1);

I = normalizeImage(I);

mask = imbinarize(I);
mask = imopen(mask, strel('disk', 2));
mask = bwareaopen(mask, 150);

data = regionprops(mask, 'Centroid');

pos = cat(1, data.Centroid);

tform = fitgeotform2d(pos, pos, 'polynomial', 2);

%U = A(1) + A(2).*X + A(3).*Y + A(4).*X.*Y + A(5).*X.^2 + A(6).*Y.^2

tformZero = images.geotrans.PolynomialTransformation2D([0 1 0 0 0 0], [0 0 1 0 0 0]);

Icorr = imwarp(I, tformZero, 'OutputView', imref2d(size(I)));

imshowpair(Icorr, I)

nnz(round(Icorr(:), 14, 'significant') == round(I(:), 14, 'significant'))

max(max(Icorr - I))

figure;
imshow(Icorr - I, [])


fixedPts = [10 20; 10 5; 2 3; 1 1; 8 10; 10 10];
[
movingPointsEstimated = transformPointsInverse(tformPolynomial,fixedPts)

