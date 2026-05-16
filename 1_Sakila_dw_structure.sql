-- ============================================================
--  Sakila Data Warehouse — Star Schema DDL
--  Run this file FIRST to create the empty warehouse.
--  No data is loaded here — only tables and indexes.
-- ============================================================


-- ============================================================
--  CREATE DATABASE
-- ============================================================

DROP DATABASE IF EXISTS sakila_dw;

CREATE DATABASE sakila_dw
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE sakila_dw;


-- ============================================================
--  DIMENSION TABLES
-- ============================================================

-- ------------------------------------------------------------
--  dim_date
--  Calendar dimension, generated (not from OLTP).
-- ------------------------------------------------------------
CREATE TABLE dim_date (
    date_key        INT         NOT NULL,   -- YYYYMMDD e.g. 20060215
    full_date       DATE        NOT NULL,
    day_of_week     TINYINT     NOT NULL,   -- 1=Monday … 7=Sunday
    day_name        VARCHAR(10) NOT NULL,
    day_of_month    TINYINT     NOT NULL,
    day_of_year     SMALLINT    NOT NULL,
    week_of_year    TINYINT     NOT NULL,
    month_number    TINYINT     NOT NULL,
    month_name      VARCHAR(10) NOT NULL,
    quarter         TINYINT     NOT NULL,   -- 1–4
    year            SMALLINT    NOT NULL,
    is_weekend      TINYINT(1)  NOT NULL DEFAULT 0,  -- 1=Sat/Sun
    CONSTRAINT pk_dim_date PRIMARY KEY (date_key)
) ENGINE = InnoDB;


-- ------------------------------------------------------------
--  dim_customer
--  Source: customer + address + city + country (flattened).
--  SCD Type 2: is_current=1 identifies the active row.
-- ------------------------------------------------------------
CREATE TABLE dim_customer (
    customer_key        INT         NOT NULL AUTO_INCREMENT,
    customer_id         SMALLINT    NOT NULL,   -- natural key
    first_name          VARCHAR(45) NOT NULL,
    last_name           VARCHAR(45) NOT NULL,
    email               VARCHAR(50) DEFAULT NULL,
    address             VARCHAR(50) NOT NULL,
    district            VARCHAR(20) NOT NULL,
    city                VARCHAR(50) NOT NULL,
    country             VARCHAR(50) NOT NULL,
    postal_code         VARCHAR(10) DEFAULT NULL,
    phone               VARCHAR(20) NOT NULL,
    active              TINYINT(1)  NOT NULL DEFAULT 1,
    create_date         DATE        NOT NULL,
    row_effective_date  DATE        NOT NULL,
    row_expiry_date     DATE        DEFAULT NULL,
    is_current          TINYINT(1)  NOT NULL DEFAULT 1,
    CONSTRAINT pk_dim_customer PRIMARY KEY (customer_key)
) ENGINE = InnoDB;


-- ------------------------------------------------------------
--  dim_film
--  Source: film + language (language folded in, no separate dim).
-- ------------------------------------------------------------
CREATE TABLE dim_film (
    film_key            INT          NOT NULL AUTO_INCREMENT,
    film_id             SMALLINT     NOT NULL,   -- natural key
    title               VARCHAR(128) NOT NULL,
    description         TEXT         DEFAULT NULL,
    release_year        YEAR         DEFAULT NULL,
    language            VARCHAR(20)  NOT NULL,
    original_language   VARCHAR(20)  DEFAULT NULL,
    rental_duration     TINYINT      NOT NULL,
    rental_rate         DECIMAL(4,2) NOT NULL,
    length_minutes      SMALLINT     DEFAULT NULL,
    replacement_cost    DECIMAL(5,2) NOT NULL,
    rating              VARCHAR(10)  DEFAULT NULL,
    special_features    VARCHAR(255) DEFAULT NULL,
    CONSTRAINT pk_dim_film PRIMARY KEY (film_key)
) ENGINE = InnoDB;


-- ------------------------------------------------------------
--  dim_category
--  Source: category.
-- ------------------------------------------------------------
CREATE TABLE dim_category (
    category_key    INT         NOT NULL AUTO_INCREMENT,
    category_id     TINYINT     NOT NULL,   -- natural key
    name            VARCHAR(25) NOT NULL,
    CONSTRAINT pk_dim_category PRIMARY KEY (category_key)
) ENGINE = InnoDB;


