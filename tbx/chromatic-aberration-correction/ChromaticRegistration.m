classdef ChromaticRegistration
    %CHROMATICREGISTRATION  Calculate and correct chromatic aberrations
    %
    %  CR = CHROMATICREGISTRATION creates a new CHROMATICREGISTRATION
    %  object. This object can be used to calculate a correction for
    %  chromatic aberration for microscopy.
    %
    %  To obtain the correction, you need to image fiducial markers (i.e.,
    %  either an image of multi-color beads or dots). The object then
    %  calculates a displacement matrix using the positions of these
    %  markers using control point registration.

    properties (SetAccess = private)

        calibrations        %Store calibration information
        refchannel = '';    %Store the reference channel

    end

    properties (Dependent)

        channelsAvailable   %List of calibrated channels

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
            %  correction for the chromatic aberration. PATH is the
            %  file path to a single ND2 image file containing images of
            %  dots or beads for calibration. 
            %
            %  OBJ = CALCULATECORRECTION(OBJ, PATH, 'ReferenceChannel', CH)
            %  will set the name of the reference channel. CH can be a
            %  number or a string of the channel name.
            % 
            %  The calibration images must have the same channels using the
            %  same optical configurations that you intend to image later.
            %  Additionally, the images must have at least 10 objects that
            %  can be used for the registration.
            % 
            %  The calibrations are calculated by fitting the detected
            %  locations of the points using a 2D geometric transformation.
            %  The calculated correction matrices will be stored in the
            %  calibrations property in OBJ.

            %Check that filepath is valid
            if exist(filepath, 'file')

                [files.folder, fn, ext] = fileparts(filepath);
                files.name = [fn, ext];

            else
                error('ChromaticRegistration:calculateCorrection:InvalidPath', ...
                    '%s is not a valid file.', filepath)
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

                        %Check that the reference channel actually exists
                        if ~ismember(ip.Results.ReferenceChannel, reader.channelNames)
                            error('ChromaticRegistration:calculateCorrection:RefChannelMissing', ...
                                '%s: The specified reference channel %s was not found in the ND2 file.', ...
                                files(iFile).name, obj.refchannel)
                        end

                        obj.refchannel = ip.Results.ReferenceChannel;
                    end
                end

                %---Start processing calibration file---%

                %Get the reference channel image
                Iref = getPlane(reader, 1, obj.refchannel, 1);

                %Calculate the correction for each channel in the
                %calibration image
                for iC = 1:reader.sizeC

                    if strcmpi(reader.channelNames{iC}, ip.Results.ReferenceChannel)

                        %Set the reference channel transformation to the identity matrix
                        tform = images.geotrans.PolynomialTransformation2D([0 1 0 0 0 0],[0 0 1 0 0 0]);

                    else
                        %Get image
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
                        end
                    end

                    %Store the calibration information
                    idx = numel(obj.calibrations) + 1;
                    obj.calibrations(idx).channel = reader.channelNames{iC};
                    obj.calibrations(idx).tform = tform;

                    %Store information about the acquisition. This is
                    %unused right now, but could be used to combine
                    %calibrations in the future.
                    obj.calibrations(idx).config = obj.getOptConfig(reader);

                end
            end

        end

        function registerND2(obj, filepath, outputDir, varargin)
            %REGISTERND2  Register an ND2 file and export the data
            %
            %  REGISTERND2(OBJ, FILE, OUTPUTDIR) will register images in
            %  the specified ND2 file and export the results as a
            %  multi-dimensional TIFF file in the OUTPUTDIR specified.
            %  OUTPUTDIR can be left blank to save the file in the current
            %  directory. The TIFF file is compatible with Fiji/ImageJ's
            %  BioFormats reader.
            %
            %  Note that the output TIFF file must be opened using
            %  BioFormats Importer in Fiji (File > Import > Bio-Formats).
            %  This is because ImageJ does not natively support the TIFF
            %  baseline specifications. If you do not use this importer,
            %  different frames in the image may appear to be "shifted".

            %Check if calibrations exist
            if isempty(obj.calibrations)
                error('ChromaticRegistration:registerND2:CalibrationsDoNotExist', ...
                    'No calibrations exist in object. Run calculateCorrection first.')            
            end

            if ~exist(filepath, 'file')
                error('ChromaticRegistration:registerND2:InvalidFile', ...
                    '%s does not exist.', filepath)  
            end

            if ~exist('outputDir', 'var')
                outputDir = '';
            end

            %Create output directory if it doesn't exist
            if ~exist(outputDir, 'dir')
                mkdir(outputDir);
            end

            %Open a reader
            reader = BioformatsImage(filepath);

            %Process inputs
            ip = inputParser;
            addParameter(ip, 'zRange', 1:reader.sizeZ);
            addParameter(ip, 'cRange', 1:reader.sizeC);
            addParameter(ip, 'tRange', 1:reader.sizeT);
            parse(ip, varargin{:})

            %Create the ImageDescription string
            imgDescStr = obj.makeImageDescription_Fiji(...
                numel(ip.Results.zRange), ...
                numel(ip.Results.cRange), ...
                numel(ip.Results.tRange));

            [~, fn] = fileparts(filepath);

            %Create a new TIFF
            tiffObj = Tiff(fullfile(outputDir, [fn, '.tif']), 'w');
            tagstruct.ImageLength = reader.height;
            tagstruct.ImageWidth = reader.width;
            tagstruct.Photometric = Tiff.Photometric.MinIsBlack;
            tagstruct.BitsPerSample = 16;
            tagstruct.SamplesPerPixel = 1;
            tagstruct.Compression = Tiff.Compression.None;
            tagstruct.PlanarConfiguration = Tiff.PlanarConfiguration.Chunky;
            tagstruct.SampleFormat = Tiff.SampleFormat.UInt;
            tagstruct.ImageDescription = imgDescStr;

            for iT = ip.Results.tRange                
                for iZ = ip.Results.zRange
                    for iC = 1:reader.sizeC

                        %Read in image
                        I = getPlane(reader, iZ, iC, iT);

                        %Set image tag
                        tiffObj.setTag(tagstruct);

                        %Register the image
                        Icorr = registerImage(obj, I, reader.channelNames{iC});

                        %Write the current image to TIFF
                        tiffObj.write(Icorr);

                        %Move to next page
                        tiffObj.writeDirectory();
                    end
                end
            end
            tiffObj.close();

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

                if size(Iout) ~= size(input)
                    error('Output not same size.')
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

        function imgDescStr = makeImageDescription_Fiji(sizeZ, sizeC, sizeT)
            %MAKEIMAGEDESCRIPTION  Generate image description tag
            %
            %  STR = MAKEIMAGEDESCRIPTION_FIJI(NZ,NC,NT) generates a
            %  Fiji/ImageJ compatible ImageDescription string. NZ, NC, 
            %  and NT are the number of z-planes, channels, and frames, 
            %  respectively

            %References:
            %https://www.mathworks.com/matlabcentral/answers/389765-how-can-i-save-an-image-with-four-channels-or-more-into-an-imagej-compatible-tiff-format
            %https://stackoverflow.com/questions/33405242/creating-a-stacked-tiff-file-causes-image-offset

            imgDescStr = ['ImageJ=1.52p' newline ...
                'images=' num2str(sizeZ * sizeT * sizeC) newline ...
                'channels=' num2str(sizeC) newline];

            if sizeZ > 1
                imgDescStr = [imgDescStr, ...
                    'slices=' num2str(sizeZ) newline];
            end

            if sizeT > 1
                imgDescStr = [imgDescStr, ...
                    'frames=' num2str(sizeT) newline];
            end
            
            imgDescStr = [imgDescStr, ...
                'hyperstack=true' newline...
                'mode=color' newline...
                'loop=false' newline...
                'min=0.0' newline...
                'max=65535.0' newline];

        end

    end



end