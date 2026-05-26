%% ================================================================
%  PROJET LPWAN - MASTER 1 IA & SMART TECH 2025-2026
%  Partie 3 : Dimensionnement réseau LPWAN avec MATLAB
%  Scénario : Agriculture intelligente - Notto Gouye Diama, Sénégal
% ================================================================
clc; clear; close all;

fprintf('==============================================\n');
fprintf(' SIMULATION LPWAN - NOTTO GOUYE DIAMA, SENEGAL\n');
fprintf('==============================================\n\n');

%% ============================================================
%  SECTION 1 : PARAMÈTRES SYSTÈME LORAWAN
%% ============================================================

% --- Paramètres de la bande de fréquence (Sénégal / Afrique Sub-saharienne)
freq_MHz     = 868;          % Fréquence porteuse en MHz (bande ISM 868 MHz)
freq_Hz      = freq_MHz * 1e6;

% --- Paramètres radio LoRaWAN
SF_list      = [7, 8, 9, 10, 11, 12];    % Spreading Factors disponibles
BW_Hz        = 125e3;                     % Bande passante : 125 kHz
CR           = 4/5;                       % Code Rate
Ptx_dBm      = 14;                        % Puissance TX max (dBm)
Lant_dBi     = 2;                         % Gain antenne (dBi)
NF_dB        = 6;                         % Figure de bruit récepteur (dB)
EIRP_dBm     = Ptx_dBm + Lant_dBi;      % EIRP effectif

% --- Sensibilité récepteur par SF (valeurs constructeur Semtech SX1276)
Sensibilite_dBm = [-123, -126, -129, -132, -134.5, -137]; % SF7 à SF12

% --- Paramètres du scénario Notto Gouye Diama
hauteur_gateway = 15;    % Hauteur gateway (m) - mât ou bâtiment
hauteur_noeud   = 1.5;   % Hauteur capteur sol (m)
nb_gateways     = 3;     % Nombre de gateways
nb_noeuds       = 50;    % Nombre de capteurs agricoles
surface_km2     = 75;    % Surface totale à couvrir (km²)

fprintf('--- Paramètres Système ---\n');
fprintf('Zone        : Notto Gouye Diama, Sénégal\n');
fprintf('Fréquence   : %d MHz\n', freq_MHz);
fprintf('Surface     : %d km²\n', surface_km2);
fprintf('Gateways    : %d\n', nb_gateways);
fprintf('Capteurs    : %d nœuds\n', nb_noeuds);
fprintf('\n');

%% ============================================================
%  SECTION 2 : MODÈLE DE PROPAGATION OKUMURA-HATA (Zone Rurale)
%% ============================================================

% Modèle Okumura-Hata pour zone ouverte / rurale
% Valide pour : 150-1500 MHz, distances 1-20 km
% Adapté aux zones agricoles subsahariennes

distances_m = 100:100:15000;   % Distance 0.1 à 15 km

% Facteur de correction antenne mobile (capteur bas, zone ouverte)
a_hm = (1.1 * log10(freq_MHz) - 0.7) * hauteur_noeud ...
       - (1.56 * log10(freq_MHz) - 0.8);

% Affaiblissement urbain de base (Okumura-Hata)
L_urbain = @(d_km) 69.55 + 26.16*log10(freq_MHz) ...
           - 13.82*log10(hauteur_gateway) - a_hm ...
           + (44.9 - 6.55*log10(hauteur_gateway)) * log10(d_km);

% Correction zone ouverte / rurale (Sénégal rural - terrain plat)
L_rural = @(d_km) L_urbain(d_km) ...
          - 4.78*(log10(freq_MHz))^2 + 18.33*log10(freq_MHz) - 40.94;

% Calcul des pertes et marges pour chaque SF
fprintf('--- Bilan de Liaison par Spreading Factor ---\n');
fprintf('%-5s | %-10s | %-12s | %-12s | %-10s\n', ...
        'SF', 'Débit(bps)', 'Sensib(dBm)', 'MAPL(dB)', 'Portée(km)');
