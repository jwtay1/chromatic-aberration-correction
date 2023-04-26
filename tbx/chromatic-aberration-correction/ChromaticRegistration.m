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

        calibrations
        refchannel = '';

    end
    
    properties (Dependent)

        channelsAvailable

    end
    
    methods

        function chList = get.channelsAvailable(obj)
            %Get list of calibrated channels

            if ~isempty(obj.calibrations)

                chList = {obj.calibrations.channel};

            else

                chList = '';

            end


        end

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

                %Resolve the reference channel name
                if isempty(obj.refchannel)
                    if isnumeric(ip.Results.ReferenceChannel)
                        obj.refchannel = reader.channelNames{ip.Results.ReferenceChannel};                        
                    else
                        obj.refchannel = ip.Results.ReferenceChannel;
                    end                    
                end

                %Check that the reference channel exists
                if ~ismember(obj.refchannel, reader.channelNames)
                    warning('ChromaticRegistration:calculateCorrection:RefChannelMissing', ...
                        '%s: The specified reference channel %s was not found in the ND2 file.', ...
                        files(iFile).name, obj.refchannel)
                    continue;
                end

                %Get the reference channel image
                Iref = getPlane(reader, 1, obj.refchannel, 1);

                %Calculate the correction for each channel in the
                %calibration image
                for iC = 1:reader.sizeC

                    if strcmpi(reader.channelNames{iC}, ip.Results.ReferenceChannel)
                        %Skip processing if it's the reference channel
                        continue
                    end

                    I = getPlane(reader, 1, iC, 1);

                    switch lower(ip.Results.CalibImageType)

                        case 'dots'
                            %Calibration image contains bright dots (e.g.,
                            %using a calibration target)
                            
                            if ~exist('dataRef', 'var')
                                refMask = obj.segmentObjects(Iref);
                                dataRef = regionprops(refMask, 'Centroid');
                            end

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

                            if ip.Results.Debug
                                %Plot for debugging
                                Icorr = imwarp(I, tform, 'OutputView', imref2d(size(I)));
                                imshowpair(Icorr, Iref)
                                keyboard
                            end
                           %TODO: Store the optical magnification settings
                    end

                    %Store the calibration information
                    idx = numel(obj.calibrations) + 1;
                    obj.calibrations(idx).channel = reader.channelNames{iC};
                    obj.calibrations(idx).tform = tform;

                    obj.calibrations(idx).config = obj.getOptConfig(reader);

                    % %Populate metadata if it exists
                    % if ~isempty(config)
                    % 
                    %     if isfield(config, 'objectiveName')
                    %         obj.calibrations(idx).objectiveName = config.objectiveName;
                    %     end
                    % 
                    %     if isfield(config, 'isSoRa')
                    %         obj.calibrations(idx).isSoRa = config.isSoRa;
                    %     end
                    % 
                    %     if isfield(config, 'SoRaZoom')
                    %         obj.calibrations(idx).SoRaZoom = config.SoRaZoom;
                    %     end
                    % 
                    % end

                end

            end

        end
        
        function Icorr = registerND2(obj, input, iZ, iC, iT, varargin)
            %REGISTERND2  Register an ND2 file and export the data
            %

            %Read in the metadata and see if we can match the correction
            config = getOptConfig(reader);

            %Process each color channel
            for iC = 1:input.sizeC

                %Read in image
                I = getPlane(input, 1, iC, 1);

                Icorr = registerImage(obj, I, input.channelNames{iC}, config);

                if iC == 1
                    imwrite(Icorr, 'test.tif', 'Compression', 'none');
                else
                    imwrite(Icorr, 'test.tif', 'Compression', 'none', 'WriteMode', 'append');
                end

            end
        end

        
        function Iout = registerImage(obj, input, channel, varargin)
            %REGISTER  Registers an image using the calculated corrections
            %
            %  CORR = REGISTER(OBJ, IMAGE, CHANNEL) will register a given
            %  input IMAGE. The image CHANNEL should be specified as a
            %  string (e.g., 'SoRa-TRITC'). Note that the calibration must
            %  exist for the given input channel, otherwise the function
            %  will throw an error.
            %
            %  CORR = REGISTER(OBJ, IMAGE, CHANNEL) will register a given
            %  input IMAGE. The image CHANNEL should be specified as a
            %  string (e.g., 'SoRa-TRITC'). Note that the calibration must
            %  exist for the given input channel, otherwise the function
            %  will throw an error.

            %Validate inputs
            if ~isnumeric(input)
                error('ChromaticRegistration:registerImage:InputNotNumeric', ...
                    'The input is not an image.')
            end

            if ~exist('channel', 'var')
                error('ChromaticRegistration:registerImage:MissingChannel', ...
                    'The channel of the input image must be specified.')
            end

            if ~ischar(channel) && ~isstring(channel)
                error('ChromaticRegistration:registerImage:ChannelNotText', ...
                    'Input image channel must be specified as a char array or string.')
            end

            %TODO: Handle the differrent objectives? 
            
            %Check if channel is reference
            if strcmp(channel, obj.refchannel)

                %Do nothing
                Iout = input;
            else

                %Find the correct calibration matrix
                chMatch = find(ismember(obj.channelsAvailable, channel), 1, 'first');

                if isempty(chMatch)
                    %No registration found or is reference channel, so do
                    %nothing.
                    error('ChromaticRegistration:registerImage:CalibrationNotFound', ...
                        'Calibration matrix for channel %s was not found.', channel);                    
                end

                Iout = imwarp(input, obj.calibrations(chMatch).tform, 'OutputView', imref2d(size(input)));

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
            %  points A and B using the Hungarian linear assignment
            %  algorithm. The maximum matching distance is set to 10.

            %Calculate the distance between each set of points in A and B
            cost = zeros(size(ptsA, 1), size(ptsB, 1));
            for ii = 1:size(ptsA, 1)
                
                cost(ii, :) = sqrt(sum((ptsA(ii,:) - ptsB).^2, 2));

            end

            M = matchpairs(cost, 10);

            %Populate the paired output matrices
            ptsAout = zeros(size(M, 1), 2);
            ptsBout = zeros(size(M, 1), 2);

            for ii = 1:size(M, 1)
                ptsAout(ii, :) = ptsA(M(ii, 1), :);
                ptsBout(ii, :) = ptsB(M(ii, 2), :);
            end

        end

        function output = getOptConfig(reader)

            if ~isempty(reader.globalMetadata)

                %Try and find objective settings
                md = char(reader.globalMetadata);

                objName = extractBetween(md, 'wsObjectiveName=', ',');

                %CameraSettings
                %sOpticalConfigName
                if ~isempty(objName)
                    output.objectiveName = objName{1};
                end

                %Check if the SoRa is in use. If so, get the
                %magnification
                optConfig = extractBetween(md, 'sOpticalConfigName=', ',');

                if ~isempty(objName)
                    if any(strfind(optConfig{:}, 'SoRa'))
                        output.isSoRa = true;

                        %Look for the magnification
                        SoRaZoom = extractBetween(md, 'dZoom=', ',');

                        output.SoRaZoom = SoRaZoom{:};

                    else

                        output.isSoRa = false;
                        output.SoRaZoom = '';

                    end
                end

            else

                output = [];

            end

        end


    end



end