function rootPath=onlineRootPath()
% Return the path to the root iset directory
%
% This function must reside in the directory at the base of the running
% version of ISETcalc's directory structure.  It is used to determine the location of various
% sub-directories.
% 
% Example:
%   fullfile(calcRootPath,'data')

rootPath=which('onlineRootPath');

[rootPath,~,~]=fileparts(rootPath);

return


