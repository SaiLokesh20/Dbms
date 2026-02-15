-- setup_all.sql
-- Single-file script: create DB, create schema, insert sample data, and run verification checks.
-- Run with: mysql -u <user> -p < setup_all.sql

CREATE DATABASE IF NOT EXISTS CallHub CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE CallHub;

/* -----------------------------
   Schema (inlined)
   ----------------------------- */

/*
    Notes & suggested checks:
    - This file intentionally does not change existing table definitions.
    - Below are recommended CHECK constraints and comments to help validate
      basic invariants. They are provided as commented examples so you can
      enable them later if desired (uncomment to apply).
*/

-- Table 1: Department — department metadata and HOD link
CREATE TABLE IF NOT EXISTS Department (
    department_id INT AUTO_INCREMENT PRIMARY KEY,
    department_name VARCHAR(100) UNIQUE NOT NULL,
    department_building VARCHAR(100) NOT NULL,
    opening_hours TIME NOT NULL,
    closing_hours TIME NOT NULL,
    hod_member_id INT NULL
);

-- Table 2: Member — member personal and departmental info
CREATE TABLE IF NOT EXISTS Member (
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

ALTER TABLE Department
ADD CONSTRAINT IF NOT EXISTS fk_hod
FOREIGN KEY (hod_member_id) REFERENCES Member(member_id);

-- Table 3: Member_Role — role assignments for members
CREATE TABLE IF NOT EXISTS Member_Role (
    member_id INT NOT NULL,
    role_id INT NOT NULL,
    is_primary BOOLEAN NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NULL,
    PRIMARY KEY (member_id, role_id, start_date),
    FOREIGN KEY (member_id) REFERENCES Member(member_id),
    FOREIGN KEY (role_id) REFERENCES Role(role_id)
);

-- Table 4: Member_Contact — alternate contacts for members
CREATE TABLE IF NOT EXISTS Member_Contact (
    contact_id INT AUTO_INCREMENT PRIMARY KEY,
    member_id INT NOT NULL,
    contact_type ENUM('PERSONAL_EMAIL','EMERGENCY_PHONE','ADDRESS','ALT_PHONE') NOT NULL,
    contact_value VARCHAR(255) NOT NULL,
    is_primary BOOLEAN NOT NULL,
    FOREIGN KEY (member_id) REFERENCES Member(member_id)
);

-- Table 5: Role — role definitions used for permissions
CREATE TABLE IF NOT EXISTS Role (
    role_id INT AUTO_INCREMENT PRIMARY KEY,
    role_name VARCHAR(50) UNIQUE NOT NULL
);

-- Table 6: Hostel — hostel records and caretakers
CREATE TABLE IF NOT EXISTS Hostel (
    hostel_id INT AUTO_INCREMENT PRIMARY KEY,
    hostel_name VARCHAR(100) UNIQUE NOT NULL,
    caretaker_member_id INT NULL,
    caretaker_contact VARCHAR(20),
    FOREIGN KEY (caretaker_member_id) REFERENCES Member(member_id)
);

-- Table 7: Lab — lab details and in-charge member
CREATE TABLE IF NOT EXISTS Lab (
    lab_id INT AUTO_INCREMENT PRIMARY KEY,
    lab_name VARCHAR(100) NOT NULL,
    department_id INT NOT NULL,
    lab_room_no VARCHAR(20) NOT NULL,
    contact_no VARCHAR(20),
    incharge_member_id INT NULL,
    FOREIGN KEY (department_id) REFERENCES Department(department_id),
    FOREIGN KEY (incharge_member_id) REFERENCES Member(member_id)
);

-- Table 8: Office_Room — office locations per department
CREATE TABLE IF NOT EXISTS Office_Room (
    office_room_id INT AUTO_INCREMENT PRIMARY KEY,
    department_id INT NOT NULL,
    building_no VARCHAR(20) NOT NULL,
    office_room_no VARCHAR(20) NOT NULL,
    office_contact VARCHAR(20),
    FOREIGN KEY (department_id) REFERENCES Department(department_id)
);

-- Table 9: Directory_Interaction_Log — logs of directory interactions
CREATE TABLE IF NOT EXISTS Directory_Interaction_Log (
    interaction_id INT AUTO_INCREMENT PRIMARY KEY,
    actor_member_id INT NOT NULL,
    target_member_id INT NOT NULL,
    interaction_type ENUM('VIEW_PROFILE','CLICK_CALL','CLICK_EMAIL') NOT NULL,
    interaction_time DATETIME NOT NULL,
    FOREIGN KEY (actor_member_id) REFERENCES Member(member_id),
    FOREIGN KEY (target_member_id) REFERENCES Member(member_id)
);

-- Table 10: Permission — permission catalogue
CREATE TABLE IF NOT EXISTS Permission (
    permission_id INT AUTO_INCREMENT PRIMARY KEY,
    permission_name VARCHAR(100) UNIQUE NOT NULL
);

-- Table 11: Role_Permission — mapping roles to permissions
CREATE TABLE IF NOT EXISTS Role_Permission (
    role_id INT NOT NULL,
    permission_id INT NOT NULL,
    PRIMARY KEY (role_id, permission_id),
    FOREIGN KEY (role_id) REFERENCES Role(role_id),
    FOREIGN KEY (permission_id) REFERENCES Permission(permission_id)
);

-- Table 12: Search_Log — records of directory searches
CREATE TABLE IF NOT EXISTS Search_Log (
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

-- Table 13: Login_History — login/logout records and IPs
CREATE TABLE IF NOT EXISTS Login_History (
    login_id INT AUTO_INCREMENT PRIMARY KEY,
    member_id INT NOT NULL,
    login_time DATETIME NOT NULL,
    logout_time DATETIME NULL,
    ip_address VARCHAR(50) NOT NULL,
    FOREIGN KEY (member_id) REFERENCES Member(member_id)
);

-- Table 14: Audit_Log — audit trail of data actions
CREATE TABLE IF NOT EXISTS Audit_Log (
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

/* -----------------------------
   Sample data (inlined)
   ----------------------------- */

-- Sample inserts (trimmed first-line USE; script already sets the DB above)

INSERT INTO Department (department_name, department_building, opening_hours, closing_hours) VALUES
('Computer Science','Block A','09:00:00','17:00:00'),
('Information Technology','Block A','09:00:00','17:00:00'),
('Electrical Engineering','Block B','09:00:00','17:00:00'),
('Mechanical Engineering','Block C','09:00:00','17:00:00'),
('Civil Engineering','Block D','09:00:00','17:00:00'),
('Electronics','Block E','09:00:00','17:00:00'),
('Data Science','Block F','09:00:00','17:00:00'),
('AI','Block F','09:00:00','17:00:00'),
('Cyber Security','Block G','09:00:00','17:00:00'),
('Administration','Admin','09:00:00','17:00:00'),
('Accounts','Admin','09:00:00','17:00:00'),
('HR','Admin','09:00:00','17:00:00'),
('Library','Library','08:00:00','20:00:00'),
('Hostel','Hostel','09:00:00','18:00:00'),
('Placement','Placement','09:00:00','17:00:00'),
('Research','R&D','09:00:00','17:00:00'),
('IT Support','IT','09:00:00','18:00:00'),
('Security','Gate','00:00:00','23:59:00'),
('Medical','Medical','09:00:00','18:00:00'),
('Exam Cell','Admin','09:00:00','17:00:00');

INSERT INTO Role (role_name) VALUES
('Student'),('Professor'),('Assistant Professor'),('Associate Professor'),
('Lab Assistant'),('Technician'),('HOD'),('Dean'),('Director'),
('Admin Staff'),('Account Officer'),('HR Manager'),
('Librarian'),('Hostel Warden'),('Security Guard'),
('Doctor'),('Nurse'),('IT Engineer'),
('Placement Officer'),('Research Scholar');

INSERT INTO Permission (permission_name) VALUES
('VIEW_CONTACT'),('EDIT_CONTACT'),('DELETE_CONTACT'),
('EXPORT'),('EMERGENCY'),('VIEW_ANALYTICS'),
('ADD_MEMBER'),('REMOVE_MEMBER'),('ASSIGN_ROLE'),
('LOGIN'),('LOGOUT'),('VIEW_DEPT'),
('ADD_DEPT'),('DELETE_DEPT'),('UPDATE_DEPT'),
('SEARCH'),('CALL'),('EMAIL'),
('VIEW_PROFILE'),('ADMIN_ACCESS');

INSERT INTO Role_Permission VALUES
(1,1),(1,10),
(2,1),(2,6),
(3,1),(3,6),
(4,1),(4,6),
(5,1),(5,7),
(6,1),(6,7),
(7,1),(7,2),
(8,1),(8,2),
(9,1),(9,4),
(10,1),(10,2);

INSERT INTO Member
(member_name,iit_email,primary_phone,dob,department_id,is_at_campus,join_date)
VALUES
('Amit Sharma','amit@org.in','9000000001','2000-01-01',1,TRUE,'2022-07-01'),
('Priya Verma','priya@org.in','9000000002','1999-02-02',2,TRUE,'2021-07-01'),
('Rahul Mehta','rahul@org.in','9000000003','2001-03-03',3,TRUE,'2023-01-01'),
('Sneha Iyer','sneha@org.in','9000000004','1998-04-04',4,TRUE,'2020-07-01'),
('Karan Patel','karan@org.in','9000000005','1997-05-05',5,TRUE,'2019-07-01'),
('Neha Gupta','neha@org.in','9000000006','2000-06-06',6,TRUE,'2022-01-01'),
('Arjun Nair','arjun@org.in','9000000007','1996-07-07',7,TRUE,'2018-01-01'),
('Pooja Singh','pooja@org.in','9000000008','1995-08-08',8,TRUE,'2017-01-01'),
('Rohit Das','rohit@org.in','9000000009','1994-09-09',9,TRUE,'2016-01-01'),
('Ananya Rao','ananya@org.in','9000000010','2002-10-10',10,TRUE,'2023-07-01'),
('Vikas Kumar','vikas@org.in','9000000011','1993-01-11',11,TRUE,'2015-01-01'),
('Meera Pillai','meera@org.in','9000000012','1992-02-12',12,TRUE,'2014-01-01'),
('Suresh Reddy','suresh@org.in','9000000013','1991-03-13',13,TRUE,'2013-01-01'),
('Kavita Joshi','kavita@org.in','9000000014','1990-04-14',14,TRUE,'2012-01-01'),
('Manoj Yadav','manoj@org.in','9000000015','1989-05-15',15,TRUE,'2011-01-01'),
('Deepak Jain','deepak@org.in','9000000016','1988-06-16',16,TRUE,'2010-01-01'),
('Farhan Ali','farhan@org.in','9000000017','1987-07-17',17,TRUE,'2009-01-01'),
('Ritu Saxena','ritu@org.in','9000000018','1999-08-18',18,TRUE,'2021-01-01'),
('Nikhil Bansal','nikhil@org.in','9000000019','1998-09-19',19,TRUE,'2020-01-01'),
('Tanya Kapoor','tanya@org.in','9000000020','2001-10-20',20,TRUE,'2023-08-01');

INSERT INTO Member_Role (member_id,role_id,is_primary,start_date) VALUES
(1,1,TRUE,'2022-07-01'),
(2,2,TRUE,'2021-07-01'),
(3,1,TRUE,'2023-01-01'),
(4,3,TRUE,'2020-07-01'),
(5,4,TRUE,'2019-07-01'),
(6,1,TRUE,'2022-01-01'),
(7,5,TRUE,'2018-01-01'),
(8,7,TRUE,'2017-01-01'),
(9,9,TRUE,'2016-01-01'),
(10,10,TRUE,'2023-07-01'),
(11,11,TRUE,'2015-01-01'),
(12,12,TRUE,'2014-01-01'),
(13,13,TRUE,'2013-01-01'),
(14,14,TRUE,'2012-01-01'),
(15,15,TRUE,'2011-01-01'),
(16,19,TRUE,'2010-01-01'),
(17,20,TRUE,'2009-01-01'),
(18,18,TRUE,'2021-01-01'),
(19,19,TRUE,'2020-01-01'),
(20,1,TRUE,'2023-08-01');

INSERT INTO Member_Contact (member_id,contact_type,contact_value,is_primary) VALUES
(1,'ALT_PHONE','8000000001',FALSE),(2,'ALT_PHONE','8000000002',FALSE),
(3,'ALT_PHONE','8000000003',FALSE),(4,'ALT_PHONE','8000000004',FALSE),
(5,'ALT_PHONE','8000000005',FALSE),(6,'ALT_PHONE','8000000006',FALSE),
(7,'ALT_PHONE','8000000007',FALSE),(8,'ALT_PHONE','8000000008',FALSE),
(9,'ALT_PHONE','8000000009',FALSE),(10,'ALT_PHONE','8000000010',FALSE),
(11,'ALT_PHONE','8000000011',FALSE),(12,'ALT_PHONE','8000000012',FALSE),
(13,'ALT_PHONE','8000000013',FALSE),(14,'ALT_PHONE','8000000014',FALSE),
(15,'ALT_PHONE','8000000015',FALSE),(16,'ALT_PHONE','8000000016',FALSE),
(17,'ALT_PHONE','8000000017',FALSE),(18,'ALT_PHONE','8000000018',FALSE),
(19,'ALT_PHONE','8000000019',FALSE),(20,'ALT_PHONE','8000000020',FALSE);

INSERT INTO Hostel (hostel_name, caretaker_member_id, caretaker_contact) VALUES
('Ganga Hostel',14,'7000000001'),
('Yamuna Hostel',15,'7000000002'),
('Krishna Hostel',16,'7000000003'),
('Kaveri Hostel',17,'7000000004'),
('Godavari Hostel',18,'7000000005'),
('Narmada Hostel',19,'7000000006'),
('Saraswati Hostel',13,'7000000007'),
('Brahmaputra Hostel',12,'7000000008'),
('Tapti Hostel',11,'7000000009'),
('Mahanadi Hostel',10,'7000000010'),
('Sabarmati Hostel',9,'7000000011'),
('Indus Hostel',8,'7000000012'),
('Teesta Hostel',7,'7000000013'),
('Periyar Hostel',6,'7000000014'),
('Hooghly Hostel',5,'7000000015'),
('Chambal Hostel',4,'7000000016'),
('Tungabhadra Hostel',3,'7000000017'),
('Beas Hostel',2,'7000000018'),
('Ravi Hostel',1,'7000000019'),
('Satluj Hostel',20,'7000000020');

INSERT INTO Lab (lab_name, department_id, lab_room_no, contact_no, incharge_member_id) VALUES
('AI Lab',8,'F201','7100000001',8),
('Robotics Lab',4,'C301','7100000002',5),
('Power Systems Lab',3,'B210','7100000003',3),
('Civil Survey Lab',5,'D102','7100000004',4),
('Electronics Lab',6,'E110','7100000005',6),
('Data Science Lab',7,'F101','7100000006',7),
('ML Lab',8,'F202','7100000007',8),
('Networking Lab',9,'G103','7100000008',9),
('IT Lab',2,'A210','7100000009',2),
('Programming Lab',1,'A101','7100000010',1),
('CAD Lab',4,'C210','7100000011',5),
('Thermal Lab',4,'C220','7100000012',5),
('Microprocessor Lab',6,'E201','7100000013',6),
('Physics Lab',3,'B110','7100000014',3),
('Chemistry Lab',5,'D210','7100000015',4),
('Research Lab',16,'R101','7100000016',16),
('Security Lab',9,'G210','7100000017',9),
('Cloud Lab',2,'A310','7100000018',2),
('IoT Lab',8,'F303','7100000019',8),
('VR Lab',7,'F401','7100000020',7);

INSERT INTO Office_Room (department_id, building_no, office_room_no, office_contact) VALUES
(1,'A','101','7200000001'),
(2,'A','102','7200000002'),
(3,'B','103','7200000003'),
(4,'C','104','7200000004'),
(5,'D','105','7200000005'),
(6,'E','106','7200000006'),
(7,'F','107','7200000007'),
(8,'F','108','7200000008'),
(9,'G','109','7200000009'),
(10,'Admin','110','7200000010'),
(11,'Admin','111','7200000011'),
(12,'Admin','112','7200000012'),
(13,'Library','113','7200000013'),
(14,'Hostel','114','7200000014'),
(15,'Placement','115','7200000015'),
(16,'R&D','116','7200000016'),
(17,'IT','117','7200000017'),
(18,'Gate','118','7200000018'),
(19,'Medical','119','7200000019'),
(20,'Admin','120','7200000020');

INSERT INTO Search_Log
(searched_by_member_id, search_keyword, search_time, result_count, filter_department_id, filter_role_id)
VALUES
(1,'Rahul','2026-01-01 10:00:00',3,1,1),
(2,'Library','2026-01-02 11:00:00',5,13,13),
(3,'Hostel','2026-01-03 12:00:00',2,14,14),
(4,'AI','2026-01-04 09:00:00',6,8,2),
(5,'Placement','2026-01-05 08:30:00',4,15,19),
(6,'Doctor','2026-01-06 10:15:00',1,19,16),
(7,'Security','2026-01-07 14:20:00',3,18,15),
(8,'Admin','2026-01-08 13:00:00',7,10,10),
(9,'Accounts','2026-01-09 15:00:00',2,11,11),
(10,'HR','2026-01-10 16:00:00',5,12,12),
(11,'Research','2026-01-11 11:00:00',2,16,20),
(12,'IT','2026-01-12 12:00:00',3,17,18),
(13,'Civil','2026-01-13 09:00:00',4,5,4),
(14,'Mechanical','2026-01-14 10:00:00',5,4,3),
(15,'Electrical','2026-01-15 11:00:00',6,3,2),
(16,'Data','2026-01-16 12:00:00',3,7,1),
(17,'Exam','2026-01-17 13:00:00',2,20,10),
(18,'AI Lab','2026-01-18 14:00:00',4,8,5),
(19,'Cloud','2026-01-19 15:00:00',3,2,18),
(20,'Security','2026-01-20 16:00:00',5,18,15);

INSERT INTO Directory_Interaction_Log
(actor_member_id,target_member_id,interaction_type,interaction_time)
VALUES
(1,2,'CLICK_CALL','2026-02-01 10:00:00'),
(2,3,'VIEW_PROFILE','2026-02-01 11:00:00'),
(3,4,'CLICK_EMAIL','2026-02-01 12:00:00'),
(4,5,'CLICK_CALL','2026-02-02 10:00:00'),
(5,6,'VIEW_PROFILE','2026-02-02 11:00:00'),
(6,7,'CLICK_EMAIL','2026-02-02 12:00:00'),
(7,8,'CLICK_CALL','2026-02-03 10:00:00'),
(8,9,'VIEW_PROFILE','2026-02-03 11:00:00'),
(9,10,'CLICK_EMAIL','2026-02-03 12:00:00'),
(10,11,'CLICK_CALL','2026-02-04 10:00:00'),
(11,12,'VIEW_PROFILE','2026-02-04 11:00:00'),
(12,13,'CLICK_EMAIL','2026-02-04 12:00:00'),
(13,14,'CLICK_CALL','2026-02-05 10:00:00'),
(14,15,'VIEW_PROFILE','2026-02-05 11:00:00'),
(15,16,'CLICK_EMAIL','2026-02-05 12:00:00'),
(16,17,'CLICK_CALL','2026-02-06 10:00:00'),
(17,18,'VIEW_PROFILE','2026-02-06 11:00:00'),
(18,19,'CLICK_EMAIL','2026-02-06 12:00:00'),
(19,20,'CLICK_CALL','2026-02-07 10:00:00'),
(20,1,'VIEW_PROFILE','2026-02-07 11:00:00');

INSERT INTO Login_History
(member_id,login_time,logout_time,ip_address)
VALUES
(1,'2026-02-01 09:00:00','2026-02-01 10:00:00','192.168.1.1'),
(2,'2026-02-01 09:05:00','2026-02-01 10:05:00','192.168.1.2'),
(3,'2026-02-01 09:10:00','2026-02-01 10:10:00','192.168.1.3'),
(4,'2026-02-01 09:15:00','2026-02-01 10:15:00','192.168.1.4'),
(5,'2026-02-01 09:20:00','2026-02-01 10:20:00','192.168.1.5'),
(6,'2026-02-01 09:25:00','2026-02-01 10:25:00','192.168.1.6'),
(7,'2026-02-01 09:30:00','2026-02-01 10:30:00','192.168.1.7'),
(8,'2026-02-01 09:35:00','2026-02-01 10:35:00','192.168.1.8'),
(9,'2026-02-01 09:40:00','2026-02-01 10:40:00','192.168.1.9'),
(10,'2026-02-01 09:45:00','2026-02-01 10:45:00','192.168.1.10'),
(11,'2026-02-01 09:50:00','2026-02-01 10:50:00','192.168.1.11'),
(12,'2026-02-01 09:55:00','2026-02-01 10:55:00','192.168.1.12'),
(13,'2026-02-01 10:00:00','2026-02-01 11:00:00','192.168.1.13'),
(14,'2026-02-01 10:05:00','2026-02-01 11:05:00','192.168.1.14'),
(15,'2026-02-01 10:10:00','2026-02-01 11:10:00','192.168.1.15'),
(16,'2026-02-01 10:15:00','2026-02-01 11:15:00','192.168.1.16'),
(17,'2026-02-01 10:20:00','2026-02-01 11:20:00','192.168.1.17'),
(18,'2026-02-01 10:25:00','2026-02-01 11:25:00','192.168.1.18'),
(19,'2026-02-01 10:30:00','2026-02-01 11:30:00','192.168.1.19'),
(20,'2026-02-01 10:35:00','2026-02-01 11:35:00','192.168.1.20');

INSERT INTO Audit_Log
(performed_by_member_id,target_member_id,action_type,affected_table,affected_row_pk,action_time)
VALUES
(9,1,'INSERT','Member','1','2026-02-01 12:00:00'),
(9,2,'UPDATE','Member','2','2026-02-01 12:05:00'),
(9,3,'DELETE','Member','3','2026-02-01 12:10:00'),
(9,4,'INSERT','Department','4','2026-02-01 12:15:00'),
(9,5,'UPDATE','Department','5','2026-02-01 12:20:00'),
(9,6,'DELETE','Department','6','2026-02-01 12:25:00'),
(9,7,'INSERT','Role','7','2026-02-01 12:30:00'),
(9,8,'UPDATE','Role','8','2026-02-01 12:35:00'),
(9,9,'DELETE','Role','9','2026-02-01 12:40:00'),
(9,10,'EXPORT','Member','10','2026-02-01 12:45:00'),
(9,11,'INSERT','Lab','11','2026-02-01 12:50:00'),
(9,12,'UPDATE','Lab','12','2026-02-01 12:55:00'),
(9,13,'DELETE','Lab','13','2026-02-01 13:00:00'),
(9,14,'INSERT','Hostel','14','2026-02-01 13:05:00'),
(9,15,'UPDATE','Hostel','15','2026-02-01 13:10:00'),
(9,16,'DELETE','Hostel','16','2026-02-01 13:15:00'),
(9,17,'INSERT','Office_Room','17','2026-02-01 13:20:00'),
(9,18,'UPDATE','Office_Room','18','2026-02-01 13:25:00'),
(9,19,'DELETE','Office_Room','19','2026-02-01 13:30:00'),
(9,20,'EMERGENCY_VIEW','Member','20','2026-02-01 13:35:00');

/* -----------------------------
   Verification checks
   ----------------------------- */

-- Basic counts
SELECT 'departments' AS item, COUNT(*) AS cnt FROM Department;
SELECT 'members' AS item, COUNT(*) AS cnt FROM Member;
SELECT 'roles' AS item, COUNT(*) AS cnt FROM Role;
SELECT 'member_roles' AS item, COUNT(*) AS cnt FROM Member_Role;
SELECT 'member_contacts' AS item, COUNT(*) AS cnt FROM Member_Contact;

-- Logical data checks (should return zero rows/counts if data is consistent)
SELECT COUNT(*) AS members_with_dob_on_or_after_join FROM Member WHERE dob >= join_date;
SELECT COUNT(*) AS memberrole_invalid_dates FROM Member_Role WHERE end_date IS NOT NULL AND start_date >= end_date;
SELECT COUNT(*) AS dept_hours_invalid FROM Department WHERE opening_hours >= closing_hours;

-- Check for members with multiple primary contacts (shows member_id and count >1)
SELECT member_id, COUNT(*) AS primary_count FROM Member_Contact WHERE is_primary = TRUE GROUP BY member_id HAVING COUNT(*) > 1;

-- Orphan foreign-key check generator: run this query, then run the produced SELECTs to see orphan counts
SELECT CONCAT(
  'SELECT ''', kcu.TABLE_SCHEMA, '.', kcu.TABLE_NAME, ''' AS child_table, ''', kcu.COLUMN_NAME,
  ''' AS child_column, ''', kcu.REFERENCED_TABLE_NAME, ''' AS parent_table, ''', kcu.REFERENCED_COLUMN_NAME,
  ''' AS parent_column, COUNT(*) AS orphan_count FROM ', kcu.TABLE_SCHEMA, '.', kcu.TABLE_NAME,
  ' LEFT JOIN ', kcu.REFERENCED_TABLE_SCHEMA, '.', kcu.REFERENCED_TABLE_NAME,
  ' ON ', kcu.TABLE_NAME, '.', kcu.COLUMN_NAME, ' = ', kcu.REFERENCED_TABLE_NAME, '.', kcu.REFERENCED_COLUMN_NAME,
  ' WHERE ', kcu.REFERENCED_TABLE_NAME, '.', kcu.REFERENCED_COLUMN_NAME, ' IS NULL;'
) AS check_statement
FROM information_schema.KEY_COLUMN_USAGE kcu
WHERE kcu.REFERENCED_TABLE_NAME IS NOT NULL
  AND kcu.TABLE_SCHEMA = 'CallHub'
ORDER BY kcu.TABLE_NAME, kcu.COLUMN_NAME;

-- Quick note: if you want these checks run automatically, capture the output of the generator and execute each line.

-- End of setup_all.sql
