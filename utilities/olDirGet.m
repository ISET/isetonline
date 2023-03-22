function resourceDir = piDirGet(resourceType)
% Returns default directory of a resource type.
% 
% Synopsis
%   resourceDir = olDirGet(resourceType)
%
% Input
%   resourceType - One of
%     {'data','scenarios', 'samples'}

% Output
%   resourceDir
%
% Description:
%   Most of these resources are in directories within isetonline.
%
% D.Cardinal -- Stanford University -- March, 2023
% See also
%

% Example:
%{
  eiDirGet('scenarios')
  piDirGet('data')
%}

%% Parse
valid = {'data','scenarios', 'samples'};

if isequal(resourceType,'help')
    disp(valid);
    return;
end

if isempty(resourceType) || ~ischar(resourceType) || ~ismember(resourceType,valid)
    fprintf('Valid resources are\n\n');
    disp(valid);
    error("%s is not a valid resource type",resourceType);
end

%% Set these resource directories once, here, in case we ever need to change them

ourRoot = olRootPath();
ourData = fullfile(ourRoot,'data');

% Now we can locate specific types of resources
switch (resourceType)
    case 'data'
        resourceDir = ourData;
    case {'scenarios'}
        resourceDir = fullfile(ourData,'scenarios');
    case {'samples'}
        resourceDir = fullfile(ourData,'samples');
 
end


end
