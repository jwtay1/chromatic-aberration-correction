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

            %Parse inputs
            ip = inputParser;
            addParameter(ip, 'ReferenceChannel', 1);
            addParameter(ip, 'CalibImageType', 'dots');
            addParameter(ip, 'Debug', false);
            parse(ip, varargin{:});


            for iFile = 1:numel(files)

                %Create a BioformatsImage object
                reader = BioformatsImage(fullfile(files(iFile).folder, files(iFile).name));

                Iref = getPlane(reader, 1, ip.Results.ReferenceChannel, 1);

                refMask = obj.segmentObjects(Iref);
                dataRef = regionprops(refMask, 'Centroid');
                
                for iC = 1:reader.sizeC

                    if iC == ip.Results.ReferenceChannel || strcmpi(reader.channelNames{iC}, ip.Results.ReferenceChannel)
                        continue
                    end

                    I = getPlane(reader, 1, iC, 1);

                    switch lower(ip.Results.CalibImageType)

                        case 'dots'
                            %Calibration image contains bright dots (e.g.,
                            %using a calibration target)

                            mask = obj.segmentObjects(I);

                            %Measure the data
                            data = regionprops(mask, 'Centroid');
                            
                            %Remove any mismatched positions
                            [ptsAout, ptsBout] = obj.matchPoints(cat(1, data.Centroid), cat(1, dataRef.Centroid));

                            if ip.Results.Debug
                                %Quiver plot for debugging
                                dd = ptsAout - ptsBout;
                                quiver(ptsAout(:, 1), ptsBout(:, 2), dd(:, 1), dd(:, 2))
                                keyboard
                            end

                            
                            % 
                            % dist = sqrt(sum((cat(1, data.Centroid) - cat(1, dataRef.Centroid)).^2, 2));
                            % 
                            % iDel = dist > 10;
                            % 
                            % data(iDel, :) = [];
                            % dataRef(iDel, :) = [];

                            %Check that we have a sufficient number of
                            %control points
                            if size(ptsAout, 1) < 10
                                error('ChromaticRegistration:calculateCorrection:InsufficientControlPoints', ...
                                    'At least 10 data points are required to obtain correction.')

                            elseif size(ptsAout, 1) ~= size(ptsBout, 1)
                                error('ChromaticRegistration:calculateCorrection:UnmatchedPoints', ...
                                    'Both data and reference must have same number of control points.')

                            end



                            %Carry out the registration
                            tform = fitgeotform2d(ptsAout, ptsBout, 'polynomial', 2);

                            % %Correct the moving image
                            % moveCorr = imwarp(Icy5norm, tform);
                            %
                            % tform = fitgeotform2d(posCy5, postritc, 'affine');

                            if ip.Results.Debug
                                %Plot for debugging
                                Icorr = imwarp(I, tform, 'OutputView', imref2d(size(I)));
                                imshowpair(Icorr, Iref)
                                keyboard
                            end

                            %Store the displacement matrix
                            idx = numel(obj.corrmatrix) + 1;
                            obj.corrmatrix(idx).channel = reader.channelNames{iC};
                            obj.corrmatrix(idx).tform = tform;
                            
                    end

                end

            end

        end
        
        
        function varargout = registerImage(obj, input, varargin)
            %REGISTER  Registers an image using the calculated corrections
            %
            %  CORR = REGISTER(OBJ, IMAGE, CHANNEL) will register a given
            %  input IMAGE. The image CHANNEL should be specified as a
            %  string (e.g., 'SoRa-TRITC').

            %TODO:Add error checking

            if isa(input, 'uint16')
                %Find the correct channel
                channels = {obj.corrmatrix.channel};

                chMatch = find(ismember(channels, varargin{1}), 1, 'first');

                if isempty(chMatch)
                    %No registration found or is reference channel, so do
                    %nothing.
                    %TODO: Record reference channel and spit out error instead
                    varargout{1} = input;
                    return;
                end

                varargout{1} = imwarp(input, obj.corrmatrix(chMatch).tform, 'OutputView', imref2d(size(input)));

            elseif isa(input, 'BioformatsImage')

                for iC = 2:input.sizeC

                    I = getPlane(input, 1, iC, 1);

                    Icorr = registerImage(obj, I, input.channelNames{iC});

                    if iC == 1
                        imwrite(Icorr, 'test.tif', 'Compression', 'none');
                    else
                        imwrite(Icorr, 'test.tif', 'Compression', 'none', 'WriteMode', 'append');
                    end

                end

            end

            



            
        end

    
    
    end

    methods (Static, Hidden)

        function mask = segmentObjects(Iin)
            %SEGMENTOBJECTS  Segment fluorescent objects in an image
            %
            %  MASK = SEGMENTOBJECTS(I_IN) returns a binary mask of the
            %  bright objects.

            %Normalize image
            Inorm = double(Iin);
            Inorm = (Inorm - min(Inorm, [], 'all'))/(max(Inorm, [], 'all') - min(Inorm, [], 'all'));

            mask = imbinarize(Inorm);
            mask = imopen(mask, strel('disk', 2));
            mask = bwareaopen(mask, 150);

            %Exclude central region - we might need a better way to do this
            % mask(:, 1:100) = false;
            % mask(2170:end, :) = false;
            % 
            % mask(1067:1253, 1049:1274) = false;

        end

        function [ptsAout, ptsBout] = matchPoints(ptsA, ptsB)
            %MATCHPOINTS  Match two sets of control points
            %
            %  [Aout, Bout] = matchPoints(A, B) matches two sets of control
            %  points A and B using a nearest-neighbor approach. 

            cost = zeros(size(ptsA, 1), size(ptsB, 1));
            for ii = 1:size(ptsA, 1)
                
                cost(ii, :) = sqrt(sum((ptsA(ii,:) - ptsB).^2, 2));

            end

            M = matchpairs(cost, 10);

            ptsAout = zeros(size(M, 1), 2);
            ptsBout = zeros(size(M, 1), 2);

            for ii = 1:size(M, 1)

                ptsAout(ii, :) = ptsA(M(ii, 1), :);
                ptsBout(ii, :) = ptsB(M(ii, 2), :);

            end



            % keyboard

            





        end




    end



end