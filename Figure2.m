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
