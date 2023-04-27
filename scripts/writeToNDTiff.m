MultiDimImg = zeros(300,400,4,5,6,'uint16');
fiji_descr = ['ImageJ=1.52p' newline ...
            'images=' num2str(size(MultiDimImg,3)*...
                              size(MultiDimImg,4)*...
                              size(MultiDimImg,5)) newline... 
            'channels=' num2str(size(MultiDimImg,3)) newline...
            'slices=' num2str(size(MultiDimImg,4)) newline...
            'frames=' num2str(size(MultiDimImg,5)) newline... 
            'hyperstack=true' newline...
            'mode=grayscale' newline...  
            'loop=false' newline...  
            'min=0.0' newline...      
            'max=65535.0'];  % change this to 256 if you use an 8bit image
            
t = Tiff('test.tif','w')
tagstruct.ImageLength = size(MultiDimImg,1);
tagstruct.ImageWidth = size(MultiDimImg,2);
tagstruct.Photometric = Tiff.Photometric.MinIsBlack;
tagstruct.BitsPerSample = 16;
tagstruct.SamplesPerPixel = 1;
tagstruct.Compression = Tiff.Compression.LZW;
tagstruct.PlanarConfiguration = Tiff.PlanarConfiguration.Chunky;
tagstruct.SampleFormat = Tiff.SampleFormat.UInt;
tagstruct.ImageDescription = fiji_descr;
for frame = 1:size(MultiDimImg,5)
    for slice = 1:size(MultiDimImg,4)
        for channel = 1:size(MultiDimImg,3)
            t.setTag(tagstruct)
            t.write(im2uint16(MultiDimImg(:,:,channel,slice,frame)));
            t.writeDirectory(); % saves a new page in the tiff file
        end
    end
end
t.close() 