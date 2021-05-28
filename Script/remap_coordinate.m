function [xy_idx_new,parent_idx_new] = remap_coordinate(xy_pos_stock,xy_idx,sizeI,grid_size)

    xy_pos = xy_pos_stock(1:size(xy_idx,1),:);
    real_idx = [1 2 3];
    % Remap coordinated based on first 3 points
    nextcell=size(xy_idx,1);
    
    offsetidx=100;  % set size of hexagonal grid: (offsetidx*2 x offsetidx*2) with origin at [xy0]
    xymap = zeros(offsetidx*2,offsetidx*2);

    for i=1:size(xy_idx,1)
        xymap(xy_idx(i,1)+offsetidx,xy_idx(i,2)+offsetidx)=1;
    end
    expandable = ones(size(xy_idx,1),1);
    
    cnt=0;
    xy_to_test = struct;
    crrsize = size(xy_idx,1);
    while nextcell<size(xy_pos_stock,1)
        crrsize = size(xy_idx,1);
        if crrsize>numel(expandable)
            expandable = [expandable(:);ones(crrsize-numel(expandable),1)];
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
                                    connectscheme(2) = isconnect(xy_idx(i,:),xy_idx(k,:));
                                    connectscheme(3) = isconnect(xy_idx(j,:),xy_idx(k,:));
                                    if (connectscheme(1)&connectscheme(2)&connectscheme(3))
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
                                               projection_length = 0.8;
                                               xy_pos_center = (xy_pos(idx_remain(1),:)+xy_pos(idx_remain(2),:))/2;
                                               xy_pos_opposite = xy_pos_center + projection_length*(xy_pos_center - xy_pos(idx_test(idx),:));
                                               % if picture is not at the border
                                               if (round(xy_pos_opposite(1))>0)&(round(xy_pos_opposite(1))<sizeI(1))&...
                                                       (round(xy_pos_opposite(2))>0)&(round(xy_pos_opposite(2))<sizeI(2))
                                                       xy0 = [xy_pos(idx_remain(1),1) xy_pos(idx_remain(2),1) xy_pos_opposite(1) ...
                                                           xy_pos(idx_remain(1),2) xy_pos(idx_remain(2),2) xy_pos_opposite(2)];
                                                       xy0_lb = xy0-[grid_size/5 grid_size/5 grid_size/1.2 ...
                                                           grid_size/5 grid_size/5 grid_size/1.2];
                                                       xy0_ub = xy0+[grid_size/5 grid_size/5 grid_size/1.2 ...
                                                           grid_size/5 grid_size/5 grid_size/1.2];
                                                       % save to test list:
                                                       cnttest= cnttest+1;
                                                       xy_to_test(cnttest).xy0=xy0;
                                                       xy_to_test(cnttest).xy0_ub=xy0_ub;
                                                       xy_to_test(cnttest).xy0_lb=xy0_lb;
                                                       xy_to_test(cnttest).xy_idx_opposite=xy_idx_opposite;
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
        if cnttest==0
            break;
        end
        %% test the list of unexplored notes (possible for parralel scan)
        xyout_rec = cell(cnttest,1);
        fout_rec = zeros(cnttest,1);
        cnttest_ = cnttest;
        for cnttest = 1:cnttest_
           tested = arrayfun(@(x) any(real_idx==x),1:size(xy_pos_stock,1));
           
           toconsider = (xy_pos_stock(:,1)>xy_to_test(cnttest).xy0_lb(3))&...
               (xy_pos_stock(:,2)>xy_to_test(cnttest).xy0_lb(6))& ...
               (xy_pos_stock(:,1)<xy_to_test(cnttest).xy0_ub(3))&...
               (xy_pos_stock(:,2)<xy_to_test(cnttest).xy0_ub(6))& ...
               (~tested(:));
           
           % Link existing points with projected points:
           if any(toconsider)
               [~,newidx] = min(((xy_pos_stock(toconsider,1) - xy_to_test(cnttest).xy0(3)).^2 + (xy_pos_stock(toconsider,2) - xy_to_test(cnttest).xy0(6)).^2));
               tmpfind = find(toconsider);
               newidx = tmpfind(newidx);
               xy = xy_pos_stock(newidx,:);
               xyout_rec{cnttest} = xy_to_test(cnttest).xy0;
               xyout_rec{cnttest}(3) = xy(1);
               xyout_rec{cnttest}(6) = xy(2);
               fout_rec(cnttest)=newidx;
           else
               fout_rec(cnttest)=1e5;
