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

        function testWarning_calculateCorrection_RefChannelMissing(testCase)

            %Create a new object
            obj = ChromaticRegistration;

            verifyWarning(testCase, ...
                calculateCorrection(obj, ...
                'D:\Projects\ALMC Tickets\T17229-Decker-ChromaticCorrection\data\ArgoCalibration\230407 SoRa 1x 100x Argo.nd2', ...
                'ReferenceChannel', 'NotAChannel'), ...
                'ChromaticRegistration:calculateCorrection:RefChannelMissing');

        end

    end


end