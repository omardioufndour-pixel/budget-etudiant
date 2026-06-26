-- ═══════════════════════════════════════════════════════════
-- SCHÉMA RELATIONNEL — BudgetEtudiant
-- ESP/UCAD — Projet tutoré L2 GLSI — 2025/2026
-- 9 tables, cohérentes avec le diagramme de classes validé
-- ═══════════════════════════════════════════════════════════

CREATE DATABASE IF NOT EXISTS budget_etudiant
  CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE budget_etudiant;

-- ───────────────────────────────────────────────────────────
-- 1. UTILISATEUR
-- ───────────────────────────────────────────────────────────
CREATE TABLE utilisateur (
  id_utilisateur    INT AUTO_INCREMENT PRIMARY KEY,
  nom               VARCHAR(100) NOT NULL,
  prenom            VARCHAR(100) NOT NULL,
  email             VARCHAR(150) NOT NULL UNIQUE,
  mot_de_passe_hash VARCHAR(255) NOT NULL,
  date_inscription  DATETIME DEFAULT CURRENT_TIMESTAMP,
  est_actif         BOOLEAN DEFAULT TRUE
) ENGINE=InnoDB;

-- ───────────────────────────────────────────────────────────
-- 2. BUDGET
-- ───────────────────────────────────────────────────────────
CREATE TABLE budget (
  id_budget       INT AUTO_INCREMENT PRIMARY KEY,
  montant_global  DECIMAL(10,2) NOT NULL,
  periode         ENUM('mensuel', 'semestriel') DEFAULT 'mensuel',
  date_debut      DATE NOT NULL,
  date_fin        DATE NOT NULL,
  statut          ENUM('actif', 'archive') DEFAULT 'actif',
  id_utilisateur  INT NOT NULL,
  CONSTRAINT chk_budget_positif CHECK (montant_global > 0),         -- RG01
  CONSTRAINT chk_dates_budget   CHECK (date_fin > date_debut),
  FOREIGN KEY (id_utilisateur) REFERENCES utilisateur(id_utilisateur)
    ON DELETE CASCADE
) ENGINE=InnoDB;

-- ───────────────────────────────────────────────────────────
-- 3. CATEGORIE
-- ───────────────────────────────────────────────────────────
CREATE TABLE categorie (
  id_categorie   INT AUTO_INCREMENT PRIMARY KEY,
  nom_categorie  VARCHAR(50) NOT NULL,
  sous_budget    DECIMAL(10,2) NOT NULL DEFAULT 0,
  couleur        VARCHAR(20) DEFAULT '#27AE60',
  id_budget      INT NOT NULL,
  CONSTRAINT chk_sous_budget_positif CHECK (sous_budget >= 0),
  FOREIGN KEY (id_budget) REFERENCES budget(id_budget)
    ON DELETE CASCADE
) ENGINE=InnoDB;

-- ───────────────────────────────────────────────────────────
-- 4. DEPENSE
-- ───────────────────────────────────────────────────────────
CREATE TABLE depense (
  id_depense        INT AUTO_INCREMENT PRIMARY KEY,
  montant           DECIMAL(10,2) NOT NULL,
  date_depense      DATE NOT NULL,
  description       VARCHAR(200),
  statut            ENUM('valide', 'en_attente') DEFAULT 'valide',
  date_modification DATETIME DEFAULT CURRENT_TIMESTAMP,
  id_categorie      INT NOT NULL,
  CONSTRAINT chk_montant_positif CHECK (montant > 0),               -- RG02
  FOREIGN KEY (id_categorie) REFERENCES categorie(id_categorie)
    ON DELETE CASCADE
) ENGINE=InnoDB;

-- ───────────────────────────────────────────────────────────
-- 5. ALERTE
-- ───────────────────────────────────────────────────────────
CREATE TABLE alerte (
  id_alerte            INT AUTO_INCREMENT PRIMARY KEY,
  type_alerte          ENUM('orange', 'rouge') NOT NULL,
  seuil                DECIMAL(5,2) NOT NULL,
  message              VARCHAR(255) NOT NULL,
  date_alerte          DATETIME DEFAULT CURRENT_TIMESTAMP,
  est_lue              BOOLEAN DEFAULT FALSE,
  pourcentage_atteint  DECIMAL(5,2),
  id_budget            INT NOT NULL,
  id_categorie         INT NULL,
  FOREIGN KEY (id_budget) REFERENCES budget(id_budget)
    ON DELETE CASCADE,
  FOREIGN KEY (id_categorie) REFERENCES categorie(id_categorie)
    ON DELETE CASCADE
) ENGINE=InnoDB;

