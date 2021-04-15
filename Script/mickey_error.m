function error = mickey_error(xy,I,I_circle,x0,y0,grid_size,xoriginal)
    % Input: xy, contain 3 points: [x(1) x(2) x(3) y(1) y(2) y(3)]
    fun = @(x) sqrt(sum((x([3 4])-x([1 2])).^2));
    % Get the triangle edge:
    e = [fun(xy([1 4 2 5])) fun(xy([1 4 3 6])) fun(xy([3 6 2 5]))];
    if any(e>grid_size*1.3)|(max(e)<grid_size*0.5)
        % triangle edge length too long or too short
        error=1e5;
    elseif get_angle(xy(1:6))<cos(pi/2-pi/9)
        % angle of the triangle too steep 20o (assume it is perfect triangle)
        error=1e5;
    else
        [newx,newy,newval]=transform_I_([x0 y0],xy(1:end-1),I_circle,size(I));
        newval = newval*xy(end);
        newcc = sub2ind(size(I),newx,newy);
        error = sum((I(newcc)-newval).^2);
    end
    %[e error]
    if exist('xoriginal','var')
        % Coefficient from beta distribution, sothat the projected point is
        % not so far away from the original points
        betacoeff = betapdf(0.5+sqrt(sum((xy([3 6]) - xoriginal([1 2])).^2))/xoriginal(3)/3,1.2,1.2)+1e-5;
        error = error/betacoeff;
    end
end