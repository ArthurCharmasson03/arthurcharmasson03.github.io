%% INTEGRATION, EQ DE MVMT DE LA FUSEX , PREDIRE APOGEE AVEC UTILISATION DES AEROFREINS CHIRON
%% IMPORTANT : METTRE A JOUR LES VARIABLES SI LE DESIGN A CHANGE
close all
%% Parametres de la fusex

Masse_Moteur_Vide=5.938; %kg
Masse_moteur_Plein=1.795+Masse_Moteur_Vide;
% Cd_Fusex=0.6;
D_Fusex=83e-3; %m2
Sref_Fusex=pi*D_Fusex^2 / 4; %m^2

%% Table Cd(Mach) pour la fusex
Drag=table2array(readtable("Drag.csv"));
Mach=table2array(readtable("Mach.csv"));
Drag_Mach=[Mach,Drag]';
[~, uniqueIdx] = unique(Drag_Mach(1,:)', 'rows', 'stable');  % 'stable' pour conserver l'ordre

% Garder les colonnes uniques dans A
Drag_Mach_u = Drag_Mach(:, uniqueIdx);
[~, sortedIdx] = sort(Drag_Mach_u(1, :));  % Trie les indices en fonction des valeurs de Mach
% Appliquer le tri aux colonnes du tableau

Cd_Fusex= Drag_Mach_u(:, sortedIdx);
%% Parametre du parachute
% D_Para =
% S_Para = Pi* D_Para^2 /4;
S_Para=0.82; % m^2
Cd_Para = 1;

%% Parametre du moteur
ISP=214;
t_comb=4.68;
Fthrust = [0,27.28,1795-1795
0.01,402.41,1795-1793.96
0.1,1285.54,1795-1793.96 
0.12,1056.51,1795-1746.05
0.26,1041.73,1795-1675.23
0.71,1026.95,1795-1450.81
1.28,998.38,1795-1172.5
2.05,901.36,1795-819.845
2.41,849.64,1795-667.878
2.83,763.51,1795-504.541
3.25,707.06,1795-355.641
3.65,655.14,1795-224.282
3.8,651.74,1795-177.022
4,624.07,1795-115.508
4.1,601.34,1795-85.966
4.19,536.17,1795-61.2852
4.31,415.67,1795-33.7489
4.41,270.17,1795-17.2147
4.52,140.2,1795-6.33224
4.6,76.92,1795-2.14479
4.65,54.94,1795-0.555351
4.67,40.16,1795-0.0968175
4.68,0,1795-0
]';

%% Recupération des informations après la phase de propulsion de la fusée sur le stabtraj

A_sortie=60; %m/s^2
V_sortie=374.5;  %m/s
H_sortie=1100; %m
X_sortie=282;  %m
Alpha_sortie=deg2rad(74.3); %rad

%% Aerofreins
global Tsortie; % variable globale ( flemme de l'utilser comme input )
Tsortie = 0.5; %s temps que l'AF prend a sortir

Mach_a = [ 1.2
    1.15
    1.1
    1.05
    1
    0.95
    0.9
    0.85
    0.8
    0.75
    0.7
    0.65
    0.6
    0.55
    0.5
    0.45
    0.4
    0.35
    0.3
    0.25
    0.2
    0.15
    0.1
    0.05
    ];

F_a = [58.27
58.82
59.47
60.23
61.13
55.03
49.25
43.80
38.68
33.89
29.42
25.28
21.47
17.97
14.80
11.95
9.41
7.19
5.27
3.67
2.37
1.37
0.66
0.18

];

F_a_mach=[Mach_a,F_a]';% a verifier avec CFD ( pour geometrie triangulaire https://www.grc.nasa.gov/www/k-12/VirtualAero/BottleRocket/airplane/shaped3.html#:~:text=A%20flat%20plate%20has%20Cd.typical%20airfoil%20has%20a%20Cd%20%3D%20.)
% [CORRECTIF portfolio] La matrice n'était pas transposée : (2,:)=0 annulait une ligne de Mach
% au lieu de la ligne des forces, ce qui rendait la trajectoire NaN dès que H ~= H_sortie.
% Original :
% F_a_mach0=[Mach_a,F_a];
% F_a_mach0(2,:)=0;
F_a_mach0=[Mach_a,zeros(size(F_a))]'; % même table de Mach, force aérofreins nulle (AF rentrés)
% S_Aerofrein=1200e-6; % m^2
% N_Aerofrein=4;

%% PARAMETRES DE SIMULATION :

H=H_sortie; % Altitude d'utilisation des AEROFREINS [m]
Retrait_Aerofreins_Apogee=0; % 1=oui | 0=non
g = 9.81; % m/s²
rho = 1.225; % densité de l'air en kg/m³
%{
    approximation du Cd de la fusée avec des moyennes (a peu près correct, plus rapide que la cfd je crois)
    Sref=Sref_Fusex+N_Aerofrein*S_Aerofrein;
    Cd_Total=Cd_Fusex;
    Cd_Total(2,:)=Cd_Fusex(2,:)*(Sref_Fusex/Sref)+(S_Aerofrein*N_Aerofrein/Sref)*Cd_Aerofreins;
%}
%% SIMULATION
X0 = [0;0.5;0;0;deg2rad(80)];
tspan5 = linspace(0, t_comb, 250);
tspan = linspace(0, 60, 20000);
options = odeset('RelTol',1e-10,'Events',@(t,X)stopend(t,X,H));
    [t5, x5] = ode45(@(t, y) rocket_dynamics_thrust(t, y, g, Cd_Fusex,0, Sref_Fusex, rho, Masse_moteur_Plein,0,Fthrust,tspan(1),ISP), tspan5, X0,options);

if Retrait_Aerofreins_Apogee==0
    disp("Aerofreins déployés lors de la descente");
else
    disp("Aerofreins retractés lors de la descente");
end
% Conditions initiales [x0, y0, vx0, vy0] en m et m/s
X0 = [X_sortie; H_sortie; V_sortie*cos(Alpha_sortie); V_sortie*sin(Alpha_sortie);Alpha_sortie]; % position initiale (x=0, y=0), vitesse initiale (vx=100 m/s, vy=200 m/s)

% Temps de simulation
% tspan = linspace(0, 60, 20000); % temps de simulation de 0 à 100 secondes

% Résolution des équations différentielles
if H ~= H_sortie
    options = odeset('RelTol',1e-10,'Events',@(t,X)Aerofreins(t,X,H));
    [t, x] = ode45(@(t, y) rocket_dynamics(t, y, g, Cd_Fusex,F_a_mach0, Sref_Fusex, rho, Masse_Moteur_Vide,A_sortie), tspan, X0,options);


    tspan2=linspace(t(end),100,20000);
    Y0=x(end,:);
else
    Y0=X0;
    tspan2=tspan;
end

options = odeset('RelTol',1e-10,'Events',@(t,X)stopapogee(t,X,X0));
[t1, y] = ode45(@(t, y) rocket_dynamics(t, y, g, Cd_Fusex,F_a_mach, Sref_Fusex, rho, Masse_Moteur_Vide,A_sortie), tspan2, Y0,options);

Y1=y(end,:);
options = odeset('RelTol',1e-10,'Events',@(t,X)stopend(t,X,X0));

%% version avec parachute
tspan3=linspace(t1(end),500,2000);
[t4, y2] = ode45(@(t, y) rocket_dynamics(t, y, g, Cd_Para,0, S_Para, rho, Masse_Moteur_Vide,A_sortie), tspan3, Y1,options);

%% version sans parachute
tspan3=linspace(t1(end),500,2000);
[t2, y1] = ode45(@(t, y) rocket_dynamics(t, y, g, Cd_Fusex,F_a_mach, Sref_Fusex, rho, Masse_Moteur_Vide,A_sortie), tspan3, Y1,options);

%% Trajectoire sans aerofrein ni parachute
options = odeset('RelTol',1e-10,'Events',@(t,X)stopend(t,X,X0));
[t3, x1] = ode45(@(t, y) rocket_dynamics(t, y, g, Cd_Fusex,0, Sref_Fusex, rho, Masse_Moteur_Vide,A_sortie), tspan2, Y0,options);

%% Tracé de la trajectoire

figure(1); hold on;
h=plot(x5(:,1), x5(:,2),'g', 'LineWidth', 2);
h1=plot(x1(:,1), x1(:,2),'b', 'LineWidth', 2);
h2=plot(y(:,1), y(:,2),'r','LineWidth', 2);
plot(y1(:,1), y1(:,2),'r','LineWidth', 2);
h3=plot(y2(:,1), y2(:,2),'g','LineWidth', 2,'LineStyle', '--');
xlabel('Portée (m)');
ylabel('Alitude (m)');
title('Trajectoire de la fusée après la phase de propulsion');
axis([0 1.1*max(x1(:,1)) 0 1.1*max(x1(:,2))])
legend([h1, h2, h3], {'Sans aérofrein', 'Avec aérofrein', 'Avec aérofrein et parachute'});
grid on;
axis equal;

%% accelerations et vitesses  / pas à jour
% figure(2);hold on;
% % plot(t,sqrt(x(:,3).^2+x(:,4).^2),'b');
% plot(t3,sqrt(x1(:,3).^2+x1(:,4).^2),'b');
% plot(t1,sqrt(y(:,3).^2+y(:,4).^2),'r');
% plot(t2,sqrt(y1(:,3).^2+y1(:,4).^2),'r');
% xlabel('Temps depuis la fin de la propulsion (s)');
% ylabel('Vitesse (m/s)');
% title('Vitesse fusée après phase de propulsion');
% grid on;

% %% Calcul de l'acceleration : FD central
% % df(n) = (df(n+1)-df(n-1))/2dt
% v=sqrt(x(:,3).^2+x(:,4).^2);
% Ax=zeros(length(x(:,1)),1);
% dt=t(2)-t(1);
% Ax(2:end-1)=(v(3:end)-v(1:end-2))/(2*dt);
% Ax(Ax==0)=NaN;
%
% v1=sqrt(x1(:,3).^2+x1(:,4).^2);
% Ax1=zeros(length(x1(:,1)),1);
% dt=t3(2)-t3(1);
% Ax1(2:end-1)=(v1(3:end)-v1(1:end-2))/(2*dt);
% Ax1(Ax1==0)=NaN;
%
% v2=sqrt(y(:,3).^2+y(:,4).^2);
% Ay=zeros(length(y(:,1)),1);
% dt=t1(2)-t1(1);
% Ay(2:end-1)=(v2(3:end)-v2(1:end-2))/(2*dt);
% Ay(Ay==0)=NaN;
%
% if Retrait_Aerofreins_Apogee==1
%     v3=sqrt(y1(:,3).^2+y1(:,4).^2);
%     Ay1=zeros(length(y1(:,1)),1);
%     dt=t2(2)-t2(1);
%     Ay1(2:end-1)=(v3(3:end)-v3(1:end-2))/(2*dt);
%     Ay1(Ay1==0)=NaN;
% end
%
% figure(3);hold on;
% plot(t,Ax,'b');
% plot(t3,Ax1,'b');
% plot(t1,Ay,'r');
% if Retrait_Aerofreins_Apogee==1
%     plot(t2,Ay1,'r');
% end
% xlabel('Temps depuis la fin de la propulsion (s)');
% ylabel('Acceleration (m/s^2)');
% title('Acceleration de la fusée après phase de propulsion');
% grid on;

%% resultats
disp("Temps de sortie des aérofreins : " + Tsortie + "s")
disp("     | Altitude Max (m) | Portee Max (m) | T à x=0 (s)")
disp("-------------------------------------------------")
disp("Sans |     "+max(x1(:,2)) + "    |    " + max(x1(:,1)) + "   |   " + t3(end)+ "   | ")
disp("-------------------------------------------------")
disp("Avec |     "+max(y(:,2)) + "    |    " + max(y1(:,1)) + "    |   " + t2(end)+ "  | ")

%% Fonctions

function DX = rocket_dynamics(t, X, g, C_da,F_a_mach, A, rho, m,Ax)
% y(1) = x, y(2) = y, y(3) = vx, y(4) = vy gamma =y(5)
acc=0;
global Tsortie;

x = X(1);
y = X(2);
vx = X(3);
vy = X(4);

if t==0
    acc=Ax;
end

V=sqrt(vx^2+vy^2);% Vitesse totale
c=sqrt(1.4*287.05*(288.15-0.0065*y));
M=V/c;

% Calcul de la trainée

if isscalar(C_da)
    C_d=C_da;
else
    C_d = interp1(C_da(1, :), C_da(2, :), M, 'linear');
end

rho=rho*(1-(0.0065*y)/288.15)^((g*0.029)/(8.314*0.0065)-1);
D = 0.5 * C_d * A * rho * V^2;

if F_a_mach==0
    F_d=0;
else
    F_d= 4*interp1(F_a_mach(1, :), F_a_mach(2, :), M, 'linear');
    if t<Tsortie
        F_d = F_d *t/Tsortie;
    end
end

D=D+F_d;

% Équations de mouvement
dxdt=X(3);
dydt=X(4);

dgamma=-(g/V)*cos(X(5));
dvxdt=(-D/m+acc/m)*cos(X(5));
dvydt=(-D/m+acc/m)*sin(X(5))-g;

DX = [dxdt; dydt; dvxdt; dvydt; dgamma];
end

function DX = rocket_dynamics_thrust(t, X, g, C_da,F_a_mach, A, rho, m,Ax,F,dt,Isp)
% y(1) = x, y(2) = y, y(3) = vx, y(4) = vy gamma =y(5)
acc=0;
global Tsortie;

x = X(1);
y = X(2);
vx = X(3);
vy = X(4);

% if t==0
%     acc=Ax;
% end

V=sqrt(vx^2+vy^2);% Vitesse totale
c=sqrt(1.4*287.05*(288.15-0.0065*y));
M=V/c;
m=m-(interp1(F(1, :), F(3, :), t, 'linear'))/1000;
% Calcul de la trainée

if isscalar(C_da)
    C_d=C_da;
else
    C_d = interp1(C_da(1, :), C_da(2, :), M, 'linear');
end

if isnan(C_d)
    C_d=0.62;
end

FThrust = interp1(F(1, :), F(2, :), t, 'spline');

rho=rho*(1-(0.0065*y)/288.15)^((g*0.029)/(8.314*0.0065)-1);

D = 0.5 * C_d * A * rho * V^2;
if V<1
    D=0;
    dgamma=0;
else
    dgamma=-(g/V)*cos(X(5));
end

if F_a_mach==0
    F_d=0;
else
    F_d= 4*interp1(F_a_mach(1, :), F_a_mach(2, :), M, 'linear');
    if t<Tsortie
        F_d = F_d *t/Tsortie;
    end
end

D=D+F_d;
disp(D-FThrust)
% Équations de mouvement
dxdt=X(3);
dydt=X(4);

dvxdt=(acc + FThrust -D)*cos(X(5))/m;
dvydt=(acc + FThrust -D)*sin(X(5))/m-g;
% dvxdt=max((-D/m +acc/m + FThrust/m )*cos(X(5)),0)
% dvydt=max((-D/m +acc/m + FThrust/m )*sin(X(5))-g,0)
DX = [dxdt; dydt; dvxdt; dvydt; dgamma];
end

function [position,isterminal,direction] = Aerofreins(t,X,H)
position = X(2)-H;                % The value that we want to be zero
isterminal = 1;                   % Halt integration
direction = 0;                    % The zero can be approached from either direction
end

function [position,isterminal,direction] = stopend(t,X,X0)
position = X(2)- 1e-2;            % The value that we want to be zero
isterminal = 1;                   % Halt integration
direction = 0;                    % The zero can be approached from either direction
end

function [position,isterminal,direction] = stopapogee(t,X,X0)
position = X(4);                  % The value that we want to be zero
isterminal = 1;                   % Halt integration
direction = 0;                    % The zero can be approached from either direction
end
function [position,isterminal,direction] = stopcomb(t,tcomb,X,X0)
position = t-tcomb;                  % The value that we want to be zero
isterminal = 1;                   % Halt integration
direction = 0;                    % The zero can be approached from either direction
end