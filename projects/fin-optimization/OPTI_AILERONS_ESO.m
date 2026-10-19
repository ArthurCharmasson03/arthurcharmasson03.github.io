%% OPTIMISATION D'AILERONS AVEC ELEMENTS FINIS ET EQUATIONS DE BARROWMAN
% Version avec calcul MEF intégré
% Lancer ce script pour démarrer l'application
%
% Algo dev par Arthur CHARMASSON / Arthur.Charmasson@estaca.eu
%
% Interface faite avec IA CLAUDE
% Sources : 
%
% https://www.nakka-rocketry.net/RD_fin.htm
% http://mae-nas.eng.usu.edu/MAE_5900_Web/5900/USLI_2010/PDF_files/rocket_handbook.pdf
%
% nécessite un StabTraj complet
%
%
% TODO LIST : 
%
%
% ANALYSE SUPERSONIQUE / TRANSONIQUE
% ANALYSE MEF 2D / 3D 


clc; close all; clear;

%% Lancement de l'application
fprintf('Lancement de l''interface d''optimisation avec MEF...\n');
createSimpleGUI();

%% FONCTION PRINCIPALE DE L'INTERFACE
function createSimpleGUI()
    % Création de la fenêtre principale
    fig = figure('Name', 'Optimisation d''Ailerons', ...
        'NumberTitle', 'off', ...
        'Position', [100 100 1100 800], ...
        'MenuBar', 'none', ...
        'ToolBar', 'none', ...
        'Resize', 'off');
    
    % Structure pour stocker les données
    handles = struct();
    
    %% PANNEAU 0: TYPE DE FUSÉE (Gauche haut)
    panel0 = uipanel(fig, ...
        'Title', 'Type de Fusée', ...
        'Position', [0.02 0.85 0.35 0.13], ...
        'FontSize', 10, ...
        'FontWeight', 'bold');
    
    % Groupe de boutons radio pour le type
    handles.type_group = uibuttongroup(panel0, ...
        'Position', [0.05 0.1 0.9 0.85], ...
        'SelectionChangedFcn', @typeChanged);
    
    handles.radio_minif = uicontrol(handles.type_group, ...
        'Style', 'radiobutton', ...
        'String', 'Minifusée (CDC VL4)', ...
        'Position', [10 40 200 25], ...
        'FontSize', 9);
    
    handles.radio_fusex = uicontrol(handles.type_group, ...
        'Style', 'radiobutton', ...
        'String', 'Fusée Expérimentale (CDC STAB)', ...
        'Position', [10 15 200 25], ...
        'FontSize', 9, ...
        'Value', 1); % Fusex par défaut
    
    % Affichage des critères actuels
    handles.criteria_text = uicontrol(panel0, ...
        'Style', 'text', ...
        'String', 'CDC: 2<MS<6, 15<Cn<40, 40<MS×Cn<100', ...
        'Position', [240 20 120 50], ...
        'HorizontalAlignment', 'left', ...
        'FontName', 'FixedWidth', ...
        'FontSize', 8, ...
        'BackgroundColor', [0.95 0.95 0.95]);
    
    %% PANNEAU 1: PARAMÈTRES D'ENTRÉE (Gauche)
    panel1 = uipanel(fig, ...
        'Title', 'Paramètres de la Fusée', ...
        'Position', [0.02 0.35 0.35 0.48], ...
        'FontSize', 10, ...
        'FontWeight', 'bold');
    
    % Liste des paramètres
    params = {
        'Diamètre fusée (cm):', 'D_fusex', '15';
        'Coefficient Cx:', 'Cx', '0.45';
        'Accélération max (g):', 'accelmax', '15';
        'Vitesse max (m/s):', 'vmax', '250';
        'Nombre d''ailerons:', 'N_ailerons', '4';
        'Épaisseur (mm):', 'e_aileron', '3';
        'Position base (cm):', 'position_bas', '80';
        'Longueur ogive (cm):', 'L_Ogive', '30';
        'Longueur fusée (cm):', 'L_fusee', '120'
    };
    
    % Création des champs
    for i = 1:length(params)
        y_pos = 320 - (i-1)*35;
        
        uicontrol(panel1, 'Style', 'text', ...
            'String', params{i,1}, ...
            'Position', [10 y_pos 120 20], ...
            'HorizontalAlignment', 'left');
        
        handles.(params{i,2}) = uicontrol(panel1, ...
            'Style', 'edit', ...
            'String', params{i,3}, ...
            'Position', [135 y_pos 80 22], ...
            'Tag', params{i,2});
    end
    
    %% PANNEAU 2: MATÉRIAUX (Gauche bas)
    panel2 = uipanel(fig, ...
        'Title', 'Matériau', ...
        'Position', [0.02 0.15 0.35 0.18], ...
        'FontSize', 10, ...
        'FontWeight', 'bold');
    
    % Menu déroulant des matériaux
    uicontrol(panel2, 'Style', 'text', ...
        'String', 'Sélection:', ...
        'Position', [10 70 60 20], ...
        'HorizontalAlignment', 'left');
    
    handles.material_popup = uicontrol(panel2, ...
        'Style', 'popupmenu', ...
        'String', {'Aluminium', 'Bois (Balsa)', 'Carbone/Époxy', 'Personnalisé'}, ...
        'Position', [75 70 180 25], ...
        'Callback', @materialChanged);
    
    % Affichage des propriétés
    handles.material_props = uicontrol(panel2, ...
        'Style', 'text', ...
        'String', sprintf('E = 69 GPa\nσ_lim = 240 MPa\nρ = 2700 kg/m³'), ...
        'Position', [10 20 240 45], ...
        'HorizontalAlignment', 'left', ...
        'FontName', 'FixedWidth');
    
    %% PANNEAU 3: CONTRÔLES (Gauche très bas)
    panel3 = uipanel(fig, ...
        'Title', 'Actions', ...
        'Position', [0.02 0.02 0.35 0.12], ...
        'FontSize', 10, ...
        'FontWeight', 'bold');
    
    % Bouton Import Excel
    handles.btn_import = uicontrol(panel3, ...
        'Style', 'pushbutton', ...
        'String', 'Import Excel', ...
        'Position', [10 10 100 35], ...
        'Callback', @importExcel);
    
    % Bouton Optimiser
    handles.btn_optimize = uicontrol(panel3, ...
        'Style', 'pushbutton', ...
        'String', 'OPTIMISER', ...
        'Position', [120 10 100 35], ...
        'BackgroundColor', [0.3 0.7 0.3], ...
        'ForegroundColor', 'white', ...
        'FontWeight', 'bold', ...
        'Callback', @runOptimization);
    
    % Bouton Export
    handles.btn_export = uicontrol(panel3, ...
        'Style', 'pushbutton', ...
        'String', 'Export', ...
        'Position', [230 10 70 35], ...
        'Enable', 'off', ...
        'Callback', @exportResults);
    
    %% PANNEAU 4: RÉSULTATS (Centre)
    panel4 = uipanel(fig, ...
        'Title', 'Résultats d''Optimisation', ...
        'Position', [0.39 0.02 0.28 0.96], ...
        'FontSize', 10, ...
        'FontWeight', 'bold');
    
    % Table des résultats
    handles.results_table = uitable(panel4, ...
        'Position', [10 250 280 490], ...
        'ColumnName', {'Paramètre', 'Valeur'}, ...
        'ColumnWidth', {180, 90}, ...
        'RowName', {});
    
    % Zone de statut
    handles.status_text = uicontrol(panel4, ...
        'Style', 'text', ...
        'String', 'Prêt', ...
        'Position', [10 200 230 40], ...
        'BackgroundColor', [0.95 0.95 0.95], ...
        'ForegroundColor', [0 0.5 0]);
    
    % Indicateurs de performance
    uicontrol(panel4, 'Style', 'text', ...
        'String', 'Indicateurs de Performance:', ...
        'Position', [10 170 230 20], ...
        'FontWeight', 'bold', ...
        'HorizontalAlignment', 'left');
    
    handles.performance_text = uicontrol(panel4, ...
        'Style', 'text', ...
        'String', '', ...
        'Position', [10 10 230 155], ...
        'HorizontalAlignment', 'left', ...
        'FontName', 'FixedWidth', ...
        'BackgroundColor', [0.98 0.98 0.98]);
    
    %% PANNEAU 5: VISUALISATION (Droite)
    panel5 = uipanel(fig, ...
        'Title', 'Visualisation', ...
        'Position', [0.69 0.02 0.29 0.96], ...
        'FontSize', 10, ...
        'FontWeight', 'bold');
    
    % Axes pour la géométrie de l'aileron
    handles.axes_geom = axes('Parent', panel5, ...
        'Position', [0.1 0.55 0.85 0.4], ...
        'Box', 'on');
    title(handles.axes_geom, 'Géométrie Aileron');
    xlabel(handles.axes_geom, 'x (cm)');
    ylabel(handles.axes_geom, 'y (cm)');
    grid(handles.axes_geom, 'on');
    axis(handles.axes_geom, 'equal');
    
    % Axes pour le diagramme de stabilité
    handles.axes_stab = axes('Parent', panel5, ...
        'Position', [0.1 0.05 0.85 0.4], ...
        'Box', 'on');
    title(handles.axes_stab, 'Stabilité');
    xlabel(handles.axes_stab, 'Marge (calibres)');
    ylabel(handles.axes_stab, 'Cn');
    grid(handles.axes_stab, 'on');
    
    % Stockage des données de matériaux
    handles.materials = struct();
    handles.materials.Aluminium = struct('E', 69e9, 'sigma', 240e6, 'rho', 2700);
    handles.materials.Bois = struct('E', 11e9, 'sigma', 60e6, 'rho', 550);
    handles.materials.Carbone = struct('E', 70e9, 'sigma', 700e6, 'rho', 1550);
    handles.current_material = handles.materials.Aluminium;
    
    % Type de fusée (par défaut Fusex)
    handles.rocket_type = 'fusex';
    
    % Stockage des handles
    guidata(fig, handles);
