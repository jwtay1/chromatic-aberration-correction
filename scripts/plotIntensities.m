clearvars
clc

zPlane = 9;

Ioriginal = imread(['20230420_beads/20230420_beads_original_z', int2str(zPlane), '.tif']);
Icorr = imread(['20230420_beads/20230420_beads_corrected_z', int2str(zPlane), '.tif']);


ff = figure;
imshow(Ioriginal);
hold on
%%
X = [55, 77, 1682 1701 2033 2051 545 569 1077 1109];
Y = [1683 1669 1544 1559 712 712 468 485 1041 1066];

% [X, Y] = ginput;
% 
for ii = 1:2:numel(X)
    
    [Cx, Cy, Por] = improfile(Ioriginal, X(ii:(ii+1)), Y(ii:(ii+1)));
    [Cx, Cy, Pcorr] = improfile(Icorr, X(ii:(ii+1)), Y(ii:(ii+1)));
    
    dist = [0; cumsum(sqrt(sum((diff([Cx, Cy])).^2, 2)))];

    fh = figure;
    plot(dist, Por(:, :, 1), 'm-', dist, Por(:, :, 2), 'g-', ...
       dist, Pcorr(:, :, 1), 'm--', dist, Pcorr(:, :, 2), 'g--')
    saveas(gcf, ['profile_bead_', int2str(ii)], 'jpg')
    close(fh)

    figure(ff)
    plot(X(ii:(ii + 1)), Y(ii:(ii + 1)),'w')
    text(X(ii), Y(ii) + 20, int2str(ii), 'Color', 'yellow')


end
saveas(gcf, ['bead_z_9', int2str(ii)], 'jpg')
