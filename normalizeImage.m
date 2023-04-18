function Inorm = normalizeImage(I)

I = double(I);

Inorm = (I - min(I, [], 'all'))/(max(I, [], 'all') - min(I, [], 'all'));