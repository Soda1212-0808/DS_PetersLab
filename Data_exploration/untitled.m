 clear all
animals={'DS022','DS023','DS025'};
error_day=cell(3,1);
for curr_animal =1:length(animals)
    animal=animals{curr_animal};

    recordings=plab.find_recordings(animal,[],'*stim*');

    recordings=recordings(vertcat(recordings.ephys)>0);
    for  curr_recording =1:length(recordings)

        rec_day= recordings(curr_recording).day;
        rec_time=recordings(curr_recording).recording{1};

        try
            ap.load_recording

        catch
            error_day{curr_animal}{curr_recording}=rec_day;
            fprintf('Skip curr_recording %d\n', curr_recording);
            continue;
        end


    end
end