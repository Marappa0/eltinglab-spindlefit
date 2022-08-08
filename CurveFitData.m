function [data, dataNames, spindleImage] = CurveFitData(filename, threshold, GOLfactor, GOLiter, objectNum, auto, varargin)

% Inputs:
% filename -    whole pathname to the .tif file (string)
% threshold -   intensity cutoff determined by the user (between 1 and 65550)
% GOLfactor -   "game of life" factor (4 or 5 usually works best)
% GOLiter -     "game of life" iterations (beyond 6 doesn't change much)
% objectNum -   manual choice of object in question (ranked biggest to
%               smallest)
% auto -        logical; true if you want the program to automatically choose an
%               object, false for manual choice
% varargin -    variable arguments in; for single images this is empty, for
%               videos this is the frame number
% Outputs:
% data -        1 x n matrix of measurements
% dataNames -   1 x n matrix of strings corresponding to data
% spindleImage - matrix image of the current figure

% these are for testing separately as a file
% clear; clc;
% [filename, pathname] = uigetfile('*.tif');
% threshold = 55000; GOLfactor = 5; GOLiter = 3;
% [mat2, height, width, ~] = stack2Mat([pathname filename]);

% Turn file into matrix image
if nargin > 6
    [mat2, height, width, ~] = stack2Mat(filename, varargin{1});
else
    [mat2, height, width, ~] = stack2Mat(filename);
end

% Create threshold image
mat2threshold = applyThreshold(mat2, threshold, GOLfactor, GOLiter);

% count number of points and preallocate vectors
numPoints = sum(sum(mat2threshold));
c2 = zeros(numPoints, 1); r2 = zeros(numPoints, 1);
count = 1;

% list of all x's (c2) and y's (r2)
for r = 1:height
    for c = 1:width
        if mat2threshold(r,c) == 1
            r2(count) = r;
            c2(count) = c;
            count = count +1;
        end
    end
end

%% Check each point and sort into objects

% make structure arrays for each object
objects(1).xcoords(1) = c2(1);
objects(1).ycoords(1) = r2(1);

% go through each image point
for i = 2:length(c2)
    noMatch = true;

    % go through each existing object
    o = 1;
    while noMatch && o <= length(objects)

        % check each point in the object until it finds a neighbor or goes
        % through all of them
        j = length(objects(o).xcoords);
        while noMatch && j>0

            % if it finds a neighbor, add to the object
            if abs(objects(o).xcoords(j)-c2(i)) <= 2 && abs(objects(o).ycoords(j)-r2(i)) <= 2
                objects(o).xcoords = [objects(o).xcoords, c2(i)];
                objects(o).ycoords = [objects(o).ycoords, r2(i)];
                noMatch = false;
            % if not, go to next object point
            else
                j = j-1;
            end
        end

        o = o+1;

    end

    % if it goes through all the points on all the objects without a match, 
    % make a new object
    if noMatch
        objects(o).xcoords(1) = c2(i);
        objects(o).ycoords(1) = r2(i);
    end

end

%% consolidate objects

% this needs to compare every point on an object with every other point on
% other objects (not really EVERY point, but this was fast enough for my
% project)

% add numPoints field to the structure array
for o = 1:length(objects)
    objects(o).numPoints = length(objects(o).xcoords);
end

% sort the objects array from most points to least
[~,order] = sort([objects(:).numPoints], 'descend');
objects = objects(order);

startLength = length(objects)+1; % set start length to be not equal to the number of objects

% repeat this big nested loop until the number of objects is stable
while startLength ~= length(objects)

    startLength = length(objects); % start length set to number of objects
    
    o1 = 1;
    while o1 < length(objects) % going through every object...
        o2 = o1+1;
        while o2 <= length(objects) % and comparing it with every other object
            noMatch = true;
            i = length(objects(o1).xcoords);
            while noMatch && i > 0 % go through every point in object 1...
                temp1 = objects(o2).xcoords;
                temp2 = objects(o2).ycoords;
                coordTrunc = (abs(temp1-objects(o1).xcoords(i)) < 10).*(abs(temp2-objects(o1).ycoords(i)) < 10); % and compare to every point in object 2
                if sum(coordTrunc) > 0 % if any points are within a radius (10) of any object 1 points, then consolidate the coordinates and delete object 2
                    noMatch = false;
                    objects(o1).xcoords = [objects(o1).xcoords, objects(o2).xcoords];
                    objects(o1).ycoords = [objects(o1).ycoords, objects(o2).ycoords];
                    objects(o2) = [];
                end
                i = i-1;
            end
            o2 = o2+1;
        end
        o1 = o1+1;
    end

end

%% center of mass of each object

for o = 1:length(objects)
    mass = 0;
    xsum = 0;
    ysum = 0;
    for i = 1:length(objects(o).xcoords)
        mass = mass + mat2(objects(o).ycoords(i), objects(o).xcoords(i));
        ysum = ysum + mat2(objects(o).ycoords(i), objects(o).xcoords(i))*objects(o).ycoords(i);
        xsum = xsum + mat2(objects(o).ycoords(i), objects(o).xcoords(i))*objects(o).xcoords(i);
    end
    objects(o).com = [xsum/mass,ysum/mass];
end

%% test plotting
% 
% imshow(mat2, [])
% for i = 1:length(objects)
%     hold on
%     scatter(objects(i).xcoords, objects(i).ycoords,'filled')
% end
% title('Different Objects')
% 
% figure()
% 
% imshow(mat2, [])
% for i = 1:length(objects)
%     hold on
%     scatter(objects(i).com(1), objects(i).com(2),50,'red', 'filled')
% end
% title('Centers of Mass')

%% Find spindle automatically or manually

if auto % automatically choose the object
    xcen = width/2; ycen = height/2;

    if length(objects)>1
        avgObjectSize = mean([objects(1:end).numPoints]);
%         avgObjectSize = 10; % this is in case the object of interest is
%         smaller than the average size object

        minDist = width;
        for o = 1:length(objects)
            if norm([xcen, ycen]-[objects(o).com]) <= minDist && length(objects(o).xcoords) > avgObjectSize
                minDist = norm([xcen, ycen]-[objects(o).com]);
                centerObj = o;
            end
        end
        
        spindle = objects(centerObj);
    else
        spindle = objects(1); 
    end
else
    spindle = objects(objectNum); % manually choose object
end

spindleMat = zeros(height, width);

% this line and the loop should do the same thing, but the single line has
% issues. I still don't know why!
% spindleMat(spindle.ycoords, spindle.xcoords) = 1;

% set all points that are part of the chosen object to 1, otherwise 0
for i = 1:length(spindle.xcoords)
    spindleMat(spindle.ycoords(i), spindle.xcoords(i)) = 1;
end

mat2 = mat2.*spindleMat; % multiply original image by the one we just made

% imshow(spindleMat,[])
% hold on
% scatter(spindle.com(1), spindle.com(2), 'filled')

%% Find moment of inertia vectors

Ixx = 0;
Iyy = 0;
Ixy = 0;

for y = 1:height
    for x = 1:width
        Ixx = Ixx + spindleMat(y,x)*(x-spindle.com(1))^2;
        Iyy = Iyy + spindleMat(y,x)*(y-spindle.com(2))^2;
        Ixy = Ixy + spindleMat(y,x)*(x-spindle.com(1))*(y-spindle.com(2));
    end
end

tensorMat = [Ixx Ixy; Ixy Iyy];

%% Calculate eigenvectors

[v,e] = eig(tensorMat);

[~,ind] = min(sum(e));

mainvector = v(:,ind);

% figure()
% imshow(mat2,[])
% hold on
% 
% x = 1:width;
% m1 = mainvector(2)/mainvector(1);
% y = m1*(x-spindle.com(1))+spindle.com(2);
% plot(x,y,'r')
% 
% m2 = v(2,2)/v(1,2);
% y2 = m2*(x-spindle.com(1))+spindle.com(2);
% plot(x,y2,'b')

%% center (this proved unecessary and made issues)
% spindleMat = zeros(height, width);
% 
% xshift = floor(spindle.com(1)-xcen);
% yshift = floor(spindle.com(2)-ycen);
% 
% for i = 1:length(spindle.xcoords)
%     val = mat2(spindle.ycoords(i), spindle.xcoords(i));
%     spindle.xcoords(i) = spindle.xcoords(i)+xshift;
%     spindle.ycoords(i) = spindle.ycoords(i)+yshift;
%     spindleMat(spindle.ycoords(i), spindle.xcoords(i)) = val;
% end

%% banana rotate
rotAngle = atan(mainvector(1)/mainvector(2));

rotImg = imrotate(mat2, -rad2deg(rotAngle), 'bilinear', 'loose');

figure('visible', 'off'); % invisible so it doesn't create a new window every frame
hold on
imshow(rotImg, []);

%% Fit curve and find poles

% list of rotated x and y values

numPoints = sum(sum(rotImg > 0));

rotX = zeros(numPoints, 1);
rotY = zeros(numPoints, 1);

[rotHeight, rotWidth] = size(rotImg); % change height and width to new rotated image values

count = 1;
for r = 1:rotHeight
    for c = 1:rotWidth
        if rotImg(r,c) > 0
            rotX(count) = c;
            rotY(count) = r;
            count = count + 1;
        end
    end
end

% imshow(rotImg,[])

fit = polyfit(rotX,rotY, 2); % fit quadratic to rotated points

% find poles

spindle.leftPole = [min(rotX), polyval(fit, min(rotX))];
spindle.rightPole = [max(rotX), polyval(fit, max(rotX))];

%% Pole separation

poleFit = polyfit(rotX,rotY, 1);
a = poleFit(1); 
% b = poleFit(2);

poleSeparation = sqrt(a^2+1)*(max(rotX)-min(rotX));

%% Arc length

a = fit(1); b = fit(2); c = fit(3);

arc = @(t) sqrt(4*a.^2*t.^2 + 4*a*b*t + b.^2 + 1);
arclength = integral(arc, min(rotX), max(rotX));

%% Curvature

% Area metric

spindleFunc = @(x) a*x.^2 + b*x + c;

x1 = min(rotX); x2 = max(rotX); y1 = spindle.leftPole(2); y2 = spindle.rightPole(2);
m1 = (y2-y1)/(x2-x1);
poleFunc = @(x) m1*(x-x1)+y1;

hold on
fplot(spindleFunc, [min(rotX) max(rotX)])
scatter(spindle.leftPole(1), spindle.leftPole(2), 10, 'filled', 'r')
scatter(spindle.rightPole(1), spindle.rightPole(2), 10, 'filled', 'r')

areaCurve = abs(integral(poleFunc, x1, x2) - integral(spindleFunc, x1, x2));

% Maximum and average curvature metrics

maxCurve = abs(2*a);

curvature = @(x) (2*a)./(4*a^2*x.^2 + 4*a*b*x + b^2 + 1).^(3/2);

avgCurve = abs(integral(curvature, x1, x2)/(x2-x1));

dataNames = ["Pole Separation (px)", "Arc Length (px)", "Area Metric (px^2)", "Max Curvature (px^-1)", "Avg Curvature (px^-1)"];

data = [poleSeparation, arclength, areaCurve, maxCurve, avgCurve];

spindleImage = getframe().cdata; % this turns the current figure into a matrix for output

%% 3D scatter plot
% I might implement this later, but for now I am just projecting into 2D

% numPoints = sum(sum(sum(matThresh)));

% pre-allocating vectors
% x = zeros(numPoints, 1);
% y = zeros(numPoints, 1);
% z = zeros(numPoints, 1);

% find each [x,y,z] and store into vectors
% count = 1;
% for k = 1:depth
%     for i = 1:width
%         for j = 1:height
%             if matThresh(i, j, k) == 1
% 
%                 x(count) = i;
%                 y(count) = j;
%                 z(count) = k;
% 
%                 count = count+1;
%             end
%         end
%     end
% end

% scatter3(x,y,z, 'filled')
