clear all

animals =     { 'DS007','DS010','AP019','AP021','DS011','AP022',...
    'DS000','DS004','DS014','DS015','DS016'};
all_workflow={ 'lcr_passive','hml_passive_audio'};


vid_table=table
id=0;
for curr_animal=1:length(animals)

    animal=animals{curr_animal};

    for curr_workflow=1:length(all_workflow)

        recordings = plab.find_recordings(animal,[],all_workflow{curr_workflow});
        for curr_recording =1:length(recordings)

            rec_day = recordings(curr_recording).day;

            [~,index_real]=max( cellfun(@(rt) ...
                numel(load( ...
                plab.locations.filename('server', animal, rec_day, rt, 'timelite.mat'), ...
                'timestamps').timestamps), ...
                recordings(curr_recording).recording));
            rec_time = recordings(curr_recording).recording{index_real};
            mousecam_fn = plab.locations.filename('server',animal,rec_day,rec_time,'mousecam','mousecam.mj2');
            id=id+1;

            vid_table.ID{id}=animal;
            vid_table.DATE{id}=rec_day;
            vid_table.RECORDING{id}=['Recording_' rec_time];
            vid_table.video_path{id}=mousecam_fn;

        end
    end
end
save('vid_table.mat','vid_table')