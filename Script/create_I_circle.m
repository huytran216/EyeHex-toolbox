function [I_circle,x0,y0,I_edge] = create_I_circle(grid_size,rsize)

    % rsize: peak value
    % grid_size: grid size
    
    % Draw circles around a perfect triangle
        I_circle = zeros(round(grid_size*(2+sqrt(3))),round(grid_size*4));
        
        xy = [grid_size,grid_size;grid_size,grid_size*3;grid_size*(1+sqrt(3)),grid_size*2];
        for i=1:3
            I_circle = filledcircle(grid_size*rsize,xy(i,1),xy(i,2),I_circle);
        end

        x0 = xy(:,1)';
        y0 = xy(:,2)';
        % apply gaussian on circle
        h = fspecial('gaussian',20,grid_size/5);
        I_circle = imfilter(I_circle,h);
        % Don't care about things far from main circle:
        I_circle = filledcircle(grid_size*rsize,grid_size*2.75,grid_size*0,I_circle,NaN);
        I_circle = filledcircle(grid_size*rsize,grid_size*2.75,grid_size*3.9,I_circle,NaN);
    % Draw edge:
        I_edge = I_circle*0;
        xcenter = mean(x0);
        ycenter = mean(y0);
        x1 = mean(x0(1:2));y1 = mean(y0(1:2));
        x1 = [x1 mean(x0(2:3))];y1 = [y1 mean(y0(2:3))];
        x1 = [x1 mean(x0([1 3]))];y1 = [y1 mean(y0([1 3]))];
        npt = 40;
        for i=1:3
            xpt = round(linspace(xcenter(1),2*x1(i)-xcenter(1),npt));
            ypt = round(linspace(ycenter(1),2*y1(i)-ycenter(1),npt));
            I_edge(sub2ind(size(I_edge),xpt,ypt))= 1;
        end
        
        if nargout ==0
            imshow(I_circle/max(I_circle(:))+I_edge);
        end