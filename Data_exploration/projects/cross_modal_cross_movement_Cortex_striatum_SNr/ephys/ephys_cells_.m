neuron_id=struct;
for curr_i=1:8
neuron_id(curr_i).animal='DS025';

neuron_id(curr_i).area='SNr';
end
neuron_id(1).rec_day='2026-01-04';
neuron_id(2).rec_day='2026-01-05'
neuron_id(3).rec_day='2026-01-06'
neuron_id(4).rec_day='2026-01-07'
neuron_id(5).rec_day='2026-01-15'
neuron_id(6).rec_day='2026-01-16'
neuron_id(7).rec_day='2026-01-17'
neuron_id(8).rec_day='2026-01-18';

neuron_id(1).probe=2;
neuron_id(2).probe=2;
neuron_id(3).probe=2;
neuron_id(4).probe=2;
neuron_id(5).probe=1;
neuron_id(6).probe=1;
neuron_id(7).probe=1;
neuron_id(8).probe=1;

neuron_id(1).id=140:223
neuron_id(2).id=1:150
neuron_id(3).id=438:504
neuron_id(4).id=1:88
neuron_id(5).id=129:190
neuron_id(6).id=1:108
neuron_id(7).id=1:65
neuron_id(8).id=7:70

save('Y:\Data process\project_cross_model_cross_movement\ephys_data\neuronal_id_label\neuronal_labels.mat','neuron_id')