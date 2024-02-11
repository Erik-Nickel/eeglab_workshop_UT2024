clear;
close all;
addpath 'C:\Users\enick\Documents\MATLAB\MATLABR2023b\eeglab2023.0'
eeglab nogui;

indir = "./example_data/"
outdir = "./preprocessing/loop_1/"

if exist(outdir, 'dir') == false
    mkdir(outdir)
end

%%
subjects = dir(indir)
subjects = {subjects(~ismember({subjects.name},{'.','..'})).name}


%%

for subject = 1:length(subjects)

    EEG = pop_loadset(char(strcat(indir,subjects(subject))))


    %% DOWNSAMPLING
    % ---------------


    dwnsamp = 100;
    EEG = pop_resample(EEG, dwnsamp);


    %% FILTERS
    % ---------------
    % high-pass 0.1Hz
    hp = 0.1;
    EEG = pop_eegfiltnew(EEG, hp, []);
    disp('High-pass filter done');

    % low-pass 40Hz
    lp = 40;
    EEG = pop_eegfiltnew(EEG, [], lp);
    disp('Low-pass filter done :)');



    %%

    EEG = pop_select(EEG,'rmchannel',{'EXG1','EXG2','EXG3','EXG4','EXG5','EXG6','EXG7','EXG8','GSR1','GSR2','Erg1','Erg2','Resp','Plet','Temp'})


    %%

    % EEG = clean_rawdata(EEG,5,[0.25 0.75],0.85,4,20,0.25)

    %%

    EEG = pop_reref(EEG,[])

    %%

    EEG = pop_epoch(EEG, {'oddball','standard','noise','oddball_with_response','standard_with_response','noise_with_response'}, [-0.2 0.800], 'epochinfo', 'yes');


    %%

    EEG = pop_rmbase(EEG, [EEG.times(1) 0]);


    %%

    EEG = pop_runica(EEG,'icatype','runica', 'chanind',1:EEG.nbchan,'extended',1,'interupt','on');


    %%

    EEG = iclabel(EEG);


    %%

    high_artifact = any(EEG.etc.ic_classification.ICLabel.classifications(:,2:6)>=.9 , 2);
    %low_brain = EEG.etc.ic_classification.ICLabel.classifications(:,1)<.05;
    %EEG.reject.gcompreject = and(high_artifact,low_brain);
    EEG.reject.gcompreject = high_artifact;

    %%


    EEG = pop_saveset( EEG, 'filename',char(subjects(subject)),'filepath',char(outdir));
end



