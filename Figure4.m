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

