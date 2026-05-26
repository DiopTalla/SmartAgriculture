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
