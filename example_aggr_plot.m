clear;
close all;
addpath 'C:\Users\enick\Documents\MATLAB\MATLABR2023b\eeglab2023.0'
eeglab nogui;

indir = './preprocessing/loop/'

subjects = dir(indir)
subjects = {subjects(~ismember({subjects.name},{'.','..'})&~contains({subjects.name},{'fdt'})).name}

fcz_std = []
fcz_odd = []
fcz_diff = []

%%

for subject = 1:length(subjects)
    
    EEG = pop_loadset(char(strcat(indir,subjects(subject))))


    tmpEEG1 = pop_selectevent(EEG,'event',find(contains({EEG.event.type},'standard')))
    maskStds = ismember([tmpEEG1.event.latency],randsample([tmpEEG1.event.latency],sum(contains({EEG.event.type},'oddball'))));
    tmpEEG1 = pop_selectevent(tmpEEG1,'event',find(maskStds))


    tmpEEG2 = pop_selectevent(EEG,'event',find(contains({EEG.event.type},'oddball')))

    tmpEEG1_fcz = pop_select(tmpEEG1,'channel',{'FCz'})
    tmpEEG2_fcz = pop_select(tmpEEG2,'channel',{'FCz'})
    
    fcz_std = [fcz_std; mean(tmpEEG1_fcz.data,3)]
    fcz_odd = [fcz_odd; mean(tmpEEG2_fcz.data,3)]

    fcz_diff = [fcz_diff; mean(tmpEEG2_fcz.data,3)- mean(tmpEEG1_fcz.data,3)]


end


%%
hold on
plot(-200:10:790,mean(fcz_std))
plot(-200:10:790,mean(fcz_odd))
plot(-200:10:790,mean(fcz_diff))
legend('std','odd','diff')