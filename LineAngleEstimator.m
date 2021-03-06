function out = LineAngleEstimator(X,mode)
%% Find the angles between nodes in a line
%   X : 2-D coordinates of nodes
% mode: 0 for degree
% mode: 1 for radian
nt = size(X,1);

if mode == 0
    for i=1:nt-1
        temp = (X(i+1,2)-X(i,2))/(X(i+1,1)-X(i,1));
        if (temp<0)
            out(i) = 360 + atand(temp);
        else
            if (X(i+1,1)-X(i,1))<0
                out(i) = 180 - atand(temp);
            else
                out(i) = atand(temp);
            end
        end
    end
else
    for i=1:nt-1
        temp = (X(i+1,2)-X(i,2))/(X(i+1,1)-X(i,1));
        if (isnan(temp)==1)
            if (i==1)
                out(i) = 0;
            else
                out(i) = out(i-1);
            end
        else
            if (temp<0)
                out(i) = 2*pi + atan(temp);
            else
                if (X(i+1,1)-X(i,1))<0
                    out(i) = pi - atan(temp);
                else
                    out(i) = atan(temp);
                end
            end
        end
    end
end
out(nt) = 0;
end