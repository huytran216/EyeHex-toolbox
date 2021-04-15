function xdiff = dir2diff(dir)
    switch dir
        case 1 
            xdiff=[1 0];
        case 2 
            xdiff=[0 1];
        case 3 
            xdiff=[-1 1];
        case 4 
            xdiff=[-1 0];
        case 5 
            xdiff=[0 -1];
        case 6 
            xdiff=[-1 -1];
    end
    
    