%                figure;
%                imshow(data.I);
%                hold on;
%                plot(xy_pos_stock(:,2),xy_pos_stock(:,1),'LineStyle','none','Marker','o','MarkerSize',5,'color','g');
%                plot(xy_pos(:,2),xy_pos(:,1),'LineStyle','none','Marker','o','MarkerSize',5,'color','b');
%                plot(xy_to_test(cnttest).xy0(4:5),xy_to_test(cnttest).xy0(1:2),'LineStyle','none','Marker','o','MarkerSize',5,'color','r');
%                % draw boundary:
%                line(...
%                    [xy_to_test(cnttest).xy0_lb(6) xy_to_test(cnttest).xy0_ub(6) ...
%                    xy_to_test(cnttest).xy0_ub(6) xy_to_test(cnttest).xy0_lb(6) xy_to_test(cnttest).xy0_lb(6)],...
%                    [xy_to_test(cnttest).xy0_lb(3) xy_to_test(cnttest).xy0_lb(3) ...
%                    xy_to_test(cnttest).xy0_ub(3) xy_to_test(cnttest).xy0_ub(3) xy_to_test(cnttest).xy0_lb(3)],...
%                    'Marker','none','MarkerSize',5,'color','r');
%                'hah'
           end
        end
        % update the node list
        cntadd =0;
        for cnttest = 1:cnttest_
           if fout_rec(cnttest)>=1e5
               %'hah'
           else
               cntadd =cntadd+1;
               % note node not found yet
               if sum(xy_idx(:, 1) == xy_to_test(cnttest).xy_idx_opposite(1) & xy_idx(:, 2) == xy_to_test(cnttest).xy_idx_opposite(2) )==0
                   % update 
                   nextcell=nextcell+1;
                   xy = xyout_rec{cnttest};
                   idx_remain=xy_to_test(cnttest).idx_remain;
                   real_idx(nextcell) = fout_rec(cnttest);
                   xy_idx(nextcell,:) = xy_to_test(cnttest).xy_idx_opposite;
                   xy_pos(nextcell,:) = [xy(3) xy(6)];
                   score(nextcell)=fout_rec(cnttest);
                   xymap(xy_idx(nextcell,1)+offsetidx,xy_idx(nextcell,2)+offsetidx)=1;

                   parent_idx(nextcell,:) = xy_to_test(cnttest).idx_remain;
                   %show results:
%                    [~,~,~,I_out] = transform_I([x0 y0],xy,I_circle,size(I_sub));
%                    I_sum = I_sum+I_out;
%                    imshowpair(I_sub, I_sum,'Scaling','joint'); hold on;
%                    line([xy_pos(xy_to_test(cnttest).idx_anchor,2) xy_pos(idx_remain,2)' xy_pos(xy_to_test(cnttest).idx_anchor,2)],...
%                        [xy_pos(xy_to_test(cnttest).idx_anchor,1) xy_pos(idx_remain,1)' xy_pos(xy_to_test(cnttest).idx_anchor,1)],...
%                        'color','w','LineWidth',3);
%                    line([xy(6) xy_pos(xy_to_test(cnttest).idx_anchor,2)],[xy(3) xy_pos(xy_to_test(cnttest).idx_anchor,1)],'color','r','LineWidth',3);
%                    hold off;
                   display([num2str(nextcell) ' cells (s) found']);
               end
           end
        end
        % Break if no new eyes are found
        if (cntadd==0)
            break;
        end
    end
    %% Plot results:
    xy_idx_new = xy_pos_stock*NaN;
    parent_idx_new = xy_pos_stock*NaN;
    xy_idx_new(real_idx,:) = xy_idx;
    if numel(real_idx)>=4
        parent_idx_new(real_idx(4:end),:)=[real_idx(round(parent_idx(4:end,1)))' real_idx(round(parent_idx(4:end,2)))'];
    end
    %% Draw map
%     figure;
%             plot(xy_pos_stock(:,2),xy_pos_stock(:,1),'LineStyle','none','Marker','o','MarkerSize',5,'color','g');
%             hold on;
%             for i=1:size(xy_pos,1)
%                 if parent_idx(i,1)&parent_idx(i,2)
%                     line(...
%                    [xy_pos(i,2) xy_pos(parent_idx(i,1),2) ...
%                    xy_pos(parent_idx(i,2),2) xy_pos(i,2)],...
%                    [xy_pos(i,1) xy_pos(parent_idx(i,1),1) ...
%                    xy_pos(parent_idx(i,2),1) xy_pos(i,1)], ...
%                    'Marker','none','MarkerSize',5,'color','r','LineWidth',2);
%                 end
%             end
%             for i=1:size(xy_pos_stock,1)
%                 if parent_idx_new(i,1)&parent_idx_new(i,2)
%                     line(...
%                    [xy_pos_stock(i,2) xy_pos_stock(parent_idx_new(i,1),2) ...
%                    xy_pos_stock(parent_idx_new(i,2),2) xy_pos_stock(i,2)],...
%                    [xy_pos_stock(i,1) xy_pos_stock(parent_idx_new(i,1),1) ...
%                    xy_pos_stock(parent_idx_new(i,2),1) xy_pos_stock(i,1)], ...
%                    'Marker','none','MarkerSize',5,'color','b','LineWidth',2);
%                 end
%             end