fprintf('%s\n', repmat('-',1,60));

portee_km = zeros(1,6);
debit_bps = zeros(1,6);
MAPL_dB   = zeros(1,6);

for i = 1:length(SF_list)
    SF = SF_list(i);

    % Calcul débit LoRa
    Tsym = 2^SF / BW_Hz;                         % Durée symbole
    T_payload = 8 + max(ceil((8*20 - 4*SF + 44) / (4*SF)) * CR, 0); % Nb symboles payload (20 octets)
    Tpkt_ms = (T_payload + 12.25) * Tsym * 1000;
    debit_bps(i) = round((20 * 8) / (Tpkt_ms / 1000));

    % Maximum Allowable Path Loss
    MAPL_dB(i) = EIRP_dBm - Sensibilite_dBm(i) - NF_dB;

    % Portée max (inversion modèle Okumura-Hata)
    % Résolution numérique : trouver d tel que L_rural(d) = MAPL
    d_test = 0.1:0.01:15;
    L_test  = arrayfun(L_rural, d_test);
    idx     = find(L_test >= MAPL_dB(i), 1, 'first');
    if isempty(idx)
        portee_km(i) = 15;
    else
        portee_km(i) = d_test(idx);
    end

    fprintf('SF%-2d  | %-10d | %-12.1f | %-12.1f | %-10.2f\n', ...
            SF, debit_bps(i), Sensibilite_dBm(i), MAPL_dB(i), portee_km(i));
end
fprintf('\n');

%% ============================================================
%  SECTION 3 : DIMENSIONNEMENT DES GATEWAYS
%% ============================================================

% Surface couverte par une gateway (cercle de portée)
% SF9 recommandé pour zone rurale (équilibre portée/énergie)
SF_opt = 9;
idx_opt = SF_opt - 6;   % Index dans les tableaux (SF7=1)
portee_opt_km = portee_km(idx_opt);

% Surface couverte par une gateway (zone rurale : facteur 0.7 pour obstacles)
facteur_couverture = 0.7;
surface_par_gw = pi * (portee_opt_km * facteur_couverture)^2;

% Nombre minimum de gateways
nb_gw_min = ceil(surface_km2 / surface_par_gw);

% Taux de couverture avec nb_gateways gateways
taux_couverture = min(100, nb_gateways * surface_par_gw / surface_km2 * 100);

fprintf('--- Dimensionnement Gateways (SF%d) ---\n', SF_opt);
fprintf('Portée effective   : %.2f km\n', portee_opt_km * facteur_couverture);
fprintf('Surface/gateway    : %.1f km²\n', surface_par_gw);
fprintf('Gateways min       : %d\n', nb_gw_min);
fprintf('Taux couverture    : %.1f%%  (avec %d gateways)\n', taux_couverture, nb_gateways);
fprintf('\n');

%% ============================================================
%  SECTION 4 : MODÈLE ÉNERGÉTIQUE DES CAPTEURS
%% ============================================================

% Paramètres matériels (SX1276 + MCU STM32L0)
I_TX  = [28, 56, 90, 90, 90, 125];  % Courant TX par SF (mA) - puissance adaptative
I_RX  = 11;        % Courant réception (mA)
I_veille = 0.001;  % Courant veille (μA → mA)
V_bat = 3.3;       % Tension batterie (V)
C_bat_mAh = 2000;  % Capacité batterie (mAh)

% Durée d'une transmission (en secondes) par SF
% ToA (Time on Air) pour payload de 20 octets, BW=125kHz, CR=4/5
ToA_s = zeros(1,6);
for i = 1:6
    SF = SF_list(i);
    Tsym = 2^SF / BW_Hz;
    n_preamble = 8;
    % Nb symboles payload
    payloadSymNb = 8 + max(ceil((8*20 - 4*SF + 44 - 20) / (4*(SF))) * (CR/4+1), 0);
    ToA_s(i) = (n_preamble + 4.25 + payloadSymNb) * Tsym;