-- ------------------------------------------------------------
--  dim_store
--  Source: store + staff (manager) + address + city + country.
-- ------------------------------------------------------------
CREATE TABLE dim_store (
    store_key       INT         NOT NULL AUTO_INCREMENT,
    store_id        TINYINT     NOT NULL,   -- natural key
    address         VARCHAR(50) NOT NULL,
    district        VARCHAR(20) NOT NULL,
    city            VARCHAR(50) NOT NULL,
    country         VARCHAR(50) NOT NULL,
    postal_code     VARCHAR(10) DEFAULT NULL,
    phone           VARCHAR(20) NOT NULL,
    manager_name    VARCHAR(91) NOT NULL,
    CONSTRAINT pk_dim_store PRIMARY KEY (store_key)
) ENGINE = InnoDB;


-- ------------------------------------------------------------
--  dim_staff
--  Source: staff.
-- ------------------------------------------------------------
CREATE TABLE dim_staff (
    staff_key   INT         NOT NULL AUTO_INCREMENT,
    staff_id    TINYINT     NOT NULL,   -- natural key
    first_name  VARCHAR(45) NOT NULL,
    last_name   VARCHAR(45) NOT NULL,
    full_name   VARCHAR(91) NOT NULL,
    email       VARCHAR(50) DEFAULT NULL,
    username    VARCHAR(16) NOT NULL,
    store_id    TINYINT     NOT NULL,
    active      TINYINT(1)  NOT NULL DEFAULT 1,
    CONSTRAINT pk_dim_staff PRIMARY KEY (staff_key)
) ENGINE = InnoDB;


-- ------------------------------------------------------------
--  dim_actor
--  Source: actor. Linked to dim_film via bridge_film_actor.
-- ------------------------------------------------------------
CREATE TABLE dim_actor (
    actor_key   INT         NOT NULL AUTO_INCREMENT,
    actor_id    SMALLINT    NOT NULL,   -- natural key
    first_name  VARCHAR(45) NOT NULL,
    last_name   VARCHAR(45) NOT NULL,
    full_name   VARCHAR(91) NOT NULL,
    CONSTRAINT pk_dim_actor PRIMARY KEY (actor_key)
) ENGINE = InnoDB;


-- ------------------------------------------------------------
--  bridge_film_actor
--  Resolves the many-to-many between dim_film and dim_actor.
-- ------------------------------------------------------------
CREATE TABLE bridge_film_actor (
    film_key    INT NOT NULL,
    actor_key   INT NOT NULL,
    CONSTRAINT pk_bridge        PRIMARY KEY (film_key, actor_key),
    CONSTRAINT fk_bridge_film   FOREIGN KEY (film_key)  REFERENCES dim_film  (film_key),
    CONSTRAINT fk_bridge_actor  FOREIGN KEY (actor_key) REFERENCES dim_actor (actor_key)
) ENGINE = InnoDB;


-- ============================================================
--  FACT TABLES
-- ============================================================

-- ------------------------------------------------------------
--  fact_rental
--  Grain: one row per rental transaction.
-- ------------------------------------------------------------
CREATE TABLE fact_rental (
    rental_key              INT          NOT NULL AUTO_INCREMENT,
    -- dimension FKs
    rental_date_key         INT          NOT NULL,
    return_date_key         INT          DEFAULT NULL,
    customer_key            INT          NOT NULL,
    film_key                INT          NOT NULL,
    category_key            INT          NOT NULL,
    store_key               INT          NOT NULL,
    staff_key               INT          NOT NULL,
    -- natural key (traceability to OLTP)
    rental_id               INT          NOT NULL,
    -- measures
    rental_duration_days    SMALLINT     DEFAULT NULL,
    allowed_duration_days   TINYINT      NOT NULL,
    days_overdue            SMALLINT     DEFAULT NULL,
    rental_rate             DECIMAL(4,2) NOT NULL,
    replacement_cost        DECIMAL(5,2) NOT NULL,
    is_returned             TINYINT(1)   NOT NULL DEFAULT 0,
    CONSTRAINT pk_fact_rental    PRIMARY KEY (rental_key),
    CONSTRAINT fk_fr_rental_date FOREIGN KEY (rental_date_key) REFERENCES dim_date     (date_key),
    CONSTRAINT fk_fr_return_date FOREIGN KEY (return_date_key) REFERENCES dim_date     (date_key),
    CONSTRAINT fk_fr_customer    FOREIGN KEY (customer_key)    REFERENCES dim_customer  (customer_key),
    CONSTRAINT fk_fr_film        FOREIGN KEY (film_key)        REFERENCES dim_film      (film_key),
    CONSTRAINT fk_fr_category    FOREIGN KEY (category_key)    REFERENCES dim_category  (category_key),
    CONSTRAINT fk_fr_store       FOREIGN KEY (store_key)       REFERENCES dim_store     (store_key),
    CONSTRAINT fk_fr_staff       FOREIGN KEY (staff_key)       REFERENCES dim_staff     (staff_key)
) ENGINE = InnoDB;