end

%% CALLBACKS

function typeChanged(src, event)
    handles = guidata(src);
    
    % Mettre à jour le type
    if event.NewValue == handles.radio_minif
        handles.rocket_type = 'minif';
        criteria_str = sprintf(['CDC Minifusée:\n' ...
            '1.5 < MS < 6\n' ...
            '15 < Cn < 30\n' ...
            '30 < MS×Cn < 100\n' ...
            'V > 18 m/s\n' ...
            '10 < L/D < 20']);
    else
        handles.rocket_type = 'fusex';
        criteria_str = sprintf(['CDC Fusex:\n' ...
            '2 < MS < 6\n' ...
            '15 < Cn < 40\n' ...
            '40 < MS×Cn < 100\n' ...
            'V > 20 m/s\n' ...
            '10 < L/D < 35']);
    end
    
    % Mettre à jour l'affichage des critères
    set(handles.criteria_text, 'String', criteria_str);
    
    % Sauvegarder
    guidata(src, handles);
end

function materialChanged(src, ~)
    handles = guidata(src);
    
    materials = {
        struct('E', 69e9, 'sigma', 240e6, 'rho', 2700);  % Aluminium
        struct('E', 11e9, 'sigma', 60e6, 'rho', 550);     % Bois
        struct('E', 70e9, 'sigma', 700e6, 'rho', 1550);   % Carbone
        struct('E', 50e9, 'sigma', 300e6, 'rho', 1500);   % Personnalisé
    };
    
    idx = get(src, 'Value');
    mat = materials{idx};
    
    % Si matériau personnalisé, ouvrir dialogue
    if idx == 4
        mat = inputMaterialProperties();
        if isempty(mat)
            set(src, 'Value', 1);
            mat = materials{1};
        end
    end
    
    % Mise à jour de l'affichage
    str = sprintf('E = %.0f GPa\nσ_lim = %.0f MPa\nρ = %.0f kg/m³', ...
        mat.E/1e9, mat.sigma/1e6, mat.rho);
    set(handles.material_props, 'String', str);
    
    handles.current_material = mat;
    guidata(src, handles);
