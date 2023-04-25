classdef ChromaticRegistrationTest < matlab.unittest.TestCase

    methods (Test)

        function test_calculateCorrection(testCase)

            %Create a new object
            obj = ChromaticRegistration;

            verifyClass(testCase, ...
                calculateCorrection(obj, ...
                'D:\Projects\ALMC Tickets\T17229-Decker-ChromaticCorrection\data\ArgoCalibration\230407 SoRa 1x 100x Argo.nd2'), ...
                'ChromaticRegistration');



        end

    end


end