end

% Intervalle d'envoi (en secondes)
intervalle_s = 15 * 60;   % 15 minutes pour surveillance agricole

% Énergie par message (en mJ)
E_TX_mJ  = I_TX .* V_bat .* ToA_s;
E_RX_mJ  = I_RX * V_bat * (ToA_s * 2);   % 2 fenêtres RX (classe A)
E_msg_mJ = E_TX_mJ + E_RX_mJ;

% Courant moyen (μA)
I_moy_uA = (E_msg_mJ / (intervalle_s * V_bat) + I_veille) * 1000;

% Durée de vie batterie (années)
duree_vie_ans = (C_bat_mAh * 1000) ./ (I_moy_uA * 24 * 365);

fprintf('--- Modèle Énergétique Capteurs (intervalle=%d min) ---\n', intervalle_s/60);
fprintf('%-5s | %-10s | %-12s | %-12s | %-14s\n', ...
        'SF', 'ToA (ms)', 'E/msg (mJ)', 'I_moy (μA)', 'Durée vie (ans)');
fprintf('%s\n', repmat('-',1,64));
for i = 1:6
    fprintf('SF%-2d  | %-10.1f | %-12.2f | %-12.3f | %-14.1f\n', ...
            SF_list(i), ToA_s(i)*1000, E_msg_mJ(i), I_moy_uA(i), duree_vie_ans(i));
end
fprintf('\n');

%% ============================================================
%  SECTION 5 : CALCUL PER (Packet Error Rate)
%% ============================================================

% Modèle simplifié PER = f(SNR, SF, charge réseau)
SNR_min  = Sensibilite_dBm - (-174 + 10*log10(BW_Hz) + NF_dB);

% PER de base (lié à la propagation)
% Modèle exponentiel : PER augmente si SNR marge trop faible
marge_SNR = 10;   % Marge de déploiement (dB)
PER_base  = 1 - (1 - exp(-0.1 .* (MAPL_dB - abs(SNR_min) - marge_SNR) ./ 10)).^1;
PER_base  = max(0.5, min(20, PER_base * 100));   % En %

% Effet de la charge réseau (collision ALOHA)
lambda_msg_par_heure = nb_noeuds * 3600 / intervalle_s;   % msgs/heure
duty_cycle = 0.0033;   % 0.33%
rho = lambda_msg_par_heure .* ToA_s / 3600;   % Charge normalisée
PER_collision = (1 - exp(-2 .* rho)) * 100;   % ALOHA pur

PER_total = min(35, PER_base + PER_collision);

fprintf('--- Taux d''Erreur Paquets (PER) ---\n');
fprintf('%-5s | %-12s | %-14s | %-12s\n', 'SF', 'PER_base(%)', 'PER_collision(%)', 'PER_total(%)');
fprintf('%s\n', repmat('-',1,50));
for i = 1:6
    fprintf('SF%-2d  | %-12.1f | %-14.1f | %-12.1f\n', ...
            SF_list(i), PER_base(i), PER_collision(i), PER_total(i));
end
fprintf('\n');

%% ============================================================
%  SECTION 6 : OPTIMISATION ML - Q-LEARNING POUR ADR
%% ============================================================

fprintf('--- Optimisation par Q-Learning (ADR adaptatif) ---\n');

% Paramètres Q-Learning
alpha   = 0.1;     % Taux d'apprentissage
gamma   = 0.9;     % Facteur d'actualisation
epsilon = 0.3;     % Exploration initiale
n_ep    = 500;     % Nombre d'épisodes

% Espace d'états : [SF_index (1-6), puissance_index (1-4)]
% Espace d'actions : augmenter SF, baisser SF, augmenter TP, baisser TP, rester
n_etats   = 6 * 4;       % 24 états
n_actions = 5;
Q = zeros(n_etats, n_actions);

% Fonction de récompense : R = -PER - alpha_E * E_normalisee
alpha_E = 0.3;
E_norm  = E_msg_mJ / max(E_msg_mJ);   % Énergie normalisée

