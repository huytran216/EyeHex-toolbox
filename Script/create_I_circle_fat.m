function [I_circle,x0,y0,I_edge] = create_I_circle_fat(grid_size,rsize)

    % rsize: peak value
    % grid_size: grid size
    
    % Draw circles around a obstuse triangle
        % first 2 points form the longest edge
        I_circle = zeros(round(grid_size*3.31),round(grid_size*6));
        
        xy = [grid_size,grid_size;grid_size,grid_size*5;grid_size*(2.31),grid_size*3];
        for i=1:3
            I_circle = filledcircle(grid_size*rsize,xy(i,1),xy(i,2),I_circle);
        end

        x0 = xy(:,1)';
        y0 = xy(:,2)';
        
        % apply gaussian on circle
        h = fspecial('gaussian',20,grid_size/3);
        I_circle = imfilter(I_circle,h);
        % Don't care about things far from main circle:
        % I_circle = filledcircle(grid_size*rsize,grid_size*2.75,grid_size*0,I_circle,NaN);
        % I_circle = filledcircle(grid_size*rsize,grid_size*2.75,grid_size*3.9,I_circle,NaN);
    % Draw edge:
        I_edge = I_circle*0;
        xproj = x0(1)+x0(2)-x0(3);
        yproj = y0(1)+y0(2)-y0(3);
        
        for j=1:2
            x0_ = [x0([j 3]) xproj];
            y0_ = [y0([j 3]) yproj];
            xcenter = mean(x0_);
            ycenter = mean(y0_);
            x1 = mean(x0_(1:2));y1 = mean(y0_(1:2));
            x1 = [x1 mean(x0_(2:3))];y1 = [y1 mean(y0_(2:3))];
            x1 = [x1 mean(x0_([1 3]))];y1 = [y1 mean(y0_([1 3]))];
            npt = 40;
            for i=1:3
                xpt = round(linspace(xcenter(1),2*x1(i)-xcenter(1),npt));
                ypt = round(linspace(ycenter(1),2*y1(i)-ycenter(1),npt));
                ptselect = (xpt>0)&(xpt<size(I_edge,1))&(ypt>0)&(ypt<size(I_edge,2));
                I_edge(sub2ind(size(I_edge),xpt(ptselect),ypt(ptselect)))= 1;
            end
        end
        if nargout==0
            imshow(I_circle/max(I_circle(:))+I_edge);
        end