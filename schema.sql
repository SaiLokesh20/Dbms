CREATE DATABASE CallHub;
USE CallHub;

/*
    Notes & suggested checks:
    - This file intentionally does not change existing table definitions.
    - Below are recommended CHECK constraints and comments to help validate
        basic invariants. They are provided as commented examples so you can
        enable them later if desired (uncomment to apply).
*/

-- Table 1: Department — department metadata and HOD link
CREATE TABLE Department (
    department_id INT AUTO_INCREMENT PRIMARY KEY,
    department_name VARCHAR(100) UNIQUE NOT NULL,
    department_building VARCHAR(100) NOT NULL,
    opening_hours TIME NOT NULL,
    closing_hours TIME NOT NULL,
    hod_member_id INT NULL
);

-- Suggested invariant: opening_hours should be before closing_hours
-- Example (commented):
-- ALTER TABLE Department
-- ADD CONSTRAINT chk_dept_hours CHECK (opening_hours < closing_hours);

-- Table 2: Member — member personal and departmental info
CREATE TABLE Member (
    member_id INT AUTO_INCREMENT PRIMARY KEY,
    member_name VARCHAR(100) NOT NULL,
    iit_email VARCHAR(150) UNIQUE NOT NULL,
    primary_phone VARCHAR(15) NOT NULL,
    dob DATE NOT NULL,
    image BLOB NULL,
    department_id INT NOT NULL,
    is_at_campus BOOLEAN NOT NULL,
    join_date DATE NOT NULL,
    exit_date DATE NULL,
    FOREIGN KEY (department_id) REFERENCES Department(department_id)
);

-- Suggested invariants for Member:
-- 1) Date of birth should be before join date
-- 2) If exit_date exists it should be on/after join_date
-- 3) `primary_phone` length/format could be validated with a CHECK or regex at application layer
-- Example (commented):
-- ALTER TABLE Member
-- ADD CONSTRAINT chk_member_dates CHECK (dob < join_date AND (exit_date IS NULL OR exit_date >= join_date));
ALTER TABLE Department
ADD CONSTRAINT fk_hod
FOREIGN KEY (hod_member_id) REFERENCES Member(member_id);

-- Table 3: Member_Role — role assignments for members
CREATE TABLE Member_Role (
    member_id INT NOT NULL,
    role_id INT NOT NULL,
    is_primary BOOLEAN NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NULL,
    PRIMARY KEY (member_id, role_id, start_date),
    FOREIGN KEY (member_id) REFERENCES Member(member_id),
    FOREIGN KEY (role_id) REFERENCES Role(role_id)
);

-- Suggested invariant: start_date should be before end_date when end_date is present
-- ALTER TABLE Member_Role
-- ADD CONSTRAINT chk_memberrole_dates CHECK (end_date IS NULL OR start_date < end_date);

-- Table 4: Member_Contact — alternate contacts for members
CREATE TABLE Member_Contact (
    contact_id INT AUTO_INCREMENT PRIMARY KEY,
    member_id INT NOT NULL,
    contact_type ENUM('PERSONAL_EMAIL','EMERGENCY_PHONE','ADDRESS','ALT_PHONE') NOT NULL,
    contact_value VARCHAR(255) NOT NULL,
    is_primary BOOLEAN NOT NULL,
    FOREIGN KEY (member_id) REFERENCES Member(member_id)
);

-- Suggestion: use `is_primary` to mark preferred contact; ensure at most one primary per member
-- This requires a UNIQUE index on (member_id, is_primary) with conditional expression
-- MySQL does not support partial unique indexes before v8.0.13, so enforce at application level


-- Table 5: Role — role definitions used for permissions
CREATE TABLE Role (
    role_id INT AUTO_INCREMENT PRIMARY KEY,
    role_name VARCHAR(50) UNIQUE NOT NULL
);

-- Table 6: Hostel — hostel records and caretakers
CREATE TABLE Hostel (
    hostel_id INT AUTO_INCREMENT PRIMARY KEY,
    hostel_name VARCHAR(100) UNIQUE NOT NULL,
    caretaker_member_id INT NULL,
    caretaker_contact VARCHAR(20),
    FOREIGN KEY (caretaker_member_id) REFERENCES Member(member_id)
);

-- Suggestion: caretaker_contact format checks and ensuring caretaker_member_id exists handled by FK already

