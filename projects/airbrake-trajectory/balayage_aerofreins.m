%% balayage_aerofreins.m
% Balayage de l'altitude de déploiement des aérofreins H, pour le curseur du portfolio.
% Lance d'abord Trajectoire_Aerofreins_v3.m (paramètres, phase propulsée, trajectoire sans
% aérofreins), puis refait la phase aérofreins pour chaque H. Ton script n'est pas modifié.
%
% A placer dans le même dossier que Trajectoire_Aerofreins_v3.m, Drag.csv et Mach.csv.
% Sorties dans le dossier slider_af/ :
%   traj_H1100.png, traj_H1200.png, ...  une image par H, axes identiques
%   apogee_vs_H.csv                      H, apogée, portée au sol
%   traj_H1100.csv, ...                  trajectoire avec aérofreins (x, y), allégée
%   sans_af.csv, propulsion.csv          courbes de référence (x, y)

clear; close all; clc;

%% 1) Ton script : paramètres + trajectoire sans aérofreins (x1) + propulsion (x5)
run('Trajectoire_Aerofreins_v3.m');   % H = H_sortie dans ton script ; X0 = état en fin de propulsion
close all;

% Table "aérofreins rentrés" : même table de Mach, force nulle.
% L'ancienne version ([Mach_a,F_a] puis ligne 2 mise à 0, sans transposée) donne NaN dès que H ~= H_sortie.
F_a_mach0 = [Mach_a, zeros(size(F_a))]';

%% 2) Réglages du balayage
dH = 100;                                   % pas du curseur (m)
apogee_sans = max(x1(:,2));
% H_sortie, puis des valeurs rondes (1200, 1300, ...) jusqu'à juste sous l'apogée
Hs = unique([H_sortie, ceil(H_sortie/dH)*dH : dH : floor((apogee_sans - 50)/dH)*dH]);
outDir = 'slider_af';
if ~exist(outDir, 'dir'), mkdir(outDir); end

xl = [0, 1.05*max(x1(:,1))];                % mêmes axes pour toutes les images
yl = [0, 1.10*apogee_sans];

apo = zeros(size(Hs));
portee = zeros(size(Hs));

%% 3) Une simulation par altitude de déploiement
for i = 1:numel(Hs)
    H = Hs(i);

    if H > H_sortie
        % montée aérofreins rentrés jusqu'à H (comme ton script, lignes 164-170)
        opt = odeset('RelTol',1e-10,'Events',@(t,X)Aerofreins(t,X,H));
        [ta, xa] = ode45(@(t,y) rocket_dynamics(t,y,g,Cd_Fusex,F_a_mach0,Sref_Fusex,rho,Masse_Moteur_Vide,A_sortie,0), tspan, X0, opt);
        Y0 = xa(end,:);
        t_dep = ta(end);
        tsp2 = linspace(t_dep, 100, 20000);
    else
        Y0 = X0;
        t_dep = 0;
        tsp2 = tspan;
    end

    % aérofreins sortis jusqu'à l'apogée
    opt = odeset('RelTol',1e-10,'Events',@(t,X)stopapogee(t,X,X0));
    [tb, yb] = ode45(@(t,y) rocket_dynamics(t,y,g,Cd_Fusex,F_a_mach,Sref_Fusex,rho,Masse_Moteur_Vide,A_sortie,t_dep), tsp2, Y0, opt);

    % descente aérofreins sortis, sans parachute (comme ton script, lignes 186-188)
    opt = odeset('RelTol',1e-10,'Events',@(t,X)stopend(t,X,X0));
    tsp3 = linspace(tb(end), 500, 2000);
    [tc, yc] = ode45(@(t,y) rocket_dynamics(t,y,g,Cd_Fusex,F_a_mach,Sref_Fusex,rho,Masse_Moteur_Vide,A_sortie,t_dep), tsp3, yb(end,:), opt);

    apo(i) = max(yb(:,2));
    portee(i) = yc(end,1);
    fprintf('H = %4d m  ->  apogee = %6.0f m   portee = %6.0f m\n', H, apo(i), portee(i));

    % image (sans texte de légende : la page l'affiche en FR/EN)
    fig = figure('Color','w','Position',[100 100 900 560],'Visible','off');
    ax = axes('Parent', fig); hold(ax, 'on');
    if exist('x5', 'var')                                                              % propulsion, si ton script la calcule
        plot(ax, x5(:,1), x5(:,2), 'Color',[0.55 0.55 0.55], 'LineWidth',1.5);
    end
    plot(ax, x1(:,1), x1(:,2), 'Color',[0.20 0.35 0.80], 'LineWidth',2);                % sans aérofreins
    plot(ax, [yb(:,1); yc(:,1)], [yb(:,2); yc(:,2)], 'Color',[0.85 0.20 0.15], 'LineWidth',2.5); % avec aérofreins
    plot(ax, Y0(1), Y0(2), 'ko', 'MarkerFaceColor','k', 'MarkerSize',7);               % point de déploiement
    plot(ax, xl, [3000 3000], '--', 'Color',[0.4 0.4 0.4], 'LineWidth',1);             % plafond C'Space
    text(ax, xl(2)*0.98, 3000, '3000 m', 'HorizontalAlignment','right', 'VerticalAlignment','bottom', 'Color',[0.4 0.4 0.4]);
    xlim(ax, xl); ylim(ax, yl);
    xlabel(ax, 'distance (m)'); ylabel(ax, 'altitude (m)');
    grid(ax, 'on'); box(ax, 'on');
    print(fig, fullfile(outDir, sprintf('traj_H%04d.png', round(H))), '-dpng', '-r110');
    close(fig);

    % données (pour un tracé directement dans la page)
    writematrix(decim([yb(:,1:2); yc(:,1:2)], 400), fullfile(outDir, sprintf('traj_H%04d.csv', round(H))));
end

%% 4) Résumé et courbes de référence
writetable(array2table([Hs(:) apo(:) portee(:)], 'VariableNames', {'H_m','apogee_m','portee_m'}), ...
    fullfile(outDir, 'apogee_vs_H.csv'));