end

function mat = inputMaterialProperties()
    prompt = {'Module de Young (GPa):', ...
              'Limite élastique (MPa):', ...
              'Masse volumique (kg/m³):'};
    title = 'Propriétés du matériau personnalisé';
    defaults = {'50', '300', '1500'};
    
    answer = inputdlg(prompt, title, [1 40], defaults);
    
    if isempty(answer)
        mat = [];
    else
        mat = struct();
        mat.E = str2double(answer{1}) * 1e9;
        mat.sigma = str2double(answer{2}) * 1e6;
        mat.rho = str2double(answer{3});
    end
end

function importExcel(src, ~)
    handles = guidata(src);
    
    [file, path] = uigetfile({'*.xlsx;*.xls', 'Excel Files (*.xlsx, *.xls)'}, 'Select Excel File');
    if isequal(file, 0)
        return;
    end
    
    try
        set(handles.status_text, 'String', 'Import en cours...', ...
            'ForegroundColor', [0.8 0.4 0]);
        drawnow;
        
        fullFilePath = fullfile(path, file);
        
        % Lire avec readcell comme dans votre code
        tab = readcell(fullFilePath, 'Sheet', 'Controle');
        
        % Extraction des données comme dans votre fonction
        D_fusex = cell2mat(tab(24,2));
        Cx = cell2mat(tab(11,3));
        accelmax = cell2mat(tab(57,6));
        vmax = cell2mat(tab(56,6));
        e_aileron = cell2mat(tab(13,3));
        N_ailerons = cell2mat(tab(14,3));
        L_Ogive = cell2mat(tab(25,2));
        TAILLE_FUSEX = cell2mat(tab(22,2));
        position_bas_aileron = cell2mat(tab(25,4));
        M_Fusex_vide = cell2mat(tab(39,7));
        M_Fusex_plein = cell2mat(tab(39,8));
        X_CDM_Vide = cell2mat(tab(40,7));
        X_CDM_Plein = cell2mat(tab(40,8));
        
        % Mise à jour des champs de l'interface
        set(handles.D_fusex, 'String', num2str(D_fusex/10)); % mm to cm
        set(handles.Cx, 'String', num2str(Cx));
        set(handles.accelmax, 'String', sprintf('%.1f', accelmax/9.81)); % m/s² to g
        set(handles.vmax, 'String', sprintf('%.0f', vmax));
        set(handles.N_ailerons, 'String', num2str(N_ailerons));
        set(handles.e_aileron, 'String', num2str(e_aileron)); % déjà en mm
        set(handles.position_bas, 'String', num2str(position_bas_aileron/10)); % mm to cm
        set(handles.L_Ogive, 'String', num2str(L_Ogive/10)); % mm to cm
        set(handles.L_fusee, 'String', num2str(TAILLE_FUSEX/10)); % mm to cm
        
        % Stocker les données additionnelles dans handles
        handles.M_Fusex_vide = M_Fusex_vide;
        handles.M_Fusex_plein = M_Fusex_plein;
        handles.X_CDM_Vide = X_CDM_Vide;
        handles.X_CDM_Plein = X_CDM_Plein;
        
        guidata(src, handles);
        
        set(handles.status_text, 'String', 'Import réussi! Données chargées depuis la feuille Controle.', ...
            'ForegroundColor', [0 0.5 0]);
        
    catch ME
        set(handles.status_text, 'String', ['Erreur import: ' ME.message], ...
            'ForegroundColor', [0.8 0 0]);
        
        msgbox(['Erreur lors de l''import. Vérifiez que le fichier contient ' ...
            'une feuille "Controle" avec les données aux positions attendues.'], ...
            'Erreur Import', 'error');
    end
end

function runOptimization(src, ~)
    handles = guidata(src);
    
    % Désactiver le bouton
    set(handles.btn_optimize, 'Enable', 'off', 'String', 'Calcul...');
    set(handles.status_text, 'String', 'Optimisation en cours...', ...
        'ForegroundColor', [0.8 0.4 0]);
    drawnow;
    
    try
        % Récupération des paramètres
        params = getParameters(handles);
        
        % Optimisation
        results = performOptimization(params, handles.current_material);
        
        % Affichage des résultats
        displayResults(handles, results);
        
        % Visualisation
        plotResults(handles, results);
        
        % Activer le bouton export
        set(handles.btn_export, 'Enable', 'on');
        
        % Stocker les résultats
        handles.optimization_results = results;
        guidata(src, handles);
        
        set(handles.status_text, 'String', 'Optimisation terminée!', ...
            'ForegroundColor', [0 0.5 0]);
        
    catch ME
        set(handles.status_text, 'String', ['Erreur: ' ME.message], ...
            'ForegroundColor', [0.8 0 0]);
    end
    
    % Réactiver le bouton
    set(handles.btn_optimize, 'Enable', 'on', 'String', 'OPTIMISER');
end

