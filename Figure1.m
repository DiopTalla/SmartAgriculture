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