-- ───────────────────────────────────────────────────────────
-- 6. NOTIFICATION
-- ───────────────────────────────────────────────────────────
CREATE TABLE notification (
  id_notification  INT AUTO_INCREMENT PRIMARY KEY,
  message          VARCHAR(255) NOT NULL,
  type             ENUM('orange', 'rouge') NOT NULL,
  date_envoi       DATETIME DEFAULT CURRENT_TIMESTAMP,
  est_lue          BOOLEAN DEFAULT FALSE,
  id_utilisateur   INT NOT NULL,
  id_alerte        INT NOT NULL,
  FOREIGN KEY (id_utilisateur) REFERENCES utilisateur(id_utilisateur)
    ON DELETE CASCADE,
  FOREIGN KEY (id_alerte) REFERENCES alerte(id_alerte)
    ON DELETE CASCADE
) ENGINE=InnoDB;

-- ───────────────────────────────────────────────────────────
-- 7. RAPPORT
-- ───────────────────────────────────────────────────────────
CREATE TABLE rapport (
  id_rapport        INT AUTO_INCREMENT PRIMARY KEY,
  titre             VARCHAR(150) NOT NULL,
  date_generation   DATETIME DEFAULT CURRENT_TIMESTAMP,
  periode_debut     DATE NOT NULL,
  periode_fin       DATE NOT NULL,
  contenu           TEXT,
  format            ENUM('PDF', 'Excel') DEFAULT 'PDF',
  id_utilisateur    INT NOT NULL,
  FOREIGN KEY (id_utilisateur) REFERENCES utilisateur(id_utilisateur)
    ON DELETE CASCADE
) ENGINE=InnoDB;

-- ───────────────────────────────────────────────────────────
-- 8. HISTORIQUE
-- ───────────────────────────────────────────────────────────
CREATE TABLE historique (
  id_historique    INT AUTO_INCREMENT PRIMARY KEY,
  action           ENUM('ajout', 'modification', 'suppression') NOT NULL,
  date_action      DATETIME DEFAULT CURRENT_TIMESTAMP,
  details          VARCHAR(255),
  id_utilisateur   INT NOT NULL,
  id_depense       INT NULL,
  FOREIGN KEY (id_utilisateur) REFERENCES utilisateur(id_utilisateur)
    ON DELETE CASCADE,
  FOREIGN KEY (id_depense) REFERENCES depense(id_depense)
    ON DELETE SET NULL
) ENGINE=InnoDB;

-- ───────────────────────────────────────────────────────────
-- 9. PLANIFICATION_DEPENSE
-- ───────────────────────────────────────────────────────────
CREATE TABLE planification_depense (
  id_planification  INT AUTO_INCREMENT PRIMARY KEY,
  montant_prevu     DECIMAL(10,2) NOT NULL,
  date_prevue       DATE NOT NULL,
  description       VARCHAR(200),
  statut            ENUM('planifie', 'realise', 'annule') DEFAULT 'planifie',
  recurrence        BOOLEAN DEFAULT FALSE,
  id_categorie      INT NOT NULL,
  CONSTRAINT chk_montant_prevu_positif CHECK (montant_prevu > 0),
  FOREIGN KEY (id_categorie) REFERENCES categorie(id_categorie)
    ON DELETE CASCADE
) ENGINE=InnoDB;

-- ═══════════════════════════════════════════════════════════
-- INDEX pour optimiser les performances (filtres fréquents)
-- ═══════════════════════════════════════════════════════════
CREATE INDEX idx_depense_categorie ON depense(id_categorie);
CREATE INDEX idx_depense_date      ON depense(date_depense);
CREATE INDEX idx_categorie_budget  ON categorie(id_budget);
CREATE INDEX idx_budget_utilisateur ON budget(id_utilisateur);
CREATE INDEX idx_historique_utilisateur ON historique(id_utilisateur);
CREATE INDEX idx_notification_utilisateur ON notification(id_utilisateur);
CREATE INDEX idx_alerte_budget ON alerte(id_budget);
CREATE INDEX idx_planification_categorie ON planification_depense(id_categorie);
CREATE INDEX idx_rapport_utilisateur ON rapport(id_utilisateur);