function params = getParameters(handles)
    params = struct();
    params.D_fusex = str2double(get(handles.D_fusex, 'String'));
    params.Cx = str2double(get(handles.Cx, 'String'));
    params.accelmax = str2double(get(handles.accelmax, 'String')) * 9.81; % g to m/s²
    params.vmax = str2double(get(handles.vmax, 'String'));
    params.N_ailerons = str2double(get(handles.N_ailerons, 'String'));
    params.e_aileron = str2double(get(handles.e_aileron, 'String')); % mm
    params.position_bas = str2double(get(handles.position_bas, 'String'));
    params.L_Ogive = str2double(get(handles.L_Ogive, 'String'));
    params.L_fusee = str2double(get(handles.L_fusee, 'String'));
    
    % Type de fusée
    params.rocket_type = handles.rocket_type;
    
    % Récupérer les données importées si elles existent
    if isfield(handles, 'M_Fusex_vide')
        params.M_Fusex_vide = handles.M_Fusex_vide;
        params.M_Fusex_plein = handles.M_Fusex_plein;
        params.X_CDM_Vide = handles.X_CDM_Vide;
        params.X_CDM_Plein = handles.X_CDM_Plein;
    end
end

function results = performOptimization(params, material)
    % Paramètres fixes
    Beta = 1;
    Cn_Ogive = 2;
    Cn_Fusex = 0;
    X_Cn_Fusex = 0;
    
    % Conversion des unités (tout en mm pour cohérence avec votre code)
    D_fusex = params.D_fusex * 10; % cm to mm
    TAILLE_FUSEX = params.L_fusee * 10; % cm to mm
    L_Ogive = params.L_Ogive * 10; % cm to mm
    X_Cn_Ogive = L_Ogive / 2;
    position_bas_aileron = params.position_bas * 10; % cm to mm
    e_aileron = params.e_aileron; % déjà en mm
    N_ailerons = params.N_ailerons;
    
    % Masses et CDM (valeurs par défaut si non importées)
    if isfield(params, 'M_Fusex_vide')
        M_Fusex_vide = params.M_Fusex_vide;
        M_Fusex_plein = params.M_Fusex_plein;
        X_CDM_Vide = params.X_CDM_Vide;
        X_CDM_Plein = params.X_CDM_Plein;
    else
        M_Fusex_vide = 3.6; % kg
        M_Fusex_plein = 7.1; % kg
        X_CDM_Vide = 578; % mm
        X_CDM_Plein = 607; % mm
    end
    
    % Fonctions aérodynamiques et stabilité
    x_cg_aileron = @(m) position_bas_aileron - m/2; % en mm
    
    Cn_ailerons = @(n,e,m,p) ((1+(D_fusex)/(2*e+D_fusex))*(4*N_ailerons*(e/D_fusex).^2)/...
        (1+sqrt(1+((2*sqrt(e.^2+(p+(n-m)/2).^2))/(m+n)).^2)));
    
    X_CP_Ailerons = @(n,e,m,p) (TAILLE_FUSEX-m) + (p*(m+2*n))./(3*(m+n)) + ...
        1/6*(m+n-(m.*n)./(m+n)); % en mm
    
    Aire = @(n,e,m,p) n.*e + p.*e/2 - (p+n-m).*e/2; % en mm²
    
    CDM_MOTEUR_VIDE = @(n,e,m,p) (M_Fusex_vide*X_CDM_Vide + ...
        x_cg_aileron(m)*(Aire(n,e,m,p)*e_aileron*material.rho*N_ailerons*1e-9))/...
        (Aire(n,e,m,p)*e_aileron*material.rho*N_ailerons*1e-9 + M_Fusex_vide);
    
    CDM_MOTEUR_PLEIN = @(n,e,m,p) (M_Fusex_plein*X_CDM_Plein + ...
        x_cg_aileron(m)*Aire(n,e,m,p)*e_aileron*material.rho*N_ailerons*1e-9)/...
        (Aire(n,e,m,p)*e_aileron*material.rho*N_ailerons*1e-9 + M_Fusex_plein);
    
    CP = @(n,e,m,p) (X_Cn_Ogive*Cn_Ogive + Cn_Fusex*X_Cn_Fusex + ...
        Cn_ailerons(n,e,m,p)*X_CP_Ailerons(n,e,m,p))/...
        (Cn_ailerons(n,e,m,p) + Cn_Ogive + Cn_Fusex);
    
    CP_SS = @(n,e,m,p) (X_Cn_Ogive*Cn_Ogive + Cn_Fusex*X_Cn_Fusex + ...
        Cn_ailerons(n,e,m,p)*X_CP_Ailerons(n,e,m,p)/Beta)/...
        (Cn_ailerons(n,e,m,p)/Beta + Cn_Ogive + Cn_Fusex);
    
    StabPlein = @(n,e,m,p) CDM_MOTEUR_PLEIN(n,e,m,p) - CP(n,e,m,p);
    StabPleinSS = @(n,e,m,p) CDM_MOTEUR_PLEIN(n,e,m,p) - CP_SS(n,e,m,p);
    StabVide = @(n,e,m,p) CDM_MOTEUR_VIDE(n,e,m,p) - CP(n,e,m,p);
    StabVideSS = @(n,e,m,p) CDM_MOTEUR_VIDE(n,e,m,p) - CP_SS(n,e,m,p);
    
    % Fonction objectif : minimiser l'aire
    obj = @(x) Aire(x(1), x(2), x(3), x(4));
    
    % Contraintes avec MEF
    nonlcon = @(x) rocketConstraintsMEF(x, StabPlein, StabVide, StabPleinSS, ...
        StabVideSS, Cn_ailerons, D_fusex, Beta, e_aileron, ...
        params.accelmax, params.vmax, params.Cx, material, params.rocket_type);
    
    % Bornes (en mm)
    lb = [20, 1, 1, 1]; % Nmin=20mm pour la fabrication
    ub = [300, 300, 300, 300];
    
    % Point initial
    x0 = [100, 100, 100, 100];
    
    % Options d'optimisation
    options = optimoptions('fmincon', ...
        'Display', 'iter', ...
        'Algorithm', 'sqp', ...
        'MaxIterations', 200, ...
        'OptimalityTolerance', 1e-6);
    
    % Optimisation
    [x_opt, fval, exitflag, output] = fmincon(obj, x0, [], [], [], [], ...
        lb, ub, nonlcon, options);
    
    % Compilation des résultats (conversion mm to cm pour affichage)
    results = struct();
    results.n = x_opt(1) / 10; % mm to cm
    results.e = x_opt(2) / 10; % mm to cm
    results.m = x_opt(3) / 10; % mm to cm
    results.p = x_opt(4) / 10; % mm to cm
    results.aire = fval / 100; % mm² to cm²
    results.masse = fval * e_aileron * material.rho * N_ailerons * 1e-9; % kg
    results.Cn = Cn_ailerons(x_opt(1), x_opt(2), x_opt(3), x_opt(4));
    results.X_CP = X_CP_Ailerons(x_opt(1), x_opt(2), x_opt(3), x_opt(4)) / 10; % mm to cm
    results.exitflag = exitflag;
    results.iterations = output.iterations;
    
    % Calcul de la marge de stabilité
    results.marge_stab_plein = -StabPlein(x_opt(1), x_opt(2), x_opt(3), x_opt(4)) / D_fusex;
    results.marge_stab_vide = -StabVide(x_opt(1), x_opt(2), x_opt(3), x_opt(4)) / D_fusex;
    
    % Calcul MEF pour affichage
    surface = (x_opt(2)*(x_opt(1)+x_opt(3))/2)*1e-6; % m²
    masse_aileron = surface*e_aileron/1000*material.rho;
    Force_lon = 2*masse_aileron*params.accelmax + 0.02*surface*params.vmax^2*params.Cx;
    Force_trans = 0.1*surface*params.vmax^2;
    
    [~, results.FS_lon, ~, ~] = FEM_aileron_force(x_opt(1)/1000, x_opt(2)/1000, ...
        x_opt(3)/1000, e_aileron/1000, -Force_lon, 100, ...
        material.sigma, material.E); % [CORRECTIF portfolio] Pa et non MPa (original : material.sigma/1e6) : le FS affiché était 10^6 fois trop petit
    
    [~, results.FS_trans, ~, ~, ~] = FEM_aileron_force_trans(x_opt(1)/1000, x_opt(2)/1000, ...
        x_opt(3)/1000, e_aileron/1000, Force_trans, 100, ...
        material.sigma, material.E); % [CORRECTIF portfolio] Pa et non MPa (original : material.sigma/1e6) : le FS affiché était 10^6 fois trop petit
