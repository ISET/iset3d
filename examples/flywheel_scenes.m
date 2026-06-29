basePath = '/Volumes/Vistalab/data/iset/flywheel/iset_auto_eval_20200108/renderings/';
sceneDir = 'city1_001/';
sceneName = 'city1_08_59_hdr_pinhole_realisticMat_motion_2020110204154';

scenes = dir(dirpath);
sceneStr = scenes(4).name;
regex = "^([^_]+)_([0-9]+_[0-9]+)_([^_]+_[^_]+)_([^_]+)_([^_]+)_([0-9]+)$";
tokens = regexp(sceneStr, regex, 'tokens', 'once');
[name,nums,optics,materials,motion,idnum] = tokens{:};

wave = 400:10:700;

sceneName = 'city1_13_11_hdr_pinhole_realisticMat_motion_2020110193440';
fname = [basePath sceneDir sceneName '/' sceneName '.dat'];
photons = piDat2ISET(fname,'wave',wave);
scene = sceneCreate('empty');
scene = sceneSet(scene,'name','Static');
scene = sceneSet(scene,'wave',wave);
scene = sceneSet(scene,'photons',photons);
sceneWindow(scene);

sceneName = 'city1_13_11_hdr_realistic_realisticMat_motion_2020110193440';
fname = [basePath sceneDir sceneName '/' sceneName '.dat'];
photons = piDat2ISET(fname,'wave',wave);
scene = sceneCreate('empty');
scene = sceneSet(scene,'name','Motion');
scene = sceneSet(scene,'wave',wave);
scene = sceneSet(scene,'photons',photons);
sceneWindow(scene);