-- ═══════════════════════════════════════════════════════════
-- DONNÉES DE TEST RICHES ET RÉALISTES
-- ═══════════════════════════════════════════════════════════

-- Nettoyage pour permettre l'exécution répétée du script
SET FOREIGN_KEY_CHECKS = 0;
TRUNCATE TABLE notification;
TRUNCATE TABLE alerte;
TRUNCATE TABLE historique;
TRUNCATE TABLE rapport;
TRUNCATE TABLE planification_depense;
TRUNCATE TABLE depense;
TRUNCATE TABLE categorie;
TRUNCATE TABLE budget;
TRUNCATE TABLE utilisateur;
SET FOREIGN_KEY_CHECKS = 1;

-- Utilisateurs de test
INSERT INTO utilisateur (id_utilisateur, nom, prenom, email, mot_de_passe_hash, est_actif) VALUES
(1, 'Diallo', 'Mamoudou Talibe', 'mamoudou@esp.sn', '$2b$12$exemplehashbcrypt1', TRUE),
(2, 'Diop', 'Awa', 'awa.diop@esp.sn', '$2b$12$exemplehashbcrypt2', TRUE),
(3, 'Sow', 'Moussa', 'moussa.sow@esp.sn', '$2b$12$exemplehashbcrypt3', FALSE);

-- Budgets mensuels et semestriels
INSERT INTO budget (id_budget, montant_global, periode, date_debut, date_fin, statut, id_utilisateur) VALUES
(1, 180000.00, 'mensuel', '2026-06-01', '2026-06-30', 'actif', 1),
(2, 250000.00, 'semestriel', '2026-01-01', '2026-06-30', 'actif', 2),
(3, 120000.00, 'mensuel', '2026-06-01', '2026-06-30', 'archive', 1);

-- Catégories détaillées
INSERT INTO categorie (id_categorie, nom_categorie, sous_budget, couleur, id_budget) VALUES
(1, 'Logement', 60000.00, '#3498DB', 1),
(2, 'Nourriture', 35000.00, '#27AE60', 1),
(3, 'Transport', 18000.00, '#F39C12', 1),
(4, 'Frais scolaires', 25000.00, '#9B59B6', 1),
(5, 'Loisirs', 15000.00, '#E74C3C', 1),
(6, 'Santé', 10000.00, '#1ABC9C', 1),
(7, 'Autres', 12000.00, '#95A5A6', 1),
(8, 'Logement', 90000.00, '#2E86DE', 2),
(9, 'Nourriture', 55000.00, '#2ECC71', 2),
(10, 'Transport', 30000.00, '#F1C40F', 2),
(11, 'Frais scolaires', 40000.00, '#8E44AD', 2),
(12, 'Loisirs', 20000.00, '#E67E22', 2),
(13, 'Santé', 15000.00, '#16A085', 2),
(14, 'Autres', 20000.00, '#7F8C8D', 2);

-- Dépenses réelles et variées
INSERT INTO depense (id_depense, montant, date_depense, description, statut, id_categorie) VALUES
(1, 45000.00, '2026-06-01', 'Loyer juin', 'valide', 1),
(2, 3800.00, '2026-06-02', 'Petit-déjeuner au marché', 'valide', 2),
(3, 1200.00, '2026-06-03', 'Ticket de bus', 'valide', 3),
(4, 5200.00, '2026-06-04', 'Photocopies et polycopiés', 'valide', 4),
(5, 6500.00, '2026-06-07', 'Sortie cinéma avec amis', 'valide', 5),
(6, 7500.00, '2026-06-08', 'Consultation médicale', 'valide', 6),
(7, 3200.00, '2026-06-09', 'Achat de fournitures diverses', 'valide', 7),
(8, 48000.00, '2026-06-10', 'Acompte loyer', 'en_attente', 8),
(9, 5000.00, '2026-06-12', 'Courses alimentaires', 'valide', 9),
(10, 3000.00, '2026-06-13', 'Essence moto', 'valide', 10),
(11, 1800.00, '2026-06-15', 'Abonnement internet', 'valide', 11),
(12, 12000.00, '2026-06-16', 'Voyage week-end', 'valide', 12),
(13, 9000.00, '2026-06-18', 'Analyses médicales', 'valide', 13),
(14, 4500.00, '2026-06-20', 'Achats imprévus', 'en_attente', 14);

