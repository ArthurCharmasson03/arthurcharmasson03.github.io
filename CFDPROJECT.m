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
Ng=500;
% dx=0.001;
% dy=0.001;
dx=1/(Ng-1);
dy=H/(Ng-1);

dt=min(2/Re,(Re*(dx^2+dy^2))/2);
Beta2=(dx/dy)^2;

kmax=1000000;
k1max=5000;
X=0:dx:L;
Y=0:dy:H;
N=length(X);
M=length(Y);
tolw=1e-7;
tolpsi=1e-4;

% rho=0.25*(cos(pi/(N-1))+cos(pi/M-1));
% f=2/(1+sqrt(1-rho^2));
f=1.3;
% f=1;
    %% initial conditions

w=zeros(N,M);
psi=zeros(N,M);
pressure=zeros(N,M);
velocity_y=zeros(N,M);
velocity_x=zeros(N,M);

velocity_x(:,1)=Us;
velocity_x(:,M)=Un;
velocity_y(1,:)=Vw;
velocity_y(N,:)=Ve;

% velocity_x(:,1)=Us*sin(pi*X/L).^2;
% velocity_x(:,M)=Un*sin(pi*X/L).^2;
% velocity_y(1,:)=Vw*sin(pi*Y/H).^2;
% velocity_y(N,:)=Ve*sin(pi*Y/H).^2;

Err=1;
k=0;
L=M-1;
tic
%% loop
while (Err > tolw && k<kmax) | k < 100 % the or k<100 is because of psi not changing the first iterations
    k=k+1;
    psi_old=psi;

    w(2:N-1, 2:M-1) = w(2:N-1, 2:M-1) ...
                  - (dt / (2*dx)) * ((velocity_x(3:N, 2:M-1) .* w(3:N, 2:M-1)) - (w(1:N-2, 2:M-1) .* velocity_x(1:N-2, 2:M-1))) ...
                  - (dt / (2*dy)) * ((velocity_y(2:N-1, 3:M) .* w(2:N-1, 3:M)) - (w(2:N-1, 1:M-2) .* velocity_y(2:N-1, 1:M-2))) ...
                  + (dt / (Re*dx^2)) * (w(3:N, 2:M-1) + w(1:N-2, 2:M-1) - 2 * w(2:N-1, 2:M-1)) ...
                  + (dt / (Re*dy^2)) * (w(2:N-1, 3:M) + w(2:N-1, 1:M-2) - 2 * w(2:N-1, 2:M-1));
    %%  calculate psi
    D1=1;
    k1=0;

    while D1 >= tolpsi && k1 < k1max
    k1 = k1 +1;
    psiold = psi ;
        for i =2: N -1
            for j =2: M -1
            psi (i , j ) = f *(1/(2*(1+ Beta2 ) ) ) *( psi ( i +1 , j ) + psi (i -1 , j ) + Beta2*( psi (i ,j -1) + psi (i , j +1) ) +( dx ^2) * w (i , j ) ) +(1 - f ) * psiold (i , j ); % SOR
            end
        end
        D1 = max ( max ( abs ( psi - psiold ) ) ) ;
    end

    velocity_y(2:N-1, 2:M-1)=-(psi(3:N, 2:M-1)-psi(1:N-2, 2:M-1))/(2*dx);
    velocity_x(2:N-1, 2:M-1)=(psi(2:N-1, 3:M)-psi(2:N-1, 1:M-2))/(2*dy);

    

    w(:,M)=(1/(2*dy^2))*(-8*psi(:,M-1)+psi(:,M-2)-6*dy*velocity_x(:,M)); % North wall
    w(:,1)=(1/(2*dy^2))*(-8*psi(:,2)+psi(:,3)+6*dy*velocity_x(:,1)); % South wall

    w(N,:)=(1/(2*dx^2))*(-8*psi(N-1,:)+psi(N-2,:)+6*dx*velocity_y(N,:)); % East wall
    w(1,:)=(1/(2*dx^2))*(-8*psi(2,:)+psi(3,:)-6*dx*velocity_y(1,:)); % West wall

    if(mod(k,100)==0)
          Err=max(max(abs(psi-psi_old)));
          fprintf('%5d %5d %5e %5d \n',k,k1,Err,max(max(psi)));
          if f<1.8
              f=f+0.01;
          elseif Err<15*tolw
              f=1;
          end
    end

    

    
    
end
toc

%% plots
 figure(1);
 s=[-1e4 -1e-2 -1.5e-3 -1e-3 -5e-4 -2.5e-4 -1e-4 -5e-5 -1e-6 -5e-7 -1e-7 -1e-10 0 1e-10 1e-5 1e-4 1e-2 3e-2 5e-2 7e-2 9e-2 0.1 0.11 0.115 0.1175 ];
 contour(psi',s,'black');axis equal;title("streamlines")
 % figure(2);
%  % contour(w')
%  figure(3);
%  plot(w(:,M));
%  xlim([0 100]);title("vorticity profile on the north wall")


