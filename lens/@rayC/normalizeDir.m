function obj = normalizeDir(obj)
%obj = normalizeDir(obj)
%normalizes all direction vectors so that the 2-norm is 1
obj.direction = normvec(obj.direction,'p',2,'dim',2);
end