end

function [c, ceq] = rocketConstraintsMEF(x, StabPlein, StabVide, StabPleinSS, StabVideSS, ...
    Cn_ailerons, D_fusex, Beta, e_aileron, accelmax, vmax, Cx, mat, rocket_type)
    % x : vecteur de conception [n, e, m, p] en mm
    n = x(1); 
    e = x(2); 
    m = x(3); 
    p = x(4);
    % Définir les limites selon le type de fusée
    if nargin < 14 || isempty(rocket_type)
        rocket_type = 'fusex'; % Par défaut
    end
    
    if strcmp(rocket_type, 'minif')
        % Cahier des charges Minifusée
        MS_min = 1.5;
        MS_max = 6;
        Cn_min = 15;
        Cn_max = 30;
        MSxCn_min = 30;
    else
        % Cahier des charges Fusex (par défaut)
        MS_min = 2;
        MS_max = 6;
        Cn_min = 15;
        Cn_max = 40;
        MSxCn_min = 40;
    end
    
    % Calcul des forces
    surface = (e*(n+m)/2)*1e-6; % m²
    masse = surface*e_aileron/1000*mat.rho; % kg
    Force_lon = 2*masse*accelmax + 0.02*surface*vmax^2*Cx; % N
    Force_trans = 0.1*surface*vmax^2; % N
    
    % Calcul MEF (conversion mm to m pour MEF)
    [~, Fs_lon, ~, ~] = FEM_aileron_force(n/1000, e/1000, m/1000, e_aileron/1000, ...
        -Force_lon, 100, mat.sigma, mat.E);
    
    [~, Fs_trans, ~, ~, d] = FEM_aileron_force_trans(n/1000, e/1000, m/1000, e_aileron/1000, ...
        Force_trans, 100, mat.sigma, mat.E);
    
    angle = e*tand(10)/1000; % Déflexion limite
    
    % Contraintes d'inégalité
    c = [];
    
    % Contraintes de stabilité adaptées au CDC
    c(1) = StabPlein(n,e,m,p) + MS_min*D_fusex; % Marge min plein
    c(2) = StabVide(n,e,m,p) + MS_min*D_fusex; % Marge min vide
    % [CORRECTIF portfolio] Stab = CDM - CP < 0 pour une fusée stable et MS = -Stab/D, donc
    % MS <= MS_max  <=>  -Stab - MS_max*D <= 0. L'ancienne forme (Stab - MS_max*D) était
    % toujours négative : la marge max n'était jamais contrainte. Original :
    % c(3) = -(MS_max*D_fusex - StabVide(n,e,m,p)); % Marge max vide
    % c(4) = -(MS_max*D_fusex - StabPlein(n,e,m,p)); % Marge max plein
    c(3) = -StabVide(n,e,m,p) - MS_max*D_fusex; % Marge max vide
    c(4) = -StabPlein(n,e,m,p) - MS_max*D_fusex; % Marge max plein
    
    % Stabilité avec sous-sonique
    % [CORRECTIF portfolio] même correction de signe que c(3)/c(4). Original :
    % c(5) = -(MS_max*D_fusex - StabVideSS(n,e,m,p));
    % c(6) = -(MS_max*D_fusex - StabPleinSS(n,e,m,p));
    c(5) = -StabVideSS(n,e,m,p) - MS_max*D_fusex;
    c(6) = -StabPleinSS(n,e,m,p) - MS_max*D_fusex;
    c(7) = Cn_min - Cn_ailerons(n,e,m,p)/Beta; % Cn min
    c(8) = Cn_ailerons(n,e,m,p)/Beta - Cn_max; % Cn max
    
    % Contraintes couplées MS×Cn adaptées
    c(9) = MSxCn_min + (StabPlein(n,e,m,p) * (Cn_ailerons(n,e,m,p)+2)/(D_fusex));
    c(10) = MSxCn_min + (StabVide(n,e,m,p) * (Cn_ailerons(n,e,m,p)+2)/D_fusex);
    c(11) = MSxCn_min + (StabPleinSS(n,e,m,p) * (Cn_ailerons(n,e,m,p)/Beta+2)/(D_fusex));
    c(12) = MSxCn_min + (StabVideSS(n,e,m,p) * (Cn_ailerons(n,e,m,p)/Beta+2)/(D_fusex));
    
    % Contraintes additionnelles
    c(13) = StabPleinSS(n,e,m,p) + MS_min*D_fusex;
    c(14) = StabVideSS(n,e,m,p) + MS_min*D_fusex;
    c(15) = Cn_min - Cn_ailerons(n,e,m,p);
    c(16) = Cn_ailerons(n,e,m,p) - Cn_max;
    
    % Contraintes structurelles MEF
    c(17) = 2 - Fs_lon; % Facteur de sécurité longitudinal > 2
    c(18) = 2 - Fs_trans; % Facteur de sécurité transverse > 2
    c(19) = 2*d - angle; % Déflexion limite
    
    % Contraintes d'égalité
    ceq = [];
