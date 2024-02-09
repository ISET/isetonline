% Script to consolidate schema updates for ISET3D/ISETOnline database
%
% D. Cardinal, Stanford University, 2024

% Start by chaining the various _store scripts together

% All our common collections should have unique indices, so updating
% should only insert new entries. If existing documents need their
% information updated, that requires a different approach

% EXPECT lots of "fail duplicate key" messages. That's normal because
% the scripts try to add everything, but only new documents succeed.

%% Think about pulling the 3d Scene repo (pbrt-v4-scenes) _first_
%  to make sure they are up to date if we have made changes

%% Both ISET3d & PBRT-v4 scenes get stored in the same collection
%  However we use two scripts in case we want to handle the
%  types of scenes differently at some point

fprintf("Storing ISET3d Scene Recipes\n");
s_storeISETSceneRecipes;
fprintf("Storing PBRT-v4 Scene Recipes\n");
s_storePBRTSceneRecipes;

%% Our main source of mergable assets is iset3d/data/assets
s_storeISETAssets;

% We don't try and merge Auto assets here, as they are a different
% kind of thing.

%% Currently we import Textures from ISETResources
%  for the remoteRecipe case, each recipe has their own
fprintf("Storing Textures from ISETResources\n");
s_storeTextures;

%% These are Auto specific, so have left them out of generic update
% s_storeAutoAssets;
% s_storeAutoSceneEXRData;
% s_storeAutoSceneRecipes;

%% These are specialty collections that require handholding
% s_storeAutoSceneISETData;
% s_storeFlareTestImages;

