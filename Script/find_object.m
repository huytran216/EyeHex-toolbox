%% Params
threshold=0.37;     % Probability of pixel in border region, separating the facets
min_size =50;       % min size of region

obj_max_angle=60;   % Mean angle for the object (0 mean no angle)
obj_min_size=35;    % Hexagon min size
%% Load image
I=imread('learned/Probability maps.tif',2);
imshow(I>threshold)
%% Remove small particles
I1 = bwareaopen(I>threshold,100);
imshow(I1);
%% create a circle 
Iround = zeros(obj_min_size+1);
for i=0:0.01:2*pi
    Iround(round(end/2+obj_min_size*sin(i)/2),round(end/2+obj_min_size*cos(i)/2))=1;
    for j=0:0.01:1
        Iround(round(end/2+j*obj_min_size*sin(i)/4),round(end/2+j*obj_min_size*cos(i)/4))=-1;
    end
end
imagesc(Iround);
%% The three main axis of the eyes
% Isub=double(I1(400:600,400:600));
% figure;
% imshow(Isub);
% hold on;
% for i=1:3
%     title(['Select facet ' num2str(i) 'to get a triangle']);
%     [x(i),y(i)]=ginput(1);
%     plot(x(i),y(i),'x');
% end

%% Find object in image
warning off;


Isub = double(I1(200:800,200:800));
boxsize = size(Isub);
% Fitting params beta    
    % beta1: position x
    % beta2: position y
    % beta3: angle of object (3D)
    % beta4: angle of object (2D)
    % beta5: size of object

beta_lb = [1 1 0 -90 obj_min_size];
beta_ub = [round(boxsize(1)-obj_min_size*1.5-1) round(boxsize(2)-obj_min_size*1.5-1) obj_max_angle 90 obj_min_size];
Iall = Isub/2;
for i=1:100
    diff_ = @(beta_) find_diff(Isub,Iround,beta_(1),beta_(2),beta_(3),beta_(4),beta_(5));
    if f<1e5
        beta0=beta;
    else
        beta0 = [randi([1,round(boxsize(1)-obj_min_size*2-1)]) randi([1,round(boxsize(2)-obj_min_size*2-1)]) 10 10 obj_min_size];
    end
    [beta,f]=fminsearchbnd(diff_,beta0,beta_lb,beta_ub);
    if (f<1e5)&&(f>0.4)
        [~,Iout] = diff_(beta);
        Isub(round(beta(1)+size(Iout,1)/2),round(beta(2)+size(Iout,2)/2))=-1e5;
        Iall(round(beta(1):beta(1)+size(Iout,1)-1),round(beta(2):beta(2)+size(Iout,2)-1))=Iall(round(beta(1):beta(1)+size(Iout,1)-1),round(beta(2):beta(2)+size(Iout,2)-1))+ Iout/2;
        f
    end
end
figure;
imshow(Iall);
beta
%% Find pattern
% Create a filter
Iround_ = twist_and_turn(Iround,70,-45);
Ih=Iround_;
Ih(Itmp(:)<0)=sum(Itmp(Itmp(:)>0))/sum(Itmp(:)<0);
%Itmp = imfill(logical(Iround),size(Iround)/2);
%Itmp=xor(Iround,Itmp);
%Ih=Iround;
%Ih(Itmp)=-sum(Iround)/sum(Itmp);
figure;
subplot(131);
imagesc(I);
subplot(132);
Iout = filter2(Ih,I);
imagesc(Iout);
subplot(133);
l = graythresh(uint8(Iout));
bw = im2bw(uint8(Iout),l);
imagesc(bw);

Generalized_hough_transform(