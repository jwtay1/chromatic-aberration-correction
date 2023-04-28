clearvars
clc

CR = ChromaticRegistration;

CR = calculateCorrection(CR, 'D:\Work\Downloads\230407 SoRa 1x 100x Argo.nd2');

file = 'D:\Work\Downloads\For_Carolyn_20230302_slide119_1.nd2';

registerND2(CR, file, 'D:\Work\Downloads\test', ...
    'zRange', 20:23);