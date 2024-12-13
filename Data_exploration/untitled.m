probe_areas{1}=probe_ccf(1).trajectory_areas  ;
probe_positions_ccf{1}=probe_ccf(1).trajectory_coords';  
save('DS_PetersLab\demo.mat','probe_areas','probe_positions_ccf')