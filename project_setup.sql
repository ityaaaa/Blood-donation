DROP DATABASE IF EXISTS blood_donation_system;
CREATE DATABASE blood_donation_system;

USE blood_donation_system;

CREATE TABLE blood_types (
    blood_type_id INT PRIMARY KEY AUTO_INCREMENT,
    blood_group VARCHAR(5) UNIQUE NOT NULL
);

CREATE TABLE compatibility_rules (
    donor_type_id INT,
    recipient_type_id INT,

    PRIMARY KEY (donor_type_id, recipient_type_id),

    FOREIGN KEY (donor_type_id)
        REFERENCES blood_types(blood_type_id)
        ON DELETE CASCADE,

    FOREIGN KEY (recipient_type_id)
        REFERENCES blood_types(blood_type_id)
        ON DELETE CASCADE
);

CREATE TABLE donors (
    donor_id INT PRIMARY KEY AUTO_INCREMENT,

    full_name VARCHAR(100) NOT NULL,

    phone_number VARCHAR(15) UNIQUE NOT NULL,

    blood_type_id INT NOT NULL,

    latitude DECIMAL(9,6) NOT NULL,
    longitude DECIMAL(9,6) NOT NULL,

    health_status ENUM('Healthy', 'Sick') DEFAULT 'Healthy',

    last_donation_date DATE NOT NULL,

    is_available BOOLEAN DEFAULT TRUE,

    registration_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (blood_type_id)
        REFERENCES blood_types(blood_type_id)
        ON DELETE CASCADE
);

INSERT INTO blood_types (blood_group) VALUES
('A+'),
('A-'),
('B+'),
('B-'),
('AB+'),
('AB-'),
('O+'),
('O-');

INSERT INTO compatibility_rules 
(donor_type_id, recipient_type_id)
VALUES

-- O- universal donor
(8,1),(8,2),(8,3),(8,4),(8,5),(8,6),(8,7),(8,8),

-- O+
(7,1),(7,3),(7,5),(7,7),

-- A-
(2,1),(2,2),(2,5),(2,6),

-- A+
(1,1),(1,5),

-- B-
(4,3),(4,4),(4,5),(4,6),

-- B+
(3,3),(3,5),

-- AB-
(6,5),(6,6),

-- AB+
(5,5);

INSERT INTO compatibility_rules 
(donor_type_id, recipient_type_id)
VALUES

-- O- universal donor
(8,1),(8,2),(8,3),(8,4),(8,5),(8,6),(8,7),(8,8),

-- O+
(7,1),(7,3),(7,5),(7,7),

-- A-
(2,1),(2,2),(2,5),(2,6),

-- A+
(1,1),(1,5),

-- B-
(4,3),(4,4),(4,5),(4,6),

-- B+
(3,3),(3,5),

-- AB-
(6,5),(6,6),

-- AB+
(5,5);


INSERT INTO donors
(full_name, phone_number, blood_type_id,
latitude, longitude,
health_status, last_donation_date, is_available)

VALUES

('Rahul Sharma', '9876543210', 8,
12.971599, 77.594566,
'Healthy', '2025-01-10', TRUE),

('Priya Nair', '9876543211', 1,
12.935223, 77.624480,
'Healthy', '2025-02-15', TRUE),

('Arjun Mehta', '9876543212', 3,
13.082680, 80.270721,
'Sick', '2025-01-20', TRUE),

('Sneha Reddy', '9876543213', 7,
17.385044, 78.486671,
'Healthy', '2025-03-01', FALSE),

('Vikram Patel', '9876543214', 2,
19.076090, 72.877426,
'Healthy', '2025-01-05', TRUE);


SELECT
    d.donor_id,
    d.full_name,
    d.phone_number,
    bt.blood_group,
    d.health_status,
    d.last_donation_date

FROM donors d

JOIN blood_types bt
    ON d.blood_type_id = bt.blood_type_id

JOIN compatibility_rules cr
    ON d.blood_type_id = cr.donor_type_id

WHERE cr.recipient_type_id = 1

AND d.health_status = 'Healthy'

AND d.is_available = TRUE

AND DATEDIFF(CURDATE(), d.last_donation_date) > 56;



SELECT
    d.donor_id,
    d.full_name,
    d.phone_number,
    bt.blood_group,

    ROUND(
        SQRT(
            POW(d.latitude - 12.9716, 2) +
            POW(d.longitude - 77.5946, 2)
        ),
        4
    ) AS distance

FROM donors d

JOIN blood_types bt
    ON d.blood_type_id = bt.blood_type_id

JOIN compatibility_rules cr
    ON d.blood_type_id = cr.donor_type_id

WHERE cr.recipient_type_id = 1

AND d.health_status = 'Healthy'

AND d.is_available = TRUE

AND DATEDIFF(CURDATE(), d.last_donation_date) > 56

ORDER BY distance ASC;



CREATE INDEX idx_blood_type
ON donors(blood_type_id);

CREATE INDEX idx_health_status
ON donors(health_status);

CREATE INDEX idx_availability
ON donors(is_available);

CREATE INDEX idx_last_donation
ON donors(last_donation_date);

CREATE TABLE emergency_requests (

    request_id INT PRIMARY KEY AUTO_INCREMENT,

    hospital_name VARCHAR(100) NOT NULL,

    needed_blood_type INT NOT NULL,

    units_needed INT NOT NULL,

    urgency_level ENUM('Low', 'Medium', 'High', 'Critical') NOT NULL,

    latitude DECIMAL(9,6) NOT NULL,

    longitude DECIMAL(9,6) NOT NULL,

    request_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (needed_blood_type)
        REFERENCES blood_types(blood_type_id)
        ON DELETE CASCADE
);

INSERT INTO emergency_requests
(hospital_name, needed_blood_type,
units_needed, urgency_level,
latitude, longitude)

VALUES

('Apollo Hospital', 1,
5, 'Critical',
12.971600, 77.594600);

SELECT
    er.hospital_name,
    bt_needed.blood_group AS needed_blood,

    d.full_name,
    d.phone_number,

    bt_donor.blood_group AS donor_blood_group,

    ROUND(
        SQRT(
            POW(d.latitude - er.latitude, 2) +
            POW(d.longitude - er.longitude, 2)
        ),
        4
    ) AS distance

FROM emergency_requests er

JOIN compatibility_rules cr
    ON er.needed_blood_type = cr.recipient_type_id

JOIN donors d
    ON d.blood_type_id = cr.donor_type_id

JOIN blood_types bt_needed
    ON er.needed_blood_type = bt_needed.blood_type_id

JOIN blood_types bt_donor
    ON d.blood_type_id = bt_donor.blood_type_id

WHERE d.health_status = 'Healthy'

AND d.is_available = TRUE

AND DATEDIFF(CURDATE(), d.last_donation_date) > 56

ORDER BY distance ASC;