writematrix(decim(x1(:,1:2), 400), fullfile(outDir, 'sans_af.csv'));
if exist('x5', 'var')
    writematrix(decim(x5(:,1:2), 200), fullfile(outDir, 'propulsion.csv'));
end
fprintf('Apogee sans aerofreins : %.0f m\n%d images ecrites dans %s\n', apogee_sans, numel(Hs), fullfile(pwd, outDir));

%% Fonctions locales (copies de Trajectoire_Aerofreins_v3.m)

function DX = rocket_dynamics(t, X, g, C_da, F_a_mach, A, rho, m, Ax, t_dep)
% Identique à ton script, sauf la rampe de sortie des aérofreins : elle part de l'instant
% de déploiement t_dep. Dans l'original elle part de t = 0, donc elle ne s'applique que
% si H = H_sortie ; au-delà, les aérofreins sortiraient instantanément.
acc=0;
global Tsortie;
y = X(2);
vx = X(3);
vy = X(4);
if t==0
    acc=Ax;
end
V=sqrt(vx^2+vy^2);
c=sqrt(1.4*287.05*(288.15-0.0065*y));
M=V/c;
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
    if t - t_dep < Tsortie
        F_d = F_d*(t - t_dep)/Tsortie;
    end
end
D=D+F_d;
dgamma=-(g/V)*cos(X(5));
dvxdt=(-D/m+acc/m)*cos(X(5));
dvydt=(-D/m+acc/m)*sin(X(5))-g;
DX = [X(3); X(4); dvxdt; dvydt; dgamma];
end

function [position,isterminal,direction] = Aerofreins(t,X,H)
position = X(2)-H;
isterminal = 1;
direction = 0;
end

function [position,isterminal,direction] = stopend(t,X,X0)
position = X(2)- 1e-2;
isterminal = 1;
direction = 0;
end

function [position,isterminal,direction] = stopapogee(t,X,X0)
position = X(4);
isterminal = 1;
direction = 0;
end

function B = decim(A, n)
% n points régulièrement espacés le long de la courbe (abscisse curviligne), pour des
% fichiers légers. Un allègement par indice garderait trop peu de points dans la descente,
% où ode45 en sort beaucoup moins que pendant la montée.
s = [0; cumsum(hypot(diff(A(:,1)), diff(A(:,2))))];
[s, iu] = unique(s);
A = A(iu, :);
si = linspace(0, s(end), min(n, numel(s)))';
B = [interp1(s, A(:,1), si), interp1(s, A(:,2), si)];
end
