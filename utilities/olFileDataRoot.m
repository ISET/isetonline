function dataRoot = olFileDataRoot(varargin)
%IADATAROOT Get root of our Data Files
%   This is where we look for data that is too large to fit in our
%   repo. Typically it will be on a network file server, although
%   for performance cloning it and setting your pref to use the cloned
%   version is certainly possible.


p = inputParser();
addParameter(p, 'local', false); % Use a local cache for performance
addParameter(p, 'type', 'filedata');

% convert our args to ieStandard and parse
varargin = ieParamFormat(varargin);
p.parse(varargin{:});

if ispc
    % Arbitrary mount points
    if p.Results.local == true
        dataDrive = 'v:';
    else
        dataDrive = 'y:';
    end
end

switch (p.Results.type)
    case 'filedata'
        dataRoot = getpref('isetauto', 'filedataroot', '');

    case {'resources', 'Resources'}
        % These are a bit of a guess, but based on acorn fs
            if ispc
                dataRoot = fullfile(dataDrive, 'data','iset','Resources');
            else
                dataRoot = fullfile(filesep, 'acorn','data','iset','Resources');
            end
    case 'PBRT_assets'
        if ispc
            dataRoot = fullfile(dataDrive, 'iset','isetauto', 'PBRT_assets');
        else
            dataRoot = fullfile(filesep, 'acorn','data','iset','isetauto', 'PBRT_assets');
        end
end
