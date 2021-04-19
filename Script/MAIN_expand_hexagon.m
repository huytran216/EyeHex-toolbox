function MAIN_expand_hexagon(img_name,set_origin_only)
%% perform automatic expansion if set_origin_only not specified
if ~exist('set_origin_only','var')
    set_origin_only = false;
end
[~,img_name] = fileparts(img_name);
%% Load image
I=imread(['../data/probability_map/' img_name '.tif'],1);
if strcmp(class(I),'uint8')
    I = double(I)/255;
end
foldername =['tmp/' img_name];
hmain = figure;
imshow(I);
I_sub = I;
%% Select origin points for hexagonal axis
%xy0 = [510 465 489 442 449 473];   % image 1
%xy0 = [634 577 606 944 950 996];    % image 2
%xy0 = [564 595 584 376 373 400];   % image 3
%xy0 = [484 470 507 518 554 554];   % Image 4
%xy0 = [600 592 633 423 460 448];   % 25174_1_lefts
xi=[];
yi=[];
while numel(xi)~=3
    title('Select three adjacent omatidia. Then press Enter.');
    [xi,yi] = getpts(hmain);
end
xy0 = [yi;xi]';
%% 
fun = @(x) sqrt(sum((x([3 4])-x([1 2])).^2));
grid_size = (fun(xy0([1 4 2 5]))+fun(xy0([1 4 3 6]))+fun(xy0([3 6 2 5])))/6;
%% Remove small particles and get background (non_eyes) pixels 
threshold=0.1;
I1 = bwareaopen(I>threshold,100);
I2=double(I1);
Ibg = imfill(I1,[1 1]);
I_bg = xor(Ibg,I1);
imshow(I_bg);
%% Create filled circle
[I_circle,x0,y0,I_grid] = create_I_circle(12,0.9);
save('Icircle.mat','x0','y0','I_circle');
%% Image registration
options = optimset('MaxFunEvals',40,'TolFun',1e-2);


%I_sub = double(I2(450:550,450:550));
% Filter I_sub to increase tolerance
%h = fspecial('gaussian',20,1);
%I_sub = imfilter(I_sub,h);
fun1 = @(xy) mickey_error(xy,I_sub,I_circle,x0,y0,grid_size*2);
tic
xy=fminsearchbnd(@(xy) fun1(xy),[xy0 1],[xy0-grid_size*3 0],[xy0+grid_size*3 10],options);
toc
[~,~,~,I_out] = transform_I_([x0 y0],xy,I_circle,size(I_sub));
imshowpair(I_sub, I_out,'Scaling','joint');
% readjust grid_size:
fun = @(x) sqrt(sum((x([3 4])-x([1 2])).^2));
grid_size = (fun(xy([1 4 2 5]))+fun(xy([1 4 3 6]))+fun(xy([3 6 2 5])))/6;
%% Create the hexagonal (slanted) coordinate:
xy_idx=[];xy_pos =[];parent_idx = [];

xy_idx(1,:) = [0 0]; xy_pos(1,:) = [xy(1) xy(4)];
xy_idx(2,:) = [1 0]; xy_pos(2,:) = [xy(2) xy(5)];
xy_idx(3,:) = [0 1]; xy_pos(3,:) = [xy(3) xy(6)];
parent_idx = [0 0; 0 0; 0 0];
brightness([1 2 3]) = xy(end);
I_sum=I_out;
cnt=0;
mkdir(foldername);
save([foldername '/original_pos.mat'],'xy_idx','xy_pos','parent_idx','brightness','fun1','I_sub','I_sum','cnt','I_bg','grid_size','I_circle','foldername');
%% Expand eyes
if ~set_origin_only
    expand_hexagon;
end