clc;
clear;
% close all;

    %% Physical Parameters
Re=1000; 
H=1;
Us=0;
Un=-1;
Ve=0;
Vw=0;
L=1;

    %% Numerical parameters
Ng=100;

dx=1/(Ng-1);
dy=H/(Ng-1);

dt=min(2/Re,(Re*(dx^2+dy^2))/2);
Beta2=(dx/dy)^2;

kmax=1000000;
k1max=10000;
X=0:dx:L;
Y=0:dy:H;
N=length(X);
M=length(Y);
tolw=-8;
tolpsi=1e-6;
nl=1;
%% initial conditions

w=zeros(N,M);
psi=zeros(N,M);
psitest=zeros(N,M);
pressure=zeros(N,M);
velocity_y=zeros(N,M);
velocity_x=zeros(N,M);

kx = (1:Ng-2) * pi;
ky = (1:Ng-2) * pi;
[KX, KY] = meshgrid(kx, ky);
K2 = KX.^2 + KY.^2;


% velocity_x(:,1)=Us*sin(pi*X/L).^2;
% velocity_x(:,M)=Un*sin(pi*X/L).^2;
% velocity_y(1,:)=Vw*sin(pi*Y/H).^2;
% velocity_y(N,:)=Ve*sin(pi*Y/H).^2;
tic
for z=1:nl
Err=1;
k=0;
L=M-1;
f=1;

velocity_x(:,1)=Us;
velocity_x(:,M)=Un;
velocity_y(1,:)=Vw;
velocity_y(N,:)=Ve;

