-- phpMyAdmin SQL Dump
-- version 5.1.2
-- https://www.phpmyadmin.net/
--
-- Host: localhost:8889
-- Generation Time: Oct 15, 2025 at 08:39 AM
-- Server version: 5.7.24
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
-- Table structure for table `admin`
--

CREATE TABLE `admin` (
  `AdminID` int(11) NOT NULL,
  `Username` varchar(50) NOT NULL,
  `Password` varchar(100) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `appointment`
--

CREATE TABLE `appointment` (
  `AppointmentID` int(11) NOT NULL,
  `LawyerID` int(11) NOT NULL,
  `ClientID` int(11) NOT NULL,
  `DateTime` datetime NOT NULL,
  `Status` enum('Upcoming','Active','Past') DEFAULT 'Upcoming',
  `Price` decimal(4,2) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `client`
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
-- Dumping data for table `client`
--

INSERT INTO `client` (`ClientID`, `Username`, `PhoneNumber`, `FullName`, `Password`, `Points`) VALUES
(1, 'user_huda', '0501111111', 'هدى المطيري', '12345', 5),
(2, 'user_lama', '0502222222', 'لمى العبدالله', '12345', 0),
(3, 'user_fatima', '0503333333', 'فاطمة العنزي', '12345', 2),
(4, 'user_reem', '0504444444', 'ريم الحربي', '12345', 3);

-- --------------------------------------------------------

--
-- Table structure for table `consultation`
--

CREATE TABLE `consultation` (
  `AppointmentID` int(11) NOT NULL,
  `Details` text NOT NULL,
  `File` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `contractreview`
--

CREATE TABLE `contractreview` (
  `AppointmentID` int(11) NOT NULL,
  `File` varchar(255) NOT NULL,
  `Details` text
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `feedback`
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
-- Dumping data for table `feedback`
--

INSERT INTO `feedback` (`FeedbackID`, `LawyerID`, `ClientID`, `Rate`, `Review`, `DateGiven`) VALUES
(5, 1, 1, 5, 'خدمة ممتازة وسريعة جداً', '2025-10-15 11:20:31'),
(6, 1, 2, 4, 'تجربة رائعة لكن التأخير بسيط بالرد', '2025-10-15 11:20:31'),
(7, 2, 3, 5, 'كانت متعاونة ومتفهمة جداً', '2025-10-15 11:20:31'),
(8, 3, 4, 5, 'شرح واضح ومساعدة قانونية ممتازة', '2025-10-15 11:20:31');

-- --------------------------------------------------------

--
-- Table structure for table `lawyer`
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
  `Points` int(11) DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `lawyer`
--

INSERT INTO `lawyer` (`LawyerID`, `Username`, `FullName`, `PhoneNumber`, `Password`, `LicenseNumber`, `YearsOfExp`, `Gender`, `MainSpecialization`, `FSubSpecialization`, `SSubSpecialization`, `LicenseFile`, `EducationQualification`, `AcademicMajor`, `LawyerPhoto`, `Status`, `Points`) VALUES
(1, 'hanenLaw', 'حنين الفصيلي', '0551112233', 'Hanen@123', 'L-2025-001', 6, 'Female', 'القانون التجاري', 'العقود', 'التحكيم التجاري', 'license_hanen.pdf', 'بكالوريوس قانون', 'القانون العام', 'lawyer1.jpg', 'Approved', 5),
(2, 'munirahLaw', 'منيره السليم', '0552223344', 'Munirah@123', 'L-2025-002', 4, 'Female', 'القانون المدني', 'الأحوال الشخصية', 'القضايا العقارية', 'license_munirah.pdf', 'بكالوريوس قانون', 'القانون الخاص', 'lawyer1.jpg', 'Approved', 5),
(3, 'lamaLaw', 'لمى الخثلان', '0553334455', 'Lama@123', 'L-2025-003', 5, 'Female', 'القانون الجنائي', 'الجرائم الإلكترونية', 'القضايا العمالية', 'license_lama.pdf', 'ماجستير قانون', 'القانون الجنائي', 'lawyer1.jpg', 'Approved', 5),
(4, 'layanLaw', 'ليان الماضي', '0554445566', 'Layan@123', 'L-2025-004', 3, 'Female', 'القانون الإداري', 'الأنظمة الحكومية', 'العقود الإدارية', 'license_layan.pdf', 'بكالوريوس قانون', 'القانون الإداري', 'lawyer1.jpg', 'Approved', 5);

-- --------------------------------------------------------

--
-- Table structure for table `request`
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
-- Indexes for dumped tables
--

--
-- Indexes for table `admin`
--
ALTER TABLE `admin`
  ADD PRIMARY KEY (`AdminID`),
  ADD UNIQUE KEY `Username` (`Username`);

--
-- Indexes for table `appointment`
--
ALTER TABLE `appointment`
  ADD PRIMARY KEY (`AppointmentID`),
  ADD KEY `LawyerID` (`LawyerID`),
  ADD KEY `ClientID` (`ClientID`);

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
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `admin`
--
ALTER TABLE `admin`
  MODIFY `AdminID` int(11) NOT NULL AUTO_INCREMENT;

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
  MODIFY `RequestID` int(11) NOT NULL AUTO_INCREMENT;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `appointment`
--
ALTER TABLE `appointment`
  ADD CONSTRAINT `appointment_ibfk_1` FOREIGN KEY (`LawyerID`) REFERENCES `lawyer` (`LawyerID`),
  ADD CONSTRAINT `appointment_ibfk_2` FOREIGN KEY (`ClientID`) REFERENCES `client` (`ClientID`);

--
-- Constraints for table `consultation`
--
ALTER TABLE `consultation`
  ADD CONSTRAINT `consultation_ibfk_1` FOREIGN KEY (`AppointmentID`) REFERENCES `appointment` (`AppointmentID`);

--
-- Constraints for table `contractreview`
--
ALTER TABLE `contractreview`
  ADD CONSTRAINT `contractreview_ibfk_1` FOREIGN KEY (`AppointmentID`) REFERENCES `appointment` (`AppointmentID`);

--
-- Constraints for table `feedback`
--
ALTER TABLE `feedback`
  ADD CONSTRAINT `feedback_ibfk_1` FOREIGN KEY (`LawyerID`) REFERENCES `lawyer` (`LawyerID`),
  ADD CONSTRAINT `feedback_ibfk_2` FOREIGN KEY (`ClientID`) REFERENCES `client` (`ClientID`);

--
-- Constraints for table `request`
--
ALTER TABLE `request`
  ADD CONSTRAINT `request_ibfk_1` FOREIGN KEY (`AdminID`) REFERENCES `admin` (`AdminID`),
  ADD CONSTRAINT `request_ibfk_2` FOREIGN KEY (`LawyerID`) REFERENCES `lawyer` (`LawyerID`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
