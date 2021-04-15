%% Scan
% tested set:
nextcell=size(xy_idx,1);
offsetidx=100;  % set size of hexagonal grid: (offsetidx*2 x offsetidx*2) with origin at [xy0]
xymap = zeros(offsetidx*2,offsetidx*2);

for i=1:size(xy_idx,1)
    xymap(xy_idx(i,1)+offsetidx,xy_idx(i,2)+offsetidx)=i;
end
expandable = ones(size(xy_idx,1),1);
%% Scanning for new nodes continuous up to a limit
xy_to_test = struct;
while nextcell<1200
    crrsize = size(xy_idx,1);
        if crrsize>numel(expandable)
            expandable = [ones(crrsize,1)];
        end
        % Find expandable nodes:
        for i=1:numel(expandable)
            if expandable(i)
                local_map = xymap(xy_idx(i,1)+[-2:2]+offsetidx,xy_idx(i,2)+[-2:2]+offsetidx);
                if any(local_map(:)==0)
                    expandable(i)=1;
                else
                    expandable(i)=0;
                end
            end
        end
    % create empty list of points to test:
    
    cnttest=0;
    % begin scanning for nodes to test
    for i=1:crrsize-2
        if expandable(i)
            for j=i+1:crrsize-1
                if expandable(j)
                    connectscheme(1)=isconnect(xy_idx(i,:),xy_idx(j,:));
                    if connectscheme(1)>0
                        for k=j+1:crrsize
                            if expandable(k)
                                % if i and j and k connects
                                connectscheme(1)=isconnect(xy_idx(i,:),xy_idx(j,:));
                                connectscheme(2) = isconnect(xy_idx(i,:),xy_idx(k,:));
                                connectscheme(3) = isconnect(xy_idx(j,:),xy_idx(k,:));
                                if connectscheme(1)&connectscheme(2)&connectscheme(3)
                                   cnt=cnt+1;
                                   idx_test = [i j k];
                                   % selecting an anchoring cell
                                   for idx = 1:3
                                       % remain cell:
                                       idx_remain = idx_test([1 2 3]~=idx);
                                       % Find the opposite cell
                                       xy_idx_opposite = xy_idx(idx_remain(1),:)+xy_idx(idx_remain(2),:)-xy_idx(idx_test(idx),:);
                                       % Check if this item has been tested:
                                       if sum(xy_idx(:, 1) == xy_idx_opposite(1) & xy_idx(:, 2) == xy_idx_opposite(2) )==0
                                           xy_pos_opposite = xy_pos(idx_remain(1),:)+xy_pos(idx_remain(2),:)-xy_pos(idx_test(idx),:);
                                           % if picture is not at the border
                                           if (round(xy_pos_opposite(1))>0)&(round(xy_pos_opposite(1))<size(I_sub,1))&...
                                                   (round(xy_pos_opposite(2))>0)&(round(xy_pos_opposite(2))<size(I_sub,2))
                                               if I_bg(round(xy_pos_opposite(1)),round(xy_pos_opposite(2)))==0
                                                   xy0 = [xy_pos(idx_remain(1),1) xy_pos(idx_remain(2),1) xy_pos_opposite(1) ...
                                                       xy_pos(idx_remain(1),2) xy_pos(idx_remain(2),2) xy_pos_opposite(2)];
                                                   grid_size_ = mean([...
                                                       sqrt((xy0(3) - xy0(1)).^2 + (xy0(6) - xy0(4)).^2) ...
                                                       sqrt((xy0(3) - xy0(2)).^2 + (xy0(6) - xy0(5)).^2) ...
                                                       sqrt((xy0(1) - xy0(2)).^2 + (xy0(4) - xy0(5)).^2)])/2;
                                                   xy0_lb = xy0-grid_size_*[0.2 0.2 0.3 0.2 0.2 0.3];
                                                   xy0_ub = xy0+grid_size_*[0.2 0.2 0.3 0.2 0.2 0.3];
                                                   % save to test list:
                                                   cnttest= cnttest+1;
                                                   xy_to_test(cnttest).grid_size=grid_size_;
                                                   xy_to_test(cnttest).xy0=xy0;
                                                   xy_to_test(cnttest).xy0_ub=xy0_ub;
                                                   xy_to_test(cnttest).xy0_lb=xy0_lb;
                                                   xy_to_test(cnttest).xy_idx_opposite=xy_idx_opposite;
                                                   xy_to_test(cnttest).brightness = mean(brightness(idx_remain));
                                                   xy_to_test(cnttest).idx_remain=idx_remain;
                                                   xy_to_test(cnttest).idx_anchor=idx_test(idx);
                                               end
                                           end
                                       end
                                   end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    if cnttest==0
        break;
    end
    %% test the list of unexplored notes (possible for parralel scan)
    xyout_rec = cell(cnttest,1);
    fout_rec = zeros(cnttest,1);
    cnttest_ = cnttest;
    parfor cnttest = 1:cnttest_
       options = optimset('MaxFunEvals',50,'TolFun',1e-2);
       xy_original = xy_to_test(cnttest).xy0([3 6]);
       grid_size_ = xy_to_test(cnttest).grid_size;
       fun2 = @(xy) mickey_error(xy,I_sub,I_circle,x0,y0,grid_size*2,[xy_original grid_size_]);
       [xy,fout]=fminsearchbnd(@(xy) fun2(xy),...
           [xy_to_test(cnttest).xy0 xy_to_test(cnttest).brightness],...
           [xy_to_test(cnttest).xy0_lb 0],[xy_to_test(cnttest).xy0_ub 10],options);
       xyout_rec{cnttest}=xy;
       fout_rec(cnttest)=fout;
    end
    % update the node list
    cntadd =0;
    for cnttest = 1:cnttest_
       if fout_rec(cnttest)>=5e3
           %'hah'
       else
           cntadd =cntadd+1;
           % note node not found yet
           if sum(xy_idx(:, 1) == xy_to_test(cnttest).xy_idx_opposite(1) & xy_idx(:, 2) == xy_to_test(cnttest).xy_idx_opposite(2) )==0
               % update 
               nextcell=nextcell+1;
               xy = xyout_rec{cnttest};
               idx_remain=xy_to_test(cnttest).idx_remain;
               xy_idx(nextcell,:) = xy_to_test(cnttest).xy_idx_opposite;
               xy_pos(nextcell,:) = [xy(3) xy(6)];
               brightness(nextcell)=xy(end);
               score(nextcell)=fout_rec(cnttest);
               xymap(xy_idx(nextcell,1)+offsetidx,xy_idx(nextcell,2)+offsetidx)=nextcell;
               
               parent_idx(nextcell,:) = xy_to_test(cnttest).idx_remain;
               % show results:
%                [~,~,~,I_out] = transform_I([x0 y0],xy,I_circle,size(I_sub));
%                I_sum = I_sum+I_out;
%                imshowpair(I_sub, I_sum,'Scaling','joint'); hold on;
%                line([xy_pos(xy_to_test(cnttest).idx_anchor,2) xy_pos(idx_remain,2)' xy_pos(xy_to_test(cnttest).idx_anchor,2)],...
%                    [xy_pos(xy_to_test(cnttest).idx_anchor,1) xy_pos(idx_remain,1)' xy_pos(xy_to_test(cnttest).idx_anchor,1)],...
%                    'color','w','LineWidth',3);
%                line([xy(6) xy_pos(xy_to_test(cnttest).idx_anchor,2)],[xy(3) xy_pos(xy_to_test(cnttest).idx_anchor,1)],'color','r','LineWidth',3);
%                hold off;
               display([num2str(nextcell) ' cells (s) found - Score: ' num2str(score(nextcell))]);
           end
       end
    end
    % Break if no new eyes are found
    if (cntadd==0)
        break;
    end
    save([foldername '/dat_probmap' num2str(nextcell)],'xy_idx','xy_pos','xymap','score','brightness','fun1','I_sub','I_sum','cnt','grid_size','parent_idx');
    % Update figures:
    hold off;
    imshow(I_sub);hold on;
    lb={};
    for i=1:size(xy_idx,1)
        lb{i}=num2str(i);
    end
    % Draw spawned images
    line(xy_pos(:,2),xy_pos(:,1),'LineStyle','none','Marker','o','MarkerSize',10,'color','g','MarkerFaceColor','r');
    hold on;
    % Draw original
    line(xy_pos(1:3,2),xy_pos(1:3,1),'LineWidth',3,'LineStyle','none','Marker','o','MarkerSize',10,'color',[1 0 1],'MarkerFaceColor','r');
    drawnow;
end
%save(['data/dat' num2str(cnt),'xy_idx','xy_pos','brightness','fun1','I_sub','I_sum','cnt']);
%% Plot idx:
% create label
%imshowpair(I_sub, I_sum,'Scaling','joint'); hold on;

%text(xy_pos(:,2),xy_pos(:,1),lb,'VerticalAlignment','bottom','HorizontalAlignment','right')