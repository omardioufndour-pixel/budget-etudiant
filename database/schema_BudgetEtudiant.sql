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

-- ═══════════════════════════════════════════════════════════
-- DONNÉES DE TEST
-- ═══════════════════════════════════════════════════════════

-- Utilisateur de test
INSERT INTO utilisateur (nom, prenom, email, mot_de_passe_hash) VALUES
('Diallo', 'Mamoudou Talibe', 'mamoudou@esp.sn', '$2b$12$exemplehashbcrypt...');

-- Budget mensuel
INSERT INTO budget (montant_global, periode, date_debut, date_fin, id_utilisateur) VALUES
(150000, 'mensuel', '2026-06-01', '2026-06-30', 1);

-- 7 catégories avec sous-budgets
INSERT INTO categorie (nom_categorie, sous_budget, couleur, id_budget) VALUES
('Logement', 50000, '#3498DB', 1),
('Nourriture', 35000, '#27AE60', 1),
('Transport', 15000, '#F39C12', 1),
('Frais scolaires', 20000, '#9B59B6', 1),
('Loisirs', 12000, '#E74C3C', 1),
('Sante', 8000, '#1ABC9C', 1),
('Autres', 10000, '#95A5A6', 1);

-- Dépenses de test
INSERT INTO depense (montant, date_depense, description, id_categorie) VALUES
(45000, '2026-06-01', 'Loyer juin', 1),
(3500,  '2026-06-03', 'Déjeuner Sandaga', 2),
(1200,  '2026-06-04', 'Bus Plateau', 3),
(5000,  '2026-06-05', 'Photocopies ESP', 4);

-- ═══════════════════════════════════════════════════════════
-- REQUÊTES DE VÉRIFICATION
-- ═══════════════════════════════════════════════════════════

-- Solde global de l'utilisateur 1
SELECT
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