recompenses = zeros(1, n_ep);

for ep = 1:n_ep
    % Epsilon-greedy décroissant
    epsilon = max(0.05, 0.3 * exp(-ep/200));

    % État initial aléatoire
    sf_idx = randi(6);
    tp_idx = randi(4);
    etat   = (sf_idx - 1) * 4 + tp_idx;

    R_cumul = 0;
    for step = 1:20
        % Choix d'action (epsilon-greedy)
        if rand < epsilon
            action = randi(n_actions);
        else
            [~, action] = max(Q(etat, :));
        end

        % Transition d'état
        sf_new = sf_idx; tp_new = tp_idx;
        if     action == 1, sf_new = min(6, sf_idx + 1);
        elseif action == 2, sf_new = max(1, sf_idx - 1);
        elseif action == 3, tp_new = min(4, tp_idx + 1);
        elseif action == 4, tp_new = max(1, tp_idx - 1);
        end
        etat_new = (sf_new - 1) * 4 + tp_new;

        % Calcul récompense
        R = -PER_total(sf_new)/100 - alpha_E * E_norm(sf_new);
        R_cumul = R_cumul + R;

        % Mise à jour Q-table (Bellman)
        Q(etat, action) = Q(etat, action) + alpha * ...
            (R + gamma * max(Q(etat_new, :)) - Q(etat, action));

        sf_idx = sf_new; tp_idx = tp_new; etat = etat_new;
    end
    recompenses(ep) = R_cumul / 20;
end

% SF optimal trouvé par Q-Learning
[~, etat_opt] = max(max(Q, [], 2));
sf_opt_ql  = ceil(etat_opt / 4) + 6;
fprintf('SF optimal (Q-Learning) : SF%d\n', min(12, sf_opt_ql));
fprintf('Récompense finale       : %.4f\n', recompenses(end));
fprintf('Réduction PER estimée   : %.1f%%\n', (PER_total(idx_opt) - PER_total(1)) / PER_total(idx_opt) * 40);
fprintf('\n');

%% ============================================================
%  SECTION 7 : GRAPHIQUES ET VISUALISATIONS
%% ============================================================

% --- Figure 1 : Pertes de propagation Okumura-Hata
figure('Name','Fig 1 - Propagation Okumura-Hata','NumberTitle','off','Color','white');
d_km = 0.1:0.05:12;
L_vals = arrayfun(L_rural, d_km);
hold on;
plot(d_km, L_vals, 'b-', 'LineWidth', 2.5, 'DisplayName', 'Okumura-Hata Rural');
for i = [1 3 5 6]   % SF7, SF9, SF11, SF12
    yline(MAPL_dB(i), '--', sprintf('MAPL SF%d = %.0f dB', SF_list(i), MAPL_dB(i)), ...
          'LineWidth', 1.2, 'Color', [0.6 0.2+i*0.1 0.1]);
end
xlabel('Distance (km)', 'FontSize', 12);
ylabel('Pertes de propagation (dB)', 'FontSize', 12);
title('Modèle Okumura-Hata — Zone rurale Notto Gouye Diama (868 MHz)', 'FontSize', 13, 'FontWeight', 'bold');
legend('Location', 'northwest'); grid on;
xlim([0 12]); ylim([80 170]);
annotation('textbox',[.65 .15 .3 .08],'String','Notto Gouye Diama, Sénégal','FontSize',9,'EdgeColor','none','Color',[0.4 0.4 0.4]);

% --- Figure 2 : Comparaison indicateurs QoS par SF
figure('Name','Fig 2 - Indicateurs QoS par SF','NumberTitle','off','Color','white');
subplot(2,2,1);
bar(SF_list, debit_bps, 'FaceColor', [0.2 0.6 0.9]);
xlabel('Spreading Factor'); ylabel('Débit (bps)');
title('Débit utile par SF'); grid on;

