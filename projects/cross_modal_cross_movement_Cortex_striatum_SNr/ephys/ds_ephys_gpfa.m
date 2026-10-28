clc
clear
Path='D:\Data process\project_SNr\data\ephys_data\package';

passive_workflows={'lcr_passive_white_circle_size40','lcr_passive_black_square',...
    'lcr_passive_grating_size40','lcr_passive_checkerboard','lcr_passive_squareHorizontalStripes'};


animals={'DS036','DS041','DS043'};
rec_days_all={{'2026-08-25','2026-08-28'},...
    {'2026-08-24','2026-08-25','2026-08-28','2026-08-31'},...
    {'2026-08-25'}};