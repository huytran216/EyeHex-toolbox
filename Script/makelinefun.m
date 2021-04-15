function fun = makelinefun(x1,y1,x2,y2,o)
%ref http://stackoverflow.com/questions/13209373/matlab-straight-line-between-2-points-with-n-points-between
if nargin < 5
    o = 1;
end
if o == 2
    fun  = @(N) deal(linspace(x1,x2,N), linspace(y1,y2,N));
else
	fun  = @(N) [linspace(x1,x2,N) ; linspace(y1,y2,N)];
end