-- ------------------------------------------------------------
--  fact_payment
--  Grain: one row per payment transaction.
-- ------------------------------------------------------------
CREATE TABLE fact_payment (
    payment_key         INT          NOT NULL AUTO_INCREMENT,
    -- dimension FKs
    payment_date_key    INT          NOT NULL,
    customer_key        INT          NOT NULL,
    staff_key           INT          NOT NULL,
    store_key           INT          NOT NULL,
    -- optional link to the rental that triggered this payment
    rental_key          INT          DEFAULT NULL,
    -- natural key
    payment_id          SMALLINT     NOT NULL,
    -- measures
    amount_paid         DECIMAL(5,2) NOT NULL,
    CONSTRAINT pk_fact_payment PRIMARY KEY (payment_key),
    CONSTRAINT fk_fp_date      FOREIGN KEY (payment_date_key) REFERENCES dim_date     (date_key),
    CONSTRAINT fk_fp_customer  FOREIGN KEY (customer_key)     REFERENCES dim_customer  (customer_key),
    CONSTRAINT fk_fp_staff     FOREIGN KEY (staff_key)        REFERENCES dim_staff     (staff_key),
    CONSTRAINT fk_fp_store     FOREIGN KEY (store_key)        REFERENCES dim_store     (store_key),
    CONSTRAINT fk_fp_rental    FOREIGN KEY (rental_key)       REFERENCES fact_rental   (rental_key)
) ENGINE = InnoDB;


-- ------------------------------------------------------------
--  fact_inventory_snapshot
--  Grain: one row per film × store × rental date.
-- ------------------------------------------------------------
CREATE TABLE fact_inventory_snapshot (
    snapshot_key        INT      NOT NULL AUTO_INCREMENT,
    -- dimension FKs
    snapshot_date_key   INT      NOT NULL,
    film_key            INT      NOT NULL,
    store_key           INT      NOT NULL,
    -- measures
    total_copies        SMALLINT NOT NULL DEFAULT 0,
    copies_rented_out   SMALLINT NOT NULL DEFAULT 0,
    copies_available    SMALLINT NOT NULL DEFAULT 0,
    CONSTRAINT pk_fact_inventory PRIMARY KEY (snapshot_key),
    CONSTRAINT fk_fi_date  FOREIGN KEY (snapshot_date_key) REFERENCES dim_date  (date_key),
    CONSTRAINT fk_fi_film  FOREIGN KEY (film_key)          REFERENCES dim_film   (film_key),
    CONSTRAINT fk_fi_store FOREIGN KEY (store_key)         REFERENCES dim_store  (store_key)
) ENGINE = InnoDB;


-- ============================================================
--  INDEXES  (on every FK column for fast analytical queries)
-- ============================================================

CREATE INDEX idx_fr_rental_date ON fact_rental             (rental_date_key);
CREATE INDEX idx_fr_return_date ON fact_rental             (return_date_key);
CREATE INDEX idx_fr_customer    ON fact_rental             (customer_key);
CREATE INDEX idx_fr_film        ON fact_rental             (film_key);
CREATE INDEX idx_fr_store       ON fact_rental             (store_key);
CREATE INDEX idx_fr_staff       ON fact_rental             (staff_key);
CREATE INDEX idx_fr_category    ON fact_rental             (category_key);
CREATE INDEX idx_fp_date        ON fact_payment            (payment_date_key);
CREATE INDEX idx_fp_customer    ON fact_payment            (customer_key);
CREATE INDEX idx_fp_store       ON fact_payment            (store_key);
CREATE INDEX idx_fi_date_film   ON fact_inventory_snapshot (snapshot_date_key, film_key);
CREATE INDEX idx_fi_store       ON fact_inventory_snapshot (store_key);
CREATE INDEX idx_dc_customer_id ON dim_customer            (customer_id, is_current);
CREATE INDEX idx_df_film_id     ON dim_film                (film_id);

-- ============================================================
--  structure created, ready for data load.
-- ============================================================