classdef ChromaticRegistration
    %CHROMATICREGISTRATION  Calculate and correct chromatic aberrations
    %
    %  CR = CHROMATICREGISTRATION creates a new CHROMATICREGISTRATION
    %  object. This object can be used to calculate a correction for
    %  chromatic aberration for microscopy.
    %
    %  To obtain the correction, you need to image fiducial markers (i.e.,
    %  either an image of multi-color beads or dots). The object then
    %  calculates a displacement matrix.

    properties (SetAccess = private)

        corrmatrix


    end
    
    
    methods

        function obj = calculateCorrection(obj, filepath, varargin)
            %CALCULATECORRECTION  Calculate aberration correction 
            %
            %  OBJ = CALCULATECORRECTION(OBJ, PATH) will compute the
            %  correction for the chromatic aberration. PATH can be the
            %  file path to a single ND2 image file or a directory
            %  containing ND2 files. The calculated correction matrices
            %  will be stored in the corrmatrix property.
            
            %Check that filepath is valid
            if exist(filepath, 'file')                

                [files.folder, fn, ext] = fileparts(filepath);
                files.name = [fn, ext];

            elseif exist(filepath, 'dir')

                %TBD

            else
                error('ChromaticRegistration:calculateCorrection:InvalidPath', ...
                    [filepath, 'is not a valid file or folder.'])
            end

            for iFile = 1:numel(files)

                %Create a BioformatsImage object
                reader = BioformatsImage(fullfile(files(iFile).folder, files(iFile).name));

                for iC = 1:reader.sizeC

                    I = getPlane(reader, 1, iC, 1);

                    



                end

            end

        end
        
        function obj = register(obj, filepath)

        end

    
    
    end



end