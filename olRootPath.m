function rootPath=olRootPath()
% Return the path to the root isetonline directory
%
% This function must reside in the directory at the base of the running
% version of ISETonlines's directory structure.  It is used to determine the location of various
% sub-directories.
% 

rootPath=which('olRootPath');

[rootPath,~, ~]=fileparts(rootPath);

return
