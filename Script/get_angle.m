function cos_angle = get_angle(xy)
    % get angle from set of 3 points of xy
    % point 1: xy(1 4)
    % point 2: xy(2 5)
    % point 3: xy(3 6)
    xy = xy - [xy(1) xy(1) xy(1) xy(4) xy(4) xy(4)];
    fun2 = @(x) sum((x([3 4])-x([1 2])).^2);
    l3 = fun2(xy([1 4 2 5]));
    l2 = fun2(xy([1 4 3 6]));
    l1 = fun2(xy([2 5 3 6]));
    z1=0;
    %
    fun = @(z) (2*z(1)*z(2)-z(2)^2-l1+l3)^2+(2*z(1)*z(2)-z(1)^2-l1+l2)^2;
    [z23] = fminsearch(fun,[0 0]);
    z=[z1 z23];
    %stem3(xy([1 2 3 1]),xy([4 5 6 4]),z([1 2 3 1]));hold on;
    %plot3(xy([1 2 3 1]),xy([4 5 6 4]),z([1 2 3 1]));
    %plot3(xy([1 2 3 1]),xy([4 5 6 4]),[0 0 0 0]);
    % calculate angle:
    B = [xy(1) xy(4) z(1); xy(2) xy(5) z(2); xy(3) xy(6) z(3); 1 1 1];
    abc = linsolve(B,[zeros(3,1);1]);
    cos_angle = abs(abc(3))/sqrt(sum(abc.^2));
end