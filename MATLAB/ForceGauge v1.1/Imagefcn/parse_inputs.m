function [A,m,method,classIn,h] = parse_inputs(varargin)
% Outputs:  A       the input image
%           m       the resize scaling factor or the new size
%           method  interpolation method (nearest,bilinear,bicubic)
%           class   storage class of A
%           h       if 0, skip filtering; if non-zero scalar, use filter 
%                   of size h; otherwise h is the anti-aliasing filter.

switch nargin
case 2,                        % imresize(A,m)
   A = varargin{1};
   m = varargin{2};
   method = 'nearest';
   classIn = class(A);
   h = [];
case 3,                        % imresize(A,m,method)
   A = varargin{1};
   m = varargin{2};
   method = varargin{3};
   classIn = class(A);
   h = [];
case 4,
   if isstr(varargin{3})       % imresize(A,m,method,h)
      A = varargin{1};
      m = varargin{2};
      method = varargin{3};
      classIn = class(A);
      h = varargin{4};
   else                        % imresize(r,g,b,m)
      for i=1:3
         if isa(varargin{i},'uint8')
            error('Please use 3-d RGB array syntax with uint8 image data');
         end
      end
      A = zeros([size(varargin{1}),3]);
      A(:,:,1) = varargin{1};
      A(:,:,2) = varargin{2};
      A(:,:,3) = varargin{3};
      m = varargin{4};
      method = 'nearest';
      classIn = class(A);
      h = [];
   end
case 5,                        % imresize(r,g,b,m,'method')
   for i=1:3
      if isa(varargin{i},'uint8')
         error('Please use 3-d RGB array syntax with uint8 image data');
      end
   end
   A = zeros([size(varargin{1}),3]);
   A(:,:,1) = varargin{1};
   A(:,:,2) = varargin{2};
   A(:,:,3) = varargin{3};
   m = varargin{4};
   method = varargin{5};
   classIn = class(A);
   h = [];
case 6,                        % imresize(r,g,b,m,'method',h)
   for i=1:3
      if isa(varargin{i},'uint8')
         error('Please use 3-d RGB array syntax with uint8 image data');
      end
   end
   A = zeros([size(varargin{1}),3]);
   A(:,:,1) = varargin{1};
   A(:,:,2) = varargin{2};
   A(:,:,3) = varargin{3};
   m = varargin{4};
   method = varargin{5};
   classIn = class(A);
   h = varargin{6};
otherwise,
   error('Invalid input arguments.');
end

if isa(A, 'uint8'),     % Convert A to Double grayscale for filtering & interpolation
   A = double(A)/255;
end

method = [lower(method),'   ']; % Protect against short method
method = method(1:3);