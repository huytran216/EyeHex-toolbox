function connect = isconnect(x0,x1)
    xdiff = x1-x0;
    connect=0;
    if xdiff==[1 0]
        connect=1;
    end
    if xdiff==[0 1]
        connect=2;
    end
    if xdiff==[-1 1]
        connect=3;
    end
    if xdiff== [-1 0]
        connect=4;
    end
    if xdiff== [0 -1]
        connect=5;
    end
    if xdiff== [1 -1]
        connect=6;    
    end