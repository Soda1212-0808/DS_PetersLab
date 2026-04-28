clear all
clc
Path = 'D:\Data process\wf_data\';

   animals =     { 'DS007','DS010','AP019','AP021','DS011','AP022',...
        'DS000','DS004','DS014','DS015','DS016',...
        'AP018','AP020','DS006','DS013',...
        };
for curr_animal=1:length(animals)
animal=animals{curr_animal}
raw_data_behavior=load([Path   'behavior\' animal '_behavior.mat']);


matches=unique(raw_data_behavior.workflow_name,'stable');
idx=cellfun(@(x) ismember(raw_data_behavior.workflow_name,x),matches,'UniformOutput',false);

figure('Position',[50 50 300 500]);
tiledlayout(4,2,'TileIndexing','columnmajor')
sgtitle(animal,'FontWeight','normal')

for i=1:4
   

nexttile
hold on

set(gca, 'YScale', 'log');
yline(0.1)
yline(0.2)

ylim([0.01 10])
switch i
    case 1
        learned=raw_data_behavior.rxn_f_mean_p<0.01;
        title('rxn f mean')
    case 2
        learned=raw_data_behavior.rxn_l_mean_p<0.01;
        title('rxn l mean')
    case 3
        learned=raw_data_behavior.rxn_f_mad_p<0.01;
        title('rxn f mad')
    case 4
        learned=raw_data_behavior.rxn_l_mad_p<0.01;
        title('rxn l mad')
end

plot(find(idx{1}),raw_data_behavior.stim2lastmove_mad(idx{1},1),'r')
plot(find(idx{2}),raw_data_behavior.stim2lastmove_mad(idx{2},1),'r')

plot(find(idx{1}),raw_data_behavior.stim2lastmove_mad_null(idx{1},1),'k')
plot(find(idx{2}),raw_data_behavior.stim2lastmove_mad_null(idx{2},1),'k')
if length(idx)==3
plot(find(idx{3}),raw_data_behavior.stim2lastmove_mad(idx{3},[2 3]),'r')

plot(find(idx{3}),raw_data_behavior.stim2lastmove_mad_null(idx{3},[2 3]),'k')
end
line1=find(learned(:,1)==1&idx{1}==1,1,'first');
if ~isempty(line1)
xline(line1-0.5)
end
line2=find(learned(:,1)==1&idx{2}==1,1,'first');
if ~isempty(line2)

xline(line2-0.5)
end
end
drawnow



for i=1:4
   

nexttile
hold on

ylim([-0.2 1])
switch i
    case 1
        learned=raw_data_behavior.rxn_f_mean_p<0.01;
        title('rxn f mean')
    case 2
        learned=raw_data_behavior.rxn_l_mean_p<0.01;
        title('rxn l mean')
    case 3
        learned=raw_data_behavior.rxn_f_mad_p<0.01;
        title('rxn f mad')
    case 4
        learned=raw_data_behavior.rxn_l_mad_p<0.01;
        title('rxn l mad')
end

temp_data=(raw_data_behavior.stim2move_mad_null(idx{1},1)-raw_data_behavior.stim2move_mad(idx{1},1))./...
    (raw_data_behavior.stim2move_mad_null(idx{1},1)+raw_data_behavior.stim2move_mad(idx{1},1))
plot(find(idx{1}),temp_data,'r')

temp_data=(raw_data_behavior.stim2lastmove_mad_null(idx{1},1)-raw_data_behavior.stim2lastmove_mad(idx{1},1))./...
    (raw_data_behavior.stim2lastmove_mad_null(idx{1},1)+raw_data_behavior.stim2lastmove_mad(idx{1},1))
plot(find(idx{1}),temp_data,'b')

temp_data=(raw_data_behavior.stim2move_mad_null(idx{2},1)-raw_data_behavior.stim2move_mad(idx{2},1))./...
    (raw_data_behavior.stim2move_mad_null(idx{2},1)+raw_data_behavior.stim2move_mad(idx{2},1))
plot(find(idx{2}),temp_data,'r')

temp_data=(raw_data_behavior.stim2lastmove_mad_null(idx{2},1)-raw_data_behavior.stim2lastmove_mad(idx{2},1))./...
    (raw_data_behavior.stim2lastmove_mad_null(idx{2},1)+raw_data_behavior.stim2lastmove_mad(idx{2},1))
plot(find(idx{2}),temp_data,'b')

% if length(idx)==3
% plot(find(idx{3}),raw_data_behavior.stim2move_med(idx{3},[2 3]),'r')
% 
% plot(find(idx{3}),raw_data_behavior.stim2move_med_null(idx{3},[2 3]),'k')
% end
line1=find(learned(:,1)==1&idx{1}==1,1,'first');
if ~isempty(line1)
xline(line1-0.5)
end
line2=find(learned(:,1)==1&idx{2}==1,1,'first');
if ~isempty(line2)

xline(line2-0.5)
end
end
drawnow


end