function oiShifted = depthShift(oi, options)
% Think about using depthmap to drive disparity
% to simulate camera motion
%
% D. Cardinal, Stanford University, 2022

arguments
    oi = oiCreate();
    options.amount = {[0 .1], [0 .2]};
end

% We have:
data  =  oi.data.photons;
depth =  oi.depthMap;

% We'll fix these for now, but should be computed
cameraShift = options.amount; % horizontal & vertical in meters
focalLength = .004; % meters -- smartphone esque
%{
In principle, the idea is to shift each pixel in the image by an
amount inversely-proportional to its depth.

I think the math is something like:

camera shift (m)     image shift (m) 
----------------  =  ----------------
object distance (m)  focal length (m)

image shift * odist = fl * camera shift
image shift = (fl * camera shift) / odist
%}

% Start with our simple OI input:
oiShifted = oi;

% So we can build a "shift array" based on depth
for aShift = 1:numel(cameraShift)
    useShift = cameraShift{aShift};
    shiftMap = zeros(size(depth,1), size(depth,2), 2);
    shiftMap(:,:,1) = (useShift(1) .* focalLength) ./ depth;
    shiftMap(:,:,2) = (useShift(2) .* focalLength) ./ depth;
    % get rid of nonsense results
    shiftMap(isinf(shiftMap)|isnan(shiftMap)) = 0; % Replace NaNs and infinite values with zeros
    % It is in meters, so we need to correct for pixels
    % We don't know our sensor yet, so need a placeholder
    shiftMap = shiftMap * 100000;

    % use our initial data as the baseline for our shift image
    shiftData = data;

    % see what happens if we don't start with fill
    shiftData(:,:,:) = 0;


    for ii = 1:size(data,1) % rows
        for iii = 1:size(data,2) % columns

            newLocation = [shiftMap(ii,iii,1) shiftMap(ii,iii,2)] + [ii iii];
            newLocation = floor(newLocation) + 1; % should grid fit!
            % only fill in slots we have
            if newLocation(1) <= size(data,1) && newLocation(2) <= size(data,2) ...
                    && newLocation(1) >= 1 && newLocation(2) >= 1
                shiftData(newLocation(1),newLocation(2),:) = data(ii,iii,:);
            end
        end
    end
    % Update our return OI with our new data
    % Copying here for debugging, can remove to save memory
    oiShifted.data.photons(:,:,:,end+1) = shiftData;

end



%{
oiWindow(oi);
oiWindow(oiShifted);
%}
%{
That leaves us with voids, that are newly-exposed areas of the scene
Assuming there is no clever pre-rendering of those, we are left
with filling them as best as we can
%}