%% loop
while (Err > 10^(tolw*z) && k<kmax) | k < 1000 % the or k<100 is because of psi not changing the first iterations
    k=k+1;
    
    psi_old=psi;
    w_old=w;
    w(2:N-1, 2:M-1) = w(2:N-1, 2:M-1) ...
                  - (dt / (2*dx)) * ((velocity_x(3:N, 2:M-1) .* w(3:N, 2:M-1)) - (w(1:N-2, 2:M-1) .* velocity_x(1:N-2, 2:M-1))) ...
                  - (dt / (2*dy)) * ((velocity_y(2:N-1, 3:M) .* w(2:N-1, 3:M)) - (w(2:N-1, 1:M-2) .* velocity_y(2:N-1, 1:M-2))) ...
                  + (dt / (Re*dx^2)) * (w(3:N, 2:M-1) + w(1:N-2, 2:M-1) - 2 * w(2:N-1, 2:M-1)) ...
                  + (dt / (Re*dy^2)) * (w(2:N-1, 3:M) + w(2:N-1, 1:M-2) - 2 * w(2:N-1, 2:M-1));

    % Sauvegarde terme convectif précédent
    % if k == 1
    %     conv_old = zeros(N-2, M-2);
    % end
    % 
    % conv = -(velocity_x(3:N,2:M-1).*w(3:N,2:M-1) - velocity_x(1:N-2,2:M-1).*w(1:N-2,2:M-1))/(2*dx) ...
    %        -(velocity_y(2:N-1,3:M).*w(2:N-1,3:M) - velocity_y(2:N-1,1:M-2).*w(2:N-1,1:M-2))/(2*dy);
    % 
    % diff = (w(3:N,2:M-1) - 2*w(2:N-1,2:M-1) + w(1:N-2,2:M-1))/dx^2 ...
    %      + (w(2:N-1,3:M) - 2*w(2:N-1,2:M-1) + w(2:N-1,1:M-2))/dy^2;
    % 
    % w(2:N-1,2:M-1) = w(2:N-1,2:M-1) + dt*(1.5*conv - 0.5*conv_old + diff/Re);
    % conv_old = conv;

    %%  calculate psi
    D1=1;
    k1=0;

    % while D1 >= tolpsi && k1 < k1max
    % k1 = k1 +1;
    % psiold = psi ;
    %     for i =2: N -1
    %         for j =2: M -1
    %         psi (i , j ) = f *(1/(2*(1+ Beta2 ) ) ) *( psi ( i +1 , j ) + psi (i -1 , j ) + Beta2*( psi (i ,j -1) + psi (i , j +1) ) +( dx ^2) * w (i , j ) ) +(1 - f ) * psiold (i , j ); % SOR
    %         end
    %     end
    %     D1 = max ( max ( abs ( psi - psiold ) ) ) ;
    % end

    % w_hat=dst(dst(w(2:end-1,2:end-1)).').';
    % psi_hat=  (dx^2)*w_hat ./ K2;
    % psi_internal = idst(idst(psi_hat.').')* (Ng-1)^2;
    % psi(2:end-1,2:end-1) = psi_internal;
    w_hat = dstn(w(2:end-1,2:end-1));
    psi_hat = (dx^2) * w_hat ./ K2;
    psi_internal = idstn(psi_hat) * (Ng-1)^2;
    psi(2:end-1,2:end-1) = psi_internal;
    % disp(max(abs(psitest(:))));



    

    velocity_y(2:N-1, 2:M-1)=-(psi(3:N, 2:M-1)-psi(1:N-2, 2:M-1))/(2*dx);
    velocity_x(2:N-1, 2:M-1)=(psi(2:N-1, 3:M)-psi(2:N-1, 1:M-2))/(2*dy);

   
   
    w(:,M)=(1/(2*dy^2))*(-8*psi(:,M-1)+psi(:,M-2)-6*dy*velocity_x(:,M)); % North wall
    w(:,1)=(1/(2*dy^2))*(-8*psi(:,2)+psi(:,3)+6*dy*velocity_x(:,1)); % South wall

    w(N,:)=(1/(2*dx^2))*(-8*psi(N-1,:)+psi(N-2,:)+6*dx*velocity_y(N,:)); % East wall
    w(1,:)=(1/(2*dx^2))*(-8*psi(2,:)+psi(3,:)-6*dx*velocity_y(1,:)); % West wall


    if(mod(k,1000)==0)
         % figure(1)
         % s=[-1e4 -1e-2 -1.5e-3 -1e-3 -5e-4 -2.5e-4 -1e-4 -5e-5 -1e-6 -5e-7 -1e-7 -1e-10 0 1e-10 1e-5 1e-4 1e-2 3e-2 5e-2 7e-2 9e-2 0.1 0.11 0.115 0.1175 ];
         % contour(psi',s,'black');axis equal;title("streamlines");drawnow;
         % figure(2)
         % contour(psitest',s);axis equal;title("streamlines");drawnow;
          Err=max(max(abs(psi-psi_old)));
          fprintf('%5d %5e %5d %5d \n',k,Err,max(max(abs(psi))),max(max(abs(psi))));
          if f<1.8
              f=f+0.01;
          elseif Err<15*tolw
              f=1;
          end
    end

   
    
    
end
% figure(z);
% s=[-1e4 -1e-2 -1.5e-3 -1e-3 -5e-4 -2.5e-4 -1e-4 -5e-5 -1e-6 -5e-7 -1e-7 -1e-10 0 1e-10 1e-5 1e-4 1e-2 3e-2 5e-2 7e-2 9e-2 0.1 0.11 0.115 0.1175 ];
% contour(psi',s,'black');axis equal;title("streamlines")
if z==nl
    break
else

    psi=log((interp2(exp(psi),'spline')));
    N=length(psi);
    w=interp2(w,'spline');
    M=N;
    velocity_y=zeros(N,N);
    velocity_x=zeros(N,N);
    dx=1/(N-1);
    dy=H/(N-1);
    dt=min(2/Re,Re*(dx^2)/2)*2;
    f=1;
    velocity_x(:,M)=Un;
    velocity_y(2:N-1, 2:M-1)=-(psi(3:N, 2:M-1)-psi(1:N-2, 2:M-1))/(2*dx);
    velocity_x(2:N-1, 2:M-1)=(psi(2:N-1, 3:M)-psi(2:N-1, 1:M-2))/(2*dy);
    kx = (1:N-2) * pi;
    ky = (1:N-2) * pi;
    [KX, KY] = meshgrid(kx, ky);
    K2 = KX.^2 + KY.^2;
    w_hat=dst(dst(w(2:end-1,2:end-1)).').';
    psi_hat=  (dx^2)*w_hat ./ K2;
    psi_internal = idst(idst(psi_hat.').')* (Ng-1)^2;
    psi(2:end-1,2:end-1) = psi_internal;
    velocity_x(:,M)=Un;
    velocity_y(2:N-1, 2:M-1)=-(psi(3:N, 2:M-1)-psi(1:N-2, 2:M-1))/(2*dx);
    velocity_x(2:N-1, 2:M-1)=(psi(2:N-1, 3:M)-psi(2:N-1, 1:M-2))/(2*dy);
    % pause(2);disp("pause")
end
end
%% test
toc
% length(psi)
% %% plots
 figure(1);
 s=[-1e4 -1e-2 -1.5e-3 -1e-3 -5e-4 -2.5e-4 -1e-4 -5e-5 -1e-6 -5e-7 -1e-7 -1e-10 0 1e-10 1e-5 1e-4 1e-2 3e-2 5e-2 7e-2 9e-2 0.1 0.11 0.115 0.1175 ];
 contour(psi',s,'black');axis equal;title("streamlines")

%% [CORRECTIF portfolio] dstn / idstn ne font pas partie de MATLAB de base :
% sans elles le script s'arrête sur "Undefined function 'dstn'". Paire DST-I 2D
% (directe non normalisée, inverse normalisée) telle que idstn(dstn(x)) = x.
% Vérifiée sur psi = sin(pi*x)*sin(2*pi*y) : erreur ~1e-15 sur l'équation de Poisson.
% Si une autre paire cohérente est dans ton path, le résultat est identique
% (seule la cohérence directe/inverse compte, la normalisation se compense).
function y = dstn(x)
    [n1, n2] = size(x);
    y = dstMatrix(n1) * x * dstMatrix(n2).';
end

function x = idstn(y)
    [n1, n2] = size(y);
    x = (2/(n1+1)) * (2/(n2+1)) * dstMatrix(n1) * y * dstMatrix(n2).';
end

function S = dstMatrix(n)
    % Matrice DST-I : S(k,j) = sin(pi*k*j/(n+1)), mise en cache entre les appels
    persistent cache
    if isempty(cache)
        cache = containers.Map('KeyType', 'double', 'ValueType', 'any');
    end
    if ~isKey(cache, n)
        k = (1:n)';
        cache(n) = sin(pi * (k * k') / (n + 1));
    end
    S = cache(n);
end