-- Table 7: Lab — lab details and in-charge member
CREATE TABLE Lab (
    lab_id INT AUTO_INCREMENT PRIMARY KEY,
    lab_name VARCHAR(100) NOT NULL,
    department_id INT NOT NULL,
    lab_room_no VARCHAR(20) NOT NULL,
    contact_no VARCHAR(20),
    incharge_member_id INT NULL,
    FOREIGN KEY (department_id) REFERENCES Department(department_id),
    FOREIGN KEY (incharge_member_id) REFERENCES Member(member_id)
);

-- Suggestion: consider UNIQUE(department_id, lab_room_no) if room numbers are unique per department



-- Table 8: Office_Room — office locations per department
CREATE TABLE Office_Room (
    office_room_id INT AUTO_INCREMENT PRIMARY KEY,
    department_id INT NOT NULL,
    building_no VARCHAR(20) NOT NULL,
    office_room_no VARCHAR(20) NOT NULL,
    office_contact VARCHAR(20),
    FOREIGN KEY (department_id) REFERENCES Department(department_id)
);

-- Suggestion: consider UNIQUE(department_id, office_room_no) to avoid duplicate room entries

-- Table 9: Directory_Interaction_Log — logs of directory interactions
CREATE TABLE Directory_Interaction_Log (
    interaction_id INT AUTO_INCREMENT PRIMARY KEY,
    actor_member_id INT NOT NULL,
    target_member_id INT NOT NULL,
    interaction_type ENUM('VIEW_PROFILE','CLICK_CALL','CLICK_EMAIL') NOT NULL,
    interaction_time DATETIME NOT NULL,
    FOREIGN KEY (actor_member_id) REFERENCES Member(member_id),
    FOREIGN KEY (target_member_id) REFERENCES Member(member_id)
);

-- Suggestion: consider indexing `interaction_time` for query performance


-- Table 10: Permission — permission catalogue
CREATE TABLE Permission (
    permission_id INT AUTO_INCREMENT PRIMARY KEY,
    permission_name VARCHAR(100) UNIQUE NOT NULL
);

-- Table 11: Role_Permission — mapping roles to permissions
CREATE TABLE Role_Permission (
    role_id INT NOT NULL,
    permission_id INT NOT NULL,
    PRIMARY KEY (role_id, permission_id),
    FOREIGN KEY (role_id) REFERENCES Role(role_id),
    FOREIGN KEY (permission_id) REFERENCES Permission(permission_id)
);

-- Table 12: Search_Log — records of directory searches
CREATE TABLE Search_Log (
    search_id INT AUTO_INCREMENT PRIMARY KEY,
    searched_by_member_id INT NOT NULL,
    search_keyword VARCHAR(100) NOT NULL,
    search_time DATETIME NOT NULL,
    result_count INT NOT NULL,
    filter_department_id INT NULL,
    filter_role_id INT NULL,
    FOREIGN KEY (searched_by_member_id) REFERENCES Member(member_id),
    FOREIGN KEY (filter_department_id) REFERENCES Department(department_id),
    FOREIGN KEY (filter_role_id) REFERENCES Role(role_id)
);

-- Suggestion: `search_keyword` could be normalized/truncated for storage; consider FULLTEXT index if supported



-- Table 13: Login_History — login/logout records and IPs
CREATE TABLE Login_History (
    login_id INT AUTO_INCREMENT PRIMARY KEY,
    member_id INT NOT NULL,
    login_time DATETIME NOT NULL,
    logout_time DATETIME NULL,
    ip_address VARCHAR(50) NOT NULL,
    FOREIGN KEY (member_id) REFERENCES Member(member_id)
);

-- Suggestion: consider adding an index on (member_id, login_time) for faster lookups

-- Table 14: Audit_Log — audit trail of data actions
CREATE TABLE Audit_Log (
    audit_id INT AUTO_INCREMENT PRIMARY KEY,
    performed_by_member_id INT NOT NULL,
    target_member_id INT NULL,
    action_type ENUM('INSERT','UPDATE','DELETE','EXPORT','EMERGENCY_VIEW') NOT NULL,
    affected_table VARCHAR(100) NOT NULL,
    affected_row_pk VARCHAR(100) NOT NULL,
    old_data JSON NULL,
    new_data JSON NULL,
    action_time DATETIME NOT NULL,
    retention_until DATE NULL,
    FOREIGN KEY (performed_by_member_id) REFERENCES Member(member_id),
    FOREIGN KEY (target_member_id) REFERENCES Member(member_id)
);

-- Suggestion: set `retention_until` via application policy; consider a scheduled job to purge
-- Example cleanup query (run periodically):
-- DELETE FROM Audit_Log WHERE retention_until IS NOT NULL AND retention_until < CURDATE();




