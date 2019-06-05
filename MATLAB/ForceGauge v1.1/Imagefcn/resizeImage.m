function b = resizeImage(A,m,method,h)
% Inputs:
%         A       Input Image
%         m       resizing factor or 1-by-2 size vector
%         method  'nearest','bilinear', or 'bicubic'
%         h       the anti-aliasing filter to use.
%                 if h is zero, don't filter
%                 if h is an integer, design and use a filter of size h
%                 if h is empty, use default filter

if prod(size(m))==1,
   bsize = floor(m*size(A));
else
   bsize = m;
end

if any(size(bsize)~=[1 2]),
   error('M must be either a scalar multiplier or a 1-by-2 size vector.');
end

% values in bsize must be at least 1.
bsize = max(bsize, 1);

if (any((bsize < 4) & (bsize < size(A))) & ~strcmp(method, 'nea'))
   fprintf('Input is too small for bilinear or bicubic method;\n');
   fprintf('using nearest-neighbor method instead.\n');
   method = 'nea';
end

if isempty(h),
   nn = 11; % Default filter size
else
   if prod(size(h))==1, 
      nn = h; h = []; 
   else 
      nn = 0;
   end
end

[m,n] = size(A);

if nn>0 & method(1)=='b',  % Design anti-aliasing filter if necessary
   if bsize(1)1 | length(h2)>1, h = h1'*h2; else h = []; end
   if length(h1)>1 | length(h2)>1, 
      a = filter2(h1',filter2(h2,A)); 
   else 
      a = A; 
   end
elseif method(1)=='b' & (prod(size(h)) > 1),
   a = filter2(h,A);
else
   a = A;
end

if method(1)=='n', % Nearest neighbor interpolation
   dx = n/bsize(2); dy = m/bsize(1); 
   uu = (dx/2+.5):dx:n+.5; vv = (dy/2+.5):dy:m+.5;
elseif all(method == 'bil') | all(method == 'bic'),
   uu = 1:(n-1)/(bsize(2)-1):n; vv = 1:(m-1)/(bsize(1)-1):m;
else
   error(['Unknown interpolation method: ',method]);
end

%
% Interpolate in blocks
%
nu = length(uu); nv = length(vv);
blk = bestblk([nv nu]);
nblks = floor([nv nu]./blk); nrem = [nv nu] - nblks.*blk;
mblocks = nblks(1); nblocks = nblks(2);
mb = blk(1); nb = blk(2);

rows = 1:blk(1); b = zeros(nv,nu);
for i=0:mblocks,
   if i==mblocks, rows = (1:nrem(1)); end
   for j=0:nblocks,
      if j==0, cols = 1:blk(2); elseif j==nblocks, cols=(1:nrem(2)); end
      if ~isempty(rows) & ~isempty(cols)
         [u,v] = meshgrid(uu(j*nb+cols),vv(i*mb+rows));
         % Interpolate points
         if method(1) == 'n', % Nearest neighbor interpolation
            b(i*mb+rows,j*nb+cols) = interp2(a,u,v,'*nearest');
         elseif all(method == 'bil'), % Bilinear interpolation
            b(i*mb+rows,j*nb+cols) = interp2(a,u,v,'*linear');
         elseif all(method == 'bic'), % Bicubic interpolation
            b(i*mb+rows,j*nb+cols) = interp2(a,u,v,'*cubic');
         end
      end
   end
end

if nargout==0,
   if isgray(b), imshow(b,size(colormap,1)), else imshow(b), end
   return
end

if isgray(A)   % This should always be true
   b = max(0,min(b,1));  
end