-- phpMyAdmin SQL Dump
-- version 5.1.2
-- https://www.phpmyadmin.net/
--
-- Host: localhost:3306
-- Generation Time: 22 أكتوبر 2025 الساعة 12:23
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
  `Password` varchar(100) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- إرجاع أو استيراد بيانات الجدول `admin`
--

INSERT INTO `admin` (`AdminID`, `Username`, `Password`) VALUES
(1, 'adminformujeer', 'adminformujeerPass');

-- --------------------------------------------------------

--
-- بنية الجدول `admin_devices`
--

CREATE TABLE `admin_devices` (
  `id` int(11) NOT NULL,
  `admin_id` int(11) NOT NULL,
  `player_id` varchar(100) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

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
  `Price` decimal(4,2) DEFAULT NULL,
  `timeslot_id` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

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
(4, 'user_reem', '0504444444', 'ريم الحربي', '12345', 3);

-- --------------------------------------------------------

--
-- بنية الجدول `consultation`
--

CREATE TABLE `consultation` (
  `AppointmentID` int(11) NOT NULL,
  `Details` text NOT NULL,
  `File` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

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
(1, 'hanenLaw', 'حنين الفصيلي', '0551112233', 'Hanen@123', 'L-2025-001', 6, 'Female', 'القانون التجاري', 'العقود', 'التحكيم التجاري', 'license_hanen.pdf', 'بكالوريوس قانون', 'القانون العام', 'lawyer1.jpg', 'Pending', 5, '0.00'),
(2, 'munirahLaw', 'منيره السليم', '0552223344', 'Munirah@123', 'L-2025-002', 4, 'Female', 'القانون المدني', 'الأحوال الشخصية', 'القضايا العقارية', 'license_munirah.pdf', 'بكالوريوس قانون', 'القانون الخاص', 'lawyer1.jpg', 'Approved', 5, '0.00'),
(3, 'lamaLaw', 'لمى الخثلان', '0553334455', 'Lama@123', 'L-2025-003', 5, 'Female', 'القانون الجنائي', 'الجرائم الإلكترونية', 'القضايا العمالية', 'license_lama.pdf', 'ماجستير قانون', 'القانون الجنائي', 'lawyer1.jpg', 'Approved', 5, '0.00'),
(4, 'layanLaw', 'ليان الماضي', '0554445566', 'Layan@123', 'L-2025-004', 3, 'Female', 'القانون الإداري', 'الأنظمة الحكومية', 'العقود الإدارية', 'license_layan.pdf', 'بكالوريوس قانون', 'القانون الإداري', 'lawyer1.jpg', 'Approved', 5, '0.00');

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
(1, 1, 1, 'license1.pdf\n', 'حنين الفصيلي', '123456', 'Pending', '2025-10-17 18:27:14'),
(2, 1, 2, 'license2.pdf', 'منيره السليم', '678900', 'Approved', '2025-10-17 18:27:14');

-- --------------------------------------------------------

--
-- بنية الجدول `timeslot`
--

CREATE TABLE `timeslot` (
  `id` int(11) NOT NULL,
  `lawyer_id` int(11) NOT NULL,
  `day` varchar(20) NOT NULL,
  `time` time NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Indexes for dumped tables
--

--
-- Indexes for table `admin`
--
ALTER TABLE `admin`
  ADD PRIMARY KEY (`AdminID`),
  ADD UNIQUE KEY `Username` (`Username`);

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
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `appointment`
--
ALTER TABLE `appointment`
  MODIFY `AppointmentID` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `client`
--
ALTER TABLE `client`
  MODIFY `ClientID` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `feedback`
--
ALTER TABLE `feedback`
  MODIFY `FeedbackID` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

--
-- AUTO_INCREMENT for table `lawyer`
--
ALTER TABLE `lawyer`
  MODIFY `LawyerID` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `request`
--
ALTER TABLE `request`
  MODIFY `RequestID` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `timeslot`
--
ALTER TABLE `timeslot`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

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
  ADD CONSTRAINT `feedback_ibfk_1` FOREIGN KEY (`LawyerID`) REFERENCES `lawyer` (`LawyerID`),
  ADD CONSTRAINT `feedback_ibfk_2` FOREIGN KEY (`ClientID`) REFERENCES `client` (`ClientID`);

--
-- القيود للجدول `request`
--
ALTER TABLE `request`
  ADD CONSTRAINT `request_ibfk_1` FOREIGN KEY (`AdminID`) REFERENCES `admin` (`AdminID`),
  ADD CONSTRAINT `request_ibfk_2` FOREIGN KEY (`LawyerID`) REFERENCES `lawyer` (`LawyerID`);

--
-- القيود للجدول `timeslot`
--
ALTER TABLE `timeslot`
  ADD CONSTRAINT `timeslot_ibfk_1` FOREIGN KEY (`lawyer_id`) REFERENCES `lawyer` (`LawyerID`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
