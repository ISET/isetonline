% Brian test script
load('oi_fog.mat');
load('imx363.mat');

hFOV = oiGet(oi,'hfov');
sensor = sensorSetSizeToFOV(sensor,hFOV,oi);

aeMethod = 'specular';
aeLevels = .90;
aeTime  = autoExposure(oi,sensor,aeLevels,aeMethod);

sensor = sensorSet(sensor,'exp time',aeTime);

sensor = sensorCompute(sensor,oi);