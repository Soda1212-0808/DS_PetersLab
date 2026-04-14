Path='D:\Data process\project_cross_model\face_data\sleap\track_data\aligned_data\';


surround_window = [-0.5,1];
mousecam_framerate = 30;
time_period = surround_window(1):1/mousecam_framerate:surround_window(2);


for curr_group=1:2
    switch curr_group
        case 1
            animals = {'DS007','DS010','AP019','AP021','DS011','AP022'};n1_name='stim_wheel_right_stage2';n2_name='stim_wheel_right_stage2_audio_volume';
        case 2
            animals = {'DS000','DS004','DS014','DS015','DS016'};n1_name='audio volume';n2_name='visual position';
    end

    tem_data_all=cell(length(animals),1);
    for curr_animal =1:length(animals)
        animal=animals{curr_animal};
        load([Path  animal '_face'  '.mat']);

        % stage1_id=find( strcmp(n1_name ,face_data.task_name),5,'last');
        stage1_id=[];
        stage2_id=find( strcmp(n2_name ,face_data.task_name),5,"first");
        % stage2_id=[];

        tem_data_all{curr_animal}=cellfun(@(id)  cellfun(@(x)   vecnorm(diff(x,1,2), 2, 4) ,...
            id,'UniformOutput',false),face_data.hml_passive_audio([stage1_id;stage2_id]),'UniformOutput',false);

        %
        % tem_data_all{curr_animal}=cellfun(@(id)  cellfun(@(x)   vecnorm(diff(x,1,2), 2, 4) ,...
        %     id,'UniformOutput',false),face_data.lcr_passive([stage1_id;stage2_id]),'UniformOutput',false);
    end






    temp_mean=...
        cellfun(@(id) feval(@(a)  cat(3,a{:}) ,cellfun(@(x) permute(nanmean(x,1),[2,3,1]), id,'UniformOutput',false)),...
        cat(2,tem_data_all{:}),'UniformOutput',false);

    temp_mean_2=feval(@(a) cat(4,a{:})  ,arrayfun(@(idx)  mean(cat(4,temp_mean{idx,:}),4)   ,1:5,'UniformOutput',false));
    temp_error=feval(@(a) cat(4,a{:}), arrayfun(@(idx)  std(cat(4,temp_mean{idx,:}),0,4)./sqrt(size(temp_mean,2))  ,1:5,'UniformOutput',false));



    figure;
    hold on
    colors={[0 0 1],[0 0 0],[ 1 0 0]}
    for curr_day=1:5
        nexttile
        for curr_passive=1:3
            % plot(temp_data{curr_passive}(:,3),'Color',colors{curr_passive})
            ap.errorfill(time_period(1:end-1)',temp_mean_2(:,3,curr_passive,curr_day),temp_error(:,3,curr_passive,curr_day),colors{curr_passive})
        end
    end

    colors={[0 0 1],[0 0 0],[ 1 0 0]}

    for curr_animal=1:6
        figure;
        for curr_day=1:5
            nexttile
            for curr_passive=1:3
                hold on
                plot(time_period(1:end-1)',temp_mean{curr_day,curr_animal}(:,3,curr_passive),'Color',colors{curr_passive})
                % ap.errorfill(time_period(1:end-1)',temp_mean_2(:,3,curr_passive,curr_day),temp_error(:,3,curr_passive,curr_day),colors{curr_passive})
            end
        end
        sgtitle(animals{curr_animal})

    end


    % ylim([0 2])
    % save(fullfile(Path,[ animal '_face.mat' ]),face_data,node_names,'-v7.3')