end

%% FONCTIONS MEF (Méthode des Éléments Finis)

function [sigma_vm_max, FS, U, x] = FEM_aileron_force(n, envergure, base, e_aileron, Force, N, sigma_lim, E)
    % Calcul MEF pour force longitudinale
    % Tous les paramètres en unités SI (m, N, Pa)
    
    L = envergure;
    dx = L / N;
    x = linspace(0, L, N+1);
    
    ddl = 2 * (N+1);
    b = base - (base-n) * (x / L);
    I = (e_aileron * b.^3) / 12;
    
    K = sparse(ddl, ddl);
    F = sparse(ddl, 1);
    
    % Matrice de rigidité élémentaire
    ke_base = @(E, I, L) E*I/L^3 * ...
        [12, 6*L, -12, 6*L;
         6*L, 4*L^2, -6*L, 2*L^2;
         -12, -6*L, 12, -6*L;
         6*L, 2*L^2, -6*L, 4*L^2];
    
    % Assemblage
    for i = 1:N 
        idx = [2*i-1, 2*i, 2*i+1, 2*i+2];
        ke = ke_base(E, (I(i)+I(i+1))/2, dx);
        K(idx, idx) = K(idx, idx) + ke;
    end
    
    % Conditions aux limites (encastrement)
    K(1:2,:) = 0;
    K(:,1:2) = 0;
    K(1,1) = 1;
    K(2,2) = 1;
    F(1:2) = 0;
    
    % Force concentrée à l'extrémité
    F(end-1) = Force;
    
    % Résolution
    U = K\F;
    
    % Calcul des efforts internes
    nNodes = N + 1;
    M_nodes = zeros(nNodes, 1);
    V_nodes = zeros(nNodes, 1);
    
    for i = 1:N
        idx = [2*i-1, 2*i, 2*i+1, 2*i+2];
        ue = U(idx);
        Ii = (I(i)+I(i+1))/2;
        ke = ke_base(E, Ii, dx);
        fe = ke * ue;
        V_nodes(i) = V_nodes(i) + fe(1);
        M_nodes(i) = M_nodes(i) + fe(2);
        V_nodes(i+1) = V_nodes(i+1) + fe(3);
        M_nodes(i+1) = M_nodes(i+1) + fe(4);
    end
    
    % Calcul des contraintes
    y_ext = e_aileron/2;
    contrainte_normale = (M_nodes' .* y_ext) ./ I;
    contrainte_cisaillement = 3/2 * (V_nodes') ./ (b * e_aileron);
    
    % Von Mises
    sigma_vm = sqrt(contrainte_normale.^2 + 3*contrainte_cisaillement.^2);
    sigma_vm_max = max(sigma_vm);
    FS = sigma_lim / sigma_vm_max;
end

function [sigma_vm_max, FS, U, x, d] = FEM_aileron_force_trans(n, envergure, base, e_aileron, Force, N, sigma_lim, E)
    % Calcul MEF pour force transversale
    % Centre de gravité pour l'application de la force
    ycg = envergure/3 * (2*n+base)/(n+base);
    ycg = round((ycg/envergure)*(N+1));
    
    L = envergure;
    dx = L / N;
    x = linspace(0, L, N+1);
    
    ddl = 2 * (N+1);
    b = base - (base-n) * (x / L);
    I = (e_aileron^3 .* b) / 12;
    
    K = sparse(ddl, ddl);
    F = sparse(ddl, 1);
    
    % Matrice de rigidité élémentaire
    ke_base = @(E, I, L) E*I/L^3 * ...
        [12, 6*L, -12, 6*L;
         6*L, 4*L^2, -6*L, 2*L^2;
         -12, -6*L, 12, -6*L;
         6*L, 2*L^2, -6*L, 4*L^2];
    
    % Assemblage
    for i = 1:N 
        idx = [2*i-1, 2*i, 2*i+1, 2*i+2];
        ke = ke_base(E, (I(i)+I(i+1))/2, dx);
        K(idx, idx) = K(idx, idx) + ke;
    end
    
    % Conditions aux limites (encastrement)
    K(1:2,:) = 0;
    K(:,1:2) = 0;
    K(1,1) = 1;
    K(2,2) = 1;
    F(1:2) = 0;
    
    % Force concentrée au centre de gravité
    if 2*ycg-1 <= length(F)
        F(2*ycg-1) = Force;
    else
        F(end-1) = Force; % Sécurité si ycg mal calculé
    end
    
    % Résolution
    U = K\F;
    
    % Calcul des efforts internes
    M_nodes = zeros(N+1, 1);
    V_nodes = zeros(N+1, 1);
    
    for i = 1:N
        idx = [2*i-1, 2*i, 2*i+1, 2*i+2];
        ue = U(idx);
        Ii = (I(i)+I(i+1))/2;
        ke = ke_base(E, Ii, dx);
        fe = ke * ue;
        V_nodes(i) = V_nodes(i) + fe(1);
        M_nodes(i) = M_nodes(i) + fe(2);
        V_nodes(i+1) = V_nodes(i+1) + fe(3);
        M_nodes(i+1) = M_nodes(i+1) + fe(4);
    end
    
    % Contraintes
    y_ext = e_aileron/2;
    contrainte_normale = (M_nodes' .* y_ext) ./ I;
    contrainte_cisaillement = 3/2 * (V_nodes') ./ (b * e_aileron);
    
    sigma_vm = sqrt(contrainte_normale.^2 + 3*contrainte_cisaillement.^2);
    sigma_vm_max = max(sigma_vm);
    
    FS = sigma_lim / sigma_vm_max;
    
    % Déplacement relatif
    if 2*ycg-1 <= length(U)
        % [CORRECTIF portfolio] U(end) est la rotation du noeud d'extrémité (ddl [w, theta] par noeud) :
        % on prend le déplacement U(end-1). Original : d = abs(U(end) - U(2*ycg-1));
        d = abs(U(end-1) - U(2*ycg-1));
    else
        d = abs(U(end-1)); % [CORRECTIF portfolio] original : d = abs(U(end));
    end
end

function displayResults(handles, results)
    % Préparation des données pour la table
    data = {
        'n (extrémité)', sprintf('%.2f cm', results.n);
        'e (envergure)', sprintf('%.2f cm', results.e);
        'm (racine)', sprintf('%.2f cm', results.m);
        'p (flèche)', sprintf('%.2f cm', results.p);
        'Surface', sprintf('%.2f cm²', results.aire);
        'Masse totale', sprintf('%.1f g', results.masse*1000);
        'Coefficient Cn', sprintf('%.2f', results.Cn);
        'Position CP', sprintf('%.1f cm', results.X_CP);
        'Marge stab plein', sprintf('%.2f cal', results.marge_stab_plein);
        'Marge stab vide', sprintf('%.2f cal', results.marge_stab_vide);
    };
    
    set(handles.results_table, 'Data', data);
    
    % Indicateurs de performance avec MEF
    perf_text = sprintf([...
        'Statut: %s\n', ...
        'Itérations: %d\n', ...
        '------------------------\n', ...
        'ANALYSE STRUCTURELLE MEF:\n', ...
        'FS longitudinal: %.2f\n', ...
        'FS transversal: %.2f\n', ...
        '------------------------\n', ...
        'Rapport m/n: %.2f\n', ...
        'Allongement: %.2f\n', ...
        'Flèche relative: %.1f%%\n', ...
        '------------------------\n', ...
        'Efficacité aéro: %.2f'], ...
        getStatusText(results.exitflag), ...
        results.iterations, ...
        results.FS_lon, ...
        results.FS_trans, ...
        results.m/results.n, ...
        results.e^2/results.aire, ...
        100*results.p/results.e, ...
        results.Cn/results.masse);
    
    set(handles.performance_text, 'String', perf_text);
end

function status = getStatusText(exitflag)
    switch exitflag
        case 1
            status = 'Optimal trouvé';
        case 0
            status = 'Limite itérations';
        case -2
            status = 'Infaisable';
        otherwise
            status = 'Arrêt';
    end
end

function plotResults(handles, results)
    % Plot 1: Géométrie de l'aileron
    axes(handles.axes_geom);
    cla(handles.axes_geom);
    
    % Coordonnées de l'aileron
    x = [0, 0, results.e, results.e, 0];
    y = [0, -results.m, -results.p-results.n, -results.p, 0];
    
    % Dessin
    fill(x, y, [0.3 0.5 0.8], 'EdgeColor', 'k', 'LineWidth', 2);
    hold on;
    
    % Centre de gravité
    xcg = mean(x(1:4));
    ycg = mean(y(1:4));
    plot(xcg, ycg, 'ro', 'MarkerSize', 8, 'MarkerFaceColor', 'r');
    text(xcg+1, ycg, 'CG', 'FontWeight', 'bold');
    
    % Annotations des dimensions
    text(results.e/2, 1, sprintf('e=%.1f', results.e), ...
        'HorizontalAlignment', 'center');
    text(-1, -results.m/2, sprintf('m=%.1f', results.m), ...
        'HorizontalAlignment', 'right');
    text(-1, -results.m-results.p/2, sprintf('n=%.1f', results.n), ...
        'HorizontalAlignment', 'right');
    text(results.e+1, -results.p/2, sprintf('p=%.1f', results.p), ...
        'HorizontalAlignment', 'left');
    
    grid on;
    axis equal;
    xlabel('x (cm)');
    ylabel('y (cm)');
    
    % Titre avec type de fusée
    if strcmp(handles.rocket_type, 'minif')
        type_str = 'Minifusée';
    else
        type_str = 'Fusex';
    end
    title(sprintf('Géométrie Optimisée %s (FS_lon=%.2f, FS_trans=%.2f)', ...
        type_str, results.FS_lon, results.FS_trans));
    
    % Plot 2: Diagramme de stabilité
    axes(handles.axes_stab);
    cla(handles.axes_stab);
    
    % Définir les limites selon le type
    if strcmp(handles.rocket_type, 'minif')
        MS_min = 1.5; MS_max = 6;
        Cn_min = 15; Cn_max = 30;
        MSxCn_min = 30; MSxCn_max = 100;
    else
        MS_min = 2; MS_max = 6;
        Cn_min = 15; Cn_max = 40;
        MSxCn_min = 40; MSxCn_max = 100;
    end
    
    % Zones de stabilité adaptées
    patch([MS_min MS_max MS_max MS_min], [0 0 50 50], [0.9 1 0.9], 'EdgeColor', 'none');
    hold on;
    patch([0 MS_min MS_min 0], [0 0 50 50], [1 0.95 0.9], 'EdgeColor', 'none');
    patch([MS_max 8 8 MS_max], [0 0 50 50], [1 0.95 0.9], 'EdgeColor', 'none');
    
    % Points de fonctionnement (plein et vide)
    plot(results.marge_stab_plein, results.Cn, 'ko', ...
        'MarkerSize', 10, 'MarkerFaceColor', 'b');
    plot(results.marge_stab_vide, results.Cn, 'ks', ...
        'MarkerSize', 10, 'MarkerFaceColor', 'g');
    
    % Ligne entre plein et vide
    plot([results.marge_stab_plein, results.marge_stab_vide], ...
        [results.Cn, results.Cn], 'k-', 'LineWidth', 2);
    
    % Lignes de référence adaptées
    plot([0 8], [Cn_min Cn_min], 'r--', 'LineWidth', 1);
    plot([0 8], [Cn_max Cn_max], 'r--', 'LineWidth', 1);
    plot([MS_min MS_min], [0 50], 'b--', 'LineWidth', 1);
    plot([MS_max MS_max], [0 50], 'b--', 'LineWidth', 1);
    
    % Courbes de contrainte Ms*Cn adaptées
    x_stab = linspace(0.4, 8, 100);
    y_min = MSxCn_min ./ x_stab;
    y_max = MSxCn_max ./ x_stab;
    plot(x_stab, y_min, 'r:', 'LineWidth', 1);
    plot(x_stab, y_max, 'r:', 'LineWidth', 1);
    
    % Labels
    text(7.5, Cn_min, sprintf('Cn=%d', Cn_min), 'Color', 'r');
    text(7.5, Cn_max, sprintf('Cn=%d', Cn_max), 'Color', 'r');
    text(MS_min, 48, sprintf('%.1f cal', MS_min), 'Color', 'b', 'HorizontalAlignment', 'center');
    text(MS_max, 48, sprintf('%.0f cal', MS_max), 'Color', 'b', 'HorizontalAlignment', 'center');
    text((MS_min+MS_max)/2, 45, sprintf('Zone %s', type_str), ...
        'HorizontalAlignment', 'center', 'FontWeight', 'bold', 'Color', [0 0.5 0]);
    
    % Légende des points
    legend([plot(NaN,NaN,'ko','MarkerFaceColor','b'), ...
            plot(NaN,NaN,'ks','MarkerFaceColor','g')], ...
           {'Moteur plein', 'Moteur vide'}, ...
           'Location', 'northeast');
    
    xlim([0 8]);
    ylim([0 50]);
    grid on;
    xlabel('Marge Statique (calibres)');
    ylabel('Coefficient Cn');
    title(sprintf('Diagramme de Stabilité - CDC %s', type_str));
end

function exportResults(src, ~)
    handles = guidata(src);
    
    if ~isfield(handles, 'optimization_results')
        msgbox('Aucun résultat à exporter', 'Attention');
        return;
    end
    
    [file, path] = uiputfile({'*.xlsx', 'Excel'; '*.txt', 'Texte'}, ...
        'Sauvegarder les résultats');
    
    if isequal(file, 0)
        return;
    end
    
    try
        results = handles.optimization_results;
        
        % Export Excel
        if contains(file, '.xlsx')
            % Création d'une table
            T = table();
            % [CORRECTIF portfolio] results.marge_stab n'existe pas (l'export plantait) :
            % on exporte les marges moteur plein / moteur vide calculées dans performOptimization.
            T.Parametre = {'n'; 'e'; 'm'; 'p'; 'Surface'; 'Masse'; 'Cn'; 'Marge plein'; 'Marge vide'};
            T.Valeur = [results.n; results.e; results.m; results.p; ...
                       results.aire; results.masse*1000; results.Cn; ...
                       results.marge_stab_plein; results.marge_stab_vide];
            T.Unite = {'cm'; 'cm'; 'cm'; 'cm'; 'cm²'; 'g'; '-'; 'calibres'; 'calibres'};
            
            writetable(T, fullfile(path, file));
            
        % Export texte
        else
            fid = fopen(fullfile(path, file), 'w');
            fprintf(fid, 'RÉSULTATS D''OPTIMISATION D''AILERONS\n');
            fprintf(fid, '=====================================\n\n');
            fprintf(fid, 'Géométrie optimale:\n');
            fprintf(fid, '  n (extrémité) = %.2f cm\n', results.n);
            fprintf(fid, '  e (envergure) = %.2f cm\n', results.e);
            fprintf(fid, '  m (racine) = %.2f cm\n', results.m);
            fprintf(fid, '  p (flèche) = %.2f cm\n\n', results.p);
            fprintf(fid, 'Performances:\n');
            fprintf(fid, '  Surface = %.2f cm²\n', results.aire);
            fprintf(fid, '  Masse totale = %.1f g\n', results.masse*1000);
            fprintf(fid, '  Coefficient Cn = %.2f\n', results.Cn);
            % [CORRECTIF portfolio] results.marge_stab n'existe pas : marges plein / vide
            fprintf(fid, '  Marge de stabilité (moteur plein) = %.2f calibres\n', results.marge_stab_plein);
            fprintf(fid, '  Marge de stabilité (moteur vide) = %.2f calibres\n', results.marge_stab_vide);
            fclose(fid);
        end
        
        msgbox('Export réussi!', 'Succès');
        
    catch ME
        msgbox(['Erreur: ' ME.message], 'Erreur', 'error');
    end
end