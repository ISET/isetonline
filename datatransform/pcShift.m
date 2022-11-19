% Experiment with Point Clouds
%  D.Cardinal, Stanford University, 2022

% Maybe mimic camera motion with point cloud
% When we have an OI with depth
% Except we undo some lens effects,
% and then redo, so might be a fidelity issue?

load('oi_001.mat', 'oi');
ph = oi.data.photons;
dp = oi.depthMap;

p = pointCloud(ph);
%pcfromdepth();

%pctransform();

%pcshow();