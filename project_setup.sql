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