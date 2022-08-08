function [imageMat, height, width, depth] = stack2Mat(filename, varargin)

% Inputs:
% filename - whole pathname to the .tif file (string)
% varargin - variable arguments in; for single images this is empty, for
%            videos this is the frame number
% Outputs:
% imageMat - image matrix created from the file
% height, width, depth - dimensions of imageMat

info = imfinfo(filename);

height = info.Height; width = info.Width; depth = length(info);

if nargin == 1 % .tif images or zstacks
    for i = 1:depth
        imageI = imread(filename, i);
        imageMat(:,:,i) = imageI(:,:);
    end

    if depth > 1
    
        projMat = zeros(height, width);
        
        for r = 1:height
            for c = 1:width
                projMat(r,c) = max(imageMat(r,c,:));
            end
        end
        
        imageMat = projMat;
        
    end

else % .tif videos
    imageMat = double(imread(filename, varargin{1}));
end

end