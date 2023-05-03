# Welcome to the Chromatic Aberration Correction Toolbox!

This toolbox attempts to determine a correction matrix to fix chromatic 
aberration in microscope images. 

## Features
- Calculates corrections between images captured in different channels
- Applies corrections to ND2 images
- Data analysis tools to visualize the correction

## Installation and Usage

[Download](https://github.com/jwtay1/chromatic-aberration-correction/releases) the latest release. **You do not need to download this repository to use the code.** 

You will also need to download the Bioformats Image Toolbox (v1.2.1+):
* [Bioformats MATLAB](https://github.com/Biofrontiers-ALMC/bioformats-matlab/releases)

### Usage

The following script shows a minimal example to calculate the correction and to register an image file:

```matlab
%Create a new ChromaticRegistration object
CR = ChromaticRegistration;

%Calculate the correction for SoRa 1x and 100x objective
CR = calculateCorrection(CR, 'D:\230407 SoRa 1x 100x Argo.nd2');

%Apply the correction to an image, exporting as a Fiji compatible TIFF-stack
registerND2(CR, D:\For_Carolyn_20230302_slide119_1.nd2, 'D:\test');

%Save the ChromaticRegistration object for later use
save('SoRa_1x_obj_100x.mat', 'CR');
```

To export the file as a series of TIFF files compatible with Imaris, set the ``OutputFormat`` to ``ImarisTiff``:

```matlab
%Apply the correction to an image, exporting as a Fiji compatible TIFF-stack
registerND2(CR, D:\For_Carolyn_20230302_slide119_1.nd2, 'D:\test', 'OutputFormat', 'ImarisTiff');
```


## Contribute

### Bug reports and feature requests

Please use the [Issue Tracker](https://github.com/jwtay1/chromatic-aberration-correction/issues) to file a bug report or to request new features.

### Source code

- The source code can be cloned from this repository
```git
git clone git@github.com:jwtay1/chromatic-aberration-correction.git
```
- The directory of the Git repository is arranged according to the best practices described in [this MathWorks blog post](https://blogs.mathworks.com/developer/2017/01/13/matlab-toolbox-best-practices/).