clearvars
clc

CR = ChromaticRegistration;

CR = calculateCorrection(CR, 'D:\Projects\ALMC Tickets\T17229-Decker-ChromaticCorrection\data\ArgoCalibration\230407 SoRa 1x 100x Argo.nd2');

file = 'D:\Projects\ALMC Tickets\T17229-Decker-ChromaticCorrection\data\Validation\For_Carolyn_20230302_slide119_1.nd2';
% folder = 'D:\Projects\ALMC Tickets\T17229-Decker-ChromaticCorrection\data\Validation';

%folder = 'D:\Projects\ALMC Tickets\T17229-Decker-ChromaticCorrection\data\Nina';

registerND2(CR, file, 'nina', 'OutputFormat', 'ImarisTiff');