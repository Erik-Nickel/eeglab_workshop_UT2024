clear; %clear all variables
close all; % close all open figures

% open EEGLAB
addpath '..\..\..\MATLAB\MATLABR2023b\eeglab2023.0' %you may add you EEGLAB path here
eeglab;


indir = "./example_data/" % define the directory where our data lies
outdir = "./preprocessing/single_subject/" % define the directory where our processed data should go

% make sure our outdir exist or if not, create it
if exist(outdir, 'dir') == false
    mkdir(outdir)
end

%% load the dataset
EEG = pop_loadset(char(strcat(indir ,'sub-001_task-P300_run-1_eeg.set')))
% for raw data possibly extension is needed
% bva-io -> pop_loadbv,
% biosig -> op_biosig, ...

pop_eegplot( EEG, 1, 1, 1); % open plot off all electrodes

%% Channel location

% find the information on the website of the manufacturer

figure; topoplot([],EEG.chanlocs, 'style', 'blank',  'electrodes', 'labelpoint', 'chaninfo', EEG.chaninfo);

%% DOWNSAMPLING
% ---------------

close all
dwnsamp = 100; %define the sample rate (usually 250 or 500)
EEG = pop_resample(EEG, dwnsamp); % downsample
pop_eegplot( EEG, 1, 1, 1);

%% FILTERS
% ---------------
% high-pass 1Hz, 1Hz is argued to be a good fit for ICA later
hp = 1;
EEG = pop_eegfiltnew(EEG, hp, []);
disp('High-pass filter done');

% low-pass 40Hz
lp = 40;
EEG = pop_eegfiltnew(EEG, [], lp);
disp('Low-pass filter done :)');

pop_eegplot( EEG, 1, 1, 1);

%% remove unused channels
close all
EEG = pop_select(EEG,'rmchannel',{'EXG1','EXG2','EXG3','EXG4','EXG5','EXG6','EXG7','EXG8','GSR1','GSR2','Erg1','Erg2','Resp','Plet','Temp'})
pop_eegplot( EEG, 1, 1, 1);

%% automatically cleaning from artiffacts
close all
EEG = clean_rawdata(EEG,5,[0.25 0.75],0.85,4,20,0.25)
pop_eegplot( EEG, 1, 1, 1);
%% rereference the data to average reference
close all
EEG = pop_reref(EEG,[])
pop_eegplot( EEG, 1, 1, 1);

%%  create epochs
close all
tmpEEG = pop_epoch(EEG, {'oddball','standard','noise','oddball_with_response','standard_with_response','noise_with_response'}, [-0.2 0.800], 'epochinfo', 'yes');
pop_eegplot( EEG, 1, 1, 1);
%sum(contains({EEG.event.type},'oddball'))


EEG = pop_epoch(EEG, {'oddball','standard','noise','oddball_with_reponse','standard_with_response','noise_with_response'}, [-0.2 0.800], 'epochinfo', 'yes');
pop_eegplot( EEG, 1, 1, 1);



%% remove baseline from -200 to stimulus on set
close all
EEG = pop_rmbase(EEG, [-200 0]); %pop_rmbase(EEG, [EEG.times(1) 0]);
pop_eegplot( EEG, 1, 1, 1);

%% run ICA on all channels
close all
EEG = pop_runica(EEG,'icatype','runica', 'chanind',1:EEG.nbchan,'extended',1,'interupt','on');
pop_topoplot(EEG, 0, [1:12] ,'BDF file resampled epochs',[3 4] ,0,'electrodes','off');

%% Label the ICA components with IClabel (Alternative, might be MARA, by hand)
close all
EEG = iclabel(EEG);
pop_selectcomps(EEG, [1:15] );

%% remove artifactual components
close all
high_artifact = any(EEG.etc.ic_classification.ICLabel.classifications(:,2:6)>=.9 , 2);
%low_brain = EEG.etc.ic_classification.ICLabel.classifications(:,1)<.05;
%EEG.reject.gcompreject = and(high_artifact,low_brain);
EEG.reject.gcompreject = high_artifact;

pop_eegplot( EEG, 1, 1, 1);

%% plot the ERP per electrode
close all


pop_plottopo(EEG, [1:EEG.nbchan]] , 'collapse all', 0)

%% plot the ERP per electrode per stimulus


tmpEEG = pop_selectevent(EEG,'event',find(contains({EEG.event.type},'standard')))
figure; pop_plottopo(tmpEEG, [1:EEG.nbchan] , '', 0)

%% plot the ERP per electrode per stimulus
figure
tmpEEG = pop_selectevent(EEG,'event',find(contains({EEG.event.type},'oddball')))

pop_plottopo(tmpEEG, [1:EEG.nbchan]] , '', 0)

%% plot MMN
close all

tmpEEG1 = pop_selectevent(EEG,'event',find(contains({EEG.event.type},'standard')))
maskStds = ismember([tmpEEG1.event.latency],randsample([tmpEEG1.event.latency],sum(contains({EEG.event.type},'oddball'))));
tmpEEG1 = pop_selectevent(tmpEEG1,'event',find(maskStds))


tmpEEG2 = pop_selectevent(EEG,'event',find(contains({EEG.event.type},'oddblla')))

tmpEEG1_fcz = pop_select(tmpEEG1,'channel',{'FCz'})
tmpEEG2_fcz = pop_select(tmpEEG2,'channel',{'FCz'})


fcz_diff = mean(tmpEEG2_fcz.data,3)- mean(tmpEEG1_fcz.data,3)

hold on
plot(-200:10:790,mean(tmpEEG1_fcz.data,3))
plot(-200:10:790,mean(tmpEEG2_fcz.data,3))
plot(-200:10:790,fcz_diff)
legend('std','odd','diff')


