-- phpMyAdmin SQL Dump
-- version 5.1.2
-- https://www.phpmyadmin.net/
--
-- Host: localhost:8889
-- Generation Time: 15 نوفمبر 2025 الساعة 23:29
-- إصدار الخادم: 5.7.24
-- PHP Version: 8.3.1

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `mujeer`
--

-- --------------------------------------------------------

--
-- بنية الجدول `admin`
--

CREATE TABLE `admin` (
  `AdminID` int(11) NOT NULL,
  `Username` varchar(50) NOT NULL,
  `Password` varchar(100) NOT NULL,
  `PhoneNumber` varchar(20) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- إرجاع أو استيراد بيانات الجدول `admin`
--

INSERT INTO `admin` (`AdminID`, `Username`, `Password`, `PhoneNumber`) VALUES
(1, 'adminformujeer', '$2y$10$hBulRI6OzxHyJ7LhlQgEleGq5o3HeXsIKIJbArCGvuMPAth.r7o2y', '0554441199');

-- --------------------------------------------------------

--
-- بنية الجدول `admin_devices`
--

CREATE TABLE `admin_devices` (
  `id` int(11) NOT NULL,
  `admin_id` int(11) NOT NULL,
  `player_id` varchar(100) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- إرجاع أو استيراد بيانات الجدول `admin_devices`
--

INSERT INTO `admin_devices` (`id`, `admin_id`, `player_id`) VALUES
(1, 1, '9662263a-73db-4ffb-9d65-e3c9be9353be');

-- --------------------------------------------------------

--
-- بنية الجدول `appointment`
--

CREATE TABLE `appointment` (
  `AppointmentID` int(11) NOT NULL,
  `LawyerID` int(11) NOT NULL,
  `ClientID` int(11) NOT NULL,
  `DateTime` datetime NOT NULL,
  `Status` enum('Upcoming','Active','Past') DEFAULT 'Upcoming',
  `Price` decimal(10,2) DEFAULT NULL,
  `timeslot_id` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- إرجاع أو استيراد بيانات الجدول `appointment`
--

INSERT INTO `appointment` (`AppointmentID`, `LawyerID`, `ClientID`, `DateTime`, `Status`, `Price`, `timeslot_id`) VALUES
(1, 7, 5, '2025-11-03 09:41:14', 'Active', NULL, 1),
(2, 1, 1, '2025-11-16 01:33:54', 'Upcoming', '200.00', 2),
(3, 2, 1, '2025-11-16 01:37:51', 'Upcoming', '350.00', 6),
(4, 4, 1, '2025-11-16 01:38:31', 'Upcoming', '200.00', 12),
(7, 3, 1, '2025-11-16 01:55:31', 'Upcoming', '1000.00', 10);

-- --------------------------------------------------------

--
-- بنية الجدول `client`
--

CREATE TABLE `client` (
  `ClientID` int(11) NOT NULL,
  `Username` varchar(50) NOT NULL,
  `PhoneNumber` varchar(20) NOT NULL,
  `FullName` varchar(100) NOT NULL,
  `Password` varchar(100) NOT NULL,
  `Points` int(11) DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- إرجاع أو استيراد بيانات الجدول `client`
--

INSERT INTO `client` (`ClientID`, `Username`, `PhoneNumber`, `FullName`, `Password`, `Points`) VALUES
(1, 'user_huda', '0501111111', 'هدى المطيري', '12345', 5),
(2, 'user_lama', '0502222222', 'لمى العبدالله', '12345', 0),
(3, 'user_fatima', '0503333333', 'فاطمة العنزي', '12345', 2),
(4, 'user_reem', '0504444444', 'ريم الحربي', '12345', 3),
(5, 'danoo', '0512345676', 'dana yahya', '$2y$10$hBulRI6OzxHyJ7LhlQgEleGq5o3HeXsIKIJbArCGvuMPAth.r7o2y', 0),
(6, 'looloo', '0513246354', 'lolo naser', '$2y$10$KmL/syqtGZhYzFKK7ETZy.XXGoIN8ezrJJ4RM5pwCALPjaGbcNcTq', 0),
(7, 'lamia', '0546576546', 'lamia', '$2y$10$B4pFACrdnCABVYmLRFl7Zui/zOlBzaDrOY2Dy/ptxkSEmfCY0R8lO', 0);

-- --------------------------------------------------------

--
-- بنية الجدول `consultation`
--

CREATE TABLE `consultation` (
  `AppointmentID` int(11) NOT NULL,
  `Details` text NOT NULL,
  `File` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- إرجاع أو استيراد بيانات الجدول `consultation`
--

INSERT INTO `consultation` (`AppointmentID`, `Details`, `File`) VALUES
(2, 'القضية', ''),
(3, 'case', ''),
(4, 'case2', ''),
(7, 'case1', '');

-- --------------------------------------------------------

--
-- بنية الجدول `contractreview`
--

CREATE TABLE `contractreview` (
  `AppointmentID` int(11) NOT NULL,
  `File` varchar(255) NOT NULL,
  `Details` text
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- بنية الجدول `feedback`
--

CREATE TABLE `feedback` (
  `FeedbackID` int(11) NOT NULL,
  `LawyerID` int(11) NOT NULL,
  `ClientID` int(11) NOT NULL,
  `Rate` tinyint(4) NOT NULL,
  `Review` text NOT NULL,
  `DateGiven` datetime DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- إرجاع أو استيراد بيانات الجدول `feedback`
--

INSERT INTO `feedback` (`FeedbackID`, `LawyerID`, `ClientID`, `Rate`, `Review`, `DateGiven`) VALUES
(5, 1, 1, 5, 'خدمة ممتازة وسريعة جداً', '2025-10-15 11:20:31'),
(6, 1, 2, 4, 'تجربة رائعة لكن التأخير بسيط بالرد', '2025-10-15 11:20:31'),
(7, 2, 3, 5, 'كانت متعاونة ومتفهمة جداً', '2025-10-15 11:20:31'),
(8, 3, 4, 5, 'شرح واضح ومساعدة قانونية ممتازة', '2025-10-15 11:20:31');

-- --------------------------------------------------------

--
-- بنية الجدول `lawyer`
--

CREATE TABLE `lawyer` (
  `LawyerID` int(11) NOT NULL,
  `Username` varchar(50) NOT NULL,
  `FullName` varchar(100) NOT NULL,
  `PhoneNumber` varchar(20) NOT NULL,
  `Password` varchar(100) NOT NULL,
  `LicenseNumber` varchar(50) NOT NULL,
  `YearsOfExp` int(11) NOT NULL,
  `Gender` enum('Male','Female') NOT NULL,
  `MainSpecialization` varchar(100) NOT NULL,
  `FSubSpecialization` varchar(100) NOT NULL,
  `SSubSpecialization` varchar(100) NOT NULL,
  `LicenseFile` varchar(255) NOT NULL,
  `EducationQualification` varchar(150) NOT NULL,
  `AcademicMajor` varchar(100) NOT NULL,
  `LawyerPhoto` varchar(255) NOT NULL,
  `Status` enum('Pending','Approved','Rejected') DEFAULT 'Pending',
  `Points` int(11) DEFAULT '0',
  `price` decimal(10,2) DEFAULT '0.00'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- إرجاع أو استيراد بيانات الجدول `lawyer`
--

INSERT INTO `lawyer` (`LawyerID`, `Username`, `FullName`, `PhoneNumber`, `Password`, `LicenseNumber`, `YearsOfExp`, `Gender`, `MainSpecialization`, `FSubSpecialization`, `SSubSpecialization`, `LicenseFile`, `EducationQualification`, `AcademicMajor`, `LawyerPhoto`, `Status`, `Points`, `price`) VALUES
(1, 'hanenLaw', 'حنين الفصيلي', '0551112233', 'Hanen@123', 'L-2025-001', 6, 'Female', 'القانون التجاري', 'العقود', 'التحكيم التجاري', 'license_hanen.pdf', 'بكالوريوس ', 'القانون ', 'lawyer1.jpg', 'Approved', 205, '200.00'),
(2, 'munirahLaw', 'منيره السليم', '0552223344', 'Munirah@123', 'L-2025-002', 4, 'Female', 'القانون المدني', 'الأحوال الشخصية', 'القضايا العقارية', 'license_munirah.pdf', 'بكالوريوس ', 'القانون ', 'lawyer1.jpg', 'Approved', 355, '350.00'),
(3, 'lamaLaw', 'لمى الخثلان', '0553334455', 'Lama@123', 'L-2025-003', 5, 'Female', 'القانون الجنائي', 'الجرائم الإلكترونية', 'القضايا العمالية', 'license_lama.pdf', 'ماجستير', 'القانون ', 'lawyer1.jpg', 'Approved', 1005, '1000.00'),
(4, 'layanLaw', 'ليان الماضي', '0554445566', 'Layan@123', 'L-2025-004', 3, 'Female', 'القانون الإداري', 'الأنظمة الحكومية', 'العقود الإدارية', 'license_layan.pdf', 'بكالوريوس ', 'القانون ', 'lawyer1.jpg', 'Approved', 205, '200.00'),
(7, 'fahadyah', 'فهد المطلق', '0564614253', '$2y$10$8TdCZyVBaVZwat3C.m4o1enWG01j1haylmDhL5RDiu1Y.9nC.Sdg.', '1166554', 4, 'Male', 'ملكية فكرية', 'القضايا الجنائية', 'القضايا التجارية', 'license_fahadyah_1761246600.pdf', 'دكتوراه', 'الشريعة', 'lawyer1.jpg', 'Approved', 0, '120.00');

-- --------------------------------------------------------

--
-- بنية الجدول `request`
--

CREATE TABLE `request` (
  `RequestID` int(11) NOT NULL,
  `AdminID` int(11) NOT NULL,
  `LawyerID` int(11) NOT NULL,
  `LawyerLicense` varchar(255) NOT NULL,
  `LawyerName` varchar(100) NOT NULL,
  `LicenseNumber` varchar(50) NOT NULL,
  `Status` enum('Pending','Approved','Rejected') DEFAULT 'Pending',
  `RequestDate` datetime DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- إرجاع أو استيراد بيانات الجدول `request`
--

INSERT INTO `request` (`RequestID`, `AdminID`, `LawyerID`, `LawyerLicense`, `LawyerName`, `LicenseNumber`, `Status`, `RequestDate`) VALUES
(1, 1, 1, 'license1.pdf\n', 'حنين الفصيلي', '123456', 'Approved', '2025-10-17 18:27:14'),
(2, 1, 2, 'license2.pdf', 'منيره السليم', '678900', 'Approved', '2025-10-17 18:27:14'),
(5, 1, 7, 'license_fahadyah_1761246600.pdf', 'fahad yahya', '1166554', 'Approved', '2025-10-23 22:10:01');

-- --------------------------------------------------------

--
-- بنية الجدول `timeslot`
--

CREATE TABLE `timeslot` (
  `id` int(11) NOT NULL,
  `lawyer_id` int(11) NOT NULL,
  `day` varchar(20) NOT NULL,
  `time` time NOT NULL,
  `is_booked` tinyint(1) DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- إرجاع أو استيراد بيانات الجدول `timeslot`
--

INSERT INTO `timeslot` (`id`, `lawyer_id`, `day`, `time`, `is_booked`) VALUES
(1, 7, 'monday', '07:00:00', 1),
(2, 1, 'monday', '09:00:00', 1),
(3, 1, 'wednesday', '14:00:00', 0),
(4, 1, 'thursday', '18:00:00', 0),
(5, 2, 'monday', '10:00:00', 0),
(6, 2, 'tuesday', '12:00:00', 1),
(7, 2, 'thursday', '17:00:00', 0),
(8, 3, 'sunday', '08:30:00', 0),
(9, 3, 'tuesday', '15:00:00', 0),
(10, 3, 'friday', '19:00:00', 1),
(11, 4, 'wednesday', '11:00:00', 0),
(12, 4, 'thursday', '13:30:00', 1),
(13, 4, 'saturday', '16:00:00', 0),
(14, 7, 'monday', '07:00:00', 0),
(15, 7, 'tuesday', '09:30:00', 0),
(16, 7, 'friday', '20:00:00', 0);

--
-- Indexes for dumped tables
--

--
-- Indexes for table `admin`
--
ALTER TABLE `admin`
  ADD PRIMARY KEY (`AdminID`),
  ADD UNIQUE KEY `Username` (`Username`),
  ADD UNIQUE KEY `PhoneNumber` (`PhoneNumber`);

--
-- Indexes for table `admin_devices`
--
ALTER TABLE `admin_devices`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `player_id` (`player_id`),
  ADD KEY `admin_id` (`admin_id`);

--
-- Indexes for table `appointment`
--
ALTER TABLE `appointment`
  ADD PRIMARY KEY (`AppointmentID`),
  ADD KEY `LawyerID` (`LawyerID`),
  ADD KEY `ClientID` (`ClientID`),
  ADD KEY `timeslot_id` (`timeslot_id`);

--
-- Indexes for table `client`
--
ALTER TABLE `client`
  ADD PRIMARY KEY (`ClientID`),
  ADD UNIQUE KEY `Username` (`Username`),
  ADD UNIQUE KEY `PhoneNumber` (`PhoneNumber`);

--
-- Indexes for table `consultation`
--
ALTER TABLE `consultation`
  ADD PRIMARY KEY (`AppointmentID`);

--
-- Indexes for table `contractreview`
--
ALTER TABLE `contractreview`
  ADD PRIMARY KEY (`AppointmentID`);

--
-- Indexes for table `feedback`
--
ALTER TABLE `feedback`
  ADD PRIMARY KEY (`FeedbackID`),
  ADD KEY `LawyerID` (`LawyerID`),
  ADD KEY `ClientID` (`ClientID`);

--
-- Indexes for table `lawyer`
--
ALTER TABLE `lawyer`
  ADD PRIMARY KEY (`LawyerID`),
  ADD UNIQUE KEY `Username` (`Username`),
  ADD UNIQUE KEY `LicenseNumber` (`LicenseNumber`),
  ADD UNIQUE KEY `PhoneNumber` (`PhoneNumber`);

--
-- Indexes for table `request`
--
ALTER TABLE `request`
  ADD PRIMARY KEY (`RequestID`),
  ADD KEY `AdminID` (`AdminID`),
  ADD KEY `LawyerID` (`LawyerID`);

--
-- Indexes for table `timeslot`
--
ALTER TABLE `timeslot`
  ADD PRIMARY KEY (`id`),
  ADD KEY `lawyer_id` (`lawyer_id`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `admin`
--
ALTER TABLE `admin`
  MODIFY `AdminID` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `admin_devices`
--
ALTER TABLE `admin_devices`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `appointment`
--
ALTER TABLE `appointment`
  MODIFY `AppointmentID` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;

--
-- AUTO_INCREMENT for table `client`
--
ALTER TABLE `client`
  MODIFY `ClientID` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;

--
-- AUTO_INCREMENT for table `feedback`
--
ALTER TABLE `feedback`
  MODIFY `FeedbackID` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

--
-- AUTO_INCREMENT for table `lawyer`
--
ALTER TABLE `lawyer`
  MODIFY `LawyerID` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;

--
-- AUTO_INCREMENT for table `request`
--
ALTER TABLE `request`
  MODIFY `RequestID` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT for table `timeslot`
--
ALTER TABLE `timeslot`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=17;

--
-- قيود الجداول المحفوظة
--

--
-- القيود للجدول `admin_devices`
--
ALTER TABLE `admin_devices`
  ADD CONSTRAINT `admin_devices_ibfk_1` FOREIGN KEY (`admin_id`) REFERENCES `admin` (`AdminID`);

--
-- القيود للجدول `appointment`
--
ALTER TABLE `appointment`
  ADD CONSTRAINT `appointment_ibfk_1` FOREIGN KEY (`LawyerID`) REFERENCES `lawyer` (`LawyerID`),
  ADD CONSTRAINT `appointment_ibfk_2` FOREIGN KEY (`ClientID`) REFERENCES `client` (`ClientID`),
  ADD CONSTRAINT `appointment_ibfk_3` FOREIGN KEY (`timeslot_id`) REFERENCES `timeslot` (`id`);

--
-- القيود للجدول `consultation`
--
ALTER TABLE `consultation`
  ADD CONSTRAINT `consultation_ibfk_1` FOREIGN KEY (`AppointmentID`) REFERENCES `appointment` (`AppointmentID`);

--
-- القيود للجدول `contractreview`
--
ALTER TABLE `contractreview`
  ADD CONSTRAINT `contractreview_ibfk_1` FOREIGN KEY (`AppointmentID`) REFERENCES `appointment` (`AppointmentID`);

--
-- القيود للجدول `feedback`
--
ALTER TABLE `feedback`
  ADD CONSTRAINT `feedback_ibfk_1` FOREIGN KEY (`LawyerID`) REFERENCES `lawyer` (`LawyerID`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `feedback_ibfk_2` FOREIGN KEY (`ClientID`) REFERENCES `client` (`ClientID`);

--
-- القيود للجدول `request`
--
ALTER TABLE `request`
  ADD CONSTRAINT `request_ibfk_1` FOREIGN KEY (`AdminID`) REFERENCES `admin` (`AdminID`),
  ADD CONSTRAINT `request_ibfk_2` FOREIGN KEY (`LawyerID`) REFERENCES `lawyer` (`LawyerID`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- القيود للجدول `timeslot`
--
ALTER TABLE `timeslot`
  ADD CONSTRAINT `timeslot_ibfk_1` FOREIGN KEY (`lawyer_id`) REFERENCES `lawyer` (`LawyerID`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