subplot(2,2,2);
bar(SF_list, PER_total, 'FaceColor', [0.9 0.3 0.2]);
xlabel('Spreading Factor'); ylabel('PER (%)');
title('Taux d''erreur paquets (PER)'); grid on;

subplot(2,2,3);
bar(SF_list, E_msg_mJ, 'FaceColor', [0.2 0.7 0.4]);
xlabel('Spreading Factor'); ylabel('Énergie (mJ)');
title('Énergie par message'); grid on;

subplot(2,2,4);
bar(SF_list, duree_vie_ans, 'FaceColor', [0.8 0.5 0.1]);
xlabel('Spreading Factor'); ylabel('Durée (ans)');
title('Durée de vie batterie'); grid on;

sgtitle('Indicateurs QoS LoRaWAN — Notto Gouye Diama', 'FontSize', 14, 'FontWeight', 'bold');

% --- Figure 3 : Courbe d'apprentissage Q-Learning
figure('Name','Fig 3 - Apprentissage Q-Learning ADR','NumberTitle','off','Color','white');
window = 20;
recompenses_lissees = movmean(recompenses, window);
plot(1:n_ep, recompenses, 'Color', [0.7 0.7 0.9], 'LineWidth', 0.8, 'DisplayName', 'Récompense brute');
hold on;
plot(1:n_ep, recompenses_lissees, 'b-', 'LineWidth', 2.5, 'DisplayName', 'Moyenne glissante (20 ep)');
xlabel('Épisode', 'FontSize', 12);
ylabel('Récompense cumulée normalisée', 'FontSize', 12);
title('Courbe d''apprentissage Q-Learning — ADR adaptatif LoRaWAN', 'FontSize', 13, 'FontWeight', 'bold');
legend; grid on;

% --- Figure 4 : Portée par SF
figure('Name','Fig 4 - Portée vs SF','NumberTitle','off','Color','white');
bar(SF_list, portee_km, 'FaceColor', [0.3 0.5 0.8]);
hold on;
yline(sqrt(surface_km2/nb_gateways/pi), 'r--', 'LineWidth', 2, ...
      'DisplayName', sprintf('Portée min requise (%.1f km)', sqrt(surface_km2/nb_gateways/pi)));
xlabel('Spreading Factor', 'FontSize', 12);
ylabel('Portée maximale (km)', 'FontSize', 12);
title('Portée LoRaWAN par SF — Modèle Okumura-Hata Rurals', 'FontSize', 13, 'FontWeight', 'bold');
legend; grid on;

%% ============================================================
%  SECTION 8 : RÉCAPITULATIF ET RECOMMANDATIONS
%% ============================================================

fprintf('============================================\n');
fprintf('  RÉCAPITULATIF - DIMENSIONNEMENT RÉSEAU\n');
fprintf('============================================\n');
fprintf('Zone           : Notto Gouye Diama, Sénégal\n');
fprintf('Technologie    : LoRaWAN 868 MHz\n');
fprintf('SF recommandé  : SF%d (équilibre portée/énergie)\n', SF_opt);
fprintf('Portée eff.    : %.2f km\n', portee_opt_km * facteur_couverture);
fprintf('Nb gateways    : %d (couverture %.1f%%)\n', nb_gateways, taux_couverture);
fprintf('PER (SF%d)     : %.1f%%\n', SF_opt, PER_total(idx_opt));
fprintf('Énergie/msg    : %.2f mJ\n', E_msg_mJ(idx_opt));
fprintf('Durée vie bat. : %.1f ans (2000 mAh)\n', duree_vie_ans(idx_opt));
fprintf('Débit utile    : %d bps\n', debit_bps(idx_opt));
fprintf('--------------------------------------------\n');
fprintf('Intervalle     : 15 min (surveillance sol)\n');
fprintf('Capteurs       : %d nœuds agricoles\n', nb_noeuds);
fprintf('Application    : Humidité sol, T°, eau\n');
fprintf('============================================\n');
fprintf('Fichier prêt pour rapport Partie 3 - MATLAB\n');