-- Alertes liées au dépassement
INSERT INTO alerte (id_alerte, type_alerte, seuil, message, est_lue, pourcentage_atteint, id_budget, id_categorie) VALUES
(1, 'orange', 80.00, 'Vous avez atteint 80% de votre budget alimentation', FALSE, 82.50, 1, 2),
(2, 'rouge', 100.00, 'Vous avez dépassé votre budget transport', TRUE, 105.00, 1, 3),
(3, 'orange', 75.00, 'Votre budget loisirs approche sa limite', FALSE, 76.00, 2, 12);

-- Notifications envoyées à l’utilisateur
INSERT INTO notification (id_notification, message, type, est_lue, id_utilisateur, id_alerte) VALUES
(1, 'Votre budget alimentation est presque atteint.', 'orange', FALSE, 1, 1),
(2, 'Attention : votre budget transport est dépassé.', 'rouge', TRUE, 1, 2),
(3, 'Votre budget loisirs approche sa limite.', 'orange', FALSE, 2, 3);

-- Rapports de synthèse
INSERT INTO rapport (id_rapport, titre, date_generation, periode_debut, periode_fin, contenu, format, id_utilisateur) VALUES
(1, 'Rapport mensuel juin 2026', '2026-06-25 10:00:00', '2026-06-01', '2026-06-30', 'Synthèse des dépenses mensuelles du budget principal.', 'PDF', 1),
(2, 'Rapport semestriel 2026', '2026-06-25 11:30:00', '2026-01-01', '2026-06-30', 'Analyse globale du semestre avec comparaison des catégories.', 'Excel', 2);

-- Historique des actions
INSERT INTO historique (id_historique, action, date_action, details, id_utilisateur, id_depense) VALUES
(1, 'ajout', '2026-06-01 08:00:00', 'Ajout du loyer juin', 1, 1),
(2, 'modification', '2026-06-03 09:15:00', 'Mise à jour du montant de la dépense alimentation', 1, 2),
(3, 'suppression', '2026-06-10 14:20:00', 'Suppression d''une dépense test', 1, NULL),
(4, 'ajout', '2026-06-12 18:10:00', 'Ajout d''une dépense transport', 2, 10);

-- Planifications de dépenses futures
INSERT INTO planification_depense (id_planification, montant_prevu, date_prevue, description, statut, recurrence, id_categorie) VALUES
(1, 5000.00, '2026-07-05', 'Abonnement internet mensuel', 'planifie', TRUE, 4),
(2, 12000.00, '2026-07-10', 'Voyage de fin de semestre', 'planifie', FALSE, 5),
(3, 3000.00, '2026-07-15', 'Réparation de la moto', 'realise', FALSE, 3);

-- ═══════════════════════════════════════════════════════════
-- REQUÊTES DE VÉRIFICATION
-- ═══════════════════════════════════════════════════════════

-- Solde global de l'utilisateur 1
SELECT
  b.id_budget,
  b.montant_global,
  COALESCE(SUM(d.montant), 0) AS total_depense,
  b.montant_global - COALESCE(SUM(d.montant), 0) AS solde_global
FROM budget b
LEFT JOIN categorie c ON c.id_budget = b.id_budget
LEFT JOIN depense d   ON d.id_categorie = c.id_categorie
WHERE b.id_utilisateur = 1
GROUP BY b.id_budget;

-- Pourcentage consommé par catégorie (RG06)
SELECT
  c.nom_categorie,
  c.sous_budget,
  COALESCE(SUM(d.montant), 0) AS total_depense,
  ROUND(COALESCE(SUM(d.montant), 0) / c.sous_budget * 100, 1) AS pourcentage
FROM categorie c
LEFT JOIN depense d ON d.id_categorie = c.id_categorie
WHERE c.id_budget = 1
GROUP BY c.id_categorie;

-- Vue synthèse des alertes actives
SELECT
  a.id_alerte,
  a.type_alerte,
  a.message,
  c.nom_categorie,
  a.pourcentage_atteint
FROM alerte a
LEFT JOIN categorie c ON c.id_categorie = a.id_categorie
WHERE a.est_lue = FALSE
ORDER BY a.id_alerte;
