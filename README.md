# PROJET LPWAN — Notto Gouye Diama, Sénégal
## Master 1 IA & Smart Tech — Réseaux sans fil 2025-2026

---

## Structure du projet

```
lpwan_simulation/
│
├── matlab/
│   └── LPWAN_Dimensionnement_Notto.m    ← ÉTAPE 1 : Dimensionnement
│
├── ns3/
│   └── lpwan-notto-gouye.cc             ← ÉTAPE 2 : Simulation protocole
│
├── omnetpp/
│   ├── LPWAN_Notto_Gouye.ned            ← ÉTAPE 3 : Topologie réseau
│   └── omnetpp.ini                      ← ÉTAPE 3 : Configuration scénarios
│
└── README.md                            ← Ce fichier
```

---

## ÉTAPE 1 — MATLAB : Dimensionnement réseau

### Ce que fait le script
1. Modélise le canal radio avec Okumura-Hata (zone rurale 868 MHz)
2. Calcule le bilan de liaison pour SF7 à SF12
3. Dimensionne le nombre de gateways (3 GW → 94% couverture)
4. Modèle énergétique complet (ToA, courant TX/RX, durée vie batterie)
5. Calcule le PER (ALOHA non-slotté + propagation)
6. Optimisation ADR par Q-Learning (500 épisodes)
7. Génère 4 figures pour le rapport

### Exécution
```matlab
% Dans MATLAB R2021a ou supérieur :
cd matlab/
run('LPWAN_Dimensionnement_Notto.m')
```

### Résultats produits
- `Fig1` : Courbes Okumura-Hata avec MAPL par SF
- `Fig2` : Comparaison PER / Énergie / Débit / Durée vie par SF
- `Fig3` : Courbe d'apprentissage Q-Learning ADR
- `Fig4` : Portée LoRaWAN par SF

### Résultats attendus (SF9 recommandé)
| Indicateur        | Valeur     |
|-------------------|------------|
| Portée effective  | ~4.8 km    |
| Couverture        | 94.2 %     |
| PER               | ~8.3 %     |
| Énergie/message   | ~21.7 mJ   |
| Durée vie batterie| ~2.8 ans   |
| Débit utile       | ~320 bps   |

---

## ÉTAPE 2 — NS-3 : Simulation du scénario agricole

### Prérequis
```bash
# NS-3.38 avec module LoRaWAN
git clone https://gitlab.com/nsnam/ns-3-dev.git ns3
cd ns3
git clone https://github.com/signetlabdei/lorawan contrib/lorawan
./ns3 configure --enable-examples --enable-tests
./ns3 build
```

### Installation du script
```bash
mkdir -p scratch/lpwan-notto-gouye
cp ../ns3/lpwan-notto-gouye.cc scratch/lpwan-notto-gouye/
```

### Exécution
```bash
# Simulation de base (SF9, 50 nœuds, 3 gateways, 60 min)
./ns3 run scratch/lpwan-notto-gouye/lpwan-notto-gouye

# Avec paramètres personnalisés
./ns3 run "scratch/lpwan-notto-gouye/lpwan-notto-gouye \
    --nNoeuds=100 --nGateways=3 --sf=9 --duree=120 --verbose=true"

# Variation du SF (SF7 à SF12)
for sf in 7 8 9 10 11 12; do
    ./ns3 run "scratch/lpwan-notto-gouye/lpwan-notto-gouye --sf=$sf" \
        >> resultats_sf_variation.txt
done
```

### Résultats produits
- Affichage console : PER, latence, débit, énergie, durée vie
- `resultats_ns3_notto_gouye.csv` : Export pour MATLAB

### Exploitation dans MATLAB
```matlab
% Charger les résultats NS-3 dans MATLAB
T = readtable('resultats_ns3_notto_gouye.csv');
disp(T)
% Tracer PER vs SF
bar(T.SF, T.PER)
xlabel('Spreading Factor'); ylabel('PER (%)')
title('PER simulé NS-3 - Notto Gouye Diama')
```

---

## ÉTAPE 3 — OMNeT++ : Validation robustesse à grande échelle

### Prérequis
```bash
# OMNeT++ 6.x + INET 4.5 + FLoRa (module LoRaWAN)
# Télécharger OMNeT++ : https://omnetpp.org/download/
# Télécharger FLoRa   : https://flora.aalto.fi/

# Configuration projet Eclipse/OMNeT++
# 1. Importer le projet dans l'IDE OMNeT++
# 2. Lier les frameworks INET et FLoRa
# 3. Compiler le projet
```

### Exécution des scénarios
```bash
cd omnetpp/

# Scénario de base
opp_run -f omnetpp.ini -c Scenario_Base -r 0

# Variation SF (tous les SFs)
opp_run -f omnetpp.ini -c Scenario_SF_Variation

# Test scalabilité (10 à 200 nœuds)
opp_run -f omnetpp.ini -c Scenario_Scalabilite

# Comparaison ADR standard vs ADR-ML
opp_run -f omnetpp.ini -c Scenario_ADR_ML

# Test duty cycle adaptatif
opp_run -f omnetpp.ini -c Scenario_DutyCycle

# Impact nombre de gateways
opp_run -f omnetpp.ini -c Scenario_Gateways
```

### Analyse des résultats
Les résultats sont analysables dans l'IDE OMNeT++ (Scave) :
1. Ouvrir les fichiers `.sca` et `.vec` dans Scave
2. Créer les graphiques dans l'onglet "Browse Data"
3. Exporter en CSV pour traitement MATLAB

---

## Pipeline d'analyse complète

```
MATLAB (dimensionnement)
    ↓  SF optimal = SF9, 3 gateways
NS-3 (simulation protocole 60 min)
    ↓  PER, latence, énergie mesurés
OMNeT++ (validation 24h, 10-200 nœuds)
    ↓  Robustesse, scalabilité, ADR-ML
Rapport Partie 3 & 4
    ↓  Figures MATLAB + tableaux NS-3 + graphes OMNeT++
```

---

## Livrables du projet

| Livrable | Fichier | Outil |
|----------|---------|-------|
| Script dimensionnement | `matlab/LPWAN_Dimensionnement_Notto.m` | MATLAB |
| Script simulation réseau | `ns3/lpwan-notto-gouye.cc` | NS-3 |
| Topologie réseau | `omnetpp/LPWAN_Notto_Gouye.ned` | OMNeT++ |
| Configuration scénarios | `omnetpp/omnetpp.ini` | OMNeT++ |
| Rapport Word/PDF | 
| Présentation PPT | 
| Plateforme IOT   | 



---

## Références

- Semtech SX1276 Datasheet (ToA, sensibilité récepteur)
- LoRa Alliance : LoRaWAN Specification v1.0.4
- Okumura M. et al. (1968) — Modèle de propagation zone rurale
- Signetlab NS-3 LoRaWAN module : github.com/signetlabdei/lorawan
- FLoRa OMNeT++ : flora.aalto.fi
- Watteyne T. et al. — LoRaWAN for Smart Agriculture

---
*Master 1 IA & Smart Tech — Dr. I. GUEYE — Réseaux sans fil 2025-2026*
## Auteur Talla DIOP Master 1 IA & Smart Tech
