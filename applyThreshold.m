function thresholdImg = applyThreshold(mat, threshold, GOLfactor, GOLiter)

% Inputs:
% mat -       image matrix of values 0-65550
% threshold - cutoff value for matrix
% GOLfactor - "game of life" factor (4 or 5 usually works best)
% GOLiter -   "game of life" iterations (beyond 6 doesn't change much)
% Output:
% thresholdImg - logical matrix of the thresholded image

[height, width] = size(mat);

thresholdImg = mat > threshold;

thresholdImg(:,1) = 0;
thresholdImg(1,:) = 0;
thresholdImg(:,end) = 0;
thresholdImg(end,:) = 0;

for i = 1:GOLiter
    for r = 2:height-1
        for c = 2:width-1
            if sum(sum(thresholdImg(r-1:r+1, c-1:c+1))) < GOLfactor
                    thresholdImg(r,c) = 0;
            end
        end
